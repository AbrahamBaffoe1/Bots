# Smart Stock Trader - Dashboard Integration Setup Guide

## 🎯 Overview

This guide explains how to set up the complete dashboard integration system that allows your MetaTrader EA to send real-time data to your backend API and display it on your web dashboard.

## 📦 What Was Implemented

### Production-Grade Modules Created:

1. **SST_WebAPI.mqh** - Full-featured HTTP/REST API client
   - GET, POST, PUT, PATCH, DELETE methods
   - Automatic retry logic (3 attempts)
   - Request/response error handling
   - Statistics tracking

2. **SST_JSON.mqh** - JSON serialization/deserialization
   - Production-ready JSON builder
   - JSON parser for API responses
   - Specialized builders for trades, performance, heartbeats

3. **SST_APIConfig.mqh** - Centralized configuration management
   - API credentials & settings
   - URL builders (DRY principle)
   - Validation & error checking
   - Dynamic configuration updates

4. **SST_Logger.mqh** - Professional logging system
   - Multiple log levels (DEBUG, INFO, WARN, ERROR, CRITICAL)
   - Console, file, and remote logging
   - Categorized logging (TRADE, API, PERFORMANCE, SYSTEM, etc.)
   - Log buffering for batch sending

5. **SST_BotAuth.mqh** - Authentication & bot registration
   - User login with JWT tokens
   - Automatic bot registration
   - Token expiry handling
   - Smart get-or-create bot logic

6. **SST_TradeSync.mqh** - Trade synchronization
   - Sends trade opens to backend
   - Sends trade closes with P/L
   - Auto-sync existing trades on startup
   - Retry failed syncs
   - Sync tracking & statistics

7. **SST_Heartbeat.mqh** - Heartbeat & monitoring
   - Periodic heartbeat signals (configurable interval)
   - Sends account status (balance, equity, margin, open positions)
   - Online/offline detection
   - Consecutive failure tracking

8. **SST_PerformanceSync.mqh** - Performance metrics synchronization
   - Calculates comprehensive metrics from trade history
   - Win rate, profit factor, max drawdown, Sharpe ratio
   - Periodic sync (configurable interval)
   - Daily performance snapshots

---

## ⚙️ Configuration

### Step 1: Enable WebRequest URLs in MetaTrader

**CRITICAL**: MT4/MT5 requires you to whitelist URLs that the EA can access.

1. Open MetaTrader
2. Go to **Tools → Options → Expert Advisors**
3. Check ✅ **Allow WebRequest for listed URLs**
4. Add these URLs (one per line):
   ```
   http://localhost:5000
   https://yourbackend.com
   ```
   Replace `https://yourbackend.com` with your actual backend URL

5. Click **OK**

**Screenshot Reference:**
```
┌──────────────────────────────────────┐
│ Expert Advisors Settings             │
├──────────────────────────────────────┤
│ ☑ Allow WebRequest for listed URLs: │
│                                      │
│ http://localhost:5000                │
│ https://yourbackend.com              │
│                                      │
└──────────────────────────────────────┘
```

---

### Step 2: Configure EA Parameters

When you attach the EA to a chart, configure these parameters:

#### Backend API Integration:
```
API_BaseURL          = "http://localhost:5000"  // Your backend URL
API_UserEmail        = "your@email.com"         // User account email
API_UserPassword     = "yourpassword"           // User account password
API_EnableSync       = true                     // Master switch
API_EnableTradeSync  = true                     // Sync trades
API_EnableHeartbeat  = true                     // Send heartbeats
API_EnablePerfSync   = true                     // Sync performance
API_HeartbeatInterval = 60                      // Heartbeat every 60 seconds
API_PerfSyncInterval  = 300                     // Performance sync every 5 minutes
```

#### Example for Production:
```
API_BaseURL          = "https://api.smartstocktrader.com"
API_UserEmail        = "trader@example.com"
API_UserPassword     = "MySecurePassword123!"
API_EnableSync       = true
API_EnableTradeSync  = true
API_EnableHeartbeat  = true
API_EnablePerfSync   = true
API_HeartbeatInterval = 60
API_PerfSyncInterval  = 300
```

