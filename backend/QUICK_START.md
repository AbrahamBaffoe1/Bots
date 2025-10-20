# Quick Start Guide - Smart Stock Trader Backend

## Prerequisites

✅ PostgreSQL installed and running
✅ Node.js (v16+) installed
✅ Database created: `smartstocktrader`

## Step 1: Install Dependencies

```bash
cd backend
npm install
```

## Step 2: Configure Environment

Create `.env` file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartstocktrader
DB_USER=postgres
DB_PASSWORD=your_postgres_password

# JWT
JWT_SECRET=your_secret_key_min_32_characters_long
JWT_EXPIRE=7d

# Email (Already configured)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=official.abraham.baffoe@gmail.com
SMTP_PASS=efpdhwojopypwamz
SMTP_FROM=official.abraham.baffoe@gmail.com
SMTP_FROM_NAME=Smart Stock Trader
```

## Step 3: Setup Database

### Option 1: Automatic Setup (Recommended)

```bash
./setup-database.sh
```

### Option 2: Manual Setup

```bash
# Create database (if not exists)
createdb smartstocktrader

# Run SQL script
psql -d smartstocktrader -f database-setup.sql
```

### Option 3: Using psql directly

```bash
# Login to PostgreSQL
psql -U postgres

# Inside psql:
\c smartstocktrader
\i database-setup.sql
```

## Step 4: Verify Database Setup

```bash
psql -d smartstocktrader -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
"
```

You should see these tables:
- users
- licenses
- subscriptions
- bot_instances
- bot_settings
- trades
- trade_history
- performance_metrics
- bot_logs
- notifications

## Step 5: Start the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

## Step 6: Test the API

### Health Check

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2025-01-20T10:00:00.000Z"
}
```

### Register User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123"
  }'
```

Save the token from response!

### Get User Info (with token)

```bash
curl -X GET http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

## Troubleshooting

### Database Connection Failed

**Error:** `Unable to connect to database`

**Solution:**
1. Check PostgreSQL is running: `pg_isready`
2. Verify credentials in `.env`
3. Test connection: `psql -U postgres -d smartstocktrader`

### Port Already in Use

**Error:** `Port 5000 is already in use`

**Solution:**
1. Change PORT in `.env` to different port (e.g., 5001)
2. Or kill process using port 5000: `lsof -ti:5000 | xargs kill`

### Permission Denied

**Error:** `permission denied for database`

**Solution:**
```sql
GRANT ALL PRIVILEGES ON DATABASE smartstocktrader TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;
```

### JWT Secret Error

**Error:** `JWT secret is not defined`

**Solution:**
Ensure `.env` has `JWT_SECRET` with at least 32 characters:
```env
JWT_SECRET=your_super_secret_key_at_least_32_characters_long
```

## Database Reset (Caution!)

If you need to reset the database:

```bash
# Drop database
dropdb smartstocktrader

# Recreate
createdb smartstocktrader

# Run setup again
./setup-database.sh
```

Or use the script:
```bash
./setup-database.sh
# Answer "yes" when prompted to drop existing database
```

## Next Steps

1. ✅ **API is running** → Test all endpoints
2. 📱 **Build frontend** → Connect to API
3. 🤖 **Configure MT4** → Connect trading bot
4. 📊 **Monitor dashboard** → View trades and profits

## Useful Commands

```bash
# Check database tables
psql -d smartstocktrader -c "\dt"

# Check database size
psql -d smartstocktrader -c "
SELECT pg_size_pretty(pg_database_size('smartstocktrader'));
"

# View recent logs
psql -d smartstocktrader -c "
SELECT * FROM bot_logs ORDER BY created_at DESC LIMIT 10;
"

# Count trades
psql -d smartstocktrader -c "
SELECT status, COUNT(*) FROM trades GROUP BY status;
"

# View active bots
psql -d smartstocktrader -c "
SELECT instance_name, status, last_heartbeat
FROM bot_instances
WHERE status = 'running';
"
```

## Email Testing

The backend is configured with Gmail SMTP. To test:

```javascript
// Add this endpoint temporarily for testing
app.post('/api/test-email', async (req, res) => {
  const nodemailer = require('nodemailer');

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  await transporter.sendMail({
    from: `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_FROM}>`,
    to: req.body.email,
    subject: 'Test Email',
    text: 'This is a test email from Smart Stock Trader!'
  });

  res.json({ success: true });
});
```

## API Documentation

Full API documentation: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

## Support

- **Documentation:** See `README.md` and `API_DOCUMENTATION.md`
- **Database Schema:** See `DATABASE_SCHEMA.md`
- **Issues:** Check troubleshooting section above

---

🎉 **You're all set!** The backend is ready to handle user authentication, bot management, and trade tracking!
