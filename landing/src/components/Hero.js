import React, { useEffect, useState } from 'react';
import { motion, useTransform, useAnimation } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Hero = ({ scrollYProgress, onLoginClick }) => {
  const y = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  // Animated counters
  const [userCount, setUserCount] = useState(0);
  const [activeTraders, setActiveTraders] = useState(0);

  // Typewriter effect
  const [displayedText, setDisplayedText] = useState('');
  const fullText = 'AI-Powered';

  useEffect(() => {
    const handleScroll = () => {
      const scrolled = window.scrollY;
      // Apply parallax effect to the ::before pseudo-element via CSS custom property
      document.documentElement.style.setProperty('--scroll-y', `${scrolled * 0.5}px`);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Typewriter animation
  useEffect(() => {
    if (inView) {
      let currentIndex = 0;
      const interval = setInterval(() => {
        if (currentIndex <= fullText.length) {
          setDisplayedText(fullText.slice(0, currentIndex));
          currentIndex++;
        } else {
          clearInterval(interval);
        }
      }, 100);
      return () => clearInterval(interval);
    }
  }, [inView]);

  // Animated counter for users
  useEffect(() => {
    if (inView) {
      let current = 0;
      const target = 2847;
      const increment = target / 50;
      const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
          setUserCount(target);
          clearInterval(timer);
        } else {
          setUserCount(Math.floor(current));
        }
      }, 30);
      return () => clearInterval(timer);
    }
  }, [inView]);

  // Animated counter for active traders
  useEffect(() => {
    if (inView) {
      let current = 0;
      const target = 1234;
      const increment = target / 50;
      const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
          setActiveTraders(target);
          clearInterval(timer);
        } else {
          setActiveTraders(Math.floor(current));
        }
      }, 30);
      return () => clearInterval(timer);
    }
  }, [inView]);

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
        {/* Gradient Orbs Background */}
        <div className="gradient-orb orb-1"></div>
        <div className="gradient-orb orb-2"></div>
        <div className="grid-pattern"></div>

        <motion.div
          className="hero-text-content"
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          {/* Tagline */}
          <motion.div
            className="hero-tagline"
            initial={{ opacity: 0 }}
            animate={inView ? { opacity: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.1 }}
          >
            Professional Trading Automation
          </motion.div>

          {/* Trust Indicators */}
          <motion.div
            className="trust-indicators"
            initial={{ opacity: 0, y: 20 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.3 }}
          >
            <div className="trust-item">
              <div className="user-avatars">
                <div className="avatar" style={{ backgroundImage: 'url(https://randomuser.me/api/portraits/men/32.jpg)' }}></div>
                <div className="avatar" style={{ backgroundImage: 'url(https://randomuser.me/api/portraits/women/44.jpg)' }}></div>
                <div className="avatar" style={{ backgroundImage: 'url(https://randomuser.me/api/portraits/men/46.jpg)' }}></div>
                <div className="avatar" style={{ backgroundImage: 'url(https://randomuser.me/api/portraits/women/68.jpg)' }}></div>
                <div className="avatar" style={{ backgroundImage: 'url(https://randomuser.me/api/portraits/men/22.jpg)' }}></div>
              </div>
              <span className="trust-text">Trusted by <strong>{userCount.toLocaleString()}+</strong> traders</span>
            </div>
            <div className="trust-divider"></div>
            <div className="trust-item">
              <div className="rating-stars">
                <StarIcon />
                <StarIcon />
                <StarIcon />
                <StarIcon />
                <StarIcon />
              </div>
              <span className="trust-text"><strong>4.9/5</strong> rating</span>
            </div>
            <div className="trust-divider"></div>
            <div className="trust-item live-status">
              <div className="status-pulse"></div>
              <span className="trust-text"><strong>{activeTraders.toLocaleString()}</strong> active now</span>
            </div>
          </motion.div>

          <h1>
            <span className="gradient-text typewriter">{displayedText}<span className="cursor">|</span></span><br />
            Trading Bot for MT4
          </h1>

          <p className="hero-subtitle">
            Experience professional algorithmic trading with advanced strategies, intelligent risk management, and real-time performance analytics powered by cutting-edge AI.
          </p>

          {/* Platform Compatibility Badges */}
          <motion.div
            className="platform-badges"
            initial={{ opacity: 0 }}
            animate={inView ? { opacity: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.6 }}
          >
            <div className="platform-badge">
              <MT4Icon />
              <span>MT4 Compatible</span>
            </div>
            <div className="platform-badge">
              <MT5Icon />
              <span>MT5 Ready</span>
            </div>
            <div className="security-badge">
              <LockIcon />
              <span>SSL Encrypted</span>
            </div>
            <div className="security-badge">
              <ShieldIcon />
              <span>Secure Trading</span>
            </div>
          </motion.div>

          <a href="#pricing" className="cta-button">
            <span>Get Started Now</span>
            <ArrowIcon />
          </a>

          {/* Risk Disclaimer */}
          <motion.div
            className="risk-disclaimer"
            initial={{ opacity: 0 }}
            animate={inView ? { opacity: 1 } : {}}
            transition={{ duration: 0.6, delay: 0.8 }}
          >
            <WarningIcon />
            <span>Risk Warning: Trading involves risk. Trade responsibly.</span>
          </motion.div>
        </motion.div>

        <motion.div
          className="hero-stats-container"
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.5 }}
        >
          {/* Live Mini Chart */}
          <motion.div
            className="live-chart-widget"
            initial={{ opacity: 0, x: -50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.7 }}
            whileHover={{ y: -5 }}
          >
            <div className="widget-header">
              <div className="widget-title">
                <ActivityIcon />
                <span>Live Performance</span>
              </div>
              <div className="live-indicator">
                <div className="pulse-dot"></div>
                <span>LIVE</span>
              </div>
            </div>
            <LiveMiniChart />
          </motion.div>

          {/* Glassmorphism Stats */}
          <div className="hero-stats">
            <motion.div
              className="stat-card glass"
              whileHover={{ scale: 1.05, y: -5 }}
              transition={{ duration: 0.3 }}
            >
              <div className="stat-icon">
                <TrendingUpIcon />
              </div>
              <div className="stat-number">73.4%</div>
              <div className="stat-label">Win Rate</div>
              <div className="stat-trend positive">+2.3% this week</div>
            </motion.div>

            <motion.div
              className="stat-card glass"
              whileHover={{ scale: 1.05, y: -5 }}
              transition={{ duration: 0.3 }}
            >
              <div className="stat-icon">
                <ChartIcon />
              </div>
              <div className="stat-number">1,247</div>
              <div className="stat-label">Total Trades</div>
              <div className="stat-trend positive">+89 today</div>
            </motion.div>

            <motion.div
              className="stat-card glass"
              whileHover={{ scale: 1.05, y: -5 }}
              transition={{ duration: 0.3 }}
            >
              <div className="stat-icon">
                <DollarIcon />
              </div>
              <div className="stat-number">+$45K</div>
              <div className="stat-label">Profit Generated</div>
              <div className="stat-trend positive">+$1.2K today</div>
            </motion.div>
          </div>

          {/* Floating Dashboard Preview */}
          <motion.div
            className="dashboard-preview"
            initial={{ opacity: 0, x: 50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.9 }}
            whileHover={{ y: -10 }}
          >
            <div className="preview-header">
              <div className="preview-title">Trading Dashboard</div>
              <div className="preview-badge">Preview</div>
            </div>
            <DashboardPreview />
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