---

## 🚀 How It Works

### Startup Sequence

```
1. EA OnInit()
   ↓
2. Initialize WebAPI Module
   ↓
3. Initialize Logger
   ↓
4. Initialize API Configuration
   ↓
5. Validate Configuration
   ↓
6. Authenticate User (Login)
   ├─ POST /api/auth/login
   └─ Receive JWT token
   ↓
7. Register/Get Bot Instance
   ├─ GET /api/bots?account_number=123456
   └─ POST /api/bots (if not found)
   ↓
8. Initialize Sync Modules
   ├─ TradeSync
   ├─ Heartbeat
   └─ PerformanceSync
   ↓
9. Send Initial Heartbeat
   └─ POST /api/bots/{id}/heartbeat
   ↓
10. Auto-Sync Existing Trades
   └─ POST /api/trades/bot/{id} (for each open trade)
   ↓
11. Send Initial Performance Snapshot
   └─ POST /api/performance/bot/{id}
   ↓
12. ✅ Ready - Dashboard LIVE!
```

---

### Runtime Operations

#### When a Trade Opens:
```
1. OrderSend() executes
   ↓
2. Trade opened successfully
   ↓
3. TradeSync_SendTradeOpen()
   ├─ Build JSON payload
   ├─ POST /api/trades/bot/{botId}
   ├─ Receive backend trade ID
   └─ Track sync status
   ↓
4. ✅ Trade visible in dashboard
```

#### When a Trade Closes:
```
1. OrderClose() executes
   ↓
2. Trade closed successfully
   ↓
3. TradeSync_SendTradeClose()
   ├─ Build JSON payload with P/L
   ├─ PUT /api/trades/{tradeId}
   └─ Update backend record
   ↓
4. ✅ Trade updated in dashboard
```

#### Periodic Updates:
```
Every 60 seconds (configurable):
   ├─ Heartbeat_Update()
   ├─ POST /api/bots/{botId}/heartbeat
   ├─ Send: balance, equity, margin, open positions
   └─ ✅ Dashboard shows bot is ONLINE

Every 5 minutes (configurable):
   ├─ PerformanceSync_Update()
   ├─ Calculate metrics from trade history
   ├─ POST /api/performance/bot/{botId}
   └─ ✅ Dashboard updates performance charts
```

---

## 📡 API Endpoints Used

### Authentication:
- **POST** `/api/auth/login` - User login
- **POST** `/api/auth/register` - User registration (optional)
- **GET** `/api/auth/profile` - Get user profile

### Bot Management:
- **GET** `/api/bots` - List user's bots
- **POST** `/api/bots` - Register new bot
- **GET** `/api/bots/{id}` - Get bot details
- **POST** `/api/bots/{id}/heartbeat` - Send heartbeat
- **GET** `/api/bots/{id}/stats` - Get bot statistics

### Trade Management:
- **GET** `/api/trades` - List all trades
- **POST** `/api/trades/bot/{botId}` - Create new trade
- **GET** `/api/trades/bot/{botId}` - Get bot's trades
- **GET** `/api/trades/{id}` - Get trade details
- **PUT** `/api/trades/{id}` - Update trade (close)

### Performance Metrics:
- **POST** `/api/performance` - Submit performance metrics
- **GET** `/api/performance/bot/{botId}` - Get bot performance history

---

## 🔍 Testing the Integration

### 1. Start Your Backend Server

```bash
cd backend
npm install
npm start
```

Backend should be running on `http://localhost:5000`

### 2. Create a User Account

Option A: Use the frontend dashboard to register
```bash
cd landing
npm install
npm start
```

Option B: Use API directly
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "trader@example.com",
    "password": "password123",
    "name": "Test Trader"
  }'
```

### 3. Configure the EA

In MT4:
1. Attach EA to a chart
2. Set parameters:
   - `API_UserEmail = "trader@example.com"`
   - `API_UserPassword = "password123"`
   - `API_EnableSync = true`

### 4. Check MT4 Expert Log

You should see:
```
═══════════════════════════════════════
   INITIALIZING API INTEGRATION
