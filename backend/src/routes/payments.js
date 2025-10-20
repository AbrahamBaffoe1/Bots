const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// Create checkout session
router.post('/create-checkout-session', paymentController.createCheckoutSession);

// Handle payment success (get license after payment)
router.get('/success', paymentController.handlePaymentSuccess);

// Stripe webhook (no auth needed - Stripe signature verification)
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleWebhook);

module.exports = router;
