# Smart Stock Trader Database Schema

## Database Design Philosophy
- **Normalized structure**: Minimize data redundancy
- **Clear relationships**: Well-defined foreign keys and constraints
- **Scalability**: Designed to handle millions of trades
- **Performance**: Indexed columns for fast queries
- **Data integrity**: Cascade operations and constraints

## Entity Relationship Diagram

```
Users (1) -----> (N) Licenses
Users (1) -----> (N) BotInstances
Users (1) -----> (N) Subscriptions
BotInstances (1) -----> (N) Trades
BotInstances (1) -----> (N) PerformanceMetrics
BotInstances (1) -----> (N) BotLogs
BotInstances (1) -----> (1) BotSettings
Trades (1) -----> (N) TradeHistory
```

## Tables

### 1. Users
Primary user account table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique user identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email |
| password_hash | VARCHAR(255) | NOT NULL | Bcrypt hashed password |
| first_name | VARCHAR(100) | NOT NULL | User first name |
| last_name | VARCHAR(100) | NOT NULL | User last name |
| role | ENUM | DEFAULT 'user' | user, admin, reseller |
| is_active | BOOLEAN | DEFAULT true | Account active status |
| email_verified | BOOLEAN | DEFAULT false | Email verification status |
| last_login | TIMESTAMP | NULL | Last login timestamp |
| created_at | TIMESTAMP | DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- email (UNIQUE)
- created_at
- role

---

### 2. Licenses
License key management

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | License identifier |
| user_id | UUID | FOREIGN KEY -> Users.id | Owner user ID |
| license_key | VARCHAR(100) | UNIQUE, NOT NULL | Encrypted license key |
| license_type | ENUM | NOT NULL | TRIAL, BASIC, PRO, ENTERPRISE |
| max_accounts | INTEGER | NOT NULL | Max MT4 accounts allowed |
| status | ENUM | DEFAULT 'active' | active, suspended, expired, revoked |
| issued_at | TIMESTAMP | DEFAULT NOW() | Issue timestamp |
| expires_at | TIMESTAMP | NULL | Expiration (NULL = lifetime) |
| hardware_id | VARCHAR(255) | NULL | Locked hardware ID |
| last_validated | TIMESTAMP | NULL | Last validation check |
| activation_count | INTEGER | DEFAULT 0 | Number of activations |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- license_key (UNIQUE)
- user_id
- status
- expires_at

**Relationships:**
- `user_id` FOREIGN KEY REFERENCES Users(id) ON DELETE CASCADE

---

### 3. Subscriptions
Subscription management for recurring billing

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Subscription ID |
| user_id | UUID | FOREIGN KEY -> Users.id | Subscriber user ID |
| plan_type | ENUM | NOT NULL | TRIAL, BASIC, PRO, ENTERPRISE |
| status | ENUM | DEFAULT 'active' | active, cancelled, expired, suspended |
| payment_method | VARCHAR(50) | NULL | Payment method used |
| amount | DECIMAL(10,2) | NOT NULL | Subscription amount |
| currency | VARCHAR(3) | DEFAULT 'USD' | Currency code |
| billing_cycle | ENUM | NOT NULL | monthly, yearly, lifetime |
| current_period_start | TIMESTAMP | NOT NULL | Current billing start |
| current_period_end | TIMESTAMP | NOT NULL | Current billing end |
| cancelled_at | TIMESTAMP | NULL | Cancellation timestamp |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- user_id
- status
- current_period_end

**Relationships:**
- `user_id` FOREIGN KEY REFERENCES Users(id) ON DELETE CASCADE

---

### 4. BotInstances
Individual bot instances running on MT4

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Bot instance ID |
| user_id | UUID | FOREIGN KEY -> Users.id | Owner user ID |
| license_id | UUID | FOREIGN KEY -> Licenses.id | Associated license |
| instance_name | VARCHAR(100) | NOT NULL | User-defined name |
| mt4_account | VARCHAR(50) | NOT NULL | MT4 account number |
| broker_name | VARCHAR(100) | NOT NULL | Broker name |
| broker_server | VARCHAR(100) | NULL | Broker server |
| status | ENUM | DEFAULT 'stopped' | running, stopped, paused, error |
| is_live | BOOLEAN | DEFAULT false | Live or demo account |
| last_heartbeat | TIMESTAMP | NULL | Last activity ping |
| started_at | TIMESTAMP | NULL | Bot start time |
| stopped_at | TIMESTAMP | NULL | Bot stop time |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- user_id
- license_id
- status
- last_heartbeat

