import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import './Dashboard.css';
import AddBotModal from '../components/AddBotModal';

const Dashboard = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [bots, setBots] = useState([]);
  const [trades, setTrades] = useState([]);
  const [stats, setStats] = useState(null);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview'); // overview, bots, trades, logs
  const [addBotModalOpen, setAddBotModalOpen] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userData = localStorage.getItem('user');

    if (!token || !userData || userData === 'undefined') {
      navigate('/');
      return;
    }

    try {
      setUser(JSON.parse(userData));
      fetchDashboardData(token);
    } catch (error) {
      console.error('Error parsing user data:', error);
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      navigate('/');
    }
  }, [navigate]);

  const fetchDashboardData = async (token) => {
    try {
      const config = {
        headers: { Authorization: `Bearer ${token}` }
      };

      const [botsRes, tradesRes] = await Promise.all([
        axios.get('http://localhost:5000/api/bots', config),
        axios.get('http://localhost:5000/api/trades', config)
      ]);

      // Backend returns { success: true, data: [...] } where data is the array directly
      const botsData = Array.isArray(botsRes.data.data) ? botsRes.data.data : (botsRes.data.data?.bots || botsRes.data.bots || []);
      const tradesData = Array.isArray(tradesRes.data.data) ? tradesRes.data.data : (tradesRes.data.data?.trades || tradesRes.data.trades || []);

      setBots(botsData);
      setTrades(tradesData);

      // Calculate stats from trades
      if (tradesData && tradesData.length > 0) {
        const closedTrades = tradesData.filter(t => t.status === 'closed');
        const totalProfit = closedTrades.reduce((sum, t) => sum + parseFloat(t.profit || 0), 0);
        const winningTrades = closedTrades.filter(t => parseFloat(t.profit) > 0);
        const winRate = closedTrades.length > 0 ? (winningTrades.length / closedTrades.length * 100).toFixed(1) : 0;

        setStats({
          totalTrades: tradesData.length,
          closedTrades: closedTrades.length,
          openTrades: tradesData.filter(t => t.status === 'open').length,
          totalProfit: totalProfit.toFixed(2),
          winRate: winRate,
          activeBots: botsData.filter(b => b.status === 'running').length
        });
      } else {
        setStats({
          totalTrades: 0,
          closedTrades: 0,
          openTrades: 0,
          totalProfit: '0.00',
          winRate: '0.0',
          activeBots: 0
        });
      }

      setLoading(false);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      if (error.response?.status === 401) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/');
      }
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/');
  };

  const handleStartBot = async (botId) => {
    try {
      const token = localStorage.getItem('token');
      await axios.post(
        `http://localhost:5000/api/bots/${botId}/start`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      fetchDashboardData(token);
    } catch (error) {
      console.error('Error starting bot:', error);
      alert(error.response?.data?.error || 'Failed to start bot');
    }
  };

  const handleStopBot = async (botId) => {
    try {
      const token = localStorage.getItem('token');
      await axios.post(
        `http://localhost:5000/api/bots/${botId}/stop`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      fetchDashboardData(token);
    } catch (error) {
      console.error('Error stopping bot:', error);
      alert(error.response?.data?.error || 'Failed to stop bot');
    }
  };

  if (loading) {
    return (
      <div className="dashboard-loading">
        <div className="loading-spinner-large"></div>
        <p>Loading dashboard...</p>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <nav className="dashboard-nav">
        <div className="dashboard-nav-left">
          <div className="dashboard-logo">
            <svg width="32" height="32" viewBox="0 0 40 40" fill="none">
              <rect width="40" height="40" rx="8" fill="url(#dashGradient)" />
              <path d="M12 28L18 18L24 22L28 12" stroke="white" strokeWidth="2.5" strokeLinecap="round"/>
              <defs>
                <linearGradient id="dashGradient" x1="0" y1="0" x2="40" y2="40">
                  <stop stopColor="#ff7f00"/>
                  <stop offset="1" stopColor="#ff5722"/>
                </linearGradient>
              </defs>
            </svg>
            <span>Smart Stock Trader</span>
          </div>
        </div>
        <div className="dashboard-nav-right">
          <div className="dashboard-user">
            <div className="user-avatar">
              {user?.first_name?.charAt(0).toUpperCase() || user?.email?.charAt(0).toUpperCase() || 'U'}
            </div>
            <span>{user?.first_name && user?.last_name ? `${user.first_name} ${user.last_name}` : user?.email}</span>
          </div>
          <button className="logout-btn" onClick={handleLogout}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
            </svg>
            Logout
          </button>
        </div>
      </nav>

      <div className="dashboard-container">
        <div className="dashboard-sidebar">
          <button
            className={`sidebar-item ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            Overview
          </button>
          <button
            className={`sidebar-item ${activeTab === 'bots' ? 'active' : ''}`}
            onClick={() => setActiveTab('bots')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"/>
            </svg>
            Bots
          </button>
          <button
            className={`sidebar-item ${activeTab === 'trades' ? 'active' : ''}`}
            onClick={() => setActiveTab('trades')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
            </svg>
            Trades
          </button>
          <button
            className={`sidebar-item ${activeTab === 'logs' ? 'active' : ''}`}
            onClick={() => setActiveTab('logs')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Logs
          </button>
        </div>

        <div className="dashboard-content">
          {activeTab === 'overview' && stats && (
            <div className="overview-section">
              <h1>Dashboard Overview</h1>
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-icon profit">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <div className="stat-label">Total Profit</div>
                    <div className={`stat-value ${parseFloat(stats.totalProfit) >= 0 ? 'positive' : 'negative'}`}>
                      ${stats.totalProfit}
                    </div>
                  </div>
                </div>

                <div className="stat-card">
                  <div className="stat-icon success">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <div className="stat-label">Win Rate</div>
                    <div className="stat-value">{stats.winRate}%</div>
                  </div>
                </div>

                <div className="stat-card">
                  <div className="stat-icon trades">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <div className="stat-label">Total Trades</div>
                    <div className="stat-value">{stats.totalTrades}</div>
                    <div className="stat-sublabel">{stats.openTrades} open</div>
                  </div>
                </div>

                <div className="stat-card">
                  <div className="stat-icon bots">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"/>
                    </svg>
                  </div>
                  <div className="stat-info">
                    <div className="stat-label">Active Bots</div>
                    <div className="stat-value">{stats.activeBots}</div>
                    <div className="stat-sublabel">of {bots.length} total</div>
                  </div>
                </div>
              </div>

              <div className="recent-activity">
                <h2>Recent Trades</h2>
                {trades.length > 0 ? (
                  <div className="trades-table-wrapper">
                    <table className="trades-table">
                      <thead>
                        <tr>
                          <th>Symbol</th>
                          <th>Type</th>
                          <th>Volume</th>
                          <th>Open Price</th>
                          <th>Close Price</th>
                          <th>Profit</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {trades.slice(0, 5).map((trade) => (
                          <tr key={trade.id}>
                            <td className="trade-symbol">{trade.symbol}</td>
                            <td>
                              <span className={`trade-type ${trade.trade_type.toLowerCase()}`}>
                                {trade.trade_type}
                              </span>
                            </td>
                            <td>{trade.lot_size || trade.volume}</td>
                            <td>${parseFloat(trade.open_price).toFixed(2)}</td>
                            <td>{trade.close_price ? `$${parseFloat(trade.close_price).toFixed(2)}` : '-'}</td>
                            <td className={parseFloat(trade.profit) >= 0 ? 'profit-positive' : 'profit-negative'}>
                              ${parseFloat(trade.profit || 0).toFixed(2)}
                            </td>
                            <td>
                              <span className={`status-badge ${trade.status}`}>
                                {trade.status}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <div className="empty-state">
                    <p>No trades yet. Start a bot to begin trading!</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'bots' && (
            <div className="bots-section">
              <div className="section-header">
                <h1>Bot Management</h1>
                <button className="add-bot-btn" onClick={() => setAddBotModalOpen(true)}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4"/>
                  </svg>
                  Add New Bot
                </button>
              </div>

              {bots.length > 0 ? (
                <div className="bots-grid">
                  {bots.map((bot) => (
                    <div key={bot.id} className="bot-card">
                      <div className="bot-card-header">
                        <h3>{bot.instance_name}</h3>
                        <span className={`bot-status ${bot.status}`}>
                          <span className="status-dot"></span>
                          {bot.status}
                        </span>
                      </div>
                      <div className="bot-card-body">
                        <div className="bot-info-row">
                          <span className="label">MT4 Account:</span>
                          <span className="value">{bot.mt4_account}</span>
                        </div>
                        <div className="bot-info-row">
                          <span className="label">Broker:</span>
                          <span className="value">{bot.broker_name}</span>
                        </div>
                        <div className="bot-info-row">
                          <span className="label">Server:</span>
                          <span className="value">{bot.broker_server || 'N/A'}</span>
                        </div>
                      </div>
                      <div className="bot-card-actions">
                        {bot.status === 'running' ? (
                          <button
                            className="bot-action-btn stop"
                            onClick={() => handleStopBot(bot.id)}
                          >
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <rect x="6" y="6" width="12" height="12" rx="2"/>
                            </svg>
                            Stop
                          </button>
                        ) : (
                          <button
                            className="bot-action-btn start"
                            onClick={() => handleStartBot(bot.id)}
                          >
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M8 5v14l11-7z"/>
                            </svg>
                            Start
                          </button>
                        )}
                        <button className="bot-action-btn settings">
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                          </svg>
                          Settings
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="empty-state-large">
                  <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" opacity="0.3">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"/>
                  </svg>
                  <h3>No Bots Created Yet</h3>
                  <p>Create your first bot to start automated trading</p>
                  <button className="add-bot-btn-large" onClick={() => setAddBotModalOpen(true)}>
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4"/>
                    </svg>
                    Activate Bot with License Key
                  </button>
                </div>
              )}
            </div>
          )}

          {activeTab === 'trades' && (
            <div className="trades-section">
              <h1>Trade History</h1>
              {trades.length > 0 ? (
                <div className="trades-table-wrapper">
                  <table className="trades-table trades-table-full">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Symbol</th>
                        <th>Type</th>
                        <th>Volume</th>
                        <th>Open Price</th>
                        <th>Close Price</th>
                        <th>Profit</th>
                        <th>Opened At</th>
                        <th>Closed At</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {trades.map((trade) => (
                        <tr key={trade.id}>
                          <td>#{trade.ticket_number}</td>
                          <td className="trade-symbol">{trade.symbol}</td>
                          <td>
                            <span className={`trade-type ${trade.trade_type.toLowerCase()}`}>
                              {trade.trade_type}
                            </span>
                          </td>
                          <td>{trade.volume}</td>
                          <td>${parseFloat(trade.open_price).toFixed(2)}</td>
                          <td>{trade.close_price ? `$${parseFloat(trade.close_price).toFixed(2)}` : '-'}</td>
                          <td className={parseFloat(trade.profit) >= 0 ? 'profit-positive' : 'profit-negative'}>
                            ${parseFloat(trade.profit || 0).toFixed(2)}
                          </td>
                          <td>{new Date(trade.opened_at).toLocaleString()}</td>
                          <td>{trade.closed_at ? new Date(trade.closed_at).toLocaleString() : '-'}</td>
                          <td>
                            <span className={`status-badge ${trade.status}`}>
                              {trade.status}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="empty-state-large">
                  <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" opacity="0.3">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
                  </svg>
                  <h3>No Trades Yet</h3>
                  <p>Your trade history will appear here once your bots start trading</p>
                </div>
              )}
            </div>
          )}

          {activeTab === 'logs' && (
            <div className="logs-section">
              <h1>Bot Logs</h1>
              <div className="logs-container">
                <div className="empty-state-large">
                  <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" opacity="0.3">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                  </svg>
                  <h3>No Logs Available</h3>
                  <p>Bot logs will appear here in real-time</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <AddBotModal
        isOpen={addBotModalOpen}
        onClose={() => setAddBotModalOpen(false)}
        onBotAdded={(newBot) => {
          setBots([...bots, newBot]);
          setAddBotModalOpen(false);
          const token = localStorage.getItem('token');
          fetchDashboardData(token);
        }}
      />
    </div>
  );
};

export default Dashboard;