═══════════════════════════════════════
✓ WebAPI Module initialized
✓ Logger initialized
✓ API Configuration initialized
✓ Configuration validated
═══ Starting Authentication Flow ═══
✓ Login successful
✓ Bot registered
═══ Authentication Complete ═══
✓ Trade Sync module initialized
✓ Heartbeat module initialized
✓ Performance Sync module initialized
╔═══════════════════════════════════╗
║ BACKEND API INTEGRATION ACTIVE!   ║
║  ✓ Authentication                 ║
║  ✓ Trade Sync                     ║
║  ✓ Heartbeat Monitoring           ║
║  ✓ Performance Metrics            ║
║  📊 Dashboard: LIVE DATA ENABLED  ║
╚═══════════════════════════════════╝
```

### 5. Verify Data Flow

**Check Heartbeat:**
```bash
# Should see periodic heartbeat logs
[2025-10-21 10:00:00] [INFO] [HEARTBEAT] HEARTBEAT: Balance: $10000.00 | Equity: $10000.00 | Open: 0
[2025-10-21 10:01:00] [INFO] [HEARTBEAT] HEARTBEAT: Balance: $10000.00 | Equity: $10000.00 | Open: 0
```

**Check Trade Sync:**
- Open a trade manually or wait for EA signal
- Check MT4 log for:
  ```
  [INFO] [TRADE] Trade synced to backend | Ticket: 123456 | Backend ID: 67890abcdef
  ```

**Check Dashboard:**
- Open web dashboard: `http://localhost:3000`
- Navigate to "My Bots" page
- You should see your bot listed with:
  - ✅ Online status
  - Current balance & equity
  - Open positions count
  - Recent trades

---

## 🐛 Troubleshooting

### Issue: "WebRequest not allowed"

**Error Code:** 4014

**Solution:**
1. Check Tools → Options → Expert Advisors
2. Ensure ✅ "Allow WebRequest for listed URLs" is checked
3. Ensure your backend URL is in the whitelist
4. Restart MT4 after changes

---

### Issue: "Login failed" or "Authentication error"

**Possible Causes:**
- Wrong email/password
- Backend server not running
- Network connection issue

**Solutions:**
1. Verify backend is running: `curl http://localhost:5000/health`
2. Check credentials in EA parameters
3. Check MT4 Expert log for detailed error
4. Try manual login via API:
   ```bash
   curl -X POST http://localhost:5000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"your@email.com","password":"yourpassword"}'
   ```

---

### Issue: "Bot not registered" or "Bot Instance ID not set"

**Solution:**
- EA will automatically try to register the bot
- Check that `API_EnableSync = true`
- Check MT4 log for registration errors
- Manually check backend logs

---

### Issue: Trades not showing in dashboard

**Checklist:**
1. ✅ `API_EnableSync = true`
2. ✅ `API_EnableTradeSync = true`
3. ✅ Bot authenticated successfully
4. ✅ Backend server running
5. ✅ Frontend dashboard connected to backend

**Debug:**
- Check MT4 Expert log for trade sync confirmations
- Check backend server logs for incoming requests
- Check database for trade records

---

### Issue: Bot shows "Offline" in dashboard

**Causes:**
- Heartbeat not being sent
- Backend not receiving heartbeat
- 3+ consecutive heartbeat failures

**Solutions:**
1. Check `API_EnableHeartbeat = true`
2. Check `API_HeartbeatInterval` (minimum 30 seconds recommended)
3. Restart EA to send fresh heartbeat
4. Check network connectivity

---

## 📊 Monitoring & Statistics

### View Sync Statistics (In MT4)

The EA automatically prints statistics on shutdown. You can also view them in the Expert log during runtime.

**WebAPI Statistics:**
```
╔════════════════════════════════════════╗
║       WebAPI Statistics                ║
╠════════════════════════════════════════╣
║ Total Requests:  42
║ Failures:        2
║ Success Rate:    95.2%
║ Last Request:    2025-10-21 10:05:23
╚════════════════════════════════════════╝
```

