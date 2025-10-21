const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const BotInstance = sequelize.define('BotInstance', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  license_id: {
    type: DataTypes.UUID,
    allowNull: true, // Allow null for MT4 EA registrations without dashboard
    references: {
      model: 'licenses',
      key: 'id'
    }
  },
  instance_name: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  mt4_account: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  broker_name: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  broker_server: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('running', 'stopped', 'paused', 'error'),
    defaultValue: 'stopped'
  },
  is_live: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  last_heartbeat: {
    type: DataTypes.DATE,
    allowNull: true
  },
  started_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  stopped_at: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'bot_instances',
  indexes: [
    { fields: ['user_id'] },
    { fields: ['license_id'] },
    { fields: ['status'] },
    { fields: ['last_heartbeat'] }
  ]
});

// Instance methods
BotInstance.prototype.isOnline = function() {
  if (!this.last_heartbeat) return false;
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  return this.last_heartbeat > fiveMinutesAgo;
};

BotInstance.prototype.getUptime = function() {
  if (this.status !== 'running' || !this.started_at) return 0;
  return Math.floor((Date.now() - this.started_at.getTime()) / 1000);
};

module.exports = BotInstance;
