import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Installation = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });
  const [activeStep, setActiveStep] = useState(0);

  const steps = [
    {
      number: 1,
      title: 'Download the Bot Files',
      description: 'After purchase, you\'ll receive a download link for the EA files via email. Extract the ZIP file to access SmartStockTrader.mq4 and all required libraries.',
      icon: 'download',
      visual: 'download'
    },
    {
      number: 2,
      title: 'Install to MT4',
      description: 'Copy all files to your MT4 directory: SmartStockTrader.mq4 → MQL4/Experts/ and all .mqh files → MQL4/Include/',
      icon: 'folder',
      visual: 'folder'
    },
    {
      number: 3,
      title: 'Configure License Key',
      description: 'Open the EA settings in MT4, navigate to the "License" tab, and paste your license key received via email.',
      icon: 'key',
      visual: 'license'
    },
    {
      number: 4,
      title: 'Start Trading',
      description: 'Attach the EA to your preferred chart, configure your risk settings, and let Smart Stock Trader handle the rest.',
      icon: 'chart',
      visual: 'trading'
    },
  ];

  return (
    <section className="installation" id="installation" ref={ref}>
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          <h2 className="section-title gradient-text">Easy Installation</h2>
          <p className="section-subtitle">Hover over each step to see the installation process in action</p>
        </motion.div>

        <div className="installation-wrapper">
          <div className="installation-steps-list">
            {steps.map((step, index) => (
              <motion.div
                key={index}
                className={`tesla-step ${activeStep === index ? 'active' : ''}`}
                initial={{ opacity: 0, x: -30 }}
                animate={inView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                onMouseEnter={() => setActiveStep(index)}
              >
                <div className="tesla-step-number">{step.number}</div>
                <div className="tesla-step-content">
                  <h3>{step.title}</h3>
                  <p>{step.description}</p>
                </div>
                <div className="tesla-step-indicator"></div>
              </motion.div>
            ))}
          </div>

          <motion.div
            className="installation-simulation"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={inView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.3 }}
          >
            <div className="simulation-header">
              <div className="sim-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
              <span className="sim-title">Installation Simulator</span>
            </div>

            <div className="simulation-body">
              <AnimatePresence mode="wait">
                <motion.div
                  key={activeStep}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.4 }}
                  className="simulation-content"
                >
                  {activeStep === 0 && <DownloadSimulation />}
                  {activeStep === 1 && <FolderSimulation />}
                  {activeStep === 2 && <LicenseSimulation />}
                  {activeStep === 3 && <TradingSimulation />}
                </motion.div>
              </AnimatePresence>
            </div>

            <div className="simulation-progress">
              <div className="progress-bar">
                <motion.div
                  className="progress-fill"
                  initial={{ width: '0%' }}
                  animate={{ width: `${((activeStep + 1) / steps.length) * 100}%` }}
                  transition={{ duration: 0.5 }}
                />
              </div>
              <div className="progress-text">
                Step {activeStep + 1} of {steps.length}
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};

// Simulation Components
const DownloadSimulation = () => (
  <div className="sim-download">
    <motion.div
      className="download-icon"
      initial={{ scale: 0 }}
      animate={{ scale: 1, rotate: [0, -10, 10, 0] }}
      transition={{ duration: 0.6 }}
    >
      <svg width="80" height="80" viewBox="0 0 24 24" fill="none">
        <path d="M21 15V19C21 19.5304 20.7893 20.0391 20.4142 20.4142C20.0391 20.7893 19.5304 21 19 21H5C4.46957 21 3.96086 20.7893 3.58579 20.4142C3.21071 20.0391 3 19.5304 3 19V15" stroke="#ff7f00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        <path d="M7 10L12 15L17 10" stroke="#ff7f00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        <path d="M12 15V3" stroke="#ff7f00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </motion.div>
    <motion.div
      className="download-file"
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.3 }}
    >
      <div className="file-icon">📦</div>
      <div className="file-name">SmartStockTrader.zip</div>
      <div className="file-size">2.4 MB</div>
    </motion.div>
    <motion.div
      className="download-progress"
      initial={{ width: 0 }}
      animate={{ width: '100%' }}
      transition={{ delay: 0.6, duration: 1.5 }}
    />
  </div>
);

