const { BotInstance, Trade, BotLog, License } = require('../models');
const { Op } = require('sequelize');

// Get all bot instances for user
exports.getBots = async (req, res) => {
  try {
    const bots = await BotInstance.findAll({
      where: { user_id: req.user.id },
      include: [
        { association: 'license' },
        {
          association: 'trades',
          where: { status: 'open' },
          required: false
        }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: { bots }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bots',
      error: error.message
    });
  }
};

// Get single bot instance
exports.getBot = async (req, res) => {
  try {
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id
      },
      include: [
        { association: 'license' },
        {
          association: 'trades',
          limit: 10,
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
      data: { bot }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bot',
      error: error.message
    });
  }
};

// Create bot instance
exports.createBot = async (req, res) => {
  try {
    const {
      license_id,
      instance_name,
      mt4_account,
      broker_name,
      broker_server,
      is_live
    } = req.body;

    // Verify license
    const license = await License.findOne({
      where: {
        id: license_id,
        user_id: req.user.id,
        status: 'active'
      }
    });

    if (!license) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive license'
      });
    }

    // Check max accounts limit
    const botCount = await BotInstance.count({
      where: { license_id: license_id }
    });

    if (botCount >= license.max_accounts) {
      return res.status(400).json({
        success: false,
        message: `License allows maximum ${license.max_accounts} accounts`
      });
    }

    // Create bot instance
    const bot = await BotInstance.create({
      user_id: req.user.id,
      license_id,
      instance_name,
      mt4_account,
      broker_name,
      broker_server,
      is_live: is_live || false
    });

    res.status(201).json({
      success: true,
      message: 'Bot instance created successfully',
      data: { bot }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create bot instance',
      error: error.message
    });
  }
};

// Start bot
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

    if (bot.status === 'running') {
      return res.status(400).json({
        success: false,
        message: 'Bot is already running'
      });
    }

    await bot.update({
      status: 'running',
      started_at: new Date(),
      last_heartbeat: new Date()
    });

    // Log the start event
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: 'Bot started by user'
    });

    res.json({
      success: true,
      message: 'Bot started successfully',
      data: { bot }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to start bot',
      error: error.message
    });
  }
};

// Stop bot
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

    if (bot.status === 'stopped') {
      return res.status(400).json({
        success: false,
        message: 'Bot is already stopped'
      });
    }

    await bot.update({
      status: 'stopped',
      stopped_at: new Date()
    });

    // Log the stop event
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'SYSTEM',
      message: 'Bot stopped by user'
    });

    res.json({
      success: true,
      message: 'Bot stopped successfully',
      data: { bot }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to stop bot',
      error: error.message
    });
  }
};

// Update bot heartbeat (called by MT4 EA)
exports.updateHeartbeat = async (req, res) => {
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
      last_heartbeat: new Date()
    });

    res.json({
      success: true,
      data: {
        status: bot.status,
        isOnline: bot.isOnline()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update heartbeat',
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
        isOnline: bot.isOnline(),
        uptime: bot.getUptime()
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
          : 0,
        profitFactor: grossLoss > 0
          ? (grossProfit / grossLoss).toFixed(2)
          : grossProfit > 0 ? 'Infinite' : 0,
        avgWin: winningTrades.length > 0
          ? (grossProfit / winningTrades.length).toFixed(2)
          : 0,
        avgLoss: losingTrades.length > 0
          ? (grossLoss / losingTrades.length).toFixed(2)
          : 0
      }
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bot statistics',
      error: error.message
    });
  }
};

// Get bot logs
exports.getBotLogs = async (req, res) => {
  try {
    const { level, category, limit = 100 } = req.query;

    const where = {
      bot_instance_id: req.params.id
    };

    if (level) where.log_level = level.toUpperCase();
    if (category) where.category = category.toUpperCase();

    const logs = await BotLog.findAll({
      where,
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: { logs }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch logs',
      error: error.message
    });
  }
};

// Delete bot instance
exports.deleteBot = async (req, res) => {
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

    if (bot.status === 'running') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete running bot. Stop it first.'
      });
    }

    await bot.destroy();

    res.json({
      success: true,
      message: 'Bot instance deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete bot',
      error: error.message
    });
  }
};