**Relationships:**
- `user_id` FOREIGN KEY REFERENCES Users(id) ON DELETE CASCADE
- `license_id` FOREIGN KEY REFERENCES Licenses(id) ON DELETE RESTRICT

---

### 5. BotSettings
Bot configuration per instance

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Settings ID |
| bot_instance_id | UUID | FOREIGN KEY -> BotInstances.id | Bot instance |
| risk_percentage | DECIMAL(5,2) | DEFAULT 2.0 | Risk per trade (%) |
| max_daily_loss | DECIMAL(10,2) | DEFAULT 100.0 | Max daily loss limit |
| max_trades_per_day | INTEGER | DEFAULT 10 | Max trades per day |
| trading_pairs | TEXT[] | NOT NULL | Allowed trading pairs |
| trading_sessions | JSONB | NOT NULL | Trading time windows |
| strategies_enabled | JSONB | NOT NULL | Active strategies config |
| stop_loss_pips | INTEGER | DEFAULT 50 | Stop loss in pips |
| take_profit_pips | INTEGER | DEFAULT 100 | Take profit in pips |
| trailing_stop | BOOLEAN | DEFAULT false | Use trailing stop |
| auto_trade | BOOLEAN | DEFAULT true | Auto-trading enabled |
| notifications_enabled | BOOLEAN | DEFAULT true | Enable notifications |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- bot_instance_id (UNIQUE)

**Relationships:**
- `bot_instance_id` FOREIGN KEY REFERENCES BotInstances(id) ON DELETE CASCADE

---

### 6. Trades
Individual trade records

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Trade ID |
| bot_instance_id | UUID | FOREIGN KEY -> BotInstances.id | Bot instance |
| ticket_number | VARCHAR(50) | NOT NULL | MT4 ticket number |
| symbol | VARCHAR(20) | NOT NULL | Trading pair (EUR/USD) |
| trade_type | ENUM | NOT NULL | BUY, SELL |
| lot_size | DECIMAL(10,2) | NOT NULL | Position size |
| open_price | DECIMAL(15,5) | NOT NULL | Entry price |
| close_price | DECIMAL(15,5) | NULL | Exit price |
| stop_loss | DECIMAL(15,5) | NULL | SL price |
| take_profit | DECIMAL(15,5) | NULL | TP price |
| commission | DECIMAL(10,2) | DEFAULT 0 | Trading commission |
| swap | DECIMAL(10,2) | DEFAULT 0 | Swap/rollover fee |
| profit | DECIMAL(10,2) | NULL | Net profit/loss |
| profit_percentage | DECIMAL(10,4) | NULL | P&L percentage |
| status | ENUM | DEFAULT 'open' | open, closed, cancelled |
| strategy_used | VARCHAR(50) | NULL | Strategy name |
| opened_at | TIMESTAMP | DEFAULT NOW() | Trade open time |
| closed_at | TIMESTAMP | NULL | Trade close time |
| duration_seconds | INTEGER | NULL | Trade duration |
| created_at | TIMESTAMP | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Indexes:**
- bot_instance_id
- status
- opened_at
- closed_at
- symbol

**Relationships:**
- `bot_instance_id` FOREIGN KEY REFERENCES BotInstances(id) ON DELETE CASCADE

---

### 7. TradeHistory
Historical price updates for open trades

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | History record ID |
| trade_id | UUID | FOREIGN KEY -> Trades.id | Parent trade |
| current_price | DECIMAL(15,5) | NOT NULL | Price at this moment |
| unrealized_profit | DECIMAL(10,2) | NOT NULL | Floating P&L |
| recorded_at | TIMESTAMP | DEFAULT NOW() | Timestamp |

**Indexes:**
- trade_id
- recorded_at

**Relationships:**
- `trade_id` FOREIGN KEY REFERENCES Trades(id) ON DELETE CASCADE

---

