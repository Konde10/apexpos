-- ============================================================
-- APEX POS — MySQL Database Schema
-- Version: 1.0
-- Description: Full relational schema for the APEX POS system
-- ============================================================

CREATE DATABASE IF NOT EXISTS apexpos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE apexpos;

-- ─────────────────────────────────────────────────────────────
-- TABLE: users
-- Stores all system users with roles and authentication
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  user_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100)  NOT NULL,
  username      VARCHAR(50)   NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,          -- bcrypt hash
  role          ENUM('admin','manager','cashier') NOT NULL DEFAULT 'cashier',
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  last_login    DATETIME      NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: categories
-- Product categories for grouping
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  category_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(80)   NOT NULL UNIQUE,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: suppliers
-- Supplier contact information
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL,
  phone         VARCHAR(20)   NULL,
  email         VARCHAR(100)  NULL,
  address       TEXT          NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: products
-- All products available for sale
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  product_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_name    VARCHAR(150)    NOT NULL,
  category_id     INT UNSIGNED    NULL,
  supplier_id     INT UNSIGNED    NULL,
  barcode         VARCHAR(50)     NULL UNIQUE,
  selling_price   DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  cost_price      DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  emoji_icon      VARCHAR(10)     NULL DEFAULT '📦',
  is_active       TINYINT(1)      NOT NULL DEFAULT 1,
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)  ON DELETE SET NULL,
  INDEX idx_barcode (barcode),
  INDEX idx_category (category_id)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: inventory
