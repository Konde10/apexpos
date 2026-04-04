// routes/sales.js — Sales Processing & Checkout
const express = require('express');
const db      = require('../db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// ─── POST /api/sales — Process a sale ────────────────────────
router.post('/', async (req, res) => {
  const { customer_id, items, discount_pct, payment_method,
          cash_tendered, reference_no, notes } = req.body;

  if (!items || !items.length) {
    return res.status(400).json({ error: 'No items provided' });
  }
  if (!payment_method) {
    return res.status(400).json({ error: 'payment_method required' });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Validate all products and lock stock rows
    const productIds = items.map(i => i.product_id);
    const [products] = await conn.query(
      `SELECT p.product_id, p.product_name, p.selling_price, p.cost_price,
              i.quantity_in_stock AS stock
       FROM   products p
       JOIN   inventory i ON p.product_id = i.product_id
       WHERE  p.product_id IN (?) AND p.is_active = 1
       FOR UPDATE`,
      [productIds]
    );

    const productMap = {};
    products.forEach(p => { productMap[p.product_id] = p; });

    // 2. Check stock availability
    for (const item of items) {
      const prod = productMap[item.product_id];
      if (!prod) {
        await conn.rollback();
        return res.status(404).json({ error: `Product ID ${item.product_id} not found` });
      }
      if (prod.stock < item.quantity) {
        await conn.rollback();
        return res.status(409).json({
          error: `Insufficient stock for "${prod.product_name}". Available: ${prod.stock}`
        });
      }
    }

    // 3. Calculate totals
    let subtotal = 0;
    const lineItems = items.map(item => {
      const prod   = productMap[item.product_id];
      const price  = parseFloat(prod.selling_price);
      const cost   = parseFloat(prod.cost_price);
      const qty    = parseInt(item.quantity);
      const lineTot = price * qty;
      subtotal += lineTot;
      return { ...item, unit_price: price, unit_cost: cost, line_total: lineTot,
               product_name: prod.product_name };
    });

    const discPct    = parseFloat(discount_pct) || 0;
    const discAmt    = subtotal * (discPct / 100);
    const afterDisc  = subtotal - discAmt;
    const taxAmt     = afterDisc * 0.15;
    const totalAmt   = afterDisc + taxAmt;
    const changeGiven = payment_method === 'cash' && cash_tendered
      ? Math.max(0, parseFloat(cash_tendered) - totalAmt) : 0;

    // 4. Create sale record
    const txnRef = 'TXN' + Date.now();
    const [saleResult] = await conn.query(
      `INSERT INTO sales
         (transaction_ref, user_id, customer_id, subtotal, discount_pct,
          discount_amount, tax_amount, total_amount, notes)
       VALUES (?,?,?,?,?,?,?,?,?)`,
      [txnRef, req.user.userId, customer_id||null,
       subtotal.toFixed(2), discPct, discAmt.toFixed(2),
       taxAmt.toFixed(2), totalAmt.toFixed(2), notes||null]
    );
    const saleId = saleResult.insertId;

    // 5. Insert sale items + deduct inventory
    for (const item of lineItems) {
      await conn.query(
        `INSERT INTO sale_items
           (sale_id, product_id, product_name, quantity, unit_price, unit_cost, line_total)
         VALUES (?,?,?,?,?,?,?)`,
        [saleId, item.product_id, item.product_name, item.quantity,
         item.unit_price, item.unit_cost, item.line_total.toFixed(2)]
      );
      // Deduct stock
      await conn.query(
        'UPDATE inventory SET quantity_in_stock = quantity_in_stock - ? WHERE product_id = ?',
        [item.quantity, item.product_id]
      );
      // Log inventory adjustment
      await conn.query(
        `INSERT INTO inventory_adjustments
           (product_id, user_id, adjustment_type, quantity_change, note)
         VALUES (?,?,'sale',?,?)`,
        [item.product_id, req.user.userId, -item.quantity, 'Sale: '+txnRef]
      );
    }

    // 6. Save payment record
    await conn.query(
      `INSERT INTO payments
         (sale_id, payment_method, amount, cash_tendered, change_given, reference_no)
       VALUES (?,?,?,?,?,?)`,
      [saleId, payment_method, totalAmt.toFixed(2),
       cash_tendered||null, changeGiven.toFixed(2), reference_no||null]
    );

    // 7. Update customer loyalty points
    if (customer_id) {
      await conn.query(
        `UPDATE customers
         SET loyalty_points   = loyalty_points + ?,
             total_spent      = total_spent + ?,
             total_purchases  = total_purchases + 1
         WHERE customer_id = ?`,
        [Math.floor(totalAmt), totalAmt.toFixed(2), customer_id]
      );
    }

    // 8. Transaction log
    await conn.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'SALE',
       txnRef + ' | ' + payment_method + ' | GHS ' + totalAmt.toFixed(2)]
    );

    await conn.commit();

    res.status(201).json({
      message: 'Sale completed',
      sale: {
        saleId, transaction_ref: txnRef,
        subtotal: +subtotal.toFixed(2),
        discount_amount: +discAmt.toFixed(2),
        tax_amount: +taxAmt.toFixed(2),
        total_amount: +totalAmt.toFixed(2),
        change_given: +changeGiven.toFixed(2),
        payment_method
      }
    });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ error: 'Server error during checkout' });
  } finally {
    conn.release();
  }
});

