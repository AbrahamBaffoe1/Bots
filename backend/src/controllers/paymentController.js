const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { License, User } = require('../models');
const crypto = require('crypto');
const emailService = require('../utils/emailService');

// Plan pricing configuration
const PLAN_PRICES = {
  TRIAL: { amount: 0, name: '7-Day Trial', max_accounts: 1, duration_days: 7 },
  BASIC: { amount: 4900, name: 'Basic Plan', max_accounts: 1, duration_days: 365 }, // $49
  PRO: { amount: 14900, name: 'Pro Plan', max_accounts: 3, duration_days: 365 }, // $149
  ENTERPRISE: { amount: 49900, name: 'Enterprise Plan', max_accounts: 10, duration_days: 365 } // $499
};

// Generate license key (same as in licenseController)
const generateLicenseKey = (type) => {
  const prefix = {
    'TRIAL': 'TRL',
    'BASIC': 'BSC',
    'PRO': 'PRO',
    'ENTERPRISE': 'ENT'
  }[type] || 'LIC';

  const randomPart = crypto.randomBytes(12).toString('hex').toUpperCase();
  return `${prefix}-${randomPart.substring(0, 4)}-${randomPart.substring(4, 8)}-${randomPart.substring(8, 12)}-${randomPart.substring(12, 16)}`;
};

// Create Stripe Checkout Session
exports.createCheckoutSession = async (req, res) => {
  try {
    const { plan_type, customer_email } = req.body;

    if (!plan_type || !PLAN_PRICES[plan_type]) {
      return res.status(400).json({
        success: false,
        message: 'Invalid plan type'
      });
    }

    const planConfig = PLAN_PRICES[plan_type];

    // For free trial, create user account and license immediately
    if (plan_type === 'TRIAL') {
      // Check if user already exists
      let user = await User.findOne({ where: { email: customer_email } });

      let password = null;
      let isNewUser = false;

      if (!user) {
        // Generate secure password
        password = crypto.randomBytes(8).toString('hex'); // 16 character password

        // Extract name from email
        const emailName = customer_email.split('@')[0];
        const nameParts = emailName.split(/[._-]/);
        const firstName = nameParts[0] ? nameParts[0].charAt(0).toUpperCase() + nameParts[0].slice(1) : 'User';
        const lastName = nameParts[1] ? nameParts[1].charAt(0).toUpperCase() + nameParts[1].slice(1) : 'Trial';

        // Create user account (password will be auto-hashed by User model beforeCreate hook)
        user = await User.create({
          email: customer_email,
          password_hash: password, // User model will hash this automatically
          first_name: firstName,
          last_name: lastName,
          email_verified: true, // Auto-verify trial users
          is_active: true
        });

        isNewUser = true;
      }

      // Generate license key
      const licenseKey = generateLicenseKey('TRIAL');
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      // Create license and assign to user
      const license = await License.create({
        user_id: user.id,
        license_key: licenseKey,
        license_type: 'TRIAL',
        max_accounts: 1,
        status: 'active',
        issued_at: new Date(),
        expires_at: expiresAt
      });

      // Send welcome email with credentials (only for new users)
      if (isNewUser && password) {
        try {
          await emailService.sendWelcomeEmail(customer_email, password, licenseKey);
          console.log(`Welcome email sent to ${customer_email}`);
        } catch (emailError) {
          console.error('Failed to send welcome email:', emailError);
          // Don't fail the registration if email fails
        }
      }

      return res.json({
        success: true,
        message: isNewUser ? 'Account created and trial activated' : 'Trial license created',
        data: {
          license_key: licenseKey,
          license_type: 'TRIAL',
          expires_at: expiresAt,
          is_new_user: isNewUser,
          email_sent: isNewUser
        }
      });
    }

    // Create Stripe Checkout Session for paid plans
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `Smart Stock Trader - ${planConfig.name}`,
              description: `Up to ${planConfig.max_accounts} MT4 account${planConfig.max_accounts > 1 ? 's' : ''}, valid for ${planConfig.duration_days} days`
            },
            unit_amount: planConfig.amount
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      customer_email: customer_email,
      metadata: {
        plan_type: plan_type,
        max_accounts: planConfig.max_accounts.toString(),
        duration_days: planConfig.duration_days.toString()
      },
      success_url: `${process.env.FRONTEND_URL}/payment-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.FRONTEND_URL}/?payment=cancelled`
    });

    res.json({
      success: true,
      data: {
        session_id: session.id,
        checkout_url: session.url
      }
    });
  } catch (error) {
    console.error('Checkout session error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create checkout session',
      error: error.message
    });
  }
};

// Handle successful payment (retrieve session and create license)
exports.handlePaymentSuccess = async (req, res) => {
  try {
    const { session_id } = req.query;

    if (!session_id) {
      return res.status(400).json({
        success: false,
        message: 'Session ID is required'
      });
    }

    // Retrieve the session from Stripe
    const session = await stripe.checkout.sessions.retrieve(session_id);

    if (session.payment_status !== 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Payment not completed'
      });
    }

    // Check if license already created for this session
    const existingLicense = await License.findOne({
      where: { hardware_id: session_id } // Using hardware_id to store session_id temporarily
    });

    if (existingLicense) {
      return res.json({
        success: true,
        message: 'License already created',
        data: {
          license_key: existingLicense.license_key,
          license_type: existingLicense.license_type,
          expires_at: existingLicense.expires_at
        }
      });
    }

    // Create license
    const { plan_type, max_accounts, duration_days } = session.metadata;
    const licenseKey = generateLicenseKey(plan_type);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + parseInt(duration_days));

    const license = await License.create({
      license_key: licenseKey,
      license_type: plan_type,
      max_accounts: parseInt(max_accounts),
      status: 'active',
      expires_at: expiresAt,
      hardware_id: session_id // Store session ID to prevent duplicate licenses
    });

    // Send email with license key to customer
    try {
      await emailService.sendLicenseKeyEmail(session.customer_email, licenseKey, plan_type);
      console.log(`License email sent to ${session.customer_email}`);
    } catch (emailError) {
      console.error('Failed to send license email:', emailError);
      // Don't fail the payment if email fails
    }

    res.json({
      success: true,
      message: 'License created successfully',
      data: {
        license_key: licenseKey,
        license_type: plan_type,
        expires_at: expiresAt,
        customer_email: session.customer_email
      }
    });
  } catch (error) {
    console.error('Payment success handler error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process payment',
      error: error.message
    });
  }
};

// Webhook handler for Stripe events
exports.handleWebhook = async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  try {
    const event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);

    // Handle the event
    switch (event.type) {
      case 'checkout.session.completed':
        const session = event.data.object;

        // Create license after successful payment
        if (session.payment_status === 'paid') {
          const { plan_type, max_accounts, duration_days } = session.metadata;
          const licenseKey = generateLicenseKey(plan_type);

          const expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + parseInt(duration_days));

          await License.create({
            license_key: licenseKey,
            license_type: plan_type,
            max_accounts: parseInt(max_accounts),
            status: 'active',
            expires_at: expiresAt,
            hardware_id: session.id
          });

          console.log(`License ${licenseKey} created for session ${session.id}`);
        }
        break;

      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(400).send(`Webhook Error: ${error.message}`);
  }
};

module.exports = exports;
