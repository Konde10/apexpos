// routes/products.js — Product Management CRUD
const express = require('express');
const db      = require('../db');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// Helper: resolve category name → category_id (creates if not exists)
async function resolveCategoryId(conn, categoryName) {
  if (!categoryName || !categoryName.trim()) return null;
  const name = categoryName.trim();
  // Try to find existing
  const [rows] = await conn.query('SELECT category_id FROM categories WHERE name = ?', [name]);
  if (rows.length) return rows[0].category_id;
  // Create new category
  const [result] = await conn.query('INSERT INTO categories (name) VALUES (?)', [name]);
  return result.insertId;
}

// Helper: resolve supplier name → supplier_id (creates if not exists)
async function resolveSupplierId(conn, supplierName) {
  if (!supplierName || !supplierName.trim()) return null;
  const name = supplierName.trim();
  const [rows] = await conn.query('SELECT supplier_id FROM suppliers WHERE name = ?', [name]);
  if (rows.length) return rows[0].supplier_id;
  const [result] = await conn.query('INSERT INTO suppliers (name) VALUES (?)', [name]);
  return result.insertId;
}

// ─── GET /api/products ────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const { search, category } = req.query;
    let sql = `
      SELECT  p.product_id, p.product_name, p.barcode,
              p.selling_price, p.cost_price, p.emoji_icon, p.is_active,
              c.name          AS category_name,
              c.category_id,
              s.name          AS supplier_name,
              s.supplier_id,
              COALESCE(i.quantity_in_stock, 0) AS stock,
              COALESCE(i.low_stock_alert,   5) AS low_stock_alert
      FROM    products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers  s ON p.supplier_id  = s.supplier_id
      LEFT JOIN inventory  i ON p.product_id   = i.product_id
      WHERE   p.is_active = 1
    `;
    const params = [];
    if (search) {
      sql += ' AND (p.product_name LIKE ? OR p.barcode LIKE ?)';
      params.push('%'+search+'%', '%'+search+'%');
    }
    if (category) {
      sql += ' AND c.name = ?';
      params.push(category);
    }
    sql += ' ORDER BY p.product_name';
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/products/categories/list ───────────────────────
// MUST be before /:id to avoid being matched as an id route
router.get('/categories/list', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM categories ORDER BY name');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/products/:id ────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT p.*, c.name AS category_name, s.name AS supplier_name,
             COALESCE(i.quantity_in_stock,0) AS stock,
             COALESCE(i.low_stock_alert,5)   AS low_stock_alert
      FROM   products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers  s ON p.supplier_id  = s.supplier_id
      LEFT JOIN inventory  i ON p.product_id   = i.product_id
      WHERE  p.product_id = ?`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Product not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── POST /api/products ───────────────────────────────────────
router.post('/', authorize('admin','manager'), async (req, res) => {
  const { product_name, category_name, supplier_name, barcode,
          selling_price, cost_price, emoji_icon, stock, low_stock_alert } = req.body;
  if (!product_name || selling_price == null) {
    return res.status(400).json({ error: 'product_name and selling_price are required' });
  }
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const categoryId = await resolveCategoryId(conn, category_name);
    const supplierId = await resolveSupplierId(conn, supplier_name);

    const [result] = await conn.query(
      `INSERT INTO products (product_name, category_id, supplier_id, barcode,
                             selling_price, cost_price, emoji_icon)
       VALUES (?,?,?,?,?,?,?)`,
      [product_name, categoryId, supplierId, barcode||null,
       selling_price, cost_price||0, emoji_icon||'📦']
    );
    const productId = result.insertId;

    await conn.query(
      'INSERT INTO inventory (product_id, quantity_in_stock, low_stock_alert) VALUES (?,?,?)',
      [productId, stock||0, low_stock_alert||5]
    );
    await conn.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'PRODUCT_ADD', 'Added: '+product_name]
    );
    await conn.commit();
    res.status(201).json({ message: 'Product created', productId });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Barcode already exists' });
    res.status(500).json({ error: 'Server error' });
  } finally {
    conn.release();
  }
});

// ─── PUT /api/products/:id ────────────────────────────────────
router.put('/:id', authorize('admin','manager'), async (req, res) => {
  const { product_name, category_name, supplier_name, barcode,
          selling_price, cost_price, emoji_icon, low_stock_alert } = req.body;
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const categoryId = await resolveCategoryId(conn, category_name);
    const supplierId = await resolveSupplierId(conn, supplier_name);

    await conn.query(
      `UPDATE products
       SET product_name=?, category_id=?, supplier_id=?,
           barcode=?, selling_price=?, cost_price=?, emoji_icon=?
       WHERE product_id=?`,
      [product_name, categoryId, supplierId, barcode||null,
       selling_price, cost_price||0, emoji_icon||'📦', req.params.id]
    );

    if (low_stock_alert != null) {
      await conn.query(
        'UPDATE inventory SET low_stock_alert=? WHERE product_id=?',
        [low_stock_alert, req.params.id]
      );
    }

    await conn.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'PRODUCT_UPDATE',
       'Updated: '+product_name+' → category: '+(category_name||'none')]
    );

    await conn.commit();
    res.json({ message: 'Product updated' });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    conn.release();
  }
});

// ─── DELETE /api/products/:id (soft delete) ───────────────────
router.delete('/:id', authorize('admin'), async (req, res) => {
  try {
    await db.query('UPDATE products SET is_active=0 WHERE product_id=?', [req.params.id]);
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'PRODUCT_DELETE', 'Deleted product ID: '+req.params.id]
    );
    res.json({ message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
