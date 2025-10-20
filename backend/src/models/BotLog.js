const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const BotLog = sequelize.define('BotLog', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  bot_instance_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'bot_instances',
      key: 'id'
    }
  },
  log_level: {
    type: DataTypes.ENUM('INFO', 'WARNING', 'ERROR', 'DEBUG'),
    allowNull: false
  },
  category: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  metadata: {
    type: DataTypes.JSONB,
    allowNull: true
  }
}, {
  tableName: 'bot_logs',
  updatedAt: false,
  indexes: [
    { fields: ['bot_instance_id'] },
    { fields: ['log_level'] },
    { fields: ['category'] },
    { fields: ['created_at'] }
  ]
});

module.exports = BotLog;
