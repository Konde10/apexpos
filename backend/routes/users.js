// routes/users.js — User Management (Admin only)
const express = require('express');
const bcrypt  = require('bcrypt');
const db      = require('../db');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate, authorize('admin'));

// ─── GET /api/users ───────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT user_id, full_name, username, role, is_active, last_login, created_at FROM users ORDER BY full_name'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── POST /api/users ──────────────────────────────────────────
router.post('/', async (req, res) => {
  const { full_name, username, password, role } = req.body;
  if (!full_name || !username || !password || !role) {
    return res.status(400).json({ error: 'All fields required' });
  }
  try {
    const hash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      'INSERT INTO users (full_name, username, password_hash, role) VALUES (?,?,?,?)',
      [full_name, username, hash, role]
    );
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'USER_ADD', 'Added user: '+username+' ('+role+')']
    );
    res.status(201).json({ message: 'User created', userId: result.insertId });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Username already taken' });
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── PUT /api/users/:id ───────────────────────────────────────
router.put('/:id', async (req, res) => {
  const { full_name, username, password, role } = req.body;
  try {
    let sql    = 'UPDATE users SET full_name=?, username=?, role=?';
    const params = [full_name, username, role];
    if (password) {
      const hash = await bcrypt.hash(password, 10);
      sql += ', password_hash=?';
      params.push(hash);
    }
    sql += ' WHERE user_id=?';
    params.push(req.params.id);
    await db.query(sql, params);
    res.json({ message: 'User updated' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── PATCH /api/users/:id/toggle ─────────────────────────────
router.patch('/:id/toggle', async (req, res) => {
  try {
    await db.query(
      'UPDATE users SET is_active = NOT is_active WHERE user_id=?', [req.params.id]
    );
    res.json({ message: 'User status toggled' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
