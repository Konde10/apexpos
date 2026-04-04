// routes/inventory.js — Inventory Management
const express = require('express');
const db      = require('../db');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// ─── GET /api/inventory ───────────────────────────────────────
// Full inventory list with stock levels and value
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT  p.product_id, p.product_name, p.emoji_icon,
              p.selling_price, p.cost_price,
              c.name               AS category_name,
              s.name               AS supplier_name,
              i.quantity_in_stock  AS stock,
              i.low_stock_alert,
              i.last_restocked,
              (p.selling_price * i.quantity_in_stock) AS stock_value,
              CASE
                WHEN i.quantity_in_stock = 0                        THEN 'out_of_stock'
                WHEN i.quantity_in_stock <= i.low_stock_alert        THEN 'low_stock'
                ELSE 'in_stock'
              END AS stock_status
      FROM    inventory i
      JOIN    products    p ON i.product_id   = p.product_id
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers  s ON p.supplier_id  = s.supplier_id
      WHERE   p.is_active = 1
      ORDER BY stock_status, p.product_name
    `);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/inventory/summary ──────────────────────────────
router.get('/summary', async (req, res) => {
  try {
    const [[summary]] = await db.query(`
      SELECT
        COUNT(*)                                             AS total_products,
        SUM(i.quantity_in_stock = 0)                        AS out_of_stock,
        SUM(i.quantity_in_stock > 0
            AND i.quantity_in_stock <= i.low_stock_alert)    AS low_stock,
        SUM(p.selling_price * i.quantity_in_stock)          AS total_stock_value
      FROM inventory i
      JOIN products p ON i.product_id = p.product_id
      WHERE p.is_active = 1
    `);
    res.json(summary);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── POST /api/inventory/restock ─────────────────────────────
router.post('/restock', authorize('admin','manager'), async (req, res) => {
  const { product_id, quantity, note } = req.body;
  if (!product_id || !quantity || quantity < 1) {
    return res.status(400).json({ error: 'product_id and quantity (>=1) required' });
  }
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    // Update inventory
    await conn.query(
      `UPDATE inventory
       SET quantity_in_stock = quantity_in_stock + ?,
           last_restocked    = NOW()
       WHERE product_id = ?`,
      [quantity, product_id]
    );
    // Log adjustment
    await conn.query(
      `INSERT INTO inventory_adjustments
         (product_id, user_id, adjustment_type, quantity_change, note)
       VALUES (?,?,?,?,?)`,
      [product_id, req.user.userId, 'restock', quantity, note||null]
    );
    await conn.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'RESTOCK', 'Product ID '+product_id+' +'+quantity]
    );
    await conn.commit();
    res.json({ message: 'Stock updated successfully' });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    conn.release();
  }
});

// ─── POST /api/inventory/adjust ──────────────────────────────
// Manual stock adjustment (damage, return, correction)
router.post('/adjust', authorize('admin','manager'), async (req, res) => {
  const { product_id, quantity_change, adjustment_type, note } = req.body;
  if (!product_id || quantity_change == null) {
    return res.status(400).json({ error: 'product_id and quantity_change required' });
  }
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query(
      'UPDATE inventory SET quantity_in_stock = GREATEST(0, quantity_in_stock + ?) WHERE product_id = ?',
      [quantity_change, product_id]
    );
    await conn.query(
      `INSERT INTO inventory_adjustments
         (product_id, user_id, adjustment_type, quantity_change, note)
       VALUES (?,?,?,?,?)`,
      [product_id, req.user.userId, adjustment_type||'adjustment', quantity_change, note||null]
    );
    await conn.commit();
    res.json({ message: 'Stock adjusted' });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ error: 'Server error' });
  } finally {
    conn.release();
  }
});

module.exports = router;
