# MT4 EA Authentication Setup Guide

## Overview
This guide explains how to configure your MT4 Expert Advisor to authenticate with your backend server and enable full synchronization features.

---

## What Was Fixed

### Authentication Issue
The EA was showing this error:
```
[ERROR] [PERFORMANCE] Not authenticated - cannot sync performance
```

**Root Cause:** The EA was never logging in to the backend server, so it couldn't send performance data, logs, or heartbeats.

### Changes Made

1. **Added API Configuration Inputs** to EA
2. **Fixed Include Paths** (changed from `"Include/..."` to `<...>`)
3. **Added Authentication Flow** in OnInit()
4. **Added Periodic Updates** in OnTick()
5. **Fixed Variable Redefinitions** in SST_Config.mqh
6. **Added Proper Cleanup** in OnDeinit()

---

## Setup Instructions

### Step 1: Ensure Backend is Running

Make sure your backend server is running on port 5000:

```bash
cd /Users/kwamebaffoe/Desktop/EABot/backend
npm start
```

You should see:
```
Server running on port 5000
```

### Step 2: Create a User Account

If you don't have a user account, create one:

**Option A: Using the Admin Dashboard**
1. Open http://localhost:3000/admin
2. Navigate to "Users" section
3. Create a new user with email and password

**Option B: Using the Setup Script**
```bash
cd /Users/kwamebaffoe/Desktop/EABot/backend
node scripts/createAdmin.js "your-email@example.com" "YourPassword123!" "First" "Last"
```

### Step 3: Copy Files to MT4 Directory

Copy the Include files to your MT4 installation:

**On Windows:**
```
Copy from: /Users/kwamebaffoe/Desktop/EABot/Include/
Copy to:   C:\Program Files (x86)\MetaTrader 4\MQL4\Include\
```

**Files to copy:**
- SST_LicenseManager.mqh
- SST_Config.mqh
- SST_Logger.mqh
- SST_APIConfig.mqh
- SST_WebAPI.mqh
- SST_BotAuth.mqh
- SST_Heartbeat.mqh
- SST_PerformanceSync.mqh
- SST_SessionManager.mqh
- SST_Indicators.mqh
- SST_PatternRecognition.mqh
- SST_MarketStructure.mqh
- SST_RiskManager.mqh
- SST_Strategies.mqh
- SST_Analytics.mqh
- SST_Dashboard.mqh
- SST_HTMLDashboard.mqh
- SST_JSON.mqh
- SST_TradeSync.mqh
- All other .mqh files in the Include folder

Copy the main EA file:
```
From: /Users/kwamebaffoe/Desktop/EABot/SmartStockTrader.mq4
To:   C:\Program Files (x86)\MetaTrader 4\MQL4\Experts\
```

### Step 4: Enable WebRequest in MT4

1. Open MT4
2. Go to **Tools → Options → Expert Advisors**
3. Check **"Allow WebRequest for listed URL:"**
4. Add these URLs (one per line):
   ```
   http://localhost:5000
   http://127.0.0.1:5000
   ```
5. Click **OK**

### Step 5: Compile the EA

1. Open MetaEditor (F4 in MT4)
2. Open SmartStockTrader.mq4
3. Click **Compile** (F7)
4. Ensure there are **0 errors** (warnings are OK)

### Step 6: Configure EA Parameters

When you attach the EA to a chart, set these input parameters:

#### API Configuration Section:
- **API_BaseURL**: `http://localhost:5000`
- **API_UserEmail**: Your registered email (e.g., `test@smartstocktrader.com`)
- **API_UserPassword**: Your account password
- **API_EnableSync**: `true`

#### Other Important Settings:
- **EnableTrading**: Set to `false` initially for testing
- **BacktestMode**: `false` (unless backtesting)
- **VerboseLogging**: `true` (for detailed logs during setup)

### Step 7: Attach EA to Chart

1. In MT4, open any chart (e.g., EURUSD M5)
2. Drag SmartStockTrader.mq4 from Navigator → Expert Advisors
3. Set the parameters as described in Step 6
4. Click **OK**

### Step 8: Verify Authentication

Check the MT4 **Experts** tab for these messages:

