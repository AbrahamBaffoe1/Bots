import React, { useEffect } from 'react';
import { motion, useTransform } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Hero = ({ scrollYProgress, onLoginClick }) => {
  const y = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  useEffect(() => {
    const handleScroll = () => {
      const scrolled = window.scrollY;
      // Apply parallax effect to the ::before pseudo-element via CSS custom property
      document.documentElement.style.setProperty('--scroll-y', `${scrolled * 0.5}px`);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

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
            <button className="nav-login-btn" onClick={() => onLoginClick('login')}>
              Login
            </button>
            <button className="nav-signup-btn" onClick={() => onLoginClick('signup')}>
              Sign Up
            </button>
          </div>
        </motion.div>
      </nav>

      <div className="hero-content">
        <motion.div
          className="hero-text-content"
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          <h1>
            <span className="gradient-text">AI-Powered</span><br />
            Trading Bot for MT4
          </h1>

          <p className="hero-subtitle">
            Experience professional algorithmic trading with advanced strategies, intelligent risk management, and real-time performance analytics powered by cutting-edge AI.
          </p>

          <a href="#pricing" className="cta-button">
            <span>Get Started Now</span>
            <ArrowIcon />
          </a>
        </motion.div>

        <motion.div
          className="hero-stats"
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.5 }}
        >
          <motion.div
            className="stat-card"
            whileHover={{ scale: 1.05 }}
            transition={{ duration: 0.3 }}
          >
            <div className="stat-number">73.4%</div>
            <div className="stat-label">Win Rate</div>
          </motion.div>

          <motion.div
            className="stat-card"
            whileHover={{ scale: 1.05 }}
            transition={{ duration: 0.3 }}
          >
            <div className="stat-number">1,247</div>
            <div className="stat-label">Total Trades</div>
          </motion.div>

          <motion.div
            className="stat-card"
            whileHover={{ scale: 1.05 }}
            transition={{ duration: 0.3 }}
          >
            <div className="stat-number">+$45K</div>
            <div className="stat-label">Profit Generated</div>
          </motion.div>
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

export default Hero;
