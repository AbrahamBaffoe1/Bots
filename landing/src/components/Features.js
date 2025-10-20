import React from 'react';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Features = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const features = [
    {
      icon: <ChartIcon />,
      title: 'Multi-Strategy Trading',
      description: 'Advanced strategies including trend following, breakout detection, and pattern recognition with customizable parameters.',
    },
    {
      icon: <ShieldIcon />,
      title: 'Advanced Risk Management',
      description: 'Dynamic position sizing, automatic stop-loss, take-profit levels, and drawdown protection to safeguard your capital.',
    },
    {
      icon: <AnalyticsIcon />,
      title: 'Real-Time Analytics',
      description: 'Comprehensive dashboard with performance metrics, trade history, and detailed analytics to track your success.',
    },
    {
      icon: <ClockIcon />,
      title: 'Session Management',
      description: 'Trade during optimal market hours with intelligent session detection for London, New York, Tokyo, and Sydney markets.',
    },
    {
      icon: <TargetIcon />,
      title: 'Pattern Recognition',
      description: 'Automatic detection of chart patterns, support/resistance levels, and market structure for precise entry points.',
    },
    {
      icon: <LockIcon />,
      title: 'Secure Licensing',
      description: 'Hardware-locked license keys ensure your investment is protected with optional account binding.',
    },
  ];

  return (
    <section className="features" id="features" ref={ref}>
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          <h2 className="section-title gradient-text">Powerful Features</h2>
          <p className="section-subtitle">Everything you need for professional algorithmic trading</p>
        </motion.div>

        <div className="features-grid">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              className="feature-card"
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              whileHover={{ y: -10, transition: { duration: 0.2 } }}
            >
              <motion.div
                className="feature-icon"
                whileHover={{ scale: 1.1, rotate: 5 }}
                transition={{ duration: 0.3 }}
              >
                {feature.icon}
              </motion.div>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

const ChartIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(34, 197, 94, 0.1)"/>
    <path d="M14 34L20 24L26 28L34 16" stroke="#22c55e" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
    <circle cx="20" cy="24" r="2.5" fill="#22c55e"/>
    <circle cx="26" cy="28" r="2.5" fill="#22c55e"/>
    <circle cx="34" cy="16" r="2.5" fill="#22c55e"/>
  </svg>
);

const ShieldIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(59, 130, 246, 0.1)"/>
    <path d="M24 14L16 18V24C16 29 20 32.5 24 34C28 32.5 32 29 32 24V18L24 14Z" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M21 24L23 26L27 22" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const AnalyticsIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(168, 85, 247, 0.1)"/>
    <rect x="16" y="26" width="4" height="8" rx="2" fill="#a855f7"/>
    <rect x="22" y="20" width="4" height="14" rx="2" fill="#a855f7"/>
    <rect x="28" y="24" width="4" height="10" rx="2" fill="#a855f7"/>
    <rect x="34" y="18" width="4" height="16" rx="2" fill="#a855f7"/>
  </svg>
);

const ClockIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(234, 179, 8, 0.1)"/>
    <circle cx="24" cy="24" r="10" stroke="#eab308" strokeWidth="2.5"/>
    <path d="M24 18V24L28 26" stroke="#eab308" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const TargetIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(239, 68, 68, 0.1)"/>
    <circle cx="24" cy="24" r="10" stroke="#ef4444" strokeWidth="2.5"/>
    <circle cx="24" cy="24" r="6" stroke="#ef4444" strokeWidth="2.5"/>
    <circle cx="24" cy="24" r="2" fill="#ef4444"/>
  </svg>
);

const LockIcon = () => (
  <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="48" height="48" rx="12" fill="rgba(161, 161, 170, 0.1)"/>
    <rect x="18" y="22" width="12" height="10" rx="2" stroke="#a1a1aa" strokeWidth="2.5"/>
    <path d="M20 22V19C20 16.7909 21.7909 15 24 15C26.2091 15 28 16.7909 28 19V22" stroke="#a1a1aa" strokeWidth="2.5" strokeLinecap="round"/>
    <circle cx="24" cy="27" r="1.5" fill="#a1a1aa"/>
  </svg>
);

export default Features;