const StarIcon = () => (
  <svg width="16" height="16" viewBox="0 0 20 20" fill="#fbbf24" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 1L12.9389 7.0561L19.5106 8.05573L14.755 12.6939L15.8779 19.4443L10 16.1L4.12215 19.4443L5.24502 12.6939L0.489435 8.05573L7.0611 7.0561L10 1Z"/>
  </svg>
);

const MT4Icon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="2" y="2" width="20" height="20" rx="4" stroke="currentColor" strokeWidth="2"/>
    <path d="M8 8L12 12L16 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M8 16L12 12L16 16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const MT5Icon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="2" y="2" width="20" height="20" rx="4" stroke="currentColor" strokeWidth="2"/>
    <path d="M7 12L10 9L13 14L17 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const LockIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="5" y="11" width="14" height="10" rx="2" stroke="currentColor" strokeWidth="2"/>
    <path d="M8 11V7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7V11" stroke="currentColor" strokeWidth="2"/>
  </svg>
);

const ShieldIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 2L4 6V12C4 16.4 7.6 20.5 12 22C16.4 20.5 20 16.4 20 12V6L12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M9 12L11 14L15 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const WarningIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 9V13M12 17H12.01M10.29 3.86L1.82 18C1.64 18.33 1.54 18.7 1.53 19.08C1.52 19.46 1.61 19.84 1.78 20.18C1.95 20.52 2.2 20.81 2.51 21.03C2.82 21.25 3.18 21.39 3.56 21.44L3.82 21.46H20.18C20.56 21.46 20.93 21.37 21.27 21.19C21.61 21.01 21.9 20.76 22.12 20.45C22.34 20.14 22.48 19.79 22.53 19.41C22.58 19.03 22.54 18.65 22.41 18.29L22.29 18L13.71 3.86C13.53 3.54 13.27 3.27 12.96 3.07C12.65 2.87 12.29 2.75 11.92 2.72C11.55 2.69 11.18 2.75 10.84 2.89C10.5 3.03 10.2 3.25 9.97 3.53L10.29 3.86Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const TrendingUpIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M23 6L13.5 15.5L8.5 10.5L1 18" stroke="url(#trendGradient)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M17 6H23V12" stroke="url(#trendGradient)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <defs>
      <linearGradient id="trendGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#22c55e"/>
        <stop offset="100%" stopColor="#10b981"/>
      </linearGradient>
    </defs>
  </svg>
);

const ChartIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M3 3V21H21" stroke="url(#chartGradient)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M7 16L12 11L16 15L21 10" stroke="url(#chartGradient)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <defs>
      <linearGradient id="chartGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#3b82f6"/>
        <stop offset="100%" stopColor="#2563eb"/>
      </linearGradient>
    </defs>
  </svg>
);

const DollarIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="12" cy="12" r="10" stroke="url(#dollarGradient)" strokeWidth="2"/>
    <path d="M12 6V18M9 9H13.5C14.6046 9 15.5 9.89543 15.5 11C15.5 12.1046 14.6046 13 13.5 13H10.5C9.39543 13 8.5 13.8954 8.5 15C8.5 16.1046 9.39543 17 10.5 17H15" stroke="url(#dollarGradient)" strokeWidth="2" strokeLinecap="round"/>
    <defs>
      <linearGradient id="dollarGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#fbbf24"/>
        <stop offset="100%" stopColor="#f59e0b"/>
      </linearGradient>
    </defs>
  </svg>
);

const ActivityIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M22 12H18L15 21L9 3L6 12H2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const LiveMiniChart = () => {
  const [chartData, setChartData] = useState([40, 45, 38, 50, 48, 60, 55, 68, 63, 75, 72, 85]);

  useEffect(() => {
    const interval = setInterval(() => {
      setChartData(prev => {
        const newData = [...prev.slice(1), Math.floor(Math.random() * 30) + 60];
        return newData;
      });
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  const max = Math.max(...chartData);
  const min = Math.min(...chartData);
  const range = max - min;

  return (
    <div className="mini-chart">
      <svg width="100%" height="100" viewBox="0 0 300 100" preserveAspectRatio="none">
        <defs>
          <linearGradient id="chartAreaGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="rgba(34, 197, 94, 0.3)"/>
            <stop offset="100%" stopColor="rgba(34, 197, 94, 0)"/>
          </linearGradient>
        </defs>

        {/* Area under the curve */}
        <path
          d={`M 0 100 ${chartData.map((value, i) => {
            const x = (i / (chartData.length - 1)) * 300;
            const y = 100 - ((value - min) / range) * 80;
            return `L ${x} ${y}`;
          }).join(' ')} L 300 100 Z`}
          fill="url(#chartAreaGradient)"
        />

        {/* Line */}
        <path
          d={`M ${chartData.map((value, i) => {
            const x = (i / (chartData.length - 1)) * 300;
            const y = 100 - ((value - min) / range) * 80;
            return `${x},${y}`;
          }).join(' L ')}`}
          fill="none"
          stroke="#22c55e"
          strokeWidth="2"
        />

        {/* Points */}
        {chartData.map((value, i) => {
          const x = (i / (chartData.length - 1)) * 300;
          const y = 100 - ((value - min) / range) * 80;
          return (
            <circle
              key={i}
              cx={x}
              cy={y}
              r="3"
              fill="#22c55e"
              opacity={i === chartData.length - 1 ? 1 : 0.5}
            />
          );
        })}
      </svg>
      <div className="chart-info">
        <div className="chart-value">
          <span className="value-label">Current</span>
          <span className="value-number positive">+{chartData[chartData.length - 1]}%</span>
        </div>
      </div>
    </div>
  );
};

const DashboardPreview = () => {
  return (
    <div className="preview-content">
      <div className="preview-metrics">
        <div className="metric-row">
          <div className="metric-item">
            <span className="metric-label">Balance</span>
            <span className="metric-value">$52,430</span>
          </div>
          <div className="metric-item">
            <span className="metric-label">Equity</span>
            <span className="metric-value positive">$53,120</span>
          </div>
        </div>
        <div className="metric-row">
          <div className="metric-item">
            <span className="metric-label">Open Positions</span>
            <span className="metric-value">7</span>
          </div>
          <div className="metric-item">
            <span className="metric-label">Today's P/L</span>
            <span className="metric-value positive">+$1,247</span>
          </div>
        </div>
      </div>

      <div className="preview-trades">
        <div className="trade-item">
          <div className="trade-symbol">EUR/USD</div>
          <div className="trade-status buy">BUY</div>
          <div className="trade-profit positive">+$324</div>
        </div>
        <div className="trade-item">
          <div className="trade-symbol">GBP/JPY</div>
          <div className="trade-status sell">SELL</div>
          <div className="trade-profit positive">+$189</div>
        </div>
        <div className="trade-item">
          <div className="trade-symbol">USD/CAD</div>
          <div className="trade-status buy">BUY</div>
          <div className="trade-profit positive">+$76</div>
        </div>
      </div>

      <div className="preview-indicator">
        <div className="indicator-dot"></div>
        <span>Auto-trading active</span>
      </div>
    </div>
  );
};

export default Hero;
