// This file contains the updated createBot function
// Replace lines 72-134 in botController.js with this:

// Create bot instance
exports.createBot = async (req, res) => {
  try {
    const {
      license_key,
      license_id,
      instance_name,
      mt4_account,
      broker_name,
      broker_server,
      is_live
    } = req.body;

    let license;

    // Find license by key or ID
    if (license_key) {
      license = await License.findOne({
        where: {
          license_key,
          status: 'active'
        }
      });

      if (!license) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or inactive license key'
        });
      }

      // Assign license to user if not already assigned
      if (!license.user_id) {
        await license.update({
          user_id: req.user.id,
          issued_at: new Date()
        });
      } else if (license.user_id !== req.user.id) {
        return res.status(400).json({
          success: false,
          message: 'License key is already in use by another user'
        });
      }
    } else if (license_id) {
      license = await License.findOne({
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
    } else {
      return res.status(400).json({
        success: false,
        message: 'Either license_key or license_id is required'
      });
    }

    // Check if license has expired
    if (license.expires_at && new Date() > new Date(license.expires_at)) {
      return res.status(400).json({
        success: false,
        message: 'License has expired'
      });
    }

    // Check max accounts limit
    const botCount = await BotInstance.count({
      where: { license_id: license.id }
    });

    if (botCount >= license.max_accounts) {
      return res.status(400).json({
        success: false,
        message: `License allows maximum ${license.max_accounts} accounts. You have ${botCount} active bot(s).`
      });
    }

    // Create bot instance
    const bot = await BotInstance.create({
      user_id: req.user.id,
      license_id: license.id,
      instance_name,
      mt4_account,
      broker_name,
      broker_server,
      is_live: is_live || false
    });

    // Include license info in response
    const botWithLicense = await BotInstance.findByPk(bot.id, {
      include: [{ association: 'license' }]
    });

    res.status(201).json({
      success: true,
      message: 'Bot instance created successfully',
      data: { bot: botWithLicense }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create bot instance',
      error: error.message
    });
  }
};
