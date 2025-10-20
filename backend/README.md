# Smart Stock Trader Backend API

Professional-grade REST API for managing trading bots, user authentication, and real-time trade tracking.

## Features

- **User Authentication** - Secure JWT-based authentication
- **Bot Management** - Create, start, stop, and monitor trading bots
- **Trade Tracking** - Real-time trade logging and analytics
- **Performance Metrics** - Comprehensive statistics and profit tracking
- **License Management** - Secure license key validation
- **Real-time Logs** - Detailed system and trading logs
- **RESTful API** - Clean, documented endpoints
- **PostgreSQL Database** - Robust relational database with proper relationships
- **Rate Limiting** - API protection against abuse
- **Security** - Helmet, CORS, bcrypt password hashing

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL
- **ORM:** Sequelize
- **Authentication:** JWT (jsonwebtoken)
- **Security:** Helmet, bcryptjs, express-rate-limit
- **Validation:** express-validator

## Prerequisites

- Node.js (v16 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

## Installation

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Database Setup

**Create PostgreSQL database:**

```sql
CREATE DATABASE smartstocktrader;
```

**Create user and grant permissions:**

```sql
CREATE USER your_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE smartstocktrader TO your_user;
```

### 3. Environment Configuration

Create `.env` file from example:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Server
NODE_ENV=development
PORT=5000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartstocktrader
DB_USER=your_user
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_secret_key_min_32_characters
JWT_EXPIRE=7d

# Frontend
FRONTEND_URL=http://localhost:3000
```

### 4. Initialize Database

```bash
npm run migrate
```

This will:
- Create all database tables
- Set up relationships
- Create indexes

## Running the Server

### Development Mode

```bash
npm run dev
```

Server will run on `http://localhost:5000` with hot-reload.

### Production Mode

```bash
npm start
```

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── database.js         # Database configuration
│   ├── controllers/
│   │   ├── authController.js   # Authentication logic
│   │   ├── botController.js    # Bot management logic
│   │   └── tradesController.js # Trade management logic
│   ├── middleware/
│   │   └── auth.js             # JWT authentication middleware
│   ├── models/
│   │   ├── User.js             # User model
│   │   ├── License.js          # License model
│   │   ├── BotInstance.js      # Bot instance model
│   │   ├── Trade.js            # Trade model
│   │   ├── BotLog.js           # Log model
│   │   └── index.js            # Model associations
│   ├── routes/
│   │   ├── auth.js             # Auth routes
│   │   ├── bots.js             # Bot routes
│   │   └── trades.js           # Trade routes
│   └── server.js               # Express server setup
├── .env.example                # Environment template
├── package.json                # Dependencies
├── API_DOCUMENTATION.md        # Complete API docs
├── DATABASE_SCHEMA.md          # Database design
└── README.md                   # This file
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile
- `PUT /api/auth/password` - Change password

### Bot Management
- `GET /api/bots` - Get all bots
- `GET /api/bots/:id` - Get single bot
- `POST /api/bots` - Create bot instance
- `POST /api/bots/:id/start` - Start bot
- `POST /api/bots/:id/stop` - Stop bot
- `POST /api/bots/:id/heartbeat` - Update heartbeat
- `GET /api/bots/:id/stats` - Get bot statistics
- `GET /api/bots/:id/logs` - Get bot logs
- `DELETE /api/bots/:id` - Delete bot

### Trade Management
- `GET /api/trades/bot/:botId` - Get trades for bot
- `GET /api/trades/:id` - Get single trade
- `POST /api/trades/bot/:botId` - Create trade
- `PUT /api/trades/:id` - Update trade
- `GET /api/trades/history` - Get trade history

See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for detailed documentation.

## Database Schema

Comprehensive database design with:
- **10 core tables** (Users, Licenses, BotInstances, Trades, etc.)
- **Proper relationships** with foreign keys
- **Cascade operations** for data integrity
- **Indexed columns** for performance
- **Check constraints** for validation

See [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) for complete schema.

## Security

### Authentication
- Passwords hashed with bcrypt (cost factor 12)
- JWT tokens with configurable expiration
- Protected routes require valid token

### API Protection
- Helmet for security headers
- CORS configured for specific origins
- Rate limiting (100 requests per 15 minutes)
- Input validation with express-validator

### Database Security
- Parameterized queries (SQL injection protection)
- Password fields excluded from JSON responses
- Soft deletes for sensitive data

## Testing API

### Using cURL

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123",
    "first_name": "John",
    "last_name": "Doe"
  }'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123"
  }'

# Get bots (with token)
curl -X GET http://localhost:5000/api/bots \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Using Postman

1. Import API endpoints from documentation
2. Set Authorization header with JWT token
3. Test all endpoints

## Development

### Database Migrations

**Reset database (caution: deletes all data):**

```bash
# Drop all tables
npm run db:reset

# Recreate tables
npm run migrate
```

**Seed sample data:**

```bash
npm run seed
```

### Debugging

Enable detailed logging:

```env
NODE_ENV=development
```

This will:
- Log all SQL queries
- Show detailed error stacks
- Enable nodemon hot-reload

## Production Deployment

### 1. Environment Setup

```env
NODE_ENV=production
DB_HOST=your_production_db
JWT_SECRET=strong_random_secret_min_32_chars
FRONTEND_URL=https://yourdomain.com
```

### 2. Security Checklist

- [ ] Change all default passwords
- [ ] Use strong JWT secret (32+ characters)
- [ ] Enable HTTPS only
- [ ] Configure CORS for production domain
- [ ] Set up PostgreSQL with SSL
- [ ] Enable database backups
- [ ] Configure firewall rules
- [ ] Set up monitoring and logging
- [ ] Use environment variables (never hardcode secrets)

### 3. Process Management

Use PM2 for production:

```bash
npm install -g pm2
pm2 start src/server.js --name "trading-api"
pm2 save
pm2 startup
```

### 4. Database Optimization

```sql
-- Enable query optimization
ANALYZE;

-- Create additional indexes for performance
CREATE INDEX idx_trades_opened_at_symbol ON trades(opened_at, symbol);
CREATE INDEX idx_bot_logs_created_at_level ON bot_logs(created_at, log_level);
```

## Monitoring

### Health Check

```bash
curl http://localhost:5000/health
```

Response:
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2025-01-20T10:00:00.000Z"
}
```

### Database Connection

Check database connectivity in logs:
```
✓ Database connection established successfully
✓ Database synchronized successfully
```

## Troubleshooting

### Database Connection Errors

```
✗ Unable to connect to database
```

**Solutions:**
1. Verify PostgreSQL is running: `systemctl status postgresql`
2. Check credentials in `.env`
3. Ensure database exists: `psql -l`
4. Check firewall: `sudo ufw status`

### Authentication Errors

```
401 Unauthorized
```

**Solutions:**
1. Verify JWT token is included in header
2. Check token hasn't expired
3. Ensure JWT_SECRET matches between requests

### Rate Limit Errors

```
429 Too Many Requests
```

**Solutions:**
1. Wait for rate limit window to reset (15 minutes)
2. Adjust rate limits in `.env`
3. Implement request queuing on client

## License

Proprietary - All rights reserved

## Support

For technical support or questions:
- Email: support@smartstocktrader.com
- Documentation: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- Database Schema: [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)

## Changelog

### v1.0.0 (2025-01-20)
- Initial release
- User authentication system
- Bot management API
- Trade tracking system
- Real-time logging
- Comprehensive database schema
- API documentation
