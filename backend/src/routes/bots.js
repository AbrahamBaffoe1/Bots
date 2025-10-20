const express = require('express');
const router = express.Router();
const botController = require('../controllers/botController');
const { auth } = require('../middleware/auth');

// Bot instance routes
router.get('/', auth, botController.getBots);
router.get('/:id', auth, botController.getBot);
router.post('/', auth, botController.createBot);
router.post('/:id/start', auth, botController.startBot);
router.post('/:id/stop', auth, botController.stopBot);
router.post('/:id/heartbeat', auth, botController.updateHeartbeat);
router.get('/:id/stats', auth, botController.getBotStats);
router.get('/:id/logs', auth, botController.getBotLogs);
router.delete('/:id', auth, botController.deleteBot);

module.exports = router;
