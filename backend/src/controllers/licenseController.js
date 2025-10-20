const { License, User, BotInstance } = require('../models');
const crypto = require('crypto');

// Generate license key
const generateLicenseKey = (type) => {
  const prefix = {
    'TRIAL': 'TRL',
    'BASIC': 'BSC',
    'PRO': 'PRO',
    'ENTERPRISE': 'ENT'
  }[type] || 'LIC';

  const randomPart = crypto.randomBytes(12).toString('hex').toUpperCase();
  const key = `${prefix}-${randomPart.substring(0, 4)}-${randomPart.substring(4, 8)}-${randomPart.substring(8, 12)}-${randomPart.substring(12, 16)}`;

  return key;
};

// Validate license key format
const isValidLicenseKeyFormat = (key) => {
  // Format: XXX-XXXX-XXXX-XXXX-XXXX
  const regex = /^(TRL|BSC|PRO|ENT|LIC)-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
  return regex.test(key);
};

// Get all user licenses
exports.getUserLicenses = async (req, res) => {
  try {
    const licenses = await License.findAll({
      where: { user_id: req.user.id },
      include: [{
        model: BotInstance,
        as: 'botInstances',
        attributes: ['id', 'instance_name', 'status', 'created_at']
      }],
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: { licenses }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch licenses',
      error: error.message
    });
  }
};

// Validate and activate license
exports.validateLicense = async (req, res) => {
  try {
    const { license_key } = req.body;

    if (!license_key) {
      return res.status(400).json({
        success: false,
        message: 'License key is required'
      });
    }

    // Check format
    if (!isValidLicenseKeyFormat(license_key)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid license key format'
      });
    }

    // Find license
    const license = await License.findOne({
      where: { license_key },
      include: [{
        model: BotInstance,
        as: 'botInstances',
        attributes: ['id']
      }]
    });

    if (!license) {
      return res.status(404).json({
        success: false,
        message: 'License key not found'
      });
    }

    // Check if license is expired
    if (license.expires_at && new Date() > new Date(license.expires_at)) {
      return res.status(400).json({
        success: false,
        message: 'License has expired'
      });
    }

    // Check if license is active
    if (license.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: `License is ${license.status}`
      });
    }

    // Check if license already belongs to another user
    if (license.user_id && license.user_id !== req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'License is already activated by another user'
      });
    }

    // Check if max accounts limit reached
    const botCount = license.botInstances ? license.botInstances.length : 0;
    const availableSlots = license.max_accounts - botCount;

    if (availableSlots <= 0) {
      return res.status(400).json({
        success: false,
        message: 'License has reached maximum account limit'
      });
    }

    // If license is not yet assigned to this user, assign it
    if (!license.user_id) {
      await license.update({
        user_id: req.user.id,
        issued_at: new Date()
      });
    }

    // Update last validated
    await license.update({
      last_validated: new Date()
    });

    res.json({
      success: true,
      message: 'License validated successfully',
      data: {
        license: {
          id: license.id,
          license_key: license.license_key,
          license_type: license.license_type,
          max_accounts: license.max_accounts,
          used_accounts: botCount,
          available_slots: availableSlots,
          expires_at: license.expires_at,
          status: license.status
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to validate license',
      error: error.message
    });
  }
};

// Create license (admin or purchase flow)
exports.createLicense = async (req, res) => {
  try {
    const {
      user_id,
      license_type,
      max_accounts,
      duration_days
    } = req.body;

    // Determine max accounts based on license type if not specified
    let maxAccounts = max_accounts;
    if (!maxAccounts) {
      maxAccounts = {
        'TRIAL': 1,
        'BASIC': 1,
        'PRO': 3,
        'ENTERPRISE': 10
      }[license_type] || 1;
    }

    // Calculate expiration date
    let expiresAt = null;
    if (duration_days) {
      expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + duration_days);
    } else {
      // Default expiration based on type
      const defaultDays = {
        'TRIAL': 7,
        'BASIC': 365,
        'PRO': 365,
        'ENTERPRISE': 365
      }[license_type] || 365;

      expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + defaultDays);
    }

    // Generate license key
    const licenseKey = generateLicenseKey(license_type);

    // Create license
    const license = await License.create({
      user_id: user_id || null, // Can be null initially for purchased licenses
      license_key: licenseKey,
      license_type,
      max_accounts: maxAccounts,
      status: 'active',
      issued_at: user_id ? new Date() : null,
      expires_at: expiresAt
    });

    res.status(201).json({
      success: true,
      message: 'License created successfully',
      data: { license }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create license',
      error: error.message
    });
  }
};

// Revoke license (admin only)
exports.revokeLicense = async (req, res) => {
  try {
    const license = await License.findByPk(req.params.id);

    if (!license) {
      return res.status(404).json({
        success: false,
        message: 'License not found'
      });
    }

    await license.update({ status: 'revoked' });

    res.json({
      success: true,
      message: 'License revoked successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to revoke license',
      error: error.message
    });
  }
};

module.exports = exports;