const FolderSimulation = () => (
  <div className="sim-folder">
    <div className="folder-structure">
      <motion.div className="folder-item" initial={{ x: -20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: 0.1 }}>
        <span className="folder-icon">📁</span> MQL4
      </motion.div>
      <motion.div className="folder-item nested" initial={{ x: -20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: 0.3 }}>
        <span className="folder-icon">📁</span> Experts
        <motion.div className="file-copy" initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ delay: 0.5 }}>
          <span className="check">✓</span>
        </motion.div>
      </motion.div>
      <motion.div className="folder-item nested" initial={{ x: -20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: 0.5 }}>
        <span className="folder-icon">📁</span> Include
        <motion.div className="file-copy" initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ delay: 0.7 }}>
          <span className="check">✓</span>
        </motion.div>
      </motion.div>
    </div>
    <motion.div
      className="success-message"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ delay: 1 }}
    >
      ✓ Files installed successfully
    </motion.div>
  </div>
);

const LicenseSimulation = () => (
  <div className="sim-license">
    <motion.div
      className="license-window"
      initial={{ scale: 0.9, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ duration: 0.5 }}
    >
      <div className="license-header">License Activation</div>
      <div className="license-body">
        <motion.div
          className="license-input"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
        >
          <div className="input-label">Enter License Key</div>
          <motion.div
            className="input-field"
            initial={{ width: 0 }}
            animate={{ width: '100%' }}
            transition={{ delay: 0.5, duration: 1 }}
          >
            XXXX-XXXX-XXXX-XXXX
          </motion.div>
        </motion.div>
        <motion.button
          className="activate-btn"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.2 }}
          whileHover={{ scale: 1.05 }}
        >
          Activate License
        </motion.button>
      </div>
    </motion.div>
    <motion.div
      className="validation-check"
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ delay: 1.5, type: 'spring' }}
    >
      <svg width="60" height="60" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="10" stroke="#22c55e" strokeWidth="2"/>
        <path d="M8 12L11 15L16 9" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </motion.div>
  </div>
);

const TradingSimulation = () => (
  <div className="sim-trading">
    <motion.div
      className="chart-container"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5 }}
    >
      <div className="chart-header">
        <span className="pair">EUR/USD</span>
        <span className="timeframe">H1</span>
      </div>
      <div className="chart-body">
        <svg width="100%" height="200" viewBox="0 0 400 200">
          <motion.path
            d="M 20 150 L 60 120 L 100 140 L 140 100 L 180 110 L 220 80 L 260 90 L 300 60 L 340 70 L 380 50"
            stroke="#22c55e"
            strokeWidth="3"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 2, ease: "easeInOut" }}
          />
          <motion.circle
            cx="380"
            cy="50"
            r="6"
            fill="#22c55e"
            initial={{ scale: 0 }}
            animate={{ scale: [0, 1.5, 1] }}
            transition={{ delay: 2, duration: 0.5 }}
          />
        </svg>
      </div>
      <motion.div
        className="bot-status"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 2.2 }}
      >
        <div className="status-indicator active"></div>
        <span>Bot Active - Monitoring Market</span>
      </motion.div>
    </motion.div>
    <motion.div
      className="trade-stats"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ delay: 2.5 }}
    >
      <div className="stat">
        <div className="stat-label">Win Rate</div>
        <div className="stat-value">87%</div>
      </div>
      <div className="stat">
        <div className="stat-label">Profit Today</div>
        <div className="stat-value">+$234</div>
      </div>
    </motion.div>
  </div>
);

export default Installation;
