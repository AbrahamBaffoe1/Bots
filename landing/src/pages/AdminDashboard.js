import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import './AdminDashboard.css';

const AdminDashboard = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [stats, setStats] = useState(null);
  const [users, setUsers] = useState([]);
  const [bots, setBots] = useState([]);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview'); // overview, users, bots, logs

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userData = localStorage.getItem('user');

    if (!token || !userData) {
      navigate('/');
      return;
    }

    try {
      const parsedUser = JSON.parse(userData);

      // Check if user is admin
      if (parsedUser.role !== 'admin') {
        alert('Access denied. Admin privileges required.');
        navigate('/dashboard');
        return;
      }

      setUser(parsedUser);
      fetchAdminData(token);
    } catch (error) {
      console.error('Error parsing user data:', error);
      navigate('/');
    }
  }, [navigate]);

  const fetchAdminData = async (token) => {
    try {
      const config = {
        headers: { Authorization: `Bearer ${token}` }
      };

      const [statsRes, usersRes, botsRes, logsRes] = await Promise.all([
        axios.get('http://localhost:5000/api/admin/stats', config),
        axios.get('http://localhost:5000/api/admin/users?limit=20', config),
        axios.get('http://localhost:5000/api/admin/bots?limit=20', config),
        axios.get('http://localhost:5000/api/admin/logs?limit=50', config)
      ]);

      setStats(statsRes.data.data);
      setUsers(usersRes.data.data.users);
      setBots(botsRes.data.data.bots);
      setLogs(logsRes.data.data.logs);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching admin data:', error);
      if (error.response?.status === 403) {
        alert('Access denied. Admin privileges required.');
        navigate('/dashboard');
      }
      setLoading(false);
    }
  };

  const handleUserAction = async (userId, action) => {
    try {
      const token = localStorage.getItem('token');
      const config = {
        headers: { Authorization: `Bearer ${token}` }
      };

      if (action === 'delete') {
        if (!window.confirm('Are you sure you want to delete this user?')) return;
        await axios.delete(`http://localhost:5000/api/admin/users/${userId}`, config);
      } else if (action === 'activate' || action === 'deactivate') {
        await axios.put(`http://localhost:5000/api/admin/users/${userId}`, {
          is_active: action === 'activate'
        }, config);
      }

      // Refresh data
      fetchAdminData(token);
    } catch (error) {
      console.error('User action error:', error);
      alert('Failed to perform action');
    }
  };

  const handleBotAction = async (botId, action) => {
    try {
      const token = localStorage.getItem('token');
      const config = {
        headers: { Authorization: `Bearer ${token}` }
      };

      if (action === 'delete') {
        if (!window.confirm('Are you sure you want to delete this bot?')) return;
        await axios.delete(`http://localhost:5000/api/admin/bots/${botId}`, config);
      } else {
        await axios.post(`http://localhost:5000/api/admin/bots/${botId}/control`, { action }, config);
      }

      // Refresh data
      fetchAdminData(token);
    } catch (error) {
      console.error('Bot action error:', error);
      alert('Failed to perform action');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/');
  };

  if (loading) {
    return (
      <div className="admin-dashboard loading">
        <div className="loading-spinner"></div>
        <p>Loading admin dashboard...</p>
      </div>
    );
  }

  return (
    <div className="admin-dashboard">
      {/* Header */}
      <header className="admin-header">
        <div className="admin-logo">
          <h1>🛡️ Admin Dashboard</h1>
        </div>
        <div className="admin-user-info">
          <span>{user?.first_name} {user?.last_name}</span>
          <span className="admin-badge">ADMIN</span>
          <button onClick={handleLogout} className="btn-logout">Logout</button>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav className="admin-tabs">
        <button
          className={activeTab === 'overview' ? 'active' : ''}
          onClick={() => setActiveTab('overview')}
        >
          📊 Overview
        </button>
        <button
          className={activeTab === 'users' ? 'active' : ''}
          onClick={() => setActiveTab('users')}
        >
          👥 Users ({users.length})
        </button>
        <button
          className={activeTab === 'bots' ? 'active' : ''}
          onClick={() => setActiveTab('bots')}
        >
          🤖 Bots ({bots.length})
        </button>
        <button
          className={activeTab === 'logs' ? 'active' : ''}
          onClick={() => setActiveTab('logs')}
        >
          📋 Logs
        </button>
      </nav>

      {/* Content */}
      <div className="admin-content">
        {/* Overview Tab */}
        {activeTab === 'overview' && stats && (
          <div className="overview-section">
            <h2>Platform Statistics</h2>

            <div className="stats-grid">
              <div className="stat-card">
                <h3>Users</h3>
                <div className="stat-number">{stats.users.total}</div>
                <div className="stat-details">
                  <span>✅ Active: {stats.users.active}</span>
                  <span>❌ Inactive: {stats.users.inactive}</span>
                </div>
              </div>

              <div className="stat-card">
                <h3>Bots</h3>
                <div className="stat-number">{stats.bots.total}</div>
                <div className="stat-details">
                  <span>🟢 Running: {stats.bots.running}</span>
                  <span>🔴 Stopped: {stats.bots.stopped}</span>
                </div>
              </div>

              <div className="stat-card">
                <h3>Trades</h3>
                <div className="stat-number">{stats.trades.total}</div>
                <div className="stat-details">
                  <span>📈 Open: {stats.trades.open}</span>
                  <span>📉 Closed: {stats.trades.closed}</span>
                  <span>🕐 Last 24h: {stats.trades.last24h}</span>
                </div>
              </div>

              <div className="stat-card">
                <h3>Performance</h3>
                <div className={`stat-number ${parseFloat(stats.performance.totalProfit) >= 0 ? 'profit' : 'loss'}`}>
                  ${stats.performance.totalProfit}
                </div>
                <div className="stat-details">
                  <span>Win Rate: {stats.performance.winRate}%</span>
                  <span>✅ Wins: {stats.performance.winningTrades}</span>
                  <span>❌ Losses: {stats.performance.losingTrades}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Users Tab */}
        {activeTab === 'users' && (
          <div className="users-section">
            <h2>User Management</h2>
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Email</th>
                  <th>Name</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Registered</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr key={u.id}>
                    <td>{u.email}</td>
                    <td>{u.first_name} {u.last_name}</td>
                    <td><span className={`role-badge ${u.role}`}>{u.role}</span></td>
                    <td>
                      <span className={`status-badge ${u.is_active ? 'active' : 'inactive'}`}>
                        {u.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>{new Date(u.created_at).toLocaleDateString()}</td>
                    <td className="actions">
                      {u.is_active ? (
                        <button onClick={() => handleUserAction(u.id, 'deactivate')} className="btn-warning">
                          Deactivate
                        </button>
                      ) : (
                        <button onClick={() => handleUserAction(u.id, 'activate')} className="btn-success">
                          Activate
                        </button>
                      )}
                      <button onClick={() => handleUserAction(u.id, 'delete')} className="btn-danger">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Bots Tab */}
        {activeTab === 'bots' && (
          <div className="bots-section">
            <h2>Bot Management</h2>
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Bot Name</th>
                  <th>Owner</th>
                  <th>MT4 Account</th>
                  <th>Broker</th>
                  <th>Status</th>
                  <th>Type</th>
                  <th>Last Heartbeat</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {bots.map(bot => (
                  <tr key={bot.id}>
                    <td>{bot.instance_name}</td>
                    <td>{bot.user?.email || 'N/A'}</td>
                    <td>{bot.mt4_account}</td>
                    <td>{bot.broker_name}</td>
                    <td>
                      <span className={`status-badge ${bot.status}`}>
                        {bot.status}
                      </span>
                    </td>
                    <td>
                      <span className={bot.is_live ? 'badge-live' : 'badge-demo'}>
                        {bot.is_live ? 'LIVE' : 'DEMO'}
                      </span>
                    </td>
                    <td>
                      {bot.last_heartbeat
                        ? new Date(bot.last_heartbeat).toLocaleString()
                        : 'Never'}
                    </td>
                    <td className="actions">
                      {bot.status === 'running' ? (
                        <button onClick={() => handleBotAction(bot.id, 'stop')} className="btn-warning">
                          Stop
                        </button>
                      ) : (
                        <button onClick={() => handleBotAction(bot.id, 'start')} className="btn-success">
                          Start
                        </button>
                      )}
                      <button onClick={() => handleBotAction(bot.id, 'delete')} className="btn-danger">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Logs Tab */}
        {activeTab === 'logs' && (
          <div className="logs-section">
            <h2>System Logs</h2>
            <div className="logs-container">
              {logs.map((log, index) => (
                <div key={index} className={`log-entry log-${log.log_level.toLowerCase()}`}>
                  <div className="log-header">
                    <span className={`log-level ${log.log_level.toLowerCase()}`}>
                      {log.log_level}
                    </span>
                    <span className="log-category">{log.category}</span>
                    <span className="log-time">
                      {new Date(log.created_at).toLocaleString()}
                    </span>
                  </div>
                  <div className="log-message">{log.message}</div>
                  {log.bot && (
                    <div className="log-bot-info">
                      Bot: {log.bot.instance_name} ({log.bot.mt4_account}) - User: {log.bot.user?.email}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminDashboard;
