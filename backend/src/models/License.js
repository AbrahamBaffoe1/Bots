const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const License = sequelize.define('License', {
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
  license_key: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  license_type: {
    type: DataTypes.ENUM('TRIAL', 'BASIC', 'PRO', 'ENTERPRISE'),
    allowNull: false
  },
  max_accounts: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  status: {
    type: DataTypes.ENUM('active', 'suspended', 'expired', 'revoked'),
    defaultValue: 'active'
  },
  issued_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  hardware_id: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  last_validated: {
    type: DataTypes.DATE,
    allowNull: true
  },
  activation_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
}, {
  tableName: 'licenses',
  indexes: [
    { fields: ['license_key'], unique: true },
    { fields: ['user_id'] },
    { fields: ['status'] },
    { fields: ['expires_at'] }
  ]
});

// Instance methods
License.prototype.isExpired = function() {
  if (!this.expires_at) return false;
  return new Date() > this.expires_at;
};

License.prototype.isActive = function() {
  return this.status === 'active' && !this.isExpired();
};

module.exports = License;
