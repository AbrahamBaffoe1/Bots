const { BotInstance, Trade, BotLog } = require('../models');
const { Op } = require('sequelize');

/**
 * MT4 EA Bot Controller
 * Handles bot registration and management from MetaTrader EA
 */

// Register/Get Bot (used by MT4 EA on startup)
exports.registerOrGetBot = async (req, res) => {
  try {
    const {
      bot_name,
      account_number,
      account_name,
      broker_name,
      server_name,
      version
    } = req.body;

    // Validate required fields
    if (!account_number || !broker_name) {
      return res.status(400).json({
        success: false,
        message: 'account_number and broker_name are required'
      });
    }

    // Check if bot already exists for this user and account
    let bot = await BotInstance.findOne({
      where: {
        user_id: req.user.id,
        mt4_account: account_number.toString(),
        broker_name: broker_name
      }
    });

    if (bot) {
      // Bot exists, update it
      await bot.update({
        instance_name: bot_name || bot.instance_name,
        broker_server: server_name || bot.broker_server,
        version: version || bot.version,
        status: 'running',
        started_at: new Date(),
        last_heartbeat: new Date()
      });

      // Log reconnection
      await BotLog.create({
        bot_instance_id: bot.id,
        log_level: 'INFO',
        category: 'SYSTEM',
        message: 'Bot reconnected from MT4 EA'
      });

      return res.json({
        success: true,
        message: 'Existing bot found and updated',
        data: {
          id: bot.id,
          _id: bot.id, // MongoDB compatibility
          bot_name: bot.instance_name,
          status: bot.status,
          isNewRegistration: false
        }
      });
    }

    // Create new bot instance
    bot = await BotInstance.create({
      user_id: req.user.id,
      instance_name: bot_name || `Bot_${account_number}`,
      mt4_account: account_number.toString(),
      account_name: account_name || '',
      broker_name: broker_name,
      broker_server: server_name || '',
      version: version || '1.0',
      is_live: true, // Assume live by default
      status: 'running',
      started_at: new Date(),
      last_heartbeat: new Date()
    });

    // Log new registration
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: 'New bot registered from MT4 EA',
      metadata: JSON.stringify({
        account_number,
        broker: broker_name,
        server: server_name,
        version
      })
    });

    res.status(201).json({
      success: true,
      message: 'Bot registered successfully',
      data: {
        id: bot.id,
        _id: bot.id, // MongoDB compatibility
        bot_name: bot.instance_name,
        status: bot.status,
        isNewRegistration: true
      }
    });
  } catch (error) {
    console.error('Bot registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register bot',
      error: error.message
    });
  }
};

// Update bot heartbeat (called by MT4 EA periodically)
exports.updateHeartbeat = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      balance,
      equity,
      margin,
      free_margin,
      open_positions,
      status
    } = req.body;

    const bot = await BotInstance.findOne({
      where: {
        id: id,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    // Update bot with heartbeat data
    await bot.update({
      last_heartbeat: new Date(),
      current_balance: balance || bot.current_balance,
      current_equity: equity || bot.current_equity,
      status: status || bot.status
    });

    res.json({
      success: true,
      message: 'Heartbeat updated',
      data: {
        bot_id: bot.id,
        status: bot.status,
        isOnline: true,
        last_heartbeat: bot.last_heartbeat
      }
    });
  } catch (error) {
    console.error('Heartbeat update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update heartbeat',
      error: error.message
    });
  }
};

// Get all bots for authenticated user
exports.getBots = async (req, res) => {
  try {
    const { account_number } = req.query;

    const where = { user_id: req.user.id };

    // If account_number is provided, filter by it
    if (account_number) {
      where.mt4_account = account_number.toString();
    }

    const bots = await BotInstance.findAll({
      where,
      include: [
        {
          model: Trade,
          as: 'trades',
          where: { status: 'open' },
          required: false,
          limit: 5
        }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: bots
    });
  } catch (error) {
    console.error('Get bots error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bots',
      error: error.message
    });
  }
};

// Get single bot by ID
exports.getBot = async (req, res) => {
  try {
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id
      },
      include: [
        {
          model: Trade,
          as: 'trades',
          limit: 20,
          order: [['opened_at', 'DESC']]
        }
      ]
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    res.json({
      success: true,
      data: bot
    });
  } catch (error) {
    console.error('Get bot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bot',
      error: error.message
    });
  }
};

// Get bot statistics
exports.getBotStats = async (req, res) => {
  try {
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    // Get trade statistics
    const allTrades = await Trade.findAll({
      where: { bot_instance_id: bot.id }
    });

    const closedTrades = allTrades.filter(t => t.status === 'closed');
    const openTrades = allTrades.filter(t => t.status === 'open');
    const winningTrades = closedTrades.filter(t => parseFloat(t.profit) > 0);
    const losingTrades = closedTrades.filter(t => parseFloat(t.profit) < 0);

    const totalProfit = closedTrades.reduce((sum, t) => sum + parseFloat(t.profit || 0), 0);
    const grossProfit = winningTrades.reduce((sum, t) => sum + parseFloat(t.profit || 0), 0);
    const grossLoss = Math.abs(losingTrades.reduce((sum, t) => sum + parseFloat(t.profit || 0), 0));

    const stats = {
      bot: {
        id: bot.id,
        name: bot.instance_name,
        status: bot.status,
        account: bot.mt4_account,
        broker: bot.broker_name,
        isOnline: bot.isOnline ? bot.isOnline() : true,
        last_heartbeat: bot.last_heartbeat
      },
      trades: {
        total: allTrades.length,
        open: openTrades.length,
        closed: closedTrades.length,
        winning: winningTrades.length,
        losing: losingTrades.length
      },
      performance: {
        totalProfit: totalProfit.toFixed(2),
        grossProfit: grossProfit.toFixed(2),
        grossLoss: grossLoss.toFixed(2),
        winRate: closedTrades.length > 0
          ? ((winningTrades.length / closedTrades.length) * 100).toFixed(2)
          : '0.00',
        profitFactor: grossLoss > 0
          ? (grossProfit / grossLoss).toFixed(2)
          : grossProfit > 0 ? '999.99' : '0.00'
      }
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get bot stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bot statistics',
      error: error.message
    });
  }
};

// Start bot (manual control from dashboard)
exports.startBot = async (req, res) => {
  try {
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    await bot.update({
      status: 'running',
      started_at: new Date()
    });

    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: 'Bot started manually from dashboard'
    });

    res.json({
      success: true,
      message: 'Bot started successfully',
      data: { bot }
    });
  } catch (error) {
    console.error('Start bot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start bot',
      error: error.message
    });
  }
};

// Stop bot (manual control from dashboard)
exports.stopBot = async (req, res) => {
  try {
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    await bot.update({
      status: 'stopped',
      stopped_at: new Date()
    });

    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: 'Bot stopped manually from dashboard'
    });

    res.json({
      success: true,
      message: 'Bot stopped successfully',
      data: { bot }
    });
  } catch (error) {
    console.error('Stop bot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to stop bot',
      error: error.message
    });
  }
};

module.exports = exports;
