const { Trade, BotInstance, BotLog } = require('../models');
const { Op } = require('sequelize');

// Get all trades for current user
exports.getAllTrades = async (req, res) => {
  try {
    const { status, symbol, limit = 100, offset = 0 } = req.query;

    // Get all user's bots
    const userBots = await BotInstance.findAll({
      where: { user_id: req.user.id },
      attributes: ['id']
    });

    const botIds = userBots.map(b => b.id);

    if (botIds.length === 0) {
      return res.json({
        success: true,
        data: {
          trades: [],
          total: 0,
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      });
    }

    const where = { bot_instance_id: { [Op.in]: botIds } };
    if (status) where.status = status;
    if (symbol) where.symbol = symbol;

    const trades = await Trade.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['opened_at', 'DESC']],
      include: [{
        model: BotInstance,
        as: 'botInstance',
        attributes: ['instance_name', 'broker_name']
      }]
    });

    res.json({
      success: true,
      data: {
        trades: trades.rows,
        total: trades.count,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trades',
      error: error.message
    });
  }
};

// Get all trades for a bot
exports.getTrades = async (req, res) => {
  try {
    const { status, symbol, limit = 50, offset = 0 } = req.query;

    // Verify bot belongs to user
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.botId,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    const where = { bot_instance_id: req.params.botId };
    if (status) where.status = status;
    if (symbol) where.symbol = symbol;

    const trades = await Trade.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['opened_at', 'DESC']]
    });

    res.json({
      success: true,
      data: {
        trades: trades.rows,
        total: trades.count,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trades',
      error: error.message
    });
  }
};

// Get single trade
exports.getTrade = async (req, res) => {
  try {
    const trade = await Trade.findOne({
      where: { id: req.params.id },
      include: [{
        association: 'botInstance',
        where: { user_id: req.user.id }
      }]
    });

    if (!trade) {
      return res.status(404).json({
        success: false,
        message: 'Trade not found'
      });
    }

    res.json({
      success: true,
      data: { trade }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trade',
      error: error.message
    });
  }
};

// Create trade (called by MT4 EA)
exports.createTrade = async (req, res) => {
  try {
    const {
      ticket_number,
      symbol,
      trade_type,
      lot_size,
      open_price,
      stop_loss,
      take_profit,
      strategy_used
    } = req.body;

    // Verify bot belongs to user
    const bot = await BotInstance.findOne({
      where: {
        id: req.params.botId,
        user_id: req.user.id
      }
    });

    if (!bot) {
      return res.status(404).json({
        success: false,
        message: 'Bot instance not found'
      });
    }

    const trade = await Trade.create({
      bot_instance_id: req.params.botId,
      ticket_number,
      symbol,
      trade_type,
      lot_size,
      open_price,
      stop_loss,
      take_profit,
      strategy_used
    });

    // Log trade open
    await BotLog.create({
      bot_instance_id: bot.id,
      log_level: 'INFO',
      category: 'TRADE',
      message: `${trade_type} trade opened: ${symbol} @ ${open_price}`,
      metadata: { trade_id: trade.id, ticket_number }
    });

    res.status(201).json({
      success: true,
      message: 'Trade created successfully',
      data: { trade }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create trade',
      error: error.message
    });
  }
};

// Update trade (called by MT4 EA)
exports.updateTrade = async (req, res) => {
  try {
    const { close_price, profit, commission, swap } = req.body;

    const trade = await Trade.findOne({
      where: { id: req.params.id },
      include: [{
        association: 'botInstance',
        where: { user_id: req.user.id }
      }]
    });

    if (!trade) {
      return res.status(404).json({
        success: false,
        message: 'Trade not found'
      });
    }

    await trade.update({
      close_price,
      profit,
      commission,
      swap,
      status: close_price ? 'closed' : trade.status,
      closed_at: close_price ? new Date() : null
    });

    // Log trade close
    if (close_price) {
      await BotLog.create({
        bot_instance_id: trade.bot_instance_id,
        log_level: 'INFO',
        category: 'TRADE',
        message: `Trade closed: ${trade.symbol} @ ${close_price} | P&L: ${profit}`,
        metadata: { trade_id: trade.id, profit }
      });
    }

    res.json({
      success: true,
      message: 'Trade updated successfully',
      data: { trade }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update trade',
      error: error.message
    });
  }
};

// Get trade history/statistics
exports.getTradeHistory = async (req, res) => {
  try {
    const { period = '7d', botId } = req.query;

    // Calculate date range
    const now = new Date();
    let startDate;

    switch (period) {
      case '24h':
        startDate = new Date(now - 24 * 60 * 60 * 1000);
        break;
      case '7d':
        startDate = new Date(now - 7 * 24 * 60 * 60 * 1000);
        break;
      case '30d':
        startDate = new Date(now - 30 * 24 * 60 * 60 * 1000);
        break;
      case '90d':
        startDate = new Date(now - 90 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(now - 7 * 24 * 60 * 60 * 1000);
    }

    const where = {
      opened_at: { [Op.gte]: startDate },
      status: 'closed'
    };

    if (botId) {
      // Verify bot belongs to user
      const bot = await BotInstance.findOne({
        where: { id: botId, user_id: req.user.id }
      });
      if (!bot) {
        return res.status(404).json({
          success: false,
          message: 'Bot instance not found'
        });
      }
      where.bot_instance_id = botId;
    } else {
      // Get all user's bots
      const userBots = await BotInstance.findAll({
        where: { user_id: req.user.id },
        attributes: ['id']
      });
      where.bot_instance_id = { [Op.in]: userBots.map(b => b.id) };
    }

    const trades = await Trade.findAll({
      where,
      order: [['opened_at', 'ASC']]
    });

    // Calculate daily profit
    const dailyProfits = {};
    trades.forEach(trade => {
      const date = trade.opened_at.toISOString().split('T')[0];
      if (!dailyProfits[date]) {
        dailyProfits[date] = 0;
      }
      dailyProfits[date] += parseFloat(trade.profit || 0);
    });

    const chartData = Object.keys(dailyProfits).map(date => ({
      date,
      profit: dailyProfits[date].toFixed(2)
    }));

    res.json({
      success: true,
      data: {
        period,
        totalTrades: trades.length,
        chartData,
        trades: trades.slice(0, 20) // Latest 20 trades
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trade history',
      error: error.message
    });
  }
};