-- Tracks stock levels per product
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inventory (
  inventory_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id        INT UNSIGNED  NOT NULL UNIQUE,
  quantity_in_stock INT           NOT NULL DEFAULT 0,
  low_stock_alert   INT           NOT NULL DEFAULT 5,
  last_restocked    DATETIME      NULL,
  updated_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: inventory_adjustments
-- Log of every stock change (restock, sale deduction, manual adj.)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inventory_adjustments (
  adjustment_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id      INT UNSIGNED  NOT NULL,
  user_id         INT UNSIGNED  NULL,
  adjustment_type ENUM('sale','restock','adjustment','damage','return') NOT NULL,
  quantity_change INT           NOT NULL,           -- negative for deductions
  note            VARCHAR(255)  NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)    REFERENCES users(user_id)       ON DELETE SET NULL
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: customers
-- Customer profiles and loyalty tracking
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  customer_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name       VARCHAR(100) NOT NULL,
  phone           VARCHAR(20)  NULL,
  email           VARCHAR(100) NULL,
  address         TEXT         NULL,
  loyalty_points  INT          NOT NULL DEFAULT 0,
  total_spent     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_purchases INT          NOT NULL DEFAULT 0,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_phone (phone),
  INDEX idx_email (email)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: sales
-- One row per completed transaction
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales (
  sale_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_ref VARCHAR(30)   NOT NULL UNIQUE,   -- e.g. TXN1718000000000
  user_id         INT UNSIGNED  NOT NULL,           -- cashier who made the sale
  customer_id     INT UNSIGNED  NULL,               -- NULL = walk-in
  subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount_pct    DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tax_amount      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_amount    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  sale_status     ENUM('completed','voided','refunded') NOT NULL DEFAULT 'completed',
  notes           TEXT          NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)     REFERENCES users(user_id)         ON DELETE RESTRICT,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL,
  INDEX idx_transaction_ref (transaction_ref),
  INDEX idx_sale_date       (created_at),
  INDEX idx_cashier         (user_id)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: sale_items
-- Line items within each sale
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sale_items (
  sale_item_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sale_id         INT UNSIGNED  NOT NULL,
  product_id      INT UNSIGNED  NOT NULL,
  product_name    VARCHAR(150)  NOT NULL,   -- snapshot at time of sale
  quantity        INT           NOT NULL DEFAULT 1,
  unit_price      DECIMAL(10,2) NOT NULL,   -- selling price at time of sale
  unit_cost       DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- cost price snapshot
  line_total      DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (sale_id)    REFERENCES sales(sale_id)       ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
  INDEX idx_sale    (sale_id),
  INDEX idx_product (product_id)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: payments
-- Payment record for each sale (supports split payment)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  payment_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sale_id         INT UNSIGNED  NOT NULL,
  payment_method  ENUM('cash','mobile','card') NOT NULL,
  amount          DECIMAL(10,2) NOT NULL,
  cash_tendered   DECIMAL(10,2) NULL,        -- for cash payments
  change_given    DECIMAL(10,2) NULL DEFAULT 0.00,
  reference_no    VARCHAR(100)  NULL,        -- mobile money / card ref
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE,
  INDEX idx_payment_sale   (sale_id),
  INDEX idx_payment_method (payment_method)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE: transaction_logs
-- Audit trail of all system actions
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_logs (
  log_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED  NULL,
  user_name   VARCHAR(100)  NULL,
  action      VARCHAR(80)   NOT NULL,   -- e.g. LOGIN, SALE, PRODUCT_SAVE
  detail      TEXT          NULL,
  ip_address  VARCHAR(45)   NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
  INDEX idx_log_date   (created_at),
  INDEX idx_log_action (action)
);


-- ═══════════════════════════════════════════════════════════════
-- SEED DATA
-- IMPORTANT: Do NOT manually insert password hashes here.
-- Run the setup script instead:
--   cd backend && node setup.js
-- This creates users with properly bcrypt-hashed passwords.
-- ═══════════════════════════════════════════════════════════════

-- Seed categories
INSERT INTO categories (name) VALUES
  ('Beverages'), ('Food'), ('Dairy'), ('Personal Care'), ('Confectionery');

-- Seed suppliers
INSERT INTO suppliers (name, phone) VALUES
  ('Coca Cola GH',   '+233302000001'),
  ('Nestle Ghana',   '+233302000002'),
  ('Unilever GH',    '+233302000003'),
  ('Promasidor',     '+233302000004'),
  ('Perfetti',       '+233302000005');

-- Seed products
INSERT INTO products (product_name, category_id, supplier_id, barcode, selling_price, cost_price, emoji_icon) VALUES
  ('Coca Cola 500ml',    1, 1, '5000112637922', 5.00,  3.50,  '🥤'),
  ('Indomie Chicken',    2, 2, '8992761150014', 2.50,  1.50,  '🍜'),
  ('Fan Ice Vanilla',    1, 1, '6001007127006', 3.00,  2.00,  '🍦'),
  ('Milo 400g',          2, 2, '4800361210016', 28.00, 20.00, '🫙'),
  ('Voltic Water 1.5L',  1, 1, '6001007090002', 4.00,  2.50,  '💧'),
  ('Cowbell Milk 400g',  3, 4, '8000700115078', 18.00, 13.00, '🥛'),
  ('Uncle Ben Rice 2kg', 2, 2, '5010034003066', 32.00, 24.00, '🍚'),
  ('Geisha Soap',        4, 3, '6001007108098', 3.50,  2.00,  '🧼'),
  ('Mentos Mint',        5, 5, '8000700181432', 1.50,  0.80,  '🍬'),
  ('Cadbury Chocolate',  5, 2, '7622201720056', 6.00,  4.00,  '🍫'),
  ('Pampas Butter 250g', 3, 4, '6001007120014', 22.00, 16.00, '🧈'),
  ('Tom Tom Candy',      5, 5, '8000700012501', 1.00,  0.50,  '🍭');

-- Seed inventory (stock levels per product)
INSERT INTO inventory (product_id, quantity_in_stock, low_stock_alert) VALUES
  (1,  48,  10),
  (2,  120, 20),
  (3,  7,   10),
  (4,  35,  5),
  (5,  0,   15),
  (6,  22,  5),
  (7,  18,  5),
  (8,  60,  10),
  (9,  80,  20),
  (10, 4,   8),
  (11, 12,  5),
  (12, 150, 30);

-- Seed customers
INSERT INTO customers (full_name, phone, email, address) VALUES
  ('Ama Owusu',    '+233244123456', 'ama@email.com',   'Kumasi, Ashanti'),
  ('Kwame Asante', '+233201234567', 'kwame@email.com', 'Kumasi, Ashanti');
