import React from 'react';
import { motion, useTransform } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Hero = ({ scrollYProgress }) => {
  const y = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  return (
    <motion.section
      className="hero"
      style={{ y, opacity }}
      ref={ref}
    >
      <nav className="nav">
        <motion.div
          className="nav-container"
          initial={{ y: -100 }}
          animate={{ y: 0 }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
        >
          <div className="logo">
            <TradingLogo />
            <span>Smart Stock Trader</span>
          </div>
          <div className="nav-links">
            <a href="#features">Features</a>
            <a href="#pricing">Pricing</a>
            <a href="#installation">Installation</a>
          </div>
        </motion.div>
      </nav>

      <div className="hero-content">
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          <h1>
            <span className="gradient-text">Professional</span><br />
            Trading Bot for MT4
          </h1>
        </motion.div>

        <motion.p
          className="hero-subtitle"
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          Advanced algorithmic trading with multi-strategy support, <br />
          intelligent risk management, and real-time analytics
        </motion.p>

        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.6, delay: 0.6 }}
        >
          <a href="#pricing" className="cta-button">
            <span>Get Started Now</span>
            <ArrowIcon />
          </a>
        </motion.div>

        <motion.div
          className="hero-visual"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 1, delay: 0.8 }}
        >
          <TradingDashboardSVG />
        </motion.div>
      </div>
    </motion.section>
  );
};

const TradingLogo = () => (
  <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="url(#logoGradient)" />
    <path d="M12 28L18 18L24 22L28 12" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
    <circle cx="18" cy="18" r="2" fill="white"/>
    <circle cx="24" cy="22" r="2" fill="white"/>
    <defs>
      <linearGradient id="logoGradient" x1="0" y1="0" x2="40" y2="40" gradientUnits="userSpaceOnUse">
        <stop stopColor="#fafafa"/>
        <stop offset="1" stopColor="#a1a1aa"/>
      </linearGradient>
    </defs>
  </svg>
);

const ArrowIcon = () => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M4 10H16M16 10L11 5M16 10L11 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const TradingDashboardSVG = () => (
  <motion.svg
    width="800"
    height="500"
    viewBox="0 0 800 500"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className="dashboard-svg"
  >
    {/* Dashboard Container */}
    <motion.rect
      x="50"
      y="50"
      width="700"
      height="400"
      rx="16"
      fill="rgba(24, 24, 27, 0.8)"
      stroke="rgba(255, 255, 255, 0.1)"
      strokeWidth="1"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6 }}
    />

    {/* Chart Lines */}
    <motion.path
      d="M100 300 L150 250 L200 280 L250 200 L300 220 L350 150 L400 180 L450 120 L500 160 L550 100 L600 140 L650 90"
      stroke="url(#chartGradient)"
      strokeWidth="3"
      strokeLinecap="round"
      fill="none"
      initial={{ pathLength: 0 }}
      animate={{ pathLength: 1 }}
      transition={{ duration: 2, delay: 0.5, ease: 'easeInOut' }}
    />

    {/* Candlesticks */}
    <motion.g initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 1 }}>
      <rect x="120" y="200" width="12" height="60" fill="#22c55e" rx="2"/>
      <rect x="160" y="180" width="12" height="80" fill="#22c55e" rx="2"/>
      <rect x="200" y="220" width="12" height="40" fill="#ef4444" rx="2"/>
      <rect x="240" y="170" width="12" height="90" fill="#22c55e" rx="2"/>
      <rect x="280" y="190" width="12" height="60" fill="#ef4444" rx="2"/>
    </motion.g>

    {/* Data Points */}
    {[150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650].map((x, i) => (
      <motion.circle
        key={i}
        cx={x}
        cy={300 - i * 20}
        r="4"
        fill="#fafafa"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.5 + i * 0.1 }}
      />
    ))}

    {/* Stats Cards */}
    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 1.2 }}>
      <rect x="70" y="370" width="150" height="60" rx="8" fill="rgba(39, 39, 42, 0.6)" stroke="rgba(255, 255, 255, 0.1)"/>
      <text x="90" y="395" fill="#a1a1aa" fontSize="12">Win Rate</text>
      <text x="90" y="420" fill="#22c55e" fontSize="24" fontWeight="600">73.4%</text>
    </motion.g>

    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 1.3 }}>
      <rect x="240" y="370" width="150" height="60" rx="8" fill="rgba(39, 39, 42, 0.6)" stroke="rgba(255, 255, 255, 0.1)"/>
      <text x="260" y="395" fill="#a1a1aa" fontSize="12">Total Trades</text>
      <text x="260" y="420" fill="#fafafa" fontSize="24" fontWeight="600">1,247</text>
    </motion.g>

    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 1.4 }}>
      <rect x="410" y="370" width="150" height="60" rx="8" fill="rgba(39, 39, 42, 0.6)" stroke="rgba(255, 255, 255, 0.1)"/>
      <text x="430" y="395" fill="#a1a1aa" fontSize="12">Profit</text>
      <text x="430" y="420" fill="#22c55e" fontSize="24" fontWeight="600">+$45.2K</text>
    </motion.g>

    <motion.g initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 1.5 }}>
      <rect x="580" y="370" width="150" height="60" rx="8" fill="rgba(39, 39, 42, 0.6)" stroke="rgba(255, 255, 255, 0.1)"/>
      <text x="600" y="395" fill="#a1a1aa" fontSize="12">Drawdown</text>
      <text x="600" y="420" fill="#fafafa" fontSize="24" fontWeight="600">-8.3%</text>
    </motion.g>

    <defs>
      <linearGradient id="chartGradient" x1="100" y1="300" x2="650" y2="90" gradientUnits="userSpaceOnUse">
        <stop stopColor="#22c55e" />
        <stop offset="1" stopColor="#fafafa" />
      </linearGradient>
    </defs>
  </motion.svg>
);

export default Hero;
