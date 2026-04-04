# APEX POS — Full Stack Point of Sale System
**Stack:** HTML / CSS / JavaScript  +  Node.js / Express  +  MySQL

---

## Project Structure

```
apexpos/
├── database/
│   └── schema.sql          ← MySQL schema + seed data
├── backend/
│   ├── server.js           ← Express entry point
│   ├── db.js               ← MySQL connection pool
│   ├── package.json        ← Node.js dependencies
│   ├── .env.example        ← Environment variable template
│   ├── middleware/
│   │   └── auth.js         ← JWT authentication + role guard
│   └── routes/
│       ├── auth.js         ← Login / Logout
│       ├── products.js     ← Product CRUD
│       ├── inventory.js    ← Stock management
│       ├── sales.js        ← Checkout & transaction processing
│       ├── customers.js    ← Customer management
│       ├── reports.js      ← Analytics & reports
│       └── users.js        ← User management (admin only)
└── frontend/
    └── index.html          ← Full POS UI (connects to API)
```

---

## Setup Instructions

### Step 1 — Install Prerequisites
- [Node.js](https://nodejs.org) v18 or higher
- [MySQL](https://dev.mysql.com/downloads/) v8.0 or higher

### Step 2 — Set Up the Database
Open your MySQL client and run:
```bash
mysql -u root -p < database/schema.sql
```
This creates the `apexpos` database with all tables and seed data (12 products, 3 users, 2 customers).

### Step 3 — Configure Environment
```bash
cd backend
cp .env.example .env
```
Open `.env` and fill in:
```
DB_PASSWORD=your_actual_mysql_password
JWT_SECRET=any_long_random_string_here
```

### Step 4 — Install Node.js Dependencies
```bash
cd backend
npm install
```

### Step 5 — Seed the Database (IMPORTANT — creates users with correct password hashes)
```bash
node setup.js
```
You will see this if it worked:
```
✅  Setup complete! Login credentials:

   Role          Username    Password
   ─────────────────────────────────
   Administrator  admin      admin123
   Manager        manager    mgr123
   Cashier        cashier    cash123
```

### Step 6 — Start the Server
```bash
node server.js
```
You should see:
```
✅  MySQL connected — database: apexpos
🚀  APEX POS server running at http://localhost:3000
```

### Step 6 — Open the System
Visit **http://localhost:3000** in your browser.

---

## Default Login Credentials

| Role          | Username  | Password   |
|---------------|-----------|------------|
| Administrator | admin     | admin123   |
| Manager       | manager   | mgr123     |
| Cashier       | cashier   | cash123    |

---

## API Endpoints

| Method | Endpoint                          | Description                  | Role Required     |
|--------|-----------------------------------|------------------------------|-------------------|
| POST   | /api/auth/login                   | Login & receive JWT token    | Public            |
| POST   | /api/auth/logout                  | Logout & log action          | Any               |
| GET    | /api/products                     | List all products             | Any               |
| POST   | /api/products                     | Add new product               | Admin / Manager   |
| PUT    | /api/products/:id                 | Update product                | Admin / Manager   |
| DELETE | /api/products/:id                 | Soft-delete product           | Admin             |
| GET    | /api/inventory                    | Stock levels & status         | Any               |
| GET    | /api/inventory/summary            | Stock summary stats           | Any               |
| POST   | /api/inventory/restock            | Add stock to a product        | Admin / Manager   |
| POST   | /api/inventory/adjust             | Manual stock adjustment       | Admin / Manager   |
| POST   | /api/sales                        | Process a sale (checkout)     | Any               |
| GET    | /api/sales                        | Sales history                 | Any               |
| GET    | /api/sales/:id                    | Single sale with items        | Any               |
| GET    | /api/customers                    | List customers                | Any               |
| POST   | /api/customers                    | Add customer                  | Any               |
| PUT    | /api/customers/:id                | Update customer               | Any               |
| DELETE | /api/customers/:id                | Delete customer               | Admin / Manager   |
| GET    | /api/reports/summary              | Revenue & transaction stats   | Admin / Manager   |
| GET    | /api/reports/profit               | Profit & margin by product    | Admin / Manager   |
| GET    | /api/reports/cashier-performance  | Sales by cashier              | Admin / Manager   |
| GET    | /api/reports/top-products         | Best selling products         | Admin / Manager   |
| GET    | /api/reports/daily-sales          | Daily totals for 30 days      | Admin / Manager   |
| GET    | /api/reports/logs                 | Transaction audit log         | Admin / Manager   |
| GET    | /api/users                        | List system users             | Admin             |
| POST   | /api/users                        | Create user                   | Admin             |
| PUT    | /api/users/:id                    | Update user                   | Admin             |
| PATCH  | /api/users/:id/toggle             | Activate / deactivate user    | Admin             |

---

## Database Tables

| Table                   | Description                                         |
|-------------------------|-----------------------------------------------------|
| users                   | System users with bcrypt-hashed passwords           |
| categories              | Product categories                                  |
| suppliers               | Supplier contact details                            |
| products                | Product catalogue with cost & selling prices        |
| inventory               | Stock levels and low-stock alert thresholds         |
| inventory_adjustments   | Full log of every stock change                      |
| customers               | Customer profiles + loyalty points                  |
| sales                   | Transaction headers                                 |
| sale_items              | Line items per transaction (price snapshot)         |
| payments                | Payment records including cash tendered & change    |
| transaction_logs        | Audit trail of all system actions                   |

---

## Security Features
- **bcrypt password hashing** (10 rounds) — passwords never stored in plain text
- **JWT authentication** — every API request requires a valid token
- **Role-based access control** — Admin / Manager / Cashier with different permissions
- **Transaction logs** — every login, sale, restock and edit is recorded with timestamp and user
- **SQL injection prevention** — all queries use parameterised statements via mysql2

---

## Three-Tier Architecture

```
┌─────────────────────────────┐
│   PRESENTATION LAYER        │
│   frontend/index.html       │
│   HTML + CSS + JavaScript   │
│   Runs in the browser       │
└────────────┬────────────────┘
             │ HTTP / REST API (JSON)
             ▼
┌─────────────────────────────┐
│   APPLICATION LAYER         │
│   backend/server.js         │
│   Node.js + Express         │
│   Business logic, JWT auth, │
│   validation, calculations  │
└────────────┬────────────────┘
             │ mysql2 driver
             ▼
┌─────────────────────────────┐
│   DATA LAYER                │
│   MySQL Database            │
│   11 relational tables      │
│   Persistent storage        │
└─────────────────────────────┘
```
