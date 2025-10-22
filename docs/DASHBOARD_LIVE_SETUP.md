# SmartStockTrader Dashboard Integration - Live Setup Guide

## Quick Setup: Connect Your EA to Dashboard

### Step 1: Configure EA Parameters for LIVE Trading

Open **SmartStockTrader_Single.mq4** and set these parameters:

```mql4
// Line 48: Disable backtest mode for live trading
extern bool    BacktestMode          = false;  // CHANGE TO FALSE FOR LIVE

// Line 49: Optional - disable verbose logs for live
extern bool    VerboseLogging        = false;  // CHANGE TO FALSE FOR LIVE

// Lines 57-58: Set your dashboard credentials
extern string  API_UserEmail         = "Ifrey2heavens@gmail.com";  // Your email
extern string  API_UserPassword      = "!bv2000gee4A!";             // Your password

// Line 59: Enable API sync for dashboard
extern bool    API_EnableSync        = true;   // CHANGE TO TRUE FOR LIVE
```

### Step 2: Compile and Load EA

1. Save the file (Ctrl+S in MetaEditor)
2. Compile (F7 or click Compile button)
3. Drag EA onto your chart
4. In the EA parameters window, verify:
   - ✅ BacktestMode = FALSE
   - ✅ API_EnableSync = TRUE
   - ✅ API_UserEmail = your email
   - ✅ API_UserPassword = your password
   - ✅ API_BaseURL = http://localhost:5000

5. Click OK

### Step 3: Verify Dashboard Connection

**Within 60 seconds**, check your dashboard:

1. Open: `http://localhost:3000/dashboard`
2. Go to "Bots" tab
3. You should see a NEW bot appear:
   - **Name**: SmartStockTrader or Bot_[YourAccountNumber]
   - **Status**: Running (green dot)
   - **MT4 Account**: Your account number
   - **Broker**: Your broker name
   - **Last Heartbeat**: Just now

### Step 4: View Bot Details & Metrics

Click on the bot to see:
- 📊 **Performance Metrics**
  - Total trades
  - Win rate %
  - Total profit/loss
  - Profit factor
  - Max drawdown

- 📈 **Live Trades**
  - Open positions
  - Trade history
  - Entry/exit prices
  - P&L per trade

- ⚙️ **Controls**
  - Start/Stop bot
  - View settings
  - Download logs

## Important Notes

### Security Warning
**DO NOT** hardcode credentials in the EA file for production!

Instead, set them in the EA parameters when loading:
1. Drag EA to chart
2. Go to "Inputs" tab
3. Enter credentials there (not in the code)

### For Multiple Bots

If you want to run BOTH:
- **SmartStockTrader** (stocks) - on one chart
- **UltraBot** (forex) - on another chart

Both will appear separately in the dashboard with their own metrics!

### Backend Must Be Running

Ensure backend server is running:
```bash
cd backend
npm start
```

You should see:
```
╔═══════════════════════════════════════════╗
║  Smart Stock Trader API Server           ║
║  Port: 5000                              ║
║  Status: ONLINE                           ║
╚═══════════════════════════════════════════╝
```

## Troubleshooting

### Bot Not Appearing in Dashboard?

**Check 1: EA Logs**
Look for these messages in MT4 "Experts" tab:
- ✓ "Authenticated with backend API"
- ✓ "BACKEND API INTEGRATION ACTIVE!"
- ✓ "Trade Sync", "Heartbeat Monitoring", "Performance Metrics"

**Check 2: Backend Logs**
```bash
tail -f /tmp/backend.log | grep -i "bot\|register"
```

You should see:
- `New bot registered from MT4 EA`
- `Bot authenticated successfully`

**Check 3: Network Connection**
Test the API:
```bash
curl http://localhost:5000/api/health
```

Should return: `{"status":"ok"}`

### Common Errors

**Error: "WebRequest not allowed"**
Solution: Add backend URL to MT4 allowed URLs:
1. Tools → Options → Expert Advisors
2. Check "Allow WebRequest for listed URL"
3. Add: `http://localhost:5000`

**Error: "Authentication failed"**
Solution: Check credentials match dashboard login:
- Email must be exact (case-sensitive)
- Password must be correct
- User must exist in database

**Error: "Bot registration failed"**
Solution: Check backend is running and accessible

## What Gets Synced to Dashboard?

### ✅ Automatic Sync (Every 60 seconds)
- Bot status (online/offline)
- Account balance
- Account equity
- Open positions count

### ✅ Real-time Sync
- Trade opened (instant)
- Trade closed (instant)
- Stop loss/take profit hit
- Profit/loss updates

### ✅ Performance Metrics (Every 5 minutes)
- Win rate
- Total profit
- Profit factor
- Sharpe ratio
- Max drawdown
- Recovery factor

## Dashboard Features Available

### 📊 Overview Tab
- Total active bots
- Combined profit/loss
- Total trades (all bots)
- Overall win rate

### 🤖 Bots Tab
- List of all bots
- Individual bot status
- Start/stop controls
- Quick stats per bot

### 📈 Trades Tab
- All trades from all bots
- Filter by symbol, status
- Sort by date, profit
- Export to CSV

### 📋 Logs Tab
- Real-time bot logs
- Error messages
- Trade signals
- System events

## Next Steps

1. ✅ Set BacktestMode = false
2. ✅ Set API_EnableSync = true
3. ✅ Enter your credentials
4. ✅ Compile and load EA
5. ✅ Check dashboard for bot
6. ✅ Start trading and monitor!

---

**Need Help?**
- Check `/tmp/backend.log` for backend errors
- Check MT4 "Experts" tab for EA errors
- Verify backend is running on port 5000
- Ensure credentials match your dashboard login
