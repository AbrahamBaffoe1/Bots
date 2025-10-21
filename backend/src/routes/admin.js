const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { adminAuth } = require('../middleware/adminAuth');

// All routes require admin authentication
router.use(adminAuth);

// ============================================================================
// USER MANAGEMENT
// ============================================================================
router.get('/users', adminController.getAllUsers);
router.get('/users/:userId', adminController.getUserDetails);
router.put('/users/:userId', adminController.updateUser);
router.delete('/users/:userId', adminController.deleteUser);

// ============================================================================
// BOT MANAGEMENT
// ============================================================================
router.get('/bots', adminController.getAllBots);
router.post('/bots/:botId/control', adminController.controlBot);
router.delete('/bots/:botId', adminController.deleteBot);

// ============================================================================
// LOGS & MONITORING
// ============================================================================
router.get('/logs', adminController.getAllLogs);

// ============================================================================
// STATISTICS
// ============================================================================
router.get('/stats', adminController.getPlatformStats);

module.exports = router;
