const express = require('express');
const router = express.Router();
const botControllerEA = require('../controllers/botController_EA');
const { auth } = require('../middleware/auth');

// Bot instance routes (MT4 EA compatible)
router.get('/', auth, botControllerEA.getBots);
router.get('/:id', auth, botControllerEA.getBot);

// MT4 EA Bot Registration (no license required)
router.post('/', auth, botControllerEA.registerOrGetBot);

// Bot control
router.post('/:id/start', auth, botControllerEA.startBot);
router.post('/:id/stop', auth, botControllerEA.stopBot);

// Heartbeat (called by MT4 EA)
router.post('/:id/heartbeat', auth, botControllerEA.updateHeartbeat);

// Statistics
router.get('/:id/stats', auth, botControllerEA.getBotStats);

module.exports = router;
