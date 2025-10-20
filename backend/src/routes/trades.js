const express = require('express');
const router = express.Router();
const tradesController = require('../controllers/tradesController');
const { auth } = require('../middleware/auth');

// Trade routes
router.get('/history', auth, tradesController.getTradeHistory);
router.get('/bot/:botId', auth, tradesController.getTrades);
router.get('/:id', auth, tradesController.getTrade);
router.post('/bot/:botId', auth, tradesController.createTrade);
router.put('/:id', auth, tradesController.updateTrade);

module.exports = router;
