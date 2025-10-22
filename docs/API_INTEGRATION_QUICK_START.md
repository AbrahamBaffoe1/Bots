# Dashboard Integration - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Enable WebRequest in MT4
```
Tools → Options → Expert Advisors
☑ Allow WebRequest for listed URLs:
  http://localhost:5000
```

### Step 2: Start Backend Server
```bash
cd backend
npm install
npm start
```

### Step 3: Create User Account
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "trader@example.com",
    "password": "password123",
    "name": "Test Trader"
  }'
```

### Step 4: Configure EA Parameters
```
API_BaseURL      = "http://localhost:5000"
API_UserEmail    = "trader@example.com"
API_UserPassword = "password123"
API_EnableSync   = true
```

### Step 5: Attach EA & Verify
Look for this in MT4 Expert log:
```
✓ BACKEND API INTEGRATION ACTIVE!
✓ Authentication
✓ Trade Sync
✓ Heartbeat Monitoring
✓ Performance Metrics
📊 Dashboard: LIVE DATA ENABLED
```

## ✅ Success Checklist
- [ ] Backend running on port 5000
- [ ] WebRequest URL whitelisted in MT4
- [ ] User account created
- [ ] EA parameters configured
- [ ] EA shows "INTEGRATION ACTIVE" in log
- [ ] Dashboard shows bot online
- [ ] Trades appear in dashboard

## 📊 Architecture Overview

```
┌─────────────────┐
│  MetaTrader EA  │
│ (MQL4 Running)  │
└────────┬────────┘
         │
         │ WebRequest (HTTP/REST)
         │
         ├─ POST /api/auth/login
         ├─ POST /api/bots
         ├─ POST /api/trades/bot/{id}
         ├─ PUT  /api/trades/{id}
         ├─ POST /api/bots/{id}/heartbeat
         └─ POST /api/performance/bot/{id}
         │
         ↓
┌─────────────────┐
│  Backend API    │
│  (Node.js)      │
│  Port: 5000     │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Database       │
│  (PostgreSQL)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Web Dashboard  │
│  (React)        │
│  Port: 3000     │
└─────────────────┘
```

## 🔧 Module Reference

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **SST_WebAPI.mqh** | HTTP client | `WebAPI_GET()`, `WebAPI_POST()`, `WebAPI_PUT()` |
| **SST_JSON.mqh** | JSON handling | `JSON_BuildTradeOpen()`, `JSON_BuildHeartbeat()` |
| **SST_APIConfig.mqh** | Configuration | `APIConfig_Init()`, `APIConfig_GetAuthToken()` |
| **SST_Logger.mqh** | Logging | `Logger_Info()`, `Logger_Error()`, `Logger_TradeOpened()` |
| **SST_BotAuth.mqh** | Authentication | `BotAuth_Authenticate()`, `BotAuth_Login()` |
| **SST_TradeSync.mqh** | Trade sync | `TradeSync_SendTradeOpen()`, `TradeSync_SendTradeClose()` |
| **SST_Heartbeat.mqh** | Monitoring | `Heartbeat_Update()`, `Heartbeat_SendNow()` |
| **SST_PerformanceSync.mqh** | Metrics | `PerformanceSync_Update()`, `PerformanceSync_SendNow()` |

## 🐛 Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "WebRequest not allowed" | URL not whitelisted | Add URL to Tools → Options → Expert Advisors |
| "Login failed" | Wrong credentials | Check `API_UserEmail` and `API_UserPassword` |
| "Connection refused" | Backend not running | Start backend: `npm start` |
| "Bot not registered" | Auth failed | Check backend logs, verify credentials |
| Trades not syncing | `API_EnableTradeSync = false` | Set to `true` in EA parameters |

## 📡 Data Flow

### Trade Open:
```
1. OrderSend() → MT4 opens trade
2. TradeSync_SendTradeOpen() → Sends to backend
3. Backend stores in DB
4. Dashboard displays trade (real-time)
```

### Trade Close:
```
1. OrderClose() → MT4 closes trade
2. TradeSync_SendTradeClose() → Updates backend
3. Backend updates DB with P/L
4. Dashboard updates trade status
```

### Heartbeat (Every 60s):
```
1. Timer triggers Heartbeat_Update()
2. Sends: balance, equity, margin, positions
3. Backend updates bot status
4. Dashboard shows "Online" with live data
```

### Performance (Every 5min):
```
1. Timer triggers PerformanceSync_Update()
2. Calculates: win rate, profit factor, etc.
3. Backend stores metrics
4. Dashboard updates charts
```

## 🔐 Security Notes

- **Never commit credentials** to git
- Use **HTTPS** in production
- Store passwords securely (environment variables)
- Implement **token refresh** for production
- Enable **rate limiting** on backend

## 📝 Development Tips

### Debugging API Calls:
```mql4
// Enable verbose logging
VerboseLogging = true;
API_EnableSync = true;
```

### Test Without Trading:
```mql4
EnableTrading = false;  // Disable actual trading
API_EnableSync = true;  // Keep API sync active
```

### Monitor API Performance:
```mql4
// Check stats in MT4 log
WebAPI_PrintStats();
TradeSync_PrintStats();
Heartbeat_PrintStats();
PerformanceSync_PrintStats();
```

### Retry Failed Syncs:
```mql4
// Automatically retries failed trade syncs
TradeSync_RetryFailedSyncs();
```

## 📚 Full Documentation

- **Complete Setup Guide:** `DASHBOARD_INTEGRATION_SETUP.md`
- **API Endpoints:** `backend/API_DOCUMENTATION.md`
- **Database Schema:** `backend/DATABASE_SCHEMA.md`
- **Backend README:** `backend/README.md`

## 🎯 Production Checklist

Before going live:

- [ ] Backend deployed to production server
- [ ] Database configured (PostgreSQL/MySQL)
- [ ] SSL certificate installed (HTTPS)
- [ ] Environment variables set
- [ ] Rate limiting enabled
- [ ] Monitoring/logging configured
- [ ] Backup strategy implemented
- [ ] Update `API_BaseURL` to production URL
- [ ] Test with small position sizes first
- [ ] Monitor for 24 hours before full deployment

## 🆘 Need Help?

**Check logs:**
- MT4: Tools → Options → Expert Advisors → Journal
- Backend: `backend/logs/`
- Database: Check trade counts in DB

**Common Commands:**
```bash
# Check backend health
curl http://localhost:5000/health

# Test login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'

# View all bots
curl http://localhost:5000/api/bots \
  -H "Authorization: Bearer YOUR_TOKEN"

# View bot trades
curl http://localhost:5000/api/trades/bot/BOT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

**Created with ❤️ using production-grade architecture, DRY principles, and clean code standards.**

