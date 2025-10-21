const { User, BotInstance, Trade, BotLog, License } = require('../models');
const { Op } = require('sequelize');
const bcrypt = require('bcryptjs');

/**
 * Admin Controller
 * Handles all admin operations
 */

// ============================================================================
// USER MANAGEMENT
// ============================================================================

// Get all users with pagination and filters
exports.getAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 50,
      role,
      search,
      is_active
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    if (role) where.role = role;
    if (is_active !== undefined) where.is_active = is_active === 'true';
    if (search) {
      where[Op.or] = [
        { email: { [Op.iLike]: `%${search}%` } },
        { first_name: { [Op.iLike]: `%${search}%` } },
        { last_name: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const { count, rows: users } = await User.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset,
      order: [['created_at', 'DESC']],
      attributes: { exclude: ['password_hash'] }
    });

    res.json({
      success: true,
      data: {
        users,
        total: count,
        page: parseInt(page),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
};

// Get user details with all related data
exports.getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId, {
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: BotInstance,
          as: 'bots',
          include: [{
            model: Trade,
            as: 'trades',
            limit: 10,
            order: [['created_at', 'DESC']]
          }]
        },
        {
          model: License,
          as: 'licenses'
        }
      ]
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Get user details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user details',
      error: error.message
    });
  }
};

// Update user (activate/deactivate, change role, etc.)
exports.updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { is_active, role, email_verified } = req.body;

    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update fields
    if (is_active !== undefined) user.is_active = is_active;
    if (role) user.role = role;
    if (email_verified !== undefined) user.email_verified = email_verified;

    await user.save();

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
};

// Delete user (and all related data)
exports.deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent deleting yourself
    if (user.id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    await user.destroy();

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
};

// ============================================================================
// BOT MANAGEMENT
// ============================================================================

// Get all bots across all users
exports.getAllBots = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 50,
      status,
      broker_name,
      is_live
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    if (status) where.status = status;
    if (broker_name) where.broker_name = { [Op.iLike]: `%${broker_name}%` };
    if (is_live !== undefined) where.is_live = is_live === 'true';

    const { count, rows: bots } = await BotInstance.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'first_name', 'last_name']
        },
        {
          model: Trade,
          as: 'trades',
          where: { status: 'open' },
          required: false,
          limit: 5
        }
      ]
    });

    res.json({
      success: true,
      data: {
        bots,
        total: count,
        page: parseInt(page),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Get all bots error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bots',
      error: error.message
    });
  }
};

// Force stop/start bot
exports.controlBot = async (req, res) => {
  try {
    const { botId } = req.params;
    const { action } = req.body; // 'start' or 'stop'

    const bot = await BotInstance.findByPk(botId);

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot not found'
      });
    }

    if (action === 'start') {
      await bot.update({
        status: 'running',
        started_at: new Date()
      });
    } else if (action === 'stop') {
      await bot.update({
        status: 'stopped',
        stopped_at: new Date()
      });
    }

    // Log admin action
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'ADMIN',
      message: `Admin ${req.user.email} ${action}ed bot`,
      metadata: JSON.stringify({ admin_id: req.user.id })
    });

    res.json({
      success: true,
      message: `Bot ${action}ed successfully`,
      data: bot
    });
  } catch (error) {
    console.error('Control bot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to control bot',
      error: error.message
    });
  }
};

// Delete bot
exports.deleteBot = async (req, res) => {
  try {
    const { botId } = req.params;

    const bot = await BotInstance.findByPk(botId);

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot not found'
      });
    }

    await bot.destroy();

    res.json({
      success: true,
      message: 'Bot deleted successfully'
    });
  } catch (error) {
    console.error('Delete bot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete bot',
      error: error.message
    });
  }
};

// ============================================================================
// LOGS & MONITORING
// ============================================================================

// Get all logs across all bots
exports.getAllLogs = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 100,
      log_level,
      category,
      bot_id,
      start_date,
      end_date
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    if (log_level) where.log_level = log_level;
    if (category) where.category = category;
    if (bot_id) where.bot_instance_id = bot_id;

    if (start_date || end_date) {
      where.created_at = {};
      if (start_date) where.created_at[Op.gte] = new Date(start_date);
      if (end_date) where.created_at[Op.lte] = new Date(end_date);
    }

    const { count, rows: logs } = await BotLog.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: BotInstance,
          as: 'botInstance',
          attributes: ['id', 'instance_name', 'mt4_account'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['email']
          }]
        }
      ]
    });

    res.json({
      success: true,
      data: {
        logs,
        total: count,
        page: parseInt(page),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Get all logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch logs',
      error: error.message
    });
  }
};

// ============================================================================
// STATISTICS & ANALYTICS
// ============================================================================

// Get platform-wide statistics
exports.getPlatformStats = async (req, res) => {
  try {
    // Total users
    const totalUsers = await User.count();
    const activeUsers = await User.count({ where: { is_active: true } });

    // Total bots
    const totalBots = await BotInstance.count();
    const runningBots = await BotInstance.count({ where: { status: 'running' } });

    // Total trades
    const totalTrades = await Trade.count();
    const openTrades = await Trade.count({ where: { status: 'open' } });
    const closedTrades = await Trade.count({ where: { status: 'closed' } });

    // Profit statistics
    const trades = await Trade.findAll({
      where: { status: 'closed' },
      attributes: ['profit']
    });

    const totalProfit = trades.reduce((sum, t) => sum + parseFloat(t.profit || 0), 0);
    const winningTrades = trades.filter(t => parseFloat(t.profit) > 0);
    const winRate = closedTrades > 0 ? (winningTrades.length / closedTrades * 100).toFixed(2) : '0.00';

    // Recent activity (last 24 hours)
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentTrades = await Trade.count({
      where: {
        created_at: { [Op.gte]: yesterday }
      }
    });

    res.json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          active: activeUsers,
          inactive: totalUsers - activeUsers
        },
        bots: {
          total: totalBots,
          running: runningBots,
          stopped: totalBots - runningBots
        },
        trades: {
          total: totalTrades,
          open: openTrades,
          closed: closedTrades,
          last24h: recentTrades
        },
        performance: {
          totalProfit: totalProfit.toFixed(2),
          winRate: winRate,
          winningTrades: winningTrades.length,
          losingTrades: closedTrades - winningTrades.length
        }
      }
    });
  } catch (error) {
    console.error('Get platform stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch platform statistics',
      error: error.message
    });
  }
};

module.exports = exports;
