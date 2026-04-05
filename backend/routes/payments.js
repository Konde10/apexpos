// routes/payments.js — Paystack Mobile Money Integration
const express = require('express');
const axios   = require('axios');
const db      = require('../db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// ─── Paystack axios client ─────────────────────────────────────
function paystackClient() {
  const key = process.env.PAYSTACK_SECRET_KEY;
  if (!key) throw new Error('PAYSTACK_SECRET_KEY not set in .env file');
  return axios.create({
    baseURL: 'https://api.paystack.co',
    timeout: 30000,
    headers: {
      'Authorization': `Bearer ${key}`,
      'Content-Type':  'application/json'
    }
  });
}

// ─── Detect Ghana network from phone number ───────────────────
function detectNetwork(phone) {
  const n      = phone.replace(/\s+/g,'').replace(/^\+233/,'0').replace(/^233/,'0');
  const prefix = n.substring(0, 3);
  // MTN Ghana prefixes
  if (['024','054','055','059','025'].includes(prefix)) return 'mtn';
  // Vodafone Ghana prefixes
  if (['020','050'].includes(prefix)) return 'vodafone';
  // AirtelTigo Ghana prefixes
  if (['027','057','026','056'].includes(prefix)) return 'airtel-tigo';
  return 'mtn'; // safe default
}

function networkDisplayName(code) {
  const map = { 'mtn': 'MTN Mobile Money', 'vodafone': 'Vodafone Cash', 'airtel-tigo': 'AirtelTigo Money' };
  return map[code] || 'Mobile Money';
}

// ─── Format phone to 233XXXXXXXXX ─────────────────────────────
function formatPhone(phone) {
  let n = phone.replace(/\s+/g,'').replace(/[^0-9]/g,'');
  if (n.startsWith('0'))   n = '233' + n.substring(1);
  if (!n.startsWith('233')) n = '233' + n;
  return n;
}

// ─── POST /api/payments/mobile/initiate ───────────────────────
router.post('/mobile/initiate', authenticate, async (req, res) => {
  const { amount, phone, email, sale_ref } = req.body;
  if (!amount || !phone) {
    return res.status(400).json({ error: 'amount and phone are required' });
  }

  const formattedPhone  = formatPhone(phone);
  const network         = detectNetwork(phone);
  const amountPesewas   = Math.round(parseFloat(amount) * 100);
  const customerEmail   = email || `${formattedPhone}@apexpos.gh`;
  const reference       = `APEX-${Date.now()}-${Math.random().toString(36).substr(2,6).toUpperCase()}`;
  const networkName     = networkDisplayName(network);

  try {
    const client = paystackClient();

    // Paystack Ghana mobile money charge
    // channel must be "mobile_money"
    // provider must be: "mtn", "vodafone", or "airtel-tigo"
    const payload = {
      email:     customerEmail,
      amount:    amountPesewas,
      currency:  'GHS',
      channel:   'mobile_money',
      mobile_money: {
        phone:    formattedPhone,
        provider: network
      },
      reference,
      metadata: {
        sale_ref,
        cashier: req.user.name,
        custom_fields: [
          { display_name: 'Network',   variable_name: 'network',   value: networkName },
          { display_name: 'Cashier',   variable_name: 'cashier',   value: req.user.name }
        ]
      }
    };

    const { data: result } = await client.post('/charge', payload);

    if (!result.status) {
      return res.status(400).json({ error: result.message || 'Paystack charge failed' });
    }

    // Log
    await db.query(
      'INSERT INTO transaction_logs (user_id, user_name, action, detail) VALUES (?,?,?,?)',
      [req.user.userId, req.user.name, 'MOMO_INITIATE',
       `${networkName} | GHS ${amount} | ${formattedPhone} | ref: ${reference}`]
    );

    // Determine message to show cashier
    const status  = result.data?.status;
    let message   = result.data?.display_text || `Request sent to ${formattedPhone}`;

    // Some networks return "send_otp" or "pending" at this stage — both are normal
    if (status === 'send_otp') {
      message = `OTP sent to ${formattedPhone}. Customer should enter it to approve.`;
    } else if (status === 'pay_offline') {
      message = `Customer will receive a prompt on their phone to approve GHS ${amount}.`;
    }

    res.json({ status, reference, network: networkName, message, data: result.data });

  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    console.error('Paystack initiate error:', msg);
    res.status(500).json({ error: msg });
  }
});

// ─── POST /api/payments/mobile/submit-otp ─────────────────────
// Some networks (Vodafone) require OTP submission
router.post('/mobile/submit-otp', authenticate, async (req, res) => {
  const { otp, reference } = req.body;
  if (!otp || !reference) {
    return res.status(400).json({ error: 'otp and reference are required' });
  }
  try {
    const client = paystackClient();
    const { data: result } = await client.post('/charge/submit_otp', { otp, reference });
    res.json({
      status:    result.data?.status,
      reference,
      message:   result.data?.display_text || 'OTP submitted'
    });
  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    console.error('Paystack OTP error:', msg);
    res.status(500).json({ error: msg });
  }
});

// ─── GET /api/payments/mobile/verify/:reference ───────────────
router.get('/mobile/verify/:reference', authenticate, async (req, res) => {
  try {
    const client = paystackClient();
    const { data: result } = await client.get(`/transaction/verify/${req.params.reference}`);

    if (!result.status) {
      return res.status(400).json({ error: result.message || 'Verification failed' });
    }

    const tx = result.data;
    res.json({
      status:    tx.status,          // 'success', 'pending', 'failed', 'abandoned'
      reference: tx.reference,
      amount:    tx.amount / 100,    // pesewas → GHS
      currency:  tx.currency,
      paid_at:   tx.paid_at,
      channel:   tx.channel,
      message:   tx.gateway_response || tx.status
    });

  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    console.error('Paystack verify error:', msg);
    res.status(500).json({ error: msg });
  }
});

// ─── Webhook handler (exported separately for raw body) ────────
const webhookHandler = [
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const crypto = require('crypto');
    const hash = crypto
      .createHmac('sha512', process.env.PAYSTACK_SECRET_KEY || '')
      .update(req.body)
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      return res.status(400).send('Invalid signature');
    }

    const event = JSON.parse(req.body);
    if (event.event === 'charge.success') {
      const tx = event.data;
      try {
        await db.query(
          'INSERT INTO transaction_logs (user_name, action, detail) VALUES (?,?,?)',
          ['Paystack', 'MOMO_SUCCESS',
           `${tx.reference} | GHS ${tx.amount / 100} | ${tx.customer?.phone_number || ''}`]
        );
      } catch(e) { console.error('Webhook DB error:', e.message); }
    }
    res.sendStatus(200);
  }
];

module.exports         = router;
module.exports.webhook = webhookHandler;
