// routes/auth.js — Login / Logout
const express  = require('express');
const bcrypt   = require('bcrypt');
const jwt      = require('jsonwebtoken');
const db       = require('../db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// ─── POST /api/auth/login ─────────────────────────────────────
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }
  try {
    const [rows] = await db.query(
      'SELECT * FROM users WHERE username = ? AND is_active = 1 LIMIT 1',
      [username]
    );
    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    // Update last login
    await db.query('UPDATE users SET last_login = NOW() WHERE user_id = ?', [user.user_id]);

    // Sign JWT
    const token = jwt.sign(
      { userId: user.user_id, username: user.username, role: user.role, name: user.full_name },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    // Log action
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail, ip_address) VALUES (?,?,?,?,?)',
      [user.user_id, user.full_name, 'LOGIN', user.role + ' signed in', req.ip]
    );

    res.json({
      token,
      user: {
        userId:   user.user_id,
        name:     user.full_name,
        username: user.username,
        role:     user.role
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── POST /api/auth/logout ────────────────────────────────────
router.post('/logout', authenticate, async (req, res) => {
  try {
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'LOGOUT', req.user.role + ' signed out']
    );
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/auth/me ─────────────────────────────────────────
router.get('/me', authenticate, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
