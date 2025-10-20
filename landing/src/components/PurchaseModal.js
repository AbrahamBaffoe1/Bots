import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const PurchaseModal = ({ isOpen, onClose, plan }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    accountNumber: '',
    paymentMethod: 'card',
  });
  const [purchaseComplete, setPurchaseComplete] = useState(false);
  const [licenseKey, setLicenseKey] = useState('');

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const generateLicenseKey = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const segment1 = Array.from({ length: 6 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('');
    const segment2 = Array.from({ length: 6 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('');

    let hash = 0;
    const str = formData.email + formData.name + Date.now();
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash = hash & hash;
    }
    const checksum = Math.abs(hash).toString(36).toUpperCase().substr(0, 4);

    return `SST-${plan?.type || 'TRIAL'}-${segment1}-${segment2}-${checksum}`;
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    // Simulate payment processing
    setTimeout(() => {
      const key = generateLicenseKey();
      setLicenseKey(key);
      setPurchaseComplete(true);

      // Store purchase data
      const purchaseData = {
        licenseKey: key,
        customerName: formData.name,
        customerEmail: formData.email,
        plan: plan?.type,
        price: plan?.price,
        accountNumber: formData.accountNumber || 'Any',
        paymentMethod: formData.paymentMethod,
        purchaseDate: new Date().toISOString(),
      };

      console.log('Purchase Data:', purchaseData);
    }, 1500);
  };

  const handleClose = () => {
    setPurchaseComplete(false);
    setFormData({
      name: '',
      email: '',
      accountNumber: '',
      paymentMethod: 'card',
    });
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

            {!purchaseComplete ? (
              <>
                <h2>Complete Your Purchase</h2>
                <p className="modal-subtitle">
                  Plan: <strong>{plan.name}</strong> - ${plan.price}
                </p>

                <form onSubmit={handleSubmit}>
                  <div className="form-group">
                    <label>Full Name</label>
                    <input
                      type="text"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      placeholder="John Doe"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>Email Address</label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      placeholder="john@example.com"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>MT4 Account Number (Optional)</label>
                    <input
                      type="text"
                      name="accountNumber"
                      value={formData.accountNumber}
                      onChange={handleInputChange}
                      placeholder="Leave empty for any account"
                    />
                  </div>

                  <div className="form-group">
                    <label>Payment Method</label>
                    <div className="payment-methods">
                      <div
                        className={`payment-method ${
                          formData.paymentMethod === 'card' ? 'selected' : ''
                        }`}
                        onClick={() =>
                          setFormData({ ...formData, paymentMethod: 'card' })
                        }
                      >
                        <CreditCardIcon />
                        <span>Card</span>
                      </div>
                      <div
                        className={`payment-method ${
                          formData.paymentMethod === 'paypal' ? 'selected' : ''
                        }`}
                        onClick={() =>
                          setFormData({ ...formData, paymentMethod: 'paypal' })
                        }
                      >
                        <PayPalIcon />
                        <span>PayPal</span>
                      </div>
                      <div
                        className={`payment-method ${
                          formData.paymentMethod === 'crypto' ? 'selected' : ''
                        }`}
                        onClick={() =>
                          setFormData({ ...formData, paymentMethod: 'crypto' })
                        }
                      >
                        <CryptoIcon />
                        <span>Crypto</span>
                      </div>
                    </div>
                  </div>

                  <motion.button
                    type="submit"
                    className="submit-button"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    Complete Purchase
                  </motion.button>
                </form>
              </>
            ) : (
              <motion.div
                className="success-content"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <motion.div
                  className="success-icon"
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', delay: 0.2 }}
                >
                  <SuccessCheckIcon />
                </motion.div>

                <h2>Purchase Successful!</h2>
                <p>Your license key has been generated. Please save it securely:</p>

                <motion.div
                  className="license-key-display"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.4 }}
                >
                  {licenseKey}
                </motion.div>

                <motion.button
                  className="copy-button"
                  onClick={() => {
                    navigator.clipboard.writeText(licenseKey);
                    alert('License key copied to clipboard!');
                  }}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.6 }}
                >
                  Copy License Key
                </motion.button>

                <p className="success-message">
                  A confirmation email with installation instructions has been sent to {formData.email}
                </p>
              </motion.div>
            )}
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

const CreditCardIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="3" y="6" width="18" height="12" rx="2" stroke="currentColor" strokeWidth="2"/>
    <path d="M3 10H21" stroke="currentColor" strokeWidth="2"/>
  </svg>
);

const PayPalIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M8 6H14C16.2091 6 18 7.79086 18 10C18 12.2091 16.2091 14 14 14H10L9 18H6L8 6Z" stroke="currentColor" strokeWidth="2"/>
  </svg>
);

const CryptoIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2"/>
    <path d="M9 10.5H14M9 13.5H14M11 8V16M13 8V16" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

const SuccessCheckIcon = () => (
  <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="40" cy="40" r="38" stroke="#22c55e" strokeWidth="4"/>
    <path d="M25 40L35 50L55 30" stroke="#22c55e" strokeWidth="5" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

export default PurchaseModal;
