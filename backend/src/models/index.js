const { sequelize } = require('../config/database');
const User = require('./User');
const License = require('./License');
const BotInstance = require('./BotInstance');
const Trade = require('./Trade');
const BotLog = require('./BotLog');

// Define associations

// User has many Licenses
User.hasMany(License, {
  foreignKey: 'user_id',
  as: 'licenses',
  onDelete: 'CASCADE'
});
License.belongsTo(User, {
  foreignKey: 'user_id',
  as: 'user'
});

// User has many BotInstances
User.hasMany(BotInstance, {
  foreignKey: 'user_id',
  as: 'botInstances',
  onDelete: 'CASCADE'
});
BotInstance.belongsTo(User, {
  foreignKey: 'user_id',
  as: 'user'
});

// License has many BotInstances
License.hasMany(BotInstance, {
  foreignKey: 'license_id',
  as: 'botInstances',
  onDelete: 'RESTRICT'
});
BotInstance.belongsTo(License, {
  foreignKey: 'license_id',
  as: 'license'
});

// BotInstance has many Trades
BotInstance.hasMany(Trade, {
  foreignKey: 'bot_instance_id',
  as: 'trades',
  onDelete: 'CASCADE'
});
Trade.belongsTo(BotInstance, {
  foreignKey: 'bot_instance_id',
  as: 'botInstance'
});

// BotInstance has many BotLogs
BotInstance.hasMany(BotLog, {
  foreignKey: 'bot_instance_id',
  as: 'logs',
  onDelete: 'CASCADE'
});
BotLog.belongsTo(BotInstance, {
  foreignKey: 'bot_instance_id',
  as: 'botInstance'
});

// Sync database function
const syncDatabase = async (options = {}) => {
  try {
    await sequelize.sync(options);
    console.log('✓ Database synchronized successfully');
    return true;
  } catch (error) {
    console.error('✗ Database synchronization failed:', error.message);
    return false;
  }
};

module.exports = {
  sequelize,
  User,
  License,
  BotInstance,
  Trade,
  BotLog,
  syncDatabase
};
