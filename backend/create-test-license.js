const { sequelize, License } = require('./src/models');
const crypto = require('crypto');

// Generate license key
function generateLicenseKey(type) {
  const prefix = { 'TRIAL': 'TRL', 'BASIC': 'BSC', 'PRO': 'PRO', 'ENTERPRISE': 'ENT' }[type] || 'LIC';
  const randomPart = crypto.randomBytes(12).toString('hex').toUpperCase();
  return `${prefix}-${randomPart.substring(0,4)}-${randomPart.substring(4,8)}-${randomPart.substring(8,12)}-${randomPart.substring(12,16)}`;
}

async function createTestLicenses() {
  try {
    await sequelize.authenticate();
    console.log('✓ Database connected');

    // Create test licenses for each tier
    const licenses = [
      {
        license_key: generateLicenseKey('TRIAL'),
        license_type: 'TRIAL',
        max_accounts: 1,
        status: 'active',
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      },
      {
        license_key: generateLicenseKey('BASIC'),
        license_type: 'BASIC',
        max_accounts: 1,
        status: 'active',
        expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year
      },
      {
        license_key: generateLicenseKey('PRO'),
        license_type: 'PRO',
        max_accounts: 3,
        status: 'active',
        expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year
      },
      {
        license_key: generateLicenseKey('ENTERPRISE'),
        license_type: 'ENTERPRISE',
        max_accounts: 10,
        status: 'active',
        expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year
      }
    ];

    console.log('\nCreating test licenses...\n');

    for (const licenseData of licenses) {
      const license = await License.create(licenseData);
      console.log(`✓ ${licenseData.license_type} License Created:`);
      console.log(`  Key: ${license.license_key}`);
      console.log(`  Max Accounts: ${license.max_accounts}`);
      console.log(`  Expires: ${license.expires_at.toLocaleDateString()}`);
      console.log('');
    }

    console.log('All test licenses created successfully!');
    console.log('\nYou can now use any of these license keys in the AddBotModal.');

    await sequelize.close();
    process.exit(0);
  } catch (error) {
    console.error('Error creating test licenses:', error);
    process.exit(1);
  }
}

createTestLicenses();
