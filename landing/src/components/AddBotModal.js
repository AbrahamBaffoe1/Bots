import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';
import './AddBotModal.css';

const AddBotModal = ({ isOpen, onClose, onBotAdded }) => {
  const [step, setStep] = useState(1); // 1: License, 2: Bot Config, 3: Success
  const [licenseKey, setLicenseKey] = useState('');
  const [validatedLicense, setValidatedLicense] = useState(null);
  const [formData, setFormData] = useState({
    instance_name: '',
    mt4_account: '',
    broker_name: '',
    broker_server: '',
    is_live: false
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === 'checkbox' ? checked : value
    });
    setError('');
  };

  const validateLicenseKey = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const token = localStorage.getItem('token');
      const response = await axios.post(
        'http://localhost:5000/api/licenses/validate',
        { license_key: licenseKey.trim().toUpperCase() },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setValidatedLicense(response.data.data.license);
      setStep(2);
    } catch (err) {
      setError(err.response?.data?.message || 'Invalid license key');
    } finally {
      setLoading(false);
    }
  };

  const createBot = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const token = localStorage.getItem('token');
      const response = await axios.post(
        'http://localhost:5000/api/bots',
        {
          license_key: licenseKey.trim().toUpperCase(),
          ...formData
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setStep(3);
      setTimeout(() => {
        onBotAdded(response.data.data.bot);
        handleClose();
      }, 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create bot');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setStep(1);
    setLicenseKey('');
    setValidatedLicense(null);
    setFormData({
      instance_name: '',
      mt4_account: '',
      broker_name: '',
      broker_server: '',
      is_live: false
    });
    setError('');
    setLoading(false);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <motion.div
        className="modal-overlay"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={handleClose}
      >
        <motion.div
          className="add-bot-modal"
          initial={{ opacity: 0, y: -50, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -50, scale: 0.95 }}
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="modal-header">
            <h2>
              {step === 1 && 'Activate License'}
              {step === 2 && 'Configure Bot'}
              {step === 3 && 'Bot Created!'}
            </h2>
            <button className="modal-close" onClick={handleClose}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </button>
          </div>

          {/* Progress Steps */}
          <div className="modal-steps">
            <div className={`step ${step >= 1 ? 'active' : ''} ${step > 1 ? 'completed' : ''}`}>
              <div className="step-circle">
                {step > 1 ? '✓' : '1'}
              </div>
              <span>License</span>
            </div>
            <div className={`step-line ${step > 1 ? 'completed' : ''}`}></div>
            <div className={`step ${step >= 2 ? 'active' : ''} ${step > 2 ? 'completed' : ''}`}>
              <div className="step-circle">
                {step > 2 ? '✓' : '2'}
              </div>
              <span>Configure</span>
            </div>
            <div className={`step-line ${step > 2 ? 'completed' : ''}`}></div>
            <div className={`step ${step >= 3 ? 'active' : ''}`}>
              <div className="step-circle">3</div>
              <span>Complete</span>
            </div>
          </div>

          {/* Step 1: License Key */}
          {step === 1 && (
            <form onSubmit={validateLicenseKey} className="modal-form">
              {error && (
                <div className="error-message">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/>
                  </svg>
                  {error}
                </div>
              )}

              <div className="form-group">
                <label htmlFor="license_key">License Key</label>
                <input
                  type="text"
                  id="license_key"
                  value={licenseKey}
                  onChange={(e) => {
                    setLicenseKey(e.target.value.toUpperCase());
                    setError('');
                  }}
                  placeholder="XXX-XXXX-XXXX-XXXX-XXXX"
                  required
                  className="license-input"
                  maxLength="24"
                />
                <small className="form-hint">
                  Enter your license key from your purchase confirmation
                </small>
              </div>

              <button type="submit" className="btn-primary" disabled={loading}>
                {loading ? (
                  <span className="loading-spinner"></span>
                ) : (
                  'Validate License'
                )}
              </button>

              <div className="no-license-section">
                <p>Don't have a license key?</p>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => window.location.href = '/#pricing'}
                >
                  Purchase License
                </button>
              </div>
            </form>
          )}

          {/* Step 2: Bot Configuration */}
          {step === 2 && validatedLicense && (
            <form onSubmit={createBot} className="modal-form">
              {/* License Info */}
              <div className="license-info">
                <div className="license-badge">
                  <span className="license-type">{validatedLicense.license_type}</span>
                  <span className="license-slots">
                    {validatedLicense.available_slots} of {validatedLicense.max_accounts} slots available
                  </span>
                </div>
              </div>

              {error && (
                <div className="error-message">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/>
                  </svg>
                  {error}
                </div>
              )}

              <div className="form-group">
                <label htmlFor="instance_name">Bot Name</label>
                <input
                  type="text"
                  id="instance_name"
                  name="instance_name"
                  value={formData.instance_name}
                  onChange={handleChange}
                  placeholder="My Trading Bot"
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="mt4_account">MT4 Account Number</label>
                <input
                  type="text"
                  id="mt4_account"
                  name="mt4_account"
                  value={formData.mt4_account}
                  onChange={handleChange}
                  placeholder="12345678"
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="broker_name">Broker Name</label>
                <input
                  type="text"
                  id="broker_name"
                  name="broker_name"
                  value={formData.broker_name}
                  onChange={handleChange}
                  placeholder="e.g., IC Markets, Pepperstone"
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="broker_server">Broker Server (Optional)</label>
                <input
                  type="text"
                  id="broker_server"
                  name="broker_server"
                  value={formData.broker_server}
                  onChange={handleChange}
                  placeholder="e.g., ICMarkets-Demo01"
                />
              </div>

              <div className="form-group checkbox-group">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    name="is_live"
                    checked={formData.is_live}
                    onChange={handleChange}
                  />
                  <span className="checkbox-text">
                    This is a live trading account
                    <small>Uncheck if this is a demo account</small>
                  </span>
                </label>
              </div>

              <div className="form-actions">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setStep(1)}
                  disabled={loading}
                >
                  Back
                </button>
                <button type="submit" className="btn-primary" disabled={loading}>
                  {loading ? (
                    <span className="loading-spinner"></span>
                  ) : (
                    'Create Bot'
                  )}
                </button>
              </div>
            </form>
          )}

          {/* Step 3: Success */}
          {step === 3 && (
            <div className="success-screen">
              <div className="success-icon">
                <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                  <circle cx="32" cy="32" r="32" fill="#10b981" fillOpacity="0.2"/>
                  <path d="M20 32L28 40L44 24" stroke="#10b981" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <h3>Bot Created Successfully!</h3>
              <p>Your trading bot has been configured and is ready to use.</p>
              <div className="success-note">
                <p>Next steps:</p>
                <ol>
                  <li>Download the EA file from the dashboard</li>
                  <li>Install it in your MT4 terminal</li>
                  <li>Enable AutoTrading in MT4</li>
                  <li>Monitor your bot's performance</li>
                </ol>
              </div>
            </div>
          )}
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
};

export default AddBotModal;
