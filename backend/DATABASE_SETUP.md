# Database Setup Guide

## Quick Start

The database has been successfully set up with all tables and seed data!

## Database Structure

### Tables Created

1. **users** - User accounts (admin, reseller, regular users)
2. **licenses** - License keys and activation management
3. **bot_instances** - MT4 trading bot instances
4. **trades** - Trade history and analytics
5. **bot_logs** - System logs and debugging information

## Available Commands

```bash
# Create tables (safe mode - preserves existing data)
npm run db:setup

# Drop and recreate all tables (⚠️ DESTROYS ALL DATA)
npm run db:setup:force

# Create tables with sample seed data
npm run db:setup:seed

# Full reset - drop everything and recreate with seed data
npm run db:reset
```

## Test Credentials

### Admin Account
- **Email:** admin@smartstocktrader.com
- **Password:** Admin@2025!
- **Role:** admin

### Test User Account
- **Email:** test@smartstocktrader.com
- **Password:** Test@2025!
- **Role:** user

## Sample Data Included

### Licenses
- **TRIAL License:** TEST-TRIAL-2025-ABCD1234 (2 accounts, 30 days)
- **PRO License:** TEST-PRO-2025-EFGH5678 (10 accounts, 1 year)

### Bot Instances
1. EUR/USD Strategy Bot (Running)
2. GBP/USD Scalper (Stopped)

### Sample Trades
- 2 closed winning trades
- 1 open trade
- Sample bot logs for debugging

## Database Schema

### Users Table
```sql
- id (UUID, Primary Key)
- email (String, Unique)
- password_hash (String)
- first_name (String)
- last_name (String)
- role (Enum: user, admin, reseller)
- is_active (Boolean)
- email_verified (Boolean)
- last_login (DateTime)
- created_at, updated_at (Timestamps)
```

### Licenses Table
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key -> users)
- license_key (String, Unique)
- license_type (Enum: TRIAL, BASIC, PRO, ENTERPRISE)
- max_accounts (Integer)
- status (Enum: active, suspended, expired, revoked)
- issued_at (DateTime)
- expires_at (DateTime)
- hardware_id (String)
- last_validated (DateTime)
- activation_count (Integer)
- created_at, updated_at (Timestamps)
```

### Bot Instances Table
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key -> users)
- license_id (UUID, Foreign Key -> licenses)
- instance_name (String)
- mt4_account (String)
- broker_name (String)
- broker_server (String)
- status (Enum: running, stopped, paused, error)
- is_live (Boolean)
- last_heartbeat (DateTime)
- started_at (DateTime)
- stopped_at (DateTime)
- created_at, updated_at (Timestamps)
```

### Trades Table
```sql
- id (UUID, Primary Key)
- bot_instance_id (UUID, Foreign Key -> bot_instances)
- ticket_number (String)
- symbol (String)
- trade_type (Enum: BUY, SELL)
- lot_size (Decimal)
- open_price (Decimal)
- close_price (Decimal)
- stop_loss (Decimal)
- take_profit (Decimal)
- commission (Decimal)
- swap (Decimal)
- profit (Decimal)
- profit_percentage (Decimal)
- status (Enum: open, closed, cancelled)
- strategy_used (String)
- opened_at (DateTime)
- closed_at (DateTime)
- duration_seconds (Integer)
- created_at, updated_at (Timestamps)
```

### Bot Logs Table
```sql
- id (UUID, Primary Key)
- bot_instance_id (UUID, Foreign Key -> bot_instances)
- log_level (Enum: INFO, WARNING, ERROR, DEBUG)
- category (String)
- message (Text)
- metadata (JSONB)
- created_at (Timestamp)
```

## Database Connection

The application uses Sequelize ORM to connect to PostgreSQL.

### Configuration (.env)
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartstocktrader
DB_USER=postgres
DB_PASSWORD=admin
```

## Manual Database Operations

### Connect to Database
```bash
PGPASSWORD=admin psql -U postgres -h localhost -d smartstocktrader
```

### Common SQL Queries

```sql
-- View all users
SELECT email, role, is_active FROM users;

-- View all licenses
SELECT license_key, license_type, status, expires_at FROM licenses;

-- View all bot instances
SELECT instance_name, status, mt4_account, broker_name FROM bot_instances;

-- View all trades
SELECT ticket_number, symbol, trade_type, profit, status FROM trades;

-- View recent logs
SELECT log_level, category, message, created_at FROM bot_logs
ORDER BY created_at DESC LIMIT 10;
```

## Resetting the Database

If you need to start fresh:

```bash
# Option 1: Using npm script (recommended)
npm run db:reset

# Option 2: Manual reset
PGPASSWORD=admin psql -U postgres -h localhost -c "DROP DATABASE smartstocktrader;"
PGPASSWORD=admin psql -U postgres -h localhost -c "CREATE DATABASE smartstocktrader;"
npm run db:setup:seed
```

## Troubleshooting

### Connection Failed
- Ensure PostgreSQL is running: `brew services list` (macOS) or `sudo service postgresql status` (Linux)
- Check credentials in .env file
- Verify database exists: `PGPASSWORD=admin psql -U postgres -h localhost -l`

### Tables Not Created
- Check server.js logs for Sequelize errors
- Ensure models are properly loaded
- Try force mode: `npm run db:setup:force`

### Migration Issues
- Sequelize handles migrations automatically
- For custom migrations, use: `npm run migrate`

## Production Deployment

When deploying to production:

1. Update .env with production database credentials
2. Set `NODE_ENV=production`
3. Use `npm run db:setup` (NOT --force to avoid data loss)
4. Never commit .env file to version control
5. Use environment variables in hosting platform
