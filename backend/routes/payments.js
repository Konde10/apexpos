// routes/payments.js — Paystack Mobile Money Integration
// Supports MTN MoMo, Vodafone Cash, AirtelTigo Money via single API
const express = require('express');
const https   = require('https');
const db      = require('../db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// ─── Helper: call Paystack API ────────────────────────────────
function paystackRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const secretKey = process.env.PAYSTACK_SECRET_KEY;
    if (!secretKey) {
      return reject(new Error('PAYSTACK_SECRET_KEY not set in .env'));
    }
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'api.paystack.co',
      port: 443,
      path,
      method,
      headers: {
        'Authorization': `Bearer ${secretKey}`,
        'Content-Type':  'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };
    const req = https.request(options, res => {
      let raw = '';
      res.on('data', chunk => raw += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); }
        catch(e) { reject(new Error('Invalid Paystack response')); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// ─── Detect network from Ghana phone number ───────────────────
function detectNetwork(phone) {
  // Normalise to local format
  const n = phone.replace(/\s+/g, '').replace(/^\+233/, '0').replace(/^233/, '0');
  const prefix = n.substring(0, 3);
  const mtn  = ['024','054','055','059','025'];
  const voda = ['020','050'];
  const airtel = ['027','057','026','056'];
  if (mtn.includes(prefix))   return 'mtn';
  if (voda.includes(prefix))  return 'vod';
  if (airtel.includes(prefix)) return 'atl';
  return 'mtn'; // default fallback
}

// ─── Format phone for Paystack (must be 233XXXXXXXXX) ─────────
function formatPhone(phone) {
  let n = phone.replace(/\s+/g, '').replace(/[^0-9]/g, '');
  if (n.startsWith('0'))   n = '233' + n.substring(1);
  if (n.startsWith('233')) return n;
  return '233' + n;
}

// ─── POST /api/payments/mobile/initiate ──────────────────────
// Initiates a Paystack mobile money charge
router.post('/mobile/initiate', authenticate, async (req, res) => {
  const { amount, phone, email, sale_ref } = req.body;
  if (!amount || !phone) {
    return res.status(400).json({ error: 'amount and phone are required' });
  }

  const formattedPhone   = formatPhone(phone);
  const network          = detectNetwork(phone);
  const amountInPesewas  = Math.round(parseFloat(amount) * 100); // Paystack uses pesewas
  const customerEmail    = email || `${formattedPhone}@apexpos.gh`;
  const reference        = `APEX-${Date.now()}-${Math.random().toString(36).substr(2,6).toUpperCase()}`;

  const networkNames = { mtn: 'MTN Mobile Money', vod: 'Vodafone Cash', atl: 'AirtelTigo Money' };

  try {
    const payload = {
      email:     customerEmail,
      amount:    amountInPesewas,
      currency:  'GHS',
      mobile_money: {
        phone:   formattedPhone,
        provider: network
      },
      reference,
      metadata: {
        sale_ref:    sale_ref || '',
        cashier:     req.user.name,
        custom_fields: [
          { display_name: 'Sale Reference', variable_name: 'sale_ref', value: sale_ref || '' },
          { display_name: 'Network',        variable_name: 'network',  value: networkNames[network] }
        ]
      }
    };

    const result = await paystackRequest('POST', '/charge', payload);

    if (!result.status) {
      return res.status(400).json({ error: result.message || 'Paystack charge failed' });
    }

    // Log initiation
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'MOMO_INITIATE',
       `${networkNames[network]} | GHS ${amount} | ${formattedPhone} | ref: ${reference}`]
    );

    res.json({
      status:    result.data?.status,
      reference,
      network:   networkNames[network],
      message:   result.data?.display_text || `Prompt sent to ${formattedPhone}. Ask customer to approve on their phone.`,
      data:      result.data
    });

  } catch (err) {
    console.error('Paystack error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/payments/mobile/verify/:reference ───────────────
// Poll this to check payment status
router.get('/mobile/verify/:reference', authenticate, async (req, res) => {
  try {
    const result = await paystackRequest('GET', `/transaction/verify/${req.params.reference}`, null);

    if (!result.status) {
      return res.status(400).json({ error: result.message || 'Verification failed' });
    }

    const tx = result.data;
    res.json({
      status:    tx.status,         // 'success', 'pending', 'failed', 'abandoned'
      reference: tx.reference,
      amount:    tx.amount / 100,   // convert back from pesewas to GHS
      currency:  tx.currency,
      paid_at:   tx.paid_at,
      channel:   tx.channel,
      message:   tx.gateway_response
    });

  } catch (err) {
    console.error('Paystack verify error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── Webhook handler (exported separately for raw body parsing) ─
const webhookHandler = [
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const crypto    = require('crypto');
    const secretKey = process.env.PAYSTACK_SECRET_KEY || '';
    const hash      = crypto
      .createHmac('sha512', secretKey)
      .update(req.body)
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      return res.status(400).json({ error: 'Invalid signature' });
    }

    const event = JSON.parse(req.body);
    if (event.event === 'charge.success') {
      const tx = event.data;
      try {
        await db.query(
          'INSERT INTO transaction_logs (user_name, action, detail) VALUES (?,?,?)',
          ['Paystack', 'MOMO_SUCCESS',
           `${tx.reference} | GHS ${tx.amount/100} | ${tx.customer?.email}`]
        );
      } catch(e) { console.error('Webhook DB error:', e.message); }
    }
    res.sendStatus(200);
  }
];

module.exports        = router;
module.exports.webhook = webhookHandler;
