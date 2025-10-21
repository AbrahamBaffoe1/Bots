const jwt = require('jsonwebtoken');
const { User } = require('../models');

/**
 * Admin Authentication Middleware
 * Ensures user is authenticated AND has admin role
 */
exports.adminAuth = async (req, res, next) => {
  try {
    // Check if token exists
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No authentication token provided'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key-change-in-production');

    // Find user
    const user = await User.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Account is disabled'
      });
    }

    // Check if user has admin role
    if (user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.'
      });
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Admin auth error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

/**
 * Super Admin Middleware (for critical operations)
 */
exports.superAdminAuth = async (req, res, next) => {
  try {
    // First check if admin
    await exports.adminAuth(req, res, () => {});

    // Additional super admin checks (e.g., email whitelist)
    const superAdminEmails = (process.env.SUPER_ADMIN_EMAILS || '').split(',');

    if (!superAdminEmails.includes(req.user.email)) {
      return res.status(403).json({
        success: false,
        message: 'Super admin privileges required'
      });
    }

    next();
  } catch (error) {
    console.error('Super admin auth error:', error);
    res.status(401).json({
      success: false,
      message: 'Unauthorized'
    });
  }
};
