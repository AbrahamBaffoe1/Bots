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
      badge: 'Advanced',
      description: 'Advanced strategies including trend following, breakout detection, and pattern recognition with customizable parameters.',
      stats: [
        { value: '15+', label: 'Strategies' },
        { value: '92%', label: 'Accuracy' }
      ]
    },
    {
      icon: <ShieldIcon />,
      title: 'Advanced Risk Management',
      badge: 'Protected',
      description: 'Dynamic position sizing, automatic stop-loss, take-profit levels, and drawdown protection to safeguard your capital.',
      stats: [
        { value: '1:3', label: 'Risk/Reward' },
        { value: '2%', label: 'Max Risk' }
      ]
    },
    {
      icon: <AnalyticsIcon />,
      title: 'Real-Time Analytics',
      badge: 'Live',
      description: 'Comprehensive dashboard with performance metrics, trade history, and detailed analytics to track your success.',
      stats: [
        { value: '24/7', label: 'Monitoring' },
        { value: '50+', label: 'Metrics' }
      ]
    },
    {
      icon: <ClockIcon />,
      title: 'Session Management',
      badge: 'Smart',
      description: 'Trade during optimal market hours with intelligent session detection for London, New York, Tokyo, and Sydney markets.',
      stats: [
        { value: '4', label: 'Sessions' },
        { value: '98%', label: 'Uptime' }
      ]
    },
    {
      icon: <TargetIcon />,
      title: 'Pattern Recognition',
      badge: 'AI-Powered',
      description: 'Automatic detection of chart patterns, support/resistance levels, and market structure for precise entry points.',
      stats: [
        { value: '20+', label: 'Patterns' },
        { value: '85%', label: 'Success' }
      ]
    },
    {
      icon: <LockIcon />,
      title: 'Secure Licensing',
      badge: 'Encrypted',
      description: 'Hardware-locked license keys ensure your investment is protected with optional account binding.',
      stats: [
        { value: '256-bit', label: 'Encryption' },
        { value: '100%', label: 'Secure' }
      ]
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
          <h2 className="section-title">Powerful Features</h2>
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
            >
              <div className="feature-card-header">
                <motion.div
                  className="feature-icon"
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  transition={{ duration: 0.3 }}
                >
                  {feature.icon}
                </motion.div>
                <h3>
                  {feature.title}
                  <span className="feature-badge">{feature.badge}</span>
                </h3>
              </div>

              <div className="feature-card-body">
                <p>{feature.description}</p>

                <div className="feature-chart-line">
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                  <div className="chart-bar"></div>
                </div>

                <div className="feature-stats">
                  {feature.stats.map((stat, i) => (
                    <div key={i} className="feature-stat">
                      <div className="feature-stat-value">{stat.value}</div>
                      <div className="feature-stat-label">{stat.label}</div>
                    </div>
                  ))}
                </div>
              </div>
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
