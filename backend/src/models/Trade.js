const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Trade = sequelize.define('Trade', {
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
  ticket_number: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  symbol: {
    type: DataTypes.STRING(20),
    allowNull: false
  },
  trade_type: {
    type: DataTypes.ENUM('BUY', 'SELL'),
    allowNull: false
  },
  lot_size: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0.01
    }
  },
  open_price: {
    type: DataTypes.DECIMAL(15, 5),
    allowNull: false
  },
  close_price: {
    type: DataTypes.DECIMAL(15, 5),
    allowNull: true
  },
  stop_loss: {
    type: DataTypes.DECIMAL(15, 5),
    allowNull: true
  },
  take_profit: {
    type: DataTypes.DECIMAL(15, 5),
    allowNull: true
  },
  commission: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0
  },
  swap: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0
  },
  profit: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true
  },
  profit_percentage: {
    type: DataTypes.DECIMAL(10, 4),
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('open', 'closed', 'cancelled'),
    defaultValue: 'open'
  },
  strategy_used: {
    type: DataTypes.STRING(50),
    allowNull: true
  },
  opened_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  closed_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  duration_seconds: {
    type: DataTypes.INTEGER,
    allowNull: true
  }
}, {
  tableName: 'trades',
  indexes: [
    { fields: ['bot_instance_id'] },
    { fields: ['status'] },
    { fields: ['opened_at'] },
    { fields: ['closed_at'] },
    { fields: ['symbol'] }
  ],
  hooks: {
    beforeUpdate: (trade) => {
      if (trade.changed('closed_at') && trade.opened_at && trade.closed_at) {
        trade.duration_seconds = Math.floor(
          (trade.closed_at - trade.opened_at) / 1000
        );
      }
    }
  }
});

// Instance methods
Trade.prototype.calculateProfit = function() {
  if (!this.close_price) return null;

  const priceDiff = this.trade_type === 'BUY'
    ? this.close_price - this.open_price
    : this.open_price - this.close_price;

  const pipValue = 10; // Standard for most pairs
  const profit = (priceDiff * parseFloat(this.lot_size) * pipValue)
    - parseFloat(this.commission)
    - parseFloat(this.swap);

  return profit;
};

Trade.prototype.isWinning = function() {
  return this.profit && parseFloat(this.profit) > 0;
};

module.exports = Trade;
