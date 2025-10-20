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
        <div className="hero-text-content">
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <h1>
              <span className="gradient-text">AI-Powered</span><br />
              Trading Bot<br />
              for MT4
            </h1>
          </motion.div>

          <motion.p
            className="hero-subtitle"
            initial={{ opacity: 0, y: 30 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
            Experience professional algorithmic trading with advanced strategies, intelligent risk management, and real-time performance analytics.
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
        </div>

        <motion.div
          className="hero-visual"
          initial={{ opacity: 0, x: 100 }}
          animate={inView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          <div className="robot-image-container">
            <img
              src="/robot.jpg"
              alt="Smart Trading Bot - AI Powered"
              className="hero-image"
            />
            <div className="image-overlay">
              <h3>Next-Gen Trading Intelligence</h3>
              <p>Powered by advanced machine learning algorithms</p>
            </div>
          </div>
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