### 8. PerformanceMetrics
Daily/hourly performance snapshots

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Metric ID |
| bot_instance_id | UUID | FOREIGN KEY -> BotInstances.id | Bot instance |
| metric_type | ENUM | NOT NULL | hourly, daily, weekly, monthly |
| period_start | TIMESTAMP | NOT NULL | Period start |
| period_end | TIMESTAMP | NOT NULL | Period end |
| total_trades | INTEGER | DEFAULT 0 | Total trades executed |
| winning_trades | INTEGER | DEFAULT 0 | Winning trades |
| losing_trades | INTEGER | DEFAULT 0 | Losing trades |
| gross_profit | DECIMAL(15,2) | DEFAULT 0 | Total profit |
| gross_loss | DECIMAL(15,2) | DEFAULT 0 | Total loss |
| net_profit | DECIMAL(15,2) | DEFAULT 0 | Net P&L |
| win_rate | DECIMAL(5,2) | DEFAULT 0 | Win percentage |
| profit_factor | DECIMAL(10,4) | DEFAULT 0 | Profit factor ratio |
| max_drawdown | DECIMAL(10,2) | DEFAULT 0 | Max drawdown |
| avg_win | DECIMAL(10,2) | DEFAULT 0 | Average win |
| avg_loss | DECIMAL(10,2) | DEFAULT 0 | Average loss |
| largest_win | DECIMAL(10,2) | DEFAULT 0 | Largest win |
| largest_loss | DECIMAL(10,2) | DEFAULT 0 | Largest loss |
| sharpe_ratio | DECIMAL(10,4) | NULL | Sharpe ratio |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |

**Indexes:**
- bot_instance_id
- metric_type
- period_start
- period_end

**Relationships:**
- `bot_instance_id` FOREIGN KEY REFERENCES BotInstances(id) ON DELETE CASCADE

---

### 9. BotLogs
System and trading logs

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Log ID |
| bot_instance_id | UUID | FOREIGN KEY -> BotInstances.id | Bot instance |
| log_level | ENUM | NOT NULL | INFO, WARNING, ERROR, DEBUG |
| category | VARCHAR(50) | NOT NULL | TRADE, SYSTEM, STRATEGY, ERROR |
| message | TEXT | NOT NULL | Log message |
| metadata | JSONB | NULL | Additional context |
| created_at | TIMESTAMP | DEFAULT NOW() | Log timestamp |

**Indexes:**
- bot_instance_id
- log_level
- category
- created_at

**Relationships:**
- `bot_instance_id` FOREIGN KEY REFERENCES BotInstances(id) ON DELETE CASCADE

---

### 10. Notifications
User notifications

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Notification ID |
| user_id | UUID | FOREIGN KEY -> Users.id | Recipient user |
| type | ENUM | NOT NULL | TRADE, ALERT, SYSTEM, ACCOUNT |
| title | VARCHAR(200) | NOT NULL | Notification title |
| message | TEXT | NOT NULL | Notification message |
| is_read | BOOLEAN | DEFAULT false | Read status |
| metadata | JSONB | NULL | Additional data |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |

**Indexes:**
- user_id
- is_read
- created_at

**Relationships:**
- `user_id` FOREIGN KEY REFERENCES Users(id) ON DELETE CASCADE

---

## Database Constraints

### Cascade Rules
- **Users deleted**: All related records cascade delete (licenses, subscriptions, bots, trades, logs)
- **License deleted**: Bot instances are restricted (cannot delete active license)
- **Bot instance deleted**: All trades, logs, settings cascade delete
- **Trade deleted**: All trade history cascade delete

### Check Constraints
- `Users.email` must be valid email format
- `Licenses.max_accounts` must be > 0
- `BotSettings.risk_percentage` must be between 0.1 and 10
- `Trades.lot_size` must be > 0
- `PerformanceMetrics.win_rate` must be between 0 and 100

### Unique Constraints
- `Users.email` must be unique
- `Licenses.license_key` must be unique
- `BotSettings.bot_instance_id` must be unique (one-to-one)

## Performance Optimization

### Indexes
All foreign keys are indexed automatically. Additional indexes:
- Timestamp columns (`created_at`, `updated_at`, `opened_at`, `closed_at`)
- Status fields for quick filtering
- Composite indexes for common queries

### Partitioning Strategy
For high-volume tables:
- **Trades**: Partition by `opened_at` (monthly)
- **BotLogs**: Partition by `created_at` (monthly)
- **TradeHistory**: Partition by `recorded_at` (daily)

### Data Retention
- **BotLogs**: Keep 90 days, archive older
- **TradeHistory**: Keep 365 days, archive older
- **Notifications**: Keep 30 days, delete older

## Security Considerations
- All passwords hashed with bcrypt (cost factor 12)
- JWT tokens for authentication (7-day expiry)
- License keys encrypted with AES-256
- API rate limiting per user
- SQL injection protection via parameterized queries
- XSS protection via input sanitization
