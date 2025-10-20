import React, { useState } from 'react';
import { useScroll } from 'framer-motion';
import './App.css';
import Hero from './components/Hero';
import Features from './components/Features';
import Pricing from './components/Pricing';
import Installation from './components/Installation';
import PurchaseModal from './components/PurchaseModal';
import ParticleBackground from './components/ParticleBackground';

function App() {
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const { scrollYProgress } = useScroll();

  const openPurchaseModal = (plan) => {
    setSelectedPlan(plan);
    setModalOpen(true);
  };

  const closePurchaseModal = () => {
    setModalOpen(false);
    setSelectedPlan(null);
  };

  return (
    <div className="App">
      <ParticleBackground />

      <Hero scrollYProgress={scrollYProgress} />
      <Features />
      <Pricing onPurchase={openPurchaseModal} />
      <Installation />

      <PurchaseModal
        isOpen={modalOpen}
        onClose={closePurchaseModal}
        plan={selectedPlan}
      />

      <footer className="footer">
        <div className="footer-content">
          <p>&copy; 2025 Smart Stock Trader. All rights reserved.</p>
          <p className="disclaimer">Professional trading involves risk. Past performance does not guarantee future results.</p>
        </div>
      </footer>
    </div>
  );
}

export default App;
