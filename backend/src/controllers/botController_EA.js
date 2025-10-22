const { BotInstance, Trade, BotLog, License } = require('../models');
const { Op } = require('sequelize');

/**
 * MT4 EA Bot Controller
 * Handles bot registration and management from MetaTrader EA
 */

// Register/Get Bot (used by MT4 EA on startup AND dashboard)
exports.registerOrGetBot = async (req, res) => {
  try {
    const {
      bot_name,
      instance_name,
      account_number,
      mt4_account,
      account_name,
      broker_name,
      server_name,
      broker_server,
      version,
      is_live,
      license_key
    } = req.body;

    // Support both MT4 EA format (account_number) and dashboard format (mt4_account)
    const accountNum = account_number || mt4_account;
    const botName = bot_name || instance_name;
    const serverName = server_name || broker_server;

    // Validate required fields
    if (!accountNum || !broker_name) {
      return res.status(400).json({
        success: false,
        message: 'account_number (or mt4_account) and broker_name are required'
      });
    }

    // If license_key is provided (from dashboard), look up the license
    let licenseId = null;
    if (license_key) {
      const license = await License.findOne({
        where: {
          license_key: license_key.trim().toUpperCase(),
          user_id: req.user.id,
          status: 'active'
        }
      });

      if (!license) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or inactive license key'
        });
      }

      // Check if license has available slots
      const existingBotsCount = await BotInstance.count({
        where: { license_id: license.id }
      });

      if (existingBotsCount >= license.max_accounts) {
        return res.status(400).json({
          success: false,
          message: `License has reached maximum accounts (${license.max_accounts}). Please upgrade or purchase additional licenses.`
        });
      }

      licenseId = license.id;
    }

    // Check if bot already exists for this user and account
    let bot = await BotInstance.findOne({
      where: {
        user_id: req.user.id,
        mt4_account: accountNum.toString(),
        broker_name: broker_name
      }
    });

    if (bot) {
      // Bot exists, update it
      await bot.update({
        instance_name: botName || bot.instance_name,
        broker_server: serverName || bot.broker_server,
        version: version || bot.version,
        is_live: is_live !== undefined ? is_live : bot.is_live,
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
          bot: bot, // Full bot object for dashboard
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
      license_id: licenseId, // Will be null for MT4 EA registrations (allowed), required for dashboard
      instance_name: botName || `Bot_${accountNum}`,
      mt4_account: accountNum.toString(),
      account_name: account_name || '',
      broker_name: broker_name,
      broker_server: serverName || '',
      version: version || '1.0',
      is_live: is_live !== undefined ? is_live : true, // Use provided value or default to true
      status: 'running',
      started_at: new Date(),
      last_heartbeat: new Date()
    });

    // Log new registration
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: license_key ? 'New bot registered from dashboard' : 'New bot registered from MT4 EA',
      metadata: JSON.stringify({
        account_number: accountNum,
        broker: broker_name,
        server: serverName,
        version,
        source: license_key ? 'dashboard' : 'mt4_ea'
      })
    });

    res.status(201).json({
      success: true,
      message: 'Bot registered successfully',
      data: {
        bot: bot, // Full bot object for dashboard
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

// ============================================================================
// LOGS & MONITORING (MT4 EA Integration)
// ============================================================================

// Submit single log entry (called by MT4 EA)
exports.submitLog = async (req, res) => {
  try {
    const { id } = req.params;
    const { log_level, category, message, metadata } = req.body;

    // Validate bot ownership
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

    // Validate required fields
    if (!log_level || !category || !message) {
      return res.status(400).json({
        success: false,
        message: 'log_level, category, and message are required'
      });
    }

    // Validate log level
    const validLogLevels = ['INFO', 'WARNING', 'ERROR', 'DEBUG'];
    if (!validLogLevels.includes(log_level.toUpperCase())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid log_level. Must be one of: INFO, WARNING, ERROR, DEBUG'
      });
    }

    // Create log entry
    const log = await BotLog.create({
      bot_instance_id: bot.id,
      log_level: log_level.toUpperCase(),
      category: category.toUpperCase(),
      message: message,
      metadata: metadata || null
    });

    res.json({
      success: true,
      message: 'Log submitted successfully',
      data: {
        log_id: log.id,
        created_at: log.created_at
      }
    });
  } catch (error) {
    console.error('Submit log error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit log',
      error: error.message
    });
  }
};

// Submit multiple logs in batch (called by MT4 EA for efficiency)
exports.submitLogsBatch = async (req, res) => {
  try {
    const { id } = req.params;
    const { logs } = req.body;

    // Validate bot ownership
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

    // Validate logs array
    if (!Array.isArray(logs) || logs.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'logs must be a non-empty array'
      });
    }

    // Validate and prepare log entries
    const validLogLevels = ['INFO', 'WARNING', 'ERROR', 'DEBUG'];
    const logEntries = [];

    for (const log of logs) {
      if (!log.log_level || !log.category || !log.message) {
        return res.status(400).json({
          success: false,
          message: 'Each log must have log_level, category, and message'
        });
      }

      if (!validLogLevels.includes(log.log_level.toUpperCase())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid log_level. Must be one of: INFO, WARNING, ERROR, DEBUG'
        });
      }

      logEntries.push({
        bot_instance_id: bot.id,
        log_level: log.log_level.toUpperCase(),
        category: log.category.toUpperCase(),
        message: log.message,
        metadata: log.metadata || null
      });
    }

    // Bulk create logs
    const createdLogs = await BotLog.bulkCreate(logEntries);

    res.json({
      success: true,
      message: createdLogs.length + ' logs submitted successfully',
      data: {
        count: createdLogs.length,
        logs: createdLogs.map(l => ({ id: l.id, created_at: l.created_at }))
      }
    });
  } catch (error) {
    console.error('Submit logs batch error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit logs',
      error: error.message
    });
  }
};

// Get logs for a bot
exports.getBotLogs = async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, log_level, category } = req.query;

    // Validate bot ownership
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

    // Build where clause
    const where = { bot_instance_id: bot.id };
    if (log_level) where.log_level = log_level.toUpperCase();
    if (category) where.category = category.toUpperCase();

    // Fetch logs
    const logs = await BotLog.findAll({
      where,
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: logs
    });
  } catch (error) {
    console.error('Get bot logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch logs',
      error: error.message
    });
  }
};
