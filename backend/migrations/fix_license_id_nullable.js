/**
 * Migration: Make license_id nullable in bot_instances table
 *
 * This allows bot instances to be created from MT4 EA without a license,
 * while dashboard activations still require a license.
 */

const { sequelize } = require('../src/config/database');

async function migrate() {
  try {
    console.log('Starting migration: Make license_id nullable...');

    await sequelize.query(`
      ALTER TABLE bot_instances
      ALTER COLUMN license_id DROP NOT NULL;
    `);

    console.log('✓ Migration completed successfully');
    console.log('  - bot_instances.license_id is now nullable');

    process.exit(0);
  } catch (error) {
    console.error('✗ Migration failed:', error.message);
    process.exit(1);
  }
}

migrate();
