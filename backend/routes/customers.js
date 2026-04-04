// routes/customers.js — Customer Management
const express = require('express');
const db      = require('../db');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// ─── GET /api/customers ───────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM customers ORDER BY full_name'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/customers/:id with purchase history ────────────
router.get('/:id', async (req, res) => {
  try {
    const [[customer]] = await db.query(
      'SELECT * FROM customers WHERE customer_id = ?', [req.params.id]);
    if (!customer) return res.status(404).json({ error: 'Customer not found' });
    const [history] = await db.query(`
      SELECT s.transaction_ref, s.total_amount, s.created_at, p.payment_method
      FROM   sales s
      LEFT JOIN payments p ON s.sale_id = p.sale_id
      WHERE  s.customer_id = ? ORDER BY s.created_at DESC LIMIT 20`,
      [req.params.id]);
    res.json({ ...customer, purchase_history: history });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── POST /api/customers ──────────────────────────────────────
router.post('/', async (req, res) => {
  const { full_name, phone, email, address } = req.body;
  if (!full_name || !phone) {
    return res.status(400).json({ error: 'full_name and phone required' });
  }
  try {
    const [result] = await db.query(
      'INSERT INTO customers (full_name, phone, email, address) VALUES (?,?,?,?)',
      [full_name, phone, email||null, address||null]
    );
    res.status(201).json({ message: 'Customer created', customerId: result.insertId });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Phone already registered' });
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── PUT /api/customers/:id ───────────────────────────────────
router.put('/:id', async (req, res) => {
  const { full_name, phone, email, address } = req.body;
  try {
    await db.query(
      'UPDATE customers SET full_name=?, phone=?, email=?, address=? WHERE customer_id=?',
      [full_name, phone, email||null, address||null, req.params.id]
    );
    res.json({ message: 'Customer updated' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── DELETE /api/customers/:id ────────────────────────────────
router.delete('/:id', authorize('admin','manager'), async (req, res) => {
  try {
    await db.query('DELETE FROM customers WHERE customer_id=?', [req.params.id]);
    res.json({ message: 'Customer deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
