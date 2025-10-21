#!/usr/bin/env node

/**
 * Database Setup Script
 *
 * This script will:
 * 1. Test database connection
 * 2. Drop all existing tables (if --force flag is used)
 * 3. Create all tables with proper schema
 * 4. Set up relationships and indexes
 * 5. Optionally seed with initial data (if --seed flag is used)
 *
 * Usage:
 *   node scripts/setupDatabase.js              # Create tables (safe mode)
 *   node scripts/setupDatabase.js --force      # Drop and recreate all tables
 *   node scripts/setupDatabase.js --seed       # Create tables and add seed data
 *   node scripts/setupDatabase.js --force --seed  # Full reset with seed data
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const { sequelize, testConnection } = require('../src/config/database');
const {
  User,
  License,
  BotInstance,
  Trade,
  BotLog,
  syncDatabase
} = require('../src/models');

// Parse command line arguments
const args = process.argv.slice(2);
const forceRecreate = args.includes('--force');
const seedData = args.includes('--seed');
const helpRequested = args.includes('--help') || args.includes('-h');

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function showHelp() {
  log('\n=== Database Setup Script ===\n', colors.bright);
  log('Usage:', colors.cyan);
  log('  node scripts/setupDatabase.js [options]\n');
  log('Options:', colors.cyan);
  log('  --force    Drop all existing tables and recreate them (WARNING: All data will be lost!)');
  log('  --seed     Add seed/sample data after creating tables');
  log('  --help     Show this help message\n');
  log('Examples:', colors.cyan);
  log('  node scripts/setupDatabase.js              # Safe mode - create missing tables only');
  log('  node scripts/setupDatabase.js --force      # Drop and recreate all tables');
  log('  node scripts/setupDatabase.js --seed       # Create tables and add seed data');
  log('  node scripts/setupDatabase.js --force --seed  # Full reset with seed data\n');
}

async function createSeedData() {
  try {
    log('\n📦 Creating seed data...', colors.cyan);

    // Create admin user
    const adminUser = await User.create({
      email: 'admin@smartstocktrader.com',
      password_hash: 'Admin@2025!', // Will be hashed by the model hook
      first_name: 'Admin',
      last_name: 'User',
      role: 'admin',
      is_active: true,
      email_verified: true
    });
    log(`  ✓ Created admin user: ${adminUser.email}`, colors.green);

    // Create test user
    const testUser = await User.create({
      email: 'test@smartstocktrader.com',
      password_hash: 'Test@2025!', // Will be hashed by the model hook
      first_name: 'Test',
      last_name: 'User',
      role: 'user',
      is_active: true,
      email_verified: true
    });
    log(`  ✓ Created test user: ${testUser.email}`, colors.green);

    // Create licenses
    const license1 = await License.create({
      user_id: testUser.id,
      license_key: 'TEST-TRIAL-2025-ABCD1234',
      license_type: 'TRIAL',
      max_accounts: 2,
      status: 'active',
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
    });
    log(`  ✓ Created TRIAL license: ${license1.license_key}`, colors.green);

    const license2 = await License.create({
      user_id: testUser.id,
      license_key: 'TEST-PRO-2025-EFGH5678',
      license_type: 'PRO',
      max_accounts: 10,
      status: 'active',
      expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year from now
    });
    log(`  ✓ Created PRO license: ${license2.license_key}`, colors.green);

    // Create bot instances
    const bot1 = await BotInstance.create({
      user_id: testUser.id,
      license_id: license1.id,
      instance_name: 'EUR/USD Strategy Bot',
      mt4_account: '12345678',
      broker_name: 'ICMarkets',
      broker_server: 'ICMarkets-Demo01',
      status: 'running',
      is_live: false,
      started_at: new Date(),
      last_heartbeat: new Date()
    });
    log(`  ✓ Created bot instance: ${bot1.instance_name}`, colors.green);

    const bot2 = await BotInstance.create({
      user_id: testUser.id,
      license_id: license2.id,
      instance_name: 'GBP/USD Scalper',
      mt4_account: '87654321',
      broker_name: 'FXCM',
      broker_server: 'FXCM-Demo',
      status: 'stopped',
      is_live: false
    });
    log(`  ✓ Created bot instance: ${bot2.instance_name}`, colors.green);

    // Create sample trades
    const trade1 = await Trade.create({
      bot_instance_id: bot1.id,
      ticket_number: 'TK100001',
      symbol: 'EURUSD',
      trade_type: 'BUY',
      lot_size: 0.1,
      open_price: 1.0850,
      close_price: 1.0890,
      stop_loss: 1.0820,
      take_profit: 1.0900,
      profit: 40.00,
      profit_percentage: 0.37,
      status: 'closed',
      strategy_used: 'MA_CROSSOVER',
      opened_at: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
      closed_at: new Date(Date.now() - 1 * 60 * 60 * 1000) // 1 hour ago
    });
    log(`  ✓ Created winning trade: ${trade1.ticket_number} (+$${trade1.profit})`, colors.green);

    const trade2 = await Trade.create({
      bot_instance_id: bot1.id,
      ticket_number: 'TK100002',
      symbol: 'GBPUSD',
      trade_type: 'SELL',
      lot_size: 0.15,
      open_price: 1.2650,
      close_price: 1.2620,
      stop_loss: 1.2680,
      take_profit: 1.2600,
      profit: 45.00,
      profit_percentage: 0.24,
      status: 'closed',
      strategy_used: 'RSI_DIVERGENCE',
      opened_at: new Date(Date.now() - 4 * 60 * 60 * 1000),
      closed_at: new Date(Date.now() - 3 * 60 * 60 * 1000)
    });
    log(`  ✓ Created winning trade: ${trade2.ticket_number} (+$${trade2.profit})`, colors.green);

    const trade3 = await Trade.create({
      bot_instance_id: bot1.id,
      ticket_number: 'TK100003',
      symbol: 'EURUSD',
      trade_type: 'BUY',
      lot_size: 0.1,
      open_price: 1.0860,
      status: 'open',
      stop_loss: 1.0830,
      take_profit: 1.0910,
      strategy_used: 'BREAKOUT',
      opened_at: new Date()
    });
    log(`  ✓ Created open trade: ${trade3.ticket_number}`, colors.green);

    // Create bot logs
    await BotLog.create({
      bot_instance_id: bot1.id,
      log_level: 'INFO',
      category: 'STARTUP',
      message: 'Bot instance started successfully',
      metadata: { version: '1.0.0', mode: 'demo' }
    });

    await BotLog.create({
      bot_instance_id: bot1.id,
      log_level: 'INFO',
      category: 'TRADE',
      message: 'Trade opened: EURUSD BUY 0.1 lots',
      metadata: { ticket: 'TK100003', strategy: 'BREAKOUT' }
    });

    await BotLog.create({
      bot_instance_id: bot1.id,
      log_level: 'WARNING',
      category: 'SYSTEM',
      message: 'High spread detected on GBPUSD',
      metadata: { spread: 3.2, threshold: 2.5 }
    });

    log(`  ✓ Created sample bot logs`, colors.green);

    log('\n✅ Seed data created successfully!\n', colors.green);
    log('Test Credentials:', colors.cyan);
    log(`  Admin: admin@smartstocktrader.com / Admin@2025!`);
    log(`  User:  test@smartstocktrader.com / Test@2025!\n`);

  } catch (error) {
    log(`\n❌ Error creating seed data: ${error.message}`, colors.red);
    throw error;
  }
}

async function setupDatabase() {
  try {
    log('\n========================================', colors.bright);
    log('   DATABASE SETUP SCRIPT', colors.bright);
    log('========================================\n', colors.bright);

    if (helpRequested) {
      showHelp();
      process.exit(0);
    }

    // Show configuration
    log('Configuration:', colors.cyan);
    log(`  Database: ${process.env.DB_NAME}`);
    log(`  Host: ${process.env.DB_HOST}:${process.env.DB_PORT || 5432}`);
    log(`  User: ${process.env.DB_USER}`);
    log(`  Mode: ${forceRecreate ? 'FORCE RECREATE (⚠️  ALL DATA WILL BE LOST)' : 'Safe (existing tables preserved)'}`,
        forceRecreate ? colors.red : colors.green);
    log(`  Seed Data: ${seedData ? 'Yes' : 'No'}\n`);

    // Confirmation prompt for force mode
    if (forceRecreate) {
      log('⚠️  WARNING: You are about to DROP ALL TABLES and recreate them!', colors.yellow);
      log('⚠️  ALL DATA WILL BE PERMANENTLY LOST!', colors.yellow);
      log('\nPress Ctrl+C now to cancel, or wait 5 seconds to continue...\n', colors.yellow);

      // Wait 5 seconds
      await new Promise(resolve => setTimeout(resolve, 5000));
    }

    // Step 1: Test database connection
    log('📡 Step 1: Testing database connection...', colors.cyan);
    const isConnected = await testConnection();

    if (!isConnected) {
      log('\n❌ Database connection failed. Please check your .env configuration.', colors.red);
      log('\nRequired environment variables:', colors.yellow);
      log('  DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT\n');
      process.exit(1);
    }

    // Step 2: Create/sync tables
    log('\n📋 Step 2: Setting up database tables...', colors.cyan);
    log(`  Creating/updating: Users, Licenses, BotInstances, Trades, BotLogs\n`);

    const syncOptions = {
      force: forceRecreate,
      alter: !forceRecreate // Use alter mode when not forcing
    };

    await syncDatabase(syncOptions);

    // List all tables created
    log('\n✅ Tables created successfully:', colors.green);
    const models = [
      { name: 'Users', model: User },
      { name: 'Licenses', model: License },
      { name: 'BotInstances', model: BotInstance },
      { name: 'Trades', model: Trade },
      { name: 'BotLogs', model: BotLog }
    ];

    for (const { name, model } of models) {
      const count = await model.count();
      log(`  ✓ ${name.padEnd(20)} (${count} records)`, colors.green);
    }

    // Step 3: Create seed data if requested
    if (seedData) {
      await createSeedData();
    }

    // Final summary
    log('\n========================================', colors.bright);
    log('   ✅ DATABASE SETUP COMPLETE!', colors.green);
    log('========================================\n', colors.bright);

    if (!seedData) {
      log('💡 Tip: Run with --seed flag to add sample data:', colors.cyan);
      log('   node scripts/setupDatabase.js --seed\n');
    }

  } catch (error) {
    log('\n========================================', colors.bright);
    log('   ❌ DATABASE SETUP FAILED', colors.red);
    log('========================================\n', colors.bright);
    log(`Error: ${error.message}`, colors.red);

    if (error.stack) {
      log('\nStack trace:', colors.yellow);
      log(error.stack);
    }

    process.exit(1);
  } finally {
    // Close database connection
    await sequelize.close();
    log('Database connection closed.\n', colors.cyan);
  }
}

// Run the setup
setupDatabase();
