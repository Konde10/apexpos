// routes/reports.js — All Analytics & Reports
const express = require('express');
const db      = require('../db');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate, authorize('admin', 'manager'));

// Helper: build date WHERE clause
function periodClause(period, alias = 's') {
  if (period === 'today') return `DATE(${alias}.created_at) = CURDATE()`;
  if (period === 'week')  return `${alias}.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)`;
  if (period === 'month') return `MONTH(${alias}.created_at)=MONTH(NOW()) AND YEAR(${alias}.created_at)=YEAR(NOW())`;
  return '1=1';
}

// ─── GET /api/reports/summary ─────────────────────────────────
router.get('/summary', async (req, res) => {
  const period = req.query.period || 'week';
  const where  = periodClause(period);
  try {
    const [[summary]] = await db.query(`
      SELECT
        COUNT(DISTINCT s.sale_id)               AS total_transactions,
        COALESCE(SUM(s.total_amount),  0)       AS total_revenue,
        COALESCE(SUM(s.discount_amount),0)      AS total_discounts,
        COALESCE(SUM(s.tax_amount),    0)       AS total_tax,
        COALESCE(AVG(s.total_amount),  0)       AS avg_sale,
        COALESCE(SUM(si.quantity),     0)       AS total_items_sold
      FROM sales s
      LEFT JOIN sale_items si ON s.sale_id = si.sale_id
      WHERE s.sale_status = 'completed' AND ${where}
    `);
    res.json(summary);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/sales-by-payment ───────────────────────
router.get('/sales-by-payment', async (req, res) => {
  const period = req.query.period || 'week';
  const where  = periodClause(period);
  try {
    const [rows] = await db.query(`
      SELECT p.payment_method,
             COUNT(s.sale_id)        AS transaction_count,
             SUM(s.total_amount)     AS total_revenue
      FROM   sales s
      JOIN   payments p ON s.sale_id = p.sale_id
      WHERE  s.sale_status = 'completed' AND ${where}
      GROUP BY p.payment_method
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/top-products ───────────────────────────
router.get('/top-products', async (req, res) => {
  const period = req.query.period || 'week';
  const where  = periodClause(period);
  try {
    const [rows] = await db.query(`
      SELECT  si.product_name,
              SUM(si.quantity)                         AS units_sold,
              SUM(si.line_total)                       AS revenue,
              SUM(si.quantity * si.unit_cost)          AS total_cost,
              SUM(si.line_total) - SUM(si.quantity * si.unit_cost) AS gross_profit
      FROM    sale_items si
      JOIN    sales s ON si.sale_id = s.sale_id
      WHERE   s.sale_status = 'completed' AND ${where}
      GROUP BY si.product_name
      ORDER BY units_sold DESC
      LIMIT 10
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/profit ──────────────────────────────────
router.get('/profit', async (req, res) => {
  const period = req.query.period || 'week';
  const where  = periodClause(period);
  try {
    const [rows] = await db.query(`
      SELECT  si.product_name,
              SUM(si.quantity)                                       AS units_sold,
              SUM(si.line_total)                                     AS revenue,
              SUM(si.quantity * si.unit_cost)                        AS cost,
              SUM(si.line_total) - SUM(si.quantity * si.unit_cost)   AS gross_profit,
              ROUND(
                (SUM(si.line_total) - SUM(si.quantity * si.unit_cost))
                / NULLIF(SUM(si.line_total),0) * 100, 2
              )                                                       AS profit_margin_pct
      FROM    sale_items si
      JOIN    sales s ON si.sale_id = s.sale_id
      WHERE   s.sale_status = 'completed' AND ${where}
      GROUP BY si.product_name
      ORDER BY gross_profit DESC
    `);
    // Summary totals
    const totRevenue = rows.reduce((a,r)=>a+parseFloat(r.revenue),0);
    const totCost    = rows.reduce((a,r)=>a+parseFloat(r.cost),0);
    const totProfit  = totRevenue - totCost;
    res.json({
      rows,
      summary: {
        total_revenue: totRevenue.toFixed(2),
        total_cost:    totCost.toFixed(2),
        gross_profit:  totProfit.toFixed(2),
        profit_margin: totRevenue>0 ? ((totProfit/totRevenue)*100).toFixed(2)+'%' : '0%'
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/cashier-performance ────────────────────
router.get('/cashier-performance', async (req, res) => {
  const period = req.query.period || 'week';
  const where  = periodClause(period);
  try {
    const [rows] = await db.query(`
      SELECT  u.full_name              AS cashier_name,
              COUNT(s.sale_id)         AS transactions,
              SUM(si_totals.items)     AS items_sold,
              SUM(s.total_amount)      AS revenue,
              AVG(s.total_amount)      AS avg_sale,
              SUM(s.discount_amount)   AS total_discounts
      FROM    sales s
      JOIN    users u ON s.user_id = u.user_id
      LEFT JOIN (
        SELECT sale_id, SUM(quantity) AS items
        FROM   sale_items GROUP BY sale_id
      ) si_totals ON s.sale_id = si_totals.sale_id
      WHERE   s.sale_status = 'completed' AND ${where}
      GROUP BY s.user_id, u.full_name
      ORDER BY revenue DESC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/daily-sales ────────────────────────────
// Sales totals grouped by day for charting
router.get('/daily-sales', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT  DATE(created_at)    AS sale_date,
              COUNT(*)            AS transactions,
              SUM(total_amount)   AS revenue
      FROM    sales
      WHERE   sale_status = 'completed'
        AND   created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
      GROUP BY DATE(created_at)
      ORDER BY sale_date ASC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ─── GET /api/reports/logs ────────────────────────────────────
router.get('/logs', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM transaction_logs ORDER BY created_at DESC LIMIT 200'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