// ─── GET /api/sales — Sales history ──────────────────────────
router.get('/', async (req, res) => {
  try {
    const { period, cashier_id, limit = 50 } = req.query;
    let sql = `
      SELECT  s.sale_id, s.transaction_ref, s.total_amount, s.discount_amount,
              s.tax_amount, s.subtotal, s.sale_status, s.created_at,
              u.full_name  AS cashier_name,
              c.full_name  AS customer_name,
              p.payment_method,
              p.cash_tendered, p.change_given,
              COUNT(si.sale_item_id) AS item_count
      FROM    sales s
      JOIN    users     u  ON s.user_id     = u.user_id
      LEFT JOIN customers c ON s.customer_id = c.customer_id
      LEFT JOIN payments  p ON s.sale_id     = p.sale_id
      LEFT JOIN sale_items si ON s.sale_id   = si.sale_id
    `;
    const params = [];
    const conditions = ["s.sale_status = 'completed'"];
    if (period === 'today') {
      conditions.push('DATE(s.created_at) = CURDATE()');
    } else if (period === 'week') {
      conditions.push('s.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)');
    } else if (period === 'month') {
      conditions.push('MONTH(s.created_at)=MONTH(NOW()) AND YEAR(s.created_at)=YEAR(NOW())');
    }
    if (cashier_id) {
      conditions.push('s.user_id = ?');
      params.push(cashier_id);
    }
    sql += ' WHERE ' + conditions.join(' AND ');
    sql += ' GROUP BY s.sale_id ORDER BY s.created_at DESC LIMIT ?';
    params.push(parseInt(limit));
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/sales/:id — Single sale with items ─────────────
router.get('/:id', async (req, res) => {
  try {
    const [[sale]] = await db.query(`
      SELECT s.*, u.full_name AS cashier_name, c.full_name AS customer_name,
             p.payment_method, p.cash_tendered, p.change_given, p.reference_no
      FROM   sales s
      JOIN   users u ON s.user_id = u.user_id
      LEFT JOIN customers c ON s.customer_id = c.customer_id
      LEFT JOIN payments  p ON s.sale_id = p.sale_id
      WHERE  s.sale_id = ?`, [req.params.id]);
    if (!sale) return res.status(404).json({ error: 'Sale not found' });
    const [items] = await db.query(
      'SELECT * FROM sale_items WHERE sale_id = ?', [req.params.id]);
    res.json({ ...sale, items });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── PATCH /api/sales/:id/void — Void a sale ─────────────────
router.patch('/:id/void', async (req, res) => {
  const { reason } = req.body;
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // Get sale items to restore stock
    const [[sale]] = await conn.query(
      'SELECT * FROM sales WHERE sale_id = ? AND sale_status = "completed"',
      [req.params.id]
    );
    if (!sale) {
      await conn.rollback();
      return res.status(404).json({ error: 'Sale not found or already voided' });
    }

    const [items] = await conn.query(
      'SELECT * FROM sale_items WHERE sale_id = ?', [req.params.id]
    );

    // Restore stock for each item
    for (const item of items) {
      await conn.query(
        'UPDATE inventory SET quantity_in_stock = quantity_in_stock + ? WHERE product_id = ?',
        [item.quantity, item.product_id]
      );
      await conn.query(
        `INSERT INTO inventory_adjustments
           (product_id, user_id, adjustment_type, quantity_change, note)
         VALUES (?,?,'return',?,?)`,
        [item.product_id, req.user.userId, item.quantity, 'Void: '+sale.transaction_ref]
      );
    }

    // Mark sale as voided
    await conn.query(
      "UPDATE sales SET sale_status = 'voided', notes = ? WHERE sale_id = ?",
      [(reason || 'Voided') + ' — by ' + req.user.name, req.params.id]
    );

    // Reverse customer loyalty points if applicable
    if (sale.customer_id) {
      await conn.query(
        `UPDATE customers
         SET loyalty_points  = GREATEST(0, loyalty_points - ?),
             total_spent     = GREATEST(0, total_spent - ?),
             total_purchases = GREATEST(0, total_purchases - 1)
         WHERE customer_id = ?`,
        [Math.floor(sale.total_amount), sale.total_amount, sale.customer_id]
      );
    }

    // Log action
    await conn.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'VOID',
       sale.transaction_ref + ' | Reason: ' + (reason || 'Not specified')]
    );

    await conn.commit();
    res.json({ message: 'Sale voided and stock restored' });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ error: 'Server error during void' });
  } finally {
    conn.release();
  }
});

module.exports = router;
