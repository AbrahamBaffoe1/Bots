import React from 'react';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Installation = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const steps = [
    {
      number: 1,
      title: 'Download the Bot Files',
      description: 'After purchase, you\'ll receive a download link for the EA files via email. Extract the ZIP file to access SmartStockTrader.mq4 and all required libraries.',
      code: null,
    },
    {
      number: 2,
      title: 'Install to MT4',
      description: 'Copy all files to your MT4 directory:',
      code: [
        'SmartStockTrader.mq4 → MQL4/Experts/',
        'All .mqh files → MQL4/Include/',
      ],
    },
    {
      number: 3,
      title: 'Configure License Key',
      description: 'Open the EA settings in MT4, navigate to the "License" tab, and paste your license key received via email. The bot will automatically validate your license.',
      code: null,
    },
    {
      number: 4,
      title: 'Start Trading',
      description: 'Attach the EA to your preferred chart, configure your risk settings, and let Smart Stock Trader handle the rest. Monitor performance through the built-in dashboard.',
      code: null,
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
          <p className="section-subtitle">Get started in minutes with our simple setup process</p>
        </motion.div>

        <div className="installation-timeline">
          {steps.map((step, index) => (
            <motion.div
              key={index}
              className="step-container"
              initial={{ opacity: 0, x: index % 2 === 0 ? -50 : 50 }}
              animate={inView ? { opacity: 1, x: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.2 }}
            >
              <motion.div
                className="step-number"
                whileHover={{ scale: 1.2, rotate: 10 }}
                transition={{ duration: 0.3 }}
              >
                {step.number}
              </motion.div>

              <div className="step-content">
                <h3>{step.title}</h3>
                <p>{step.description}</p>
                {step.code && (
                  <div className="code-block">
                    {step.code.map((line, i) => (
                      <motion.div
                        key={i}
                        className="code-line"
                        initial={{ opacity: 0, y: 10 }}
                        animate={inView ? { opacity: 1, y: 0 } : {}}
                        transition={{ delay: index * 0.2 + 0.5 + i * 0.1 }}
                      >
                        <code>{line}</code>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>

              {index < steps.length - 1 && (
                <motion.div
                  className="step-connector"
                  initial={{ scaleY: 0 }}
                  animate={inView ? { scaleY: 1 } : {}}
                  transition={{ duration: 0.5, delay: index * 0.2 + 0.3 }}
                />
              )}
            </motion.div>
          ))}
        </div>

        <motion.div
          className="installation-visual"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
        >
          <MT4SetupSVG />
        </motion.div>
      </div>
    </section>
  );
};

const MT4SetupSVG = () => (
  <svg width="600" height="300" viewBox="0 0 600 300" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Terminal Window */}
    <rect x="50" y="50" width="500" height="200" rx="12" fill="rgba(24, 24, 27, 0.8)" stroke="rgba(255, 255, 255, 0.1)" strokeWidth="1"/>

    {/* Window Controls */}
    <circle cx="70" cy="70" r="5" fill="#ef4444"/>
    <circle cx="90" cy="70" r="5" fill="#eab308"/>
    <circle cx="110" cy="70" r="5" fill="#22c55e"/>

    {/* Title Bar */}
    <text x="140" y="75" fill="#a1a1aa" fontSize="12" fontWeight="500">MetaTrader 4 - Expert Advisors</text>

    {/* Folder Icons */}
    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}>
      <rect x="80" y="100" width="60" height="50" rx="6" fill="rgba(161, 161, 170, 0.2)" stroke="rgba(255, 255, 255, 0.1)"/>
      <path d="M90 110 L100 110 L105 105 L125 105 L130 110 L130 140 L90 140 Z" fill="rgba(161, 161, 170, 0.3)"/>
      <text x="95" y="130" fill="#a1a1aa" fontSize="10">Experts</text>
    </motion.g>

    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }}>
      <rect x="160" y="100" width="60" height="50" rx="6" fill="rgba(161, 161, 170, 0.2)" stroke="rgba(255, 255, 255, 0.1)"/>
      <path d="M170 110 L180 110 L185 105 L205 105 L210 110 L210 140 L170 140 Z" fill="rgba(161, 161, 170, 0.3)"/>
      <text x="172" y="130" fill="#a1a1aa" fontSize="10">Include</text>
    </motion.g>

    {/* File Icons */}
    <motion.g initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.6 }}>
      <rect x="260" y="105" width="100" height="40" rx="4" fill="rgba(34, 197, 94, 0.1)" stroke="#22c55e" strokeWidth="1"/>
      <text x="270" y="128" fill="#22c55e" fontSize="11" fontWeight="600">SmartStock...</text>
    </motion.g>

    <motion.g initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.7 }}>
      <rect x="380" y="105" width="100" height="40" rx="4" fill="rgba(59, 130, 246, 0.1)" stroke="#3b82f6" strokeWidth="1"/>
      <text x="390" y="128" fill="#3b82f6" fontSize="11" fontWeight="600">Libraries.mqh</text>
    </motion.g>

    {/* Success Checkmark */}
    <motion.g
      initial={{ scale: 0 }}
      animate={{ scale: 1 }}
      transition={{ delay: 1, type: 'spring' }}
    >
      <circle cx="500" cy="125" r="20" fill="rgba(34, 197, 94, 0.2)" stroke="#22c55e" strokeWidth="2"/>
      <path d="M490 125 L497 132 L510 118" stroke="#22c55e" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
    </motion.g>

    {/* Terminal Lines */}
    <motion.g initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.8 }}>
      <text x="80" y="180" fill="#22c55e" fontSize="11" fontFamily="monospace">✓ Files copied successfully</text>
      <text x="80" y="200" fill="#a1a1aa" fontSize="11" fontFamily="monospace">Installation complete. Ready to activate.</text>
    </motion.g>
  </svg>
);

export default Installation;