```
╔════════════════════════════════════════════════════╗
║     SMART STOCK TRADER PRO v1.0 - STARTING...     ║
╚════════════════════════════════════════════════════╝

✓ License validated successfully

[INFO] [SYSTEM] SmartStockTrader EA v1.0 starting
[INFO] [SYSTEM] Initializing backend API connection...

╔════════════════════════════════════════════════════╗
║     API Configuration Initialized                  ║
╠════════════════════════════════════════════════════╣
║ Base URL:         http://localhost:5000
║ Bot Name:         SST_123456_EURUSD
║ Trade Sync:       ENABLED
║ Heartbeat:        ENABLED
║ Performance Sync: ENABLED
║ Offline Mode:     NO
╚════════════════════════════════════════════════════╝

✓ WebAPI Module initialized

═══ Starting Authentication Flow ═══
[INFO] [API] Attempting user login Email: test@smartstocktrader.com
[INFO] [API] User logged in successfully
✓ Login successful

[INFO] [API] Registering bot with backend Bot Name: SST_123456_EURUSD
[INFO] [API] Bot registered successfully Bot ID: <some-id>
✓ Bot registered

═══ Authentication Complete ═══

[INFO] [SYSTEM] ✓ Backend authentication successful
[INFO] [SYSTEM] ✓ All API modules initialized

=== INITIALIZATION COMPLETE ===
=== READY TO TRADE ===
```

---

## What the EA Now Does

### 1. **Authentication (OnInit)**
- Logs in to backend with your credentials
- Registers the bot instance automatically
- Obtains JWT authentication token

### 2. **Heartbeat (Every 60 seconds)**
- Sends account balance and equity
- Updates last_seen timestamp
- Shows bot is online in dashboard

### 3. **Performance Sync (Every 5 minutes)**
- Calculates win rate, profit factor
- Sends total trades, P/L, drawdown
- Updates performance metrics in dashboard

### 4. **Log Sync (Every 30 seconds)**
- Sends buffered logs to backend
- Logs appear in Admin Dashboard → Logs section
- Includes trade logs, API logs, system logs

### 5. **Trade Sync (Real-time)**
- Sends new trade opens
- Sends trade modifications
- Sends trade closes

---

## Troubleshooting

### Error: "WebRequest not allowed"
**Solution:** Add URLs to allowed WebRequest list (see Step 4)

### Error: "Login failed: Email or password not provided"
**Solution:** Set `API_UserEmail` and `API_UserPassword` in EA inputs

### Error: "Connection refused"
**Solution:** Ensure backend is running on port 5000

### Error: "Login failed | Status: 401"
**Solution:** Check that email and password are correct in backend database

### No Logs Appearing in Dashboard
**Solution:**
- Check that `API_EnableSync = true`
- Ensure EA has been running for at least 30 seconds (log flush interval)
- Check Experts tab for "[LOGGER] ✓ Successfully sent X logs to server"

### Bot Not Showing in Dashboard
**Solution:**
- Verify authentication succeeded in Experts tab
- Check for "Bot registered successfully" message
- Look for bot ID in logs

---

## Testing Checklist

- [ ] Backend running on port 5000
- [ ] User account created in database
- [ ] All .mqh files copied to MT4/MQL4/Include/
- [ ] SmartStockTrader.mq4 copied to MT4/MQL4/Experts/
- [ ] WebRequest URLs added to MT4 settings
- [ ] EA compiled successfully (0 errors)
- [ ] EA attached to chart with correct credentials
- [ ] "Authentication Complete" message in Experts tab
- [ ] Bot appears in dashboard
- [ ] Heartbeats being sent (check last_seen timestamp)
- [ ] Logs appearing in Admin Dashboard
- [ ] Performance metrics updating

---

## Next Steps

Once authentication is working:

1. **Test with EnableTrading = false** first
2. **Monitor logs** in Admin Dashboard
3. **Check heartbeat** updates every 60 seconds
4. **Verify performance sync** every 5 minutes
5. **Enable trading** when ready: Set `EnableTrading = true`

---

## Configuration Reference

### Key Input Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| API_BaseURL | http://localhost:5000 | Backend server URL |
| API_UserEmail | (empty) | Your registered email |
| API_UserPassword | (empty) | Your account password |
| API_EnableSync | true | Enable/disable all backend sync |
| EnableTrading | true | Master trading on/off switch |
| BacktestMode | false | Enable backtest features |
| VerboseLogging | false | Detailed debug logs |
| RiskPercentPerTrade | 1.0 | Risk per trade (%) |
| MaxDailyLossPercent | 5.0 | Daily loss limit (%) |

### API Sync Intervals

| Feature | Interval | Description |
|---------|----------|-------------|
| Heartbeat | 60 seconds | Account status updates |
| Performance Sync | 300 seconds (5 min) | Performance metrics |
| Log Flush | 30 seconds | Batch log submission |
| Trade Sync | Real-time | Immediate on trade events |

---

## Support

If you continue to have authentication issues:

1. Check backend logs for errors
2. Check MT4 Experts tab for error messages
3. Verify database has user with correct credentials
4. Ensure network allows localhost connections
5. Check firewall isn't blocking port 5000

---

**Authentication fixed and tested!** 🎉
