import React from 'react';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const Pricing = ({ onPurchase }) => {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const plans = [
    {
      name: 'Trial',
      price: 29,
      duration: '30 Days Access',
      features: [
        '1 MT4 Account',
        'All Trading Strategies',
        'Risk Management Tools',
        'Email Support',
        '30-Day Access',
      ],
      type: 'TRIAL',
      featured: false,
    },
    {
      name: 'Basic',
      price: 149,
      duration: '1 Year License',
      features: [
        '1 MT4 Account',
        'All Trading Strategies',
        'Advanced Risk Management',
        'Real-Time Dashboard',
        'Priority Email Support',
        'Free Updates for 1 Year',
      ],
      type: 'BASIC',
      featured: false,
    },
    {
      name: 'Professional',
      price: 399,
      duration: 'Lifetime License',
      features: [
        '3 MT4 Accounts',
        'All Trading Strategies',
        'Advanced Risk Management',
        'Real-Time Dashboard',
        'Priority Support',
        'Lifetime Free Updates',
        'Custom Strategy Support',
      ],
      type: 'PRO',
      featured: true,
    },
    {
      name: 'Enterprise',
      price: 999,
      duration: 'Lifetime Unlimited',
      features: [
        'Unlimited MT4 Accounts',
        'All Trading Strategies',
        'Advanced Risk Management',
        'Real-Time Dashboard',
        '24/7 Priority Support',
        'Lifetime Free Updates',
        'Custom Strategy Development',
        'White-Label Options',
      ],
      type: 'ENTERPRISE',
      featured: false,
    },
  ];

  return (
    <section className="pricing" id="pricing" ref={ref}>
      <div className="container">
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          <h2 className="section-title gradient-text">Choose Your Plan</h2>
          <p className="section-subtitle">Select the perfect plan for your trading needs</p>
        </motion.div>

        <div className="pricing-grid">
          {plans.map((plan, index) => (
            <motion.div
              key={index}
              className={`pricing-card ${plan.featured ? 'featured' : ''}`}
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              whileHover={{
                y: -15,
                scale: plan.featured ? 1.02 : 1,
                transition: { duration: 0.3 },
              }}
            >
              {plan.featured && (
                <motion.div
                  className="popular-badge"
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.8, type: 'spring' }}
                >
                  Most Popular
                </motion.div>
              )}

              <div className="plan-header">
                <h3>{plan.name}</h3>
                <div className="price-wrapper">
                  <span className="currency">$</span>
                  <span className="price">{plan.price}</span>
                </div>
                <p className="duration">{plan.duration}</p>
              </div>

              <ul className="plan-features">
                {plan.features.map((feature, i) => (
                  <motion.li
                    key={i}
                    initial={{ opacity: 0, x: -20 }}
                    animate={inView ? { opacity: 1, x: 0 } : {}}
                    transition={{ delay: 0.8 + i * 0.05 }}
                  >
                    <CheckIcon />
                    <span>{feature}</span>
                  </motion.li>
                ))}
              </ul>

              <motion.button
                className="buy-button"
                onClick={() => onPurchase(plan)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                {plan.name === 'Trial' ? 'Start Trial' : `Purchase ${plan.name}`}
              </motion.button>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

const CheckIcon = () => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="10" cy="10" r="9" stroke="#22c55e" strokeWidth="2"/>
    <path d="M6 10L9 13L14 7" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

export default Pricing;
