// setup.js — Seeds the database with correct bcrypt-hashed passwords
// Run this: cd backend && node setup.js
// Safe to run multiple times — always resets users.

require('dotenv').config();
const bcrypt = require('bcrypt');
const db     = require('./db');

async function setup() {
  console.log('\n APEX POS Setup');
  console.log('================\n');

  try {
    console.log('Generating password hashes...');
    const adminHash   = await bcrypt.hash('admin123', 10);
    const managerHash = await bcrypt.hash('mgr123',   10);
    const cashierHash = await bcrypt.hash('cash123',  10);
    console.log('Done hashing.\n');

    // Disable foreign key checks so we can clear users safely
    await db.query('SET FOREIGN_KEY_CHECKS = 0');
    await db.query('DELETE FROM users');
    await db.query('SET FOREIGN_KEY_CHECKS = 1');
    console.log('Cleared old users.');

    // Insert with real hashes
    await db.query(
      `INSERT INTO users (full_name, username, password_hash, role, is_active) VALUES
        ('Admin User',   'admin',   ?, 'admin',   1),
        ('Grace Mensah', 'manager', ?, 'manager', 1),
        ('Kofi Asante',  'cashier', ?, 'cashier', 1)`,
      [adminHash, managerHash, cashierHash]
    );
    console.log('Users inserted.\n');

    // Verify hashes work
    const [rows] = await db.query('SELECT username, password_hash FROM users');
    console.log('Verifying hashes...');
    const pwMap = { admin: 'admin123', manager: 'mgr123', cashier: 'cash123' };
    for (const row of rows) {
      const ok = await bcrypt.compare(pwMap[row.username], row.password_hash);
      console.log('  ' + row.username + ': ' + (ok ? 'OK' : 'FAILED'));
    }

    console.log('\n================');
    console.log('Setup complete!\n');
    console.log('  Username   Password    Role');
    console.log('  ----------------------------');
    console.log('  admin      admin123    Administrator');
    console.log('  manager    mgr123      Manager');
    console.log('  cashier    cash123     Cashier');
    console.log('\nNow run: node server.js');
    console.log('Then open: http://localhost:3000\n');

  } catch (err) {
    console.error('\nSetup failed:', err.message);
    if (err.code === 'ECONNREFUSED' || err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('Check your .env — DB_HOST, DB_USER, DB_PASSWORD, DB_NAME must be correct.');
    }
    process.exit(1);
  }
  process.exit(0);
}

setup();
