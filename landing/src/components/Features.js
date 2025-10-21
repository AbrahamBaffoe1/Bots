import React, { useEffect } from 'react';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Features = () => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  useEffect(() => {
    const handleScroll = () => {
      const scrolled = window.scrollY;
      const featuresSection = document.querySelector('.features');

      if (featuresSection) {
        const sectionTop = featuresSection.offsetTop;
        const sectionHeight = featuresSection.offsetHeight;
        const scrollPosition = scrolled - sectionTop + window.innerHeight;

        // Only apply parallax when section is in view
        if (scrollPosition > 0 && scrolled < sectionTop + sectionHeight) {
          // Background moves slower (0.3x)
          document.documentElement.style.setProperty('--scroll-y-features', `${(scrolled - sectionTop) * 0.3}px`);
          // Title moves slightly (0.15x)
          document.documentElement.style.setProperty('--scroll-y-title', `${(scrolled - sectionTop) * -0.15}px`);
          // Subtitle moves slightly more (0.2x)
          document.documentElement.style.setProperty('--scroll-y-subtitle', `${(scrolled - sectionTop) * -0.2}px`);
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const features = [
    {
      icon: <ChartIcon />,
      title: 'Multi-Strategy Trading',
      subtitle: 'Advanced algorithmic strategies',
      description: 'Trend following, breakout detection, and pattern recognition with customizable parameters for optimal performance.',
      visual: <TradingVisual />,
      link: 'Learn More'
    },
    {
      icon: <ShieldIcon />,
      title: 'Advanced Risk Management',
      subtitle: 'Protect your capital',
      description: 'Dynamic position sizing, automatic stop-loss, take-profit levels, and drawdown protection built-in.',
      visual: <RiskVisual />,
      link: 'Learn More'
    },
    {
      icon: <AnalyticsIcon />,
      title: 'Real-Time Analytics',
      subtitle: 'Track every metric',
      description: 'Comprehensive dashboard with performance metrics, trade history, and detailed analytics at your fingertips.',
      visual: <AnalyticsVisual />,
      link: 'Learn More'
    },
    {
      icon: <ClockIcon />,
      title: 'Session Management',
      subtitle: 'Trade at optimal hours',
      description: 'Intelligent session detection for London, New York, Tokyo, and Sydney markets. Never miss a profitable window.',
      visual: <SessionVisual />,
      link: 'Learn More'
    },
    {
      icon: <TargetIcon />,
      title: 'Pattern Recognition',
      subtitle: 'AI-powered precision',
      description: 'Automatic detection of chart patterns, support/resistance levels, and market structure for perfect entries.',
      visual: <PatternVisual />,
      link: 'Learn More'
    },
    {
      icon: <LockIcon />,
      title: 'Secure & Encrypted',
      subtitle: 'Bank-grade security',
      description: 'Hardware-locked license keys with 256-bit encryption ensure your investment stays protected.',
      visual: <SecurityVisual />,
      link: 'Learn More'
    },
  ];

  return (
    <section className="features" id="features" ref={ref}>
      <motion.div
        className="features-header"
        initial={{ opacity: 0, y: 50 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6 }}
      >
        <h2 className="section-title">Powerful Features</h2>
        <p className="section-subtitle">Everything you need for professional algorithmic trading</p>
      </motion.div>

      <div className="features-container">
        {features.map((feature, index) => (
          <motion.div
            key={index}
            className={`tesla-feature-card ${index % 2 === 0 ? 'layout-left' : 'layout-right'}`}
            initial={{ opacity: 0, y: 80 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: index * 0.15 }}
          >
            <div className="tesla-feature-visual">
              <motion.div
                className="visual-container"
                whileHover={{ scale: 1.02 }}
                transition={{ duration: 0.4 }}
              >
                {feature.visual}
              </motion.div>
            </div>

            <div className="tesla-feature-content">
              <div className="feature-icon-small">
                {feature.icon}
              </div>
              <h3 className="tesla-feature-title">{feature.title}</h3>
              <p className="tesla-feature-subtitle">{feature.subtitle}</p>
              <p className="tesla-feature-description">{feature.description}</p>
              <a href="#" className="tesla-feature-link">
                {feature.link}
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path d="M6 12L10 8L6 4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </a>
            </div>
          </motion.div>
        ))}
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

// Tesla-style Visual Components
const TradingVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      <defs>
        <linearGradient id="tradingGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="rgba(34, 197, 94, 0.4)"/>
          <stop offset="100%" stopColor="rgba(34, 197, 94, 0)"/>
        </linearGradient>
      </defs>
      {/* Grid */}
      <line x1="0" y1="60" x2="600" y2="60" stroke="rgba(255,255,255,0.05)" strokeWidth="1"/>
      <line x1="0" y1="120" x2="600" y2="120" stroke="rgba(255,255,255,0.05)" strokeWidth="1"/>
      <line x1="0" y1="180" x2="600" y2="180" stroke="rgba(255,255,255,0.05)" strokeWidth="1"/>
      <line x1="0" y1="240" x2="600" y2="240" stroke="rgba(255,255,255,0.05)" strokeWidth="1"/>

      {/* Trading line */}
      <path d="M 0 200 Q 100 180 150 160 T 300 100 T 450 120 T 600 80"
            fill="url(#tradingGradient)" opacity="0.3"/>
      <path d="M 0 200 Q 100 180 150 160 T 300 100 T 450 120 T 600 80"
            stroke="#22c55e" strokeWidth="3" fill="none"/>

      {/* Buy/Sell Markers */}
      <circle cx="150" cy="160" r="6" fill="#22c55e"/>
      <circle cx="300" cy="100" r="6" fill="#22c55e"/>
      <circle cx="450" cy="120" r="6" fill="#ef4444"/>
    </svg>
  </div>
);

const RiskVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      {/* Shield visualization */}
      <path d="M300 40L200 80V160C200 210 250 250 300 270C350 250 400 210 400 160V80L300 40Z"
            fill="rgba(59, 130, 246, 0.1)" stroke="#3b82f6" strokeWidth="3"/>
      <path d="M260 150L285 175L340 120" stroke="#3b82f6" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>

      {/* Risk levels */}
      <rect x="120" y="200" width="100" height="20" rx="10" fill="rgba(34, 197, 94, 0.2)"/>
      <rect x="120" y="200" width="70" height="20" rx="10" fill="#22c55e"/>
      <text x="120" y="250" fill="#a1a1aa" fontSize="14">Low Risk: 2%</text>

      <rect x="380" y="200" width="100" height="20" rx="10" fill="rgba(239, 68, 68, 0.2)"/>
      <rect x="380" y="200" width="30" height="20" rx="10" fill="#ef4444"/>
      <text x="380" y="250" fill="#a1a1aa" fontSize="14">Protected</text>
    </svg>
  </div>
);

const AnalyticsVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      {/* Dashboard cards */}
      <rect x="50" y="40" width="200" height="100" rx="12" fill="rgba(168, 85, 247, 0.1)" stroke="rgba(168, 85, 247, 0.3)" strokeWidth="2"/>
      <text x="70" y="70" fill="#a855f7" fontSize="16" fontWeight="600">Win Rate</text>
      <text x="70" y="110" fill="#a855f7" fontSize="36" fontWeight="700">73.4%</text>

      <rect x="280" y="40" width="200" height="100" rx="12" fill="rgba(34, 197, 94, 0.1)" stroke="rgba(34, 197, 94, 0.3)" strokeWidth="2"/>
      <text x="300" y="70" fill="#22c55e" fontSize="16" fontWeight="600">Profit</text>
      <text x="300" y="110" fill="#22c55e" fontSize="36" fontWeight="700">+$45K</text>

      {/* Mini chart bars */}
      <rect x="80" y="220" width="30" height="60" rx="4" fill="#a855f7" opacity="0.8"/>
      <rect x="130" y="200" width="30" height="80" rx="4" fill="#a855f7" opacity="0.9"/>
      <rect x="180" y="190" width="30" height="90" rx="4" fill="#a855f7"/>
      <rect x="230" y="210" width="30" height="70" rx="4" fill="#a855f7" opacity="0.8"/>
    </svg>
  </div>
);

const SessionVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      {/* World time zones */}
      <circle cx="150" cy="100" r="60" fill="rgba(234, 179, 8, 0.1)" stroke="#eab308" strokeWidth="2"/>
      <text x="130" y="105" fill="#eab308" fontSize="14" fontWeight="600">Tokyo</text>
      <text x="125" y="125" fill="#a1a1aa" fontSize="12">Active</text>

      <circle cx="300" cy="100" r="60" fill="rgba(34, 197, 94, 0.1)" stroke="#22c55e" strokeWidth="2"/>
      <text x="275" y="105" fill="#22c55e" fontSize="14" fontWeight="600">London</text>
      <text x="275" y="125" fill="#a1a1aa" fontSize="12">Active</text>

      <circle cx="450" cy="100" r="60" fill="rgba(161, 161, 170, 0.1)" stroke="#71717a" strokeWidth="2"/>
      <text x="415" y="105" fill="#71717a" fontSize="14" fontWeight="600">New York</text>
      <text x="425" y="125" fill="#71717a" fontSize="12">Closed</text>

      {/* Timeline */}
      <line x1="50" y1="220" x2="550" y2="220" stroke="rgba(255,255,255,0.1)" strokeWidth="2"/>
      <rect x="100" y="210" width="80" height="20" rx="4" fill="#22c55e" opacity="0.6"/>
      <rect x="250" y="210" width="120" height="20" rx="4" fill="#eab308" opacity="0.6"/>
    </svg>
  </div>
);

const PatternVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      {/* Pattern detection */}
      <path d="M 50 250 L 100 200 L 150 220 L 200 150 L 250 170 L 300 80 L 350 100 L 400 120 L 450 60 L 500 90 L 550 50"
            stroke="#ef4444" strokeWidth="3" fill="none"/>

      {/* Pattern highlight boxes */}
      <rect x="180" y="130" width="90" height="90" rx="8" fill="none" stroke="#ef4444" strokeWidth="2" strokeDasharray="5,5"/>
      <text x="190" y="125" fill="#ef4444" fontSize="12" fontWeight="600">Head & Shoulders</text>

      <rect x="420" y="40" width="110" height="90" rx="8" fill="none" stroke="#22c55e" strokeWidth="2" strokeDasharray="5,5"/>
      <text x="430" y="35" fill="#22c55e" fontSize="12" fontWeight="600">Bullish Flag</text>

      {/* Support/Resistance lines */}
      <line x1="50" y1="180" x2="550" y2="180" stroke="#3b82f6" strokeWidth="2" strokeDasharray="10,5" opacity="0.5"/>
      <text x="450" y="175" fill="#3b82f6" fontSize="12">Resistance</text>
    </svg>
  </div>
);

const SecurityVisual = () => (
  <div className="tesla-visual">
    <svg width="100%" height="300" viewBox="0 0 600 300" fill="none">
      {/* Lock visual */}
      <rect x="200" y="120" width="200" height="140" rx="20" fill="rgba(161, 161, 170, 0.1)" stroke="#a1a1aa" strokeWidth="3"/>
      <path d="M240 120V90C240 62 262 40 290 40C318 40 340 62 340 90V120"
            stroke="#a1a1aa" strokeWidth="3" strokeLinecap="round"/>
      <circle cx="290" cy="180" r="20" fill="#a1a1aa"/>
      <rect x="280" y="180" width="20" height="40" rx="4" fill="#a1a1aa"/>

      {/* Encryption indicators */}
      <text x="220" y="280" fill="#a1a1aa" fontSize="16" fontWeight="600">256-bit Encryption</text>

      {/* Key indicators */}
      <circle cx="100" cy="150" r="8" fill="#22c55e"/>
      <line x1="108" y1="150" x2="180" y2="150" stroke="#22c55e" strokeWidth="2"/>

      <circle cx="500" cy="150" r="8" fill="#22c55e"/>
      <line x1="420" y1="150" x2="492" y2="150" stroke="#22c55e" strokeWidth="2"/>
    </svg>
  </div>
);

export default Features;