**Trade Sync Statistics:**
```
╔════════════════════════════════════════╗
║       Trade Sync Statistics            ║
╠════════════════════════════════════════╣
║ Total Synced:     15
║ Total Attempts:   17
║ Successful:       15
║ Failed:           2
║ Success Rate:     88.2%
╚════════════════════════════════════════╝
```

**Heartbeat Statistics:**
```
╔════════════════════════════════════════╗
║       Heartbeat Statistics             ║
╠════════════════════════════════════════╣
║ Status:           ONLINE
║ Last Heartbeat:   2025-10-21 10:05:00
║ Success Count:    120
║ Failure Count:    1
║ Success Rate:     99.2%
║ Consecutive Fails: 0
╚════════════════════════════════════════╝
```

---

## 🔐 Security Best Practices

### 1. Never Hardcode Credentials

❌ **Bad:**
```mql4
extern string API_UserEmail = "admin@mysite.com";
extern string API_UserPassword = "MyPassword123!";
```

✅ **Good:**
- Leave them blank in code
- Set them via EA parameters when attaching to chart
- Use environment variables if possible

### 2. Use HTTPS in Production

❌ **Bad:**
```mql4
extern string API_BaseURL = "http://myapi.com";  // Unencrypted!
```

✅ **Good:**
```mql4
extern string API_BaseURL = "https://myapi.com";  // SSL/TLS encrypted
```

### 3. Implement Token Refresh

The current implementation handles 7-day JWT expiry. For production, consider:
- Shorter token expiry (e.g., 24 hours)
- Automatic token refresh logic
- Refresh tokens

---

## 📈 Performance Optimization

### Reduce API Calls

**Adjust Intervals Based on Needs:**
```mql4
// High-frequency (more load)
API_HeartbeatInterval = 30   // Every 30 seconds
API_PerfSyncInterval = 60    // Every 1 minute

// Low-frequency (less load)
API_HeartbeatInterval = 300  // Every 5 minutes
API_PerfSyncInterval = 1800  // Every 30 minutes
```

### Batch Operations

Future enhancement: Instead of sending each trade individually, batch multiple trades in a single API call.

---

## 🎉 Success Indicators

Your dashboard integration is working perfectly when you see:

1. ✅ MT4 Expert log shows "BACKEND API INTEGRATION ACTIVE!"
2. ✅ Bot appears as "Online" in web dashboard
3. ✅ New trades appear in dashboard within seconds of opening
4. ✅ Closed trades update with P/L immediately
5. ✅ Performance metrics update every 5 minutes
6. ✅ Balance/equity updates every minute
7. ✅ No errors in MT4 Expert log
8. ✅ Backend logs show incoming requests
9. ✅ WebAPI success rate > 95%
10. ✅ Trade sync success rate > 90%

---

## 📞 Support & Documentation

- **Backend API Docs:** `/Users/kwamebaffoe/Desktop/EABot/backend/API_DOCUMENTATION.md`
- **Database Schema:** `/Users/kwamebaffoe/Desktop/EABot/backend/DATABASE_SCHEMA.md`
- **Module Source Code:** `/Users/kwamebaffoe/Desktop/EABot/Include/SST_*.mqh`

---

## 🚀 Next Steps

1. **Test in Strategy Tester (Backtest Mode):**
   - Set `BacktestMode = true`
   - API sync is automatically disabled in backtest
   - Test your trading logic without API overhead

2. **Deploy Backend to Production:**
   - Set up PostgreSQL/MySQL database
   - Deploy to cloud (Heroku, AWS, DigitalOcean, etc.)
   - Update `API_BaseURL` to production URL
   - Configure SSL certificate

3. **Monitor & Scale:**
   - Set up backend monitoring (New Relic, Datadog, etc.)
   - Monitor API response times
   - Scale backend if handling multiple bots

4. **Enhance Features:**
   - Add email notifications on trade open/close
   - Add SMS alerts for critical events
   - Create mobile app using backend API
   - Add real-time WebSocket updates

---

**🎊 Congratulations! Your EA is now fully integrated with your dashboard backend!**

