const { sequelize, User, License } = require('../src/models');

async function updateLicense() {
  try {
    console.log('🔄 Updating license key for Ifrey2heavens@gmail.com...');

    // Connect to database
    await sequelize.authenticate();
    console.log('✓ Database connected');

    // Find user
    const user = await User.findOne({
      where: { email: 'ifrey2heavens@gmail.com' }
    });

    if (!user) {
      console.log('✗ User not found with email: ifrey2heavens@gmail.com');
      console.log('Creating user...');

      const bcrypt = require('bcrypt');
      const hashedPassword = await bcrypt.hash('!bv2000gee4A!', 10);

      const newUser = await User.create({
        email: 'ifrey2heavens@gmail.com',
        password_hash: hashedPassword,
        first_name: 'Ifrey',
        last_name: 'User',
        role: 'user',
        is_active: true,
        email_verified: true
      });

      console.log('✓ User created with ID:', newUser.id);

      // Create license for new user
      const license = await License.create({
        user_id: newUser.id,
        license_key: 'SST-ENTERPRISE-W0674G-XF9XH9-89WA',
        license_type: 'ENTERPRISE',
        max_accounts: 999,
        status: 'active',
        issued_at: new Date(),
        expires_at: new Date('2026-12-31T23:59:59Z'),
        activation_count: 0
      });

      console.log('✓ ENTERPRISE license created:', license.license_key);
      console.log('\n╔════════════════════════════════════════════════════╗');
      console.log('║          LICENSE SETUP COMPLETE!                   ║');
      console.log('╠════════════════════════════════════════════════════╣');
      console.log('║ User Email:    ifrey2heavens@gmail.com             ║');
      console.log('║ Password:      !bv2000gee4A!                       ║');
      console.log('║ License Key:   SST-ENTERPRISE-W0674G-XF9XH9-89WA   ║');
      console.log('║ License Type:  ENTERPRISE                          ║');
      console.log('║ Max Accounts:  999                                 ║');
      console.log('║ Expires:       2026-12-31                          ║');
      console.log('║ Status:        ACTIVE ✅                           ║');
      console.log('╚════════════════════════════════════════════════════╝\n');

      process.exit(0);
    }

    console.log('✓ User found:', user.email);
    console.log('  User ID:', user.id);

    // Check for existing licenses
    const existingLicenses = await License.findAll({
      where: { user_id: user.id }
    });

    console.log(`  Existing licenses: ${existingLicenses.length}`);

    // Check if new license already exists
    const existingNewLicense = await License.findOne({
      where: { license_key: 'SST-ENTERPRISE-W0674G-XF9XH9-89WA' }
    });

    if (existingNewLicense) {
      console.log('✓ License already exists!');
      console.log('  License Key: SST-ENTERPRISE-W0674G-XF9XH9-89WA');
      console.log('  License Type:', existingNewLicense.license_type);
      console.log('  Status:', existingNewLicense.status);
      process.exit(0);
    }

    // Deactivate old licenses
    if (existingLicenses.length > 0) {
      await License.update(
        { status: 'revoked' },
        { where: { user_id: user.id } }
      );
      console.log('✓ Revoked old licenses');
    }

    // Create new ENTERPRISE license
    const newLicense = await License.create({
      user_id: user.id,
      license_key: 'SST-ENTERPRISE-W0674G-XF9XH9-89WA',
      license_type: 'ENTERPRISE',
      max_accounts: 999,
      status: 'active',
      issued_at: new Date(),
      expires_at: new Date('2026-12-31T23:59:59Z'),
      activation_count: 0
    });

    console.log('✓ New ENTERPRISE license created!');
    console.log('\n╔════════════════════════════════════════════════════╗');
    console.log('║          LICENSE UPDATED SUCCESSFULLY!             ║');
    console.log('╠════════════════════════════════════════════════════╣');
    console.log('║ User Email:    ifrey2heavens@gmail.com             ║');
    console.log('║ Password:      !bv2000gee4A!                       ║');
    console.log('║ License Key:   SST-ENTERPRISE-W0674G-XF9XH9-89WA   ║');
    console.log('║ License Type:  ENTERPRISE                          ║');
    console.log('║ Max Accounts:  999                                 ║');
    console.log('║ Expires:       2026-12-31                          ║');
    console.log('║ Status:        ACTIVE ✅                           ║');
    console.log('╚════════════════════════════════════════════════════╝\n');

    process.exit(0);
  } catch (error) {
    console.error('✗ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

updateLicense();
