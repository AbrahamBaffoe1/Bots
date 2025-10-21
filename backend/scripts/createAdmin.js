/**
 * Create Admin User Script
 *
 * Usage: node scripts/createAdmin.js <email> <password> <firstName> <lastName>
 * Example: node scripts/createAdmin.js admin@example.com SecurePass123! Admin User
 */

const { User } = require('../src/models');

async function createAdmin() {
  try {
    const args = process.argv.slice(2);

    if (args.length < 4) {
      console.log('❌ Missing arguments');
      console.log('\nUsage: node scripts/createAdmin.js <email> <password> <firstName> <lastName>');
      console.log('Example: node scripts/createAdmin.js admin@example.com SecurePass123! Admin User');
      process.exit(1);
    }

    const [email, password, firstName, lastName] = args;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });

    if (existingUser) {
      // Update to admin if not already
      if (existingUser.role === 'admin') {
        console.log('✓ User is already an admin');
        console.log(`  Email: ${existingUser.email}`);
        console.log(`  Name: ${existingUser.first_name} ${existingUser.last_name}`);
        process.exit(0);
      } else {
        await existingUser.update({ role: 'admin' });
        console.log('✓ Existing user promoted to admin');
        console.log(`  Email: ${existingUser.email}`);
        console.log(`  Name: ${existingUser.first_name} ${existingUser.last_name}`);
        process.exit(0);
      }
    }

    // Create new admin user
    const admin = await User.create({
      email,
      password_hash: password, // Will be hashed by the model hook
      first_name: firstName,
      last_name: lastName,
      role: 'admin',
      is_active: true,
      email_verified: true
    });

    console.log('╔══════════════════════════════════════╗');
    console.log('║  ADMIN USER CREATED SUCCESSFULLY!   ║');
    console.log('╚══════════════════════════════════════╝');
    console.log(`\n✓ Email: ${admin.email}`);
    console.log(`✓ Name: ${admin.first_name} ${admin.last_name}`);
    console.log(`✓ Role: ${admin.role}`);
    console.log(`✓ ID: ${admin.id}`);
    console.log('\n📝 Login credentials:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log('\n⚠️  IMPORTANT: Change the password after first login!');
    console.log('\n🌐 Admin Dashboard: http://localhost:3000/admin');

    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to create admin user:', error.message);
    process.exit(1);
  }
}

createAdmin();
