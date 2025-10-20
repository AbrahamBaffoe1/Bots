import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';

const PurchaseModal = ({ isOpen, onClose, plan }) => {
  const [formData, setFormData] = useState({
    email: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Map plan names to backend plan types
      const planTypeMap = {
        'Trial': 'TRIAL',
        'Basic': 'BASIC',
        'Pro': 'PRO',
        'Enterprise': 'ENTERPRISE'
      };

      const planType = planTypeMap[plan.name] || 'BASIC';

      // Create checkout session
      const response = await axios.post(
        'http://localhost:5000/api/payments/create-checkout-session',
        {
          plan_type: planType,
          customer_email: formData.email
        }
      );

      if (response.data.success) {
        if (planType === 'TRIAL') {
          // For trial, show success message
          const message = response.data.data.is_new_user
            ? `🎉 Account Created Successfully!\n\nYour login credentials and license key have been sent to:\n${formData.email}\n\nPlease check your email inbox (and spam folder) for your password and license key.\n\nYou can now login to your dashboard!`
            : `✅ Trial License Generated!\n\nYour license key: ${response.data.data.license_key}\n\nPlease save this key and use it to activate your bot in the dashboard.`;

          alert(message);
          handleClose();
        } else {
          // For paid plans, redirect to Stripe Checkout
          window.location.href = response.data.data.checkout_url;
        }
      }
    } catch (err) {
      console.error('Payment error:', err);
      setError(err.response?.data?.message || 'Failed to process payment. Please try again.');
      setLoading(false);
    }
  };

  const handleClose = () => {
    setFormData({ email: '' });
    setError('');
    setLoading(false);
    onClose();
  };

  if (!plan) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="modal-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={handleClose}
        >
          <motion.div
            className="modal-container"
            initial={{ scale: 0.9, y: 50 }}
            animate={{ scale: 1, y: 0 }}
            exit={{ scale: 0.9, y: 50 }}
            onClick={(e) => e.stopPropagation()}
          >
            <button className="modal-close" onClick={handleClose}>
              <CloseIcon />
            </button>

            <h2>Purchase {plan.name} Plan</h2>
            <p className="modal-subtitle">
              ${plan.price} - Up to {plan.accounts} MT4 Account{plan.accounts > 1 ? 's' : ''}
            </p>

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  placeholder="your@email.com"
                  required
                  disabled={loading}
                />
                <small>License key will be sent to this email</small>
              </div>

              {error && (
                <div className="error-message">
                  {error}
                </div>
              )}

              <div className="plan-features">
                <h4>What you'll get:</h4>
                <ul>
                  <li>License key for {plan.accounts} MT4 account{plan.accounts > 1 ? 's' : ''}</li>
                  <li>{plan.name === 'Trial' ? '7 days' : '1 year'} access</li>
                  <li>Automated trading 24/7</li>
                  <li>Email support</li>
                  {plan.name === 'Pro' && <li>Priority support</li>}
                  {plan.name === 'Enterprise' && <li>Dedicated support</li>}
                </ul>
              </div>

              <motion.button
                type="submit"
                className="submit-button"
                whileHover={{ scale: loading ? 1 : 1.02 }}
                whileTap={{ scale: loading ? 1 : 0.98 }}
                disabled={loading}
              >
                {loading ? 'Processing...' : plan.name === 'Trial' ? 'Get Free Trial' : 'Continue to Payment'}
              </motion.button>

              <p className="payment-note">
                {plan.name === 'Trial'
                  ? 'No payment required for trial'
                  : 'You will be redirected to secure Stripe checkout'}
              </p>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

const CloseIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

export default PurchaseModal;
