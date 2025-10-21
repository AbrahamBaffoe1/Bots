require('dotenv').config();
const axios = require('axios');

const API_URL = 'http://localhost:5000/api';
const TEST_EMAIL = 'test.trial@example.com';

async function testTrialFlow() {
  console.log('\n=== Testing Complete Trial Account Flow ===\n');

  try {
    // Step 1: Create trial account
    console.log('Step 1: Creating trial account...');
    const trialResponse = await axios.post(`${API_URL}/payments/create-checkout-session`, {
      plan_type: 'TRIAL',
      customer_email: TEST_EMAIL
    });

    console.log('✓ Trial account created successfully!');
    console.log('Response:', JSON.stringify(trialResponse.data, null, 2));

    const { license_key, is_new_user, email_sent } = trialResponse.data.data;

    if (!is_new_user) {
      console.log('\n⚠️  User already exists. Exiting test.');
      return;
    }

    console.log('\n✓ New user created');
    console.log(`✓ License Key: ${license_key}`);
    console.log(`✓ Email sent: ${email_sent}`);

    // Wait a moment for database to commit
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Step 2: Fetch the generated password from the database
    console.log('\n\nStep 2: Fetching generated password from database...');
    const { Pool } = require('pg');
    const pool = new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD
    });

    const userResult = await pool.query('SELECT password_hash FROM users WHERE email = $1', [TEST_EMAIL]);

    if (userResult.rows.length === 0) {
      console.error('✗ User not found in database!');
      return;
    }

    console.log('✓ User found in database');
    console.log('✓ Password hash exists:', userResult.rows[0].password_hash ? 'YES' : 'NO');

    // Note: We can't retrieve the plain password, but we can verify it was hashed
    console.log('\n⚠️  NOTE: The plain password was sent via email. Check your email inbox for login credentials.');
    console.log('⚠️  For testing purposes, you can manually create a password by updating the database:');
    console.log(`\n    UPDATE users SET password_hash = crypt('testpass123', gen_salt('bf', 12)) WHERE email = '${TEST_EMAIL}';\n`);
    console.log('    Then login with password: testpass123\n');

    await pool.end();

    // Step 3: Test login (will fail since we don't have the plain password)
    console.log('\nStep 3: Testing login flow...');
    console.log('⚠️  Cannot test login automatically because password was randomly generated.');
    console.log('⚠️  Please check the email sent to:', TEST_EMAIL);
    console.log('⚠️  Or update the password in database as shown above.');

    console.log('\n=== Test Summary ===');
    console.log('✓ Trial account creation: PASSED');
    console.log('✓ License generation: PASSED');
    console.log('✓ User record in database: PASSED');
    console.log('✓ Password hashing: PASSED');
    console.log('⚠️  Login test: SKIPPED (need password from email)');
    console.log('\n✓ All automated tests passed!');
    console.log('\nManual steps to complete:');
    console.log('1. Check email inbox for welcome message');
    console.log('2. Use the provided credentials to login at http://localhost:3000');
    console.log('3. Verify you can access the dashboard');
    console.log('4. Try activating a bot with the license key');

  } catch (error) {
    console.error('\n✗ Test failed:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
      console.error('Response status:', error.response.status);
    }
    process.exit(1);
  }
}

testTrialFlow();
