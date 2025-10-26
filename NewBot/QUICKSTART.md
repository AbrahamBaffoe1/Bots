# Quick Start Guide - MT5 Trading System

Get up and running with the MT5 Expert Advisors in under 15 minutes!

## Fast Track Setup (5 Steps)

### Step 1: Install Python Dependencies (2 minutes)

```bash
cd NewBot
pip install -r requirements.txt
```

**macOS Users**: You'll need MT5 running via Wine or Windows VM since MT5 is Windows-only.

### Step 2: Configure Your Account (2 minutes)

```bash
# Copy example environment file
cp .env.example .env

# Edit with your details
nano .env  # or use your favorite editor
```

**Required Settings**:
```env
MT5_LOGIN=12345678
MT5_PASSWORD=YourPassword123
MT5_SERVER=BrokerName-Demo  # or -Live
BACKEND_URL=http://localhost:5000
```

### Step 3: Start Backend Server (1 minute)

```bash
cd ../backend
npm start
```

You should see: `✓ Server running on port 5000`

### Step 4: Start Python Bridge (1 minute)

```bash
cd ../NewBot
python mt5_bridge.py
```

You should see:
```
✓ MT5 initialized successfully
✓ Logged in to MT5 account: 12345678
✓ Account Balance: $10000.00
✓ WebSocket server started successfully
```

### Step 5: Attach EA to MT5 Chart (5 minutes)

1. **Open MT5** (must be installed on Windows)

2. **Install the EAs**:
   - Press `Ctrl+Shift+D` (Open Data Folder)
   - Navigate to `MQL5/Experts/`
   - Copy these files here:
     - `stocksOnlymachine.mq5`
     - `GoldTrader.mq5`
     - `forexMaster.mq5`

3. **Compile the EAs**:
   - Press `F4` (MetaEditor)
   - Open each `.mq5` file
   - Press `F7` (Compile)
   - Check for "0 errors"

4. **Attach EA to Chart**:
   - Open a chart (e.g., EURUSD H1)
   - Press `Ctrl+N` (Navigator)
   - Expand "Expert Advisors"
   - Drag `forexMaster` onto chart
   - In dialog:
     - ✓ Check "Allow automated trading"
     - ✓ Check "Allow DLL imports"
     - Set your risk settings
   - Click **OK**

5. **Verify It's Running**:
   - Look for smiley face in top-right corner 😊
   - Check "Experts" tab at bottom for logs
   - Should see: "=== Forex Master EA Initializing ==="

## Quick Configuration

### Conservative Settings (Recommended for Beginners)

**Stock EA**:
```
Risk Per Trade: 0.5%
Max Daily Trades: 5
Risk:Reward: 1:2
Enable Trading: TRUE
```

**Gold EA**:
```
Risk Per Trade: 0.3%
Strategy: HYBRID
Max Daily Trades: 3
Max Daily Drawdown: 1.5%
```

**Forex EA**:
```
Risk Per Trade: 0.5%
Max Simultaneous Trades: 3
Use Correlation: TRUE
Max Daily Trades: 10
```

### Aggressive Settings (For Experienced Traders)

**Stock EA**:
```
Risk Per Trade: 1.5%
Max Daily Trades: 15
Risk:Reward: 1:3
```

**Gold EA**:
```
Risk Per Trade: 1.0%
Strategy: BREAKOUT
Max Daily Trades: 8
```

**Forex EA**:
```
Risk Per Trade: 1.0%
Max Simultaneous Trades: 5
Max Daily Trades: 20
```

## First Trade Checklist

Before going live, verify:

- [ ] ✓ Trading on DEMO account (not live!)
- [ ] ✓ Backend server running (check `http://localhost:5000`)
- [ ] ✓ Python bridge connected (check console logs)
- [ ] ✓ EA shows 😊 in chart corner
- [ ] ✓ "Experts" tab shows initialization logs
- [ ] ✓ AutoTrading button enabled (MT5 toolbar)
- [ ] ✓ Account has sufficient balance
- [ ] ✓ Internet connection is stable

## Quick Test

### Test the Stock EA (AAPL)

1. **Open AAPL chart** (H1 timeframe)
2. **Attach stocksOnlymachine EA**
3. **Settings**:
   ```
   Enable Trading: TRUE
   Risk Percent: 0.5%
   Use ATR Stop Loss: TRUE
   Enable WebSocket: FALSE  # Test local signals first
   ```
4. **Wait for conditions**:
   - Must be during market hours (9:30 AM - 4:00 PM EST)
   - EA checks on each new bar
   - Watch "Experts" tab for signal detection

### Test the Gold EA (XAUUSD)

1. **Open XAUUSD chart** (H1 timeframe)
2. **Attach GoldTrader EA**
3. **Settings**:
   ```
   Enable Trading: TRUE
   Risk Percent: 0.3%
   Strategy: TREND
   Trade London Session: TRUE
   ```
4. **Best times**: London (8 AM - 5 PM GMT) or NY session (1 PM - 10 PM GMT)

### Test the Forex EA (EURUSD)

1. **Open EURUSD chart** (H1 timeframe)
2. **Attach forexMaster EA**
3. **Settings**:
   ```
   Enable Trading: TRUE
   Risk Percent: 0.5%
   Strategy: TREND
   Trading Pairs: EURUSD,GBPUSD,USDJPY
   ```
4. **It will trade all configured pairs automatically**

## Monitoring Your First Day

### What to Watch

**MT5 Experts Tab**:
```
✓ Initialization messages
✓ Signal detection
✓ Trade execution
✓ Position management
✗ Any error messages
```

**Python Bridge Console**:
```
✓ WebSocket connections
✓ Account info updates
✓ Position updates every 5 seconds
✓ Trade notifications
```

**Backend (Terminal)**:
```
✓ API requests from EAs
✓ Trade notifications received
✓ Database updates
```

## Common First-Day Issues

### "EA is not trading!"

**Quick Fixes**:
1. ✓ AutoTrading button ON (MT5 toolbar)
2. ✓ EA Input: "Enable Trading" = TRUE
3. ✓ Check market hours (Stock EA)
4. ✓ Check spread (must be below max spread setting)
5. ✓ Look for signals in Experts tab
6. ✓ Verify sufficient margin

### "WebSocket connection failed"

**Quick Fixes**:
1. ✓ Python bridge running?
2. ✓ Backend server running?
3. ✓ Check `.env` file settings
4. ✓ Firewall not blocking port 8765?
5. ✓ For testing: Set "Enable WebSocket" = FALSE in EA

### "Trade execution failed"

**Quick Fixes**:
1. ✓ Check MT5 "Trade" tab for error message
2. ✓ Verify account has margin
3. ✓ Symbol is tradeable?
4. ✓ Broker allows automated trading?
5. ✓ Check lot size not too small/large

## Performance Expectations

### First Week (Demo)

**Expected**:
- 5-15 trades depending on EA and settings
- Mix of wins and losses
- Should see risk management working
- Daily limits should prevent overtrading

**Red Flags**:
- All losses (check strategy/market conditions)
- No trades at all (check settings/logs)
- Excessive trades (check daily limits)
- Large drawdown (reduce risk %)

### First Month Goals

- Understand EA behavior
- Fine-tune settings
- Build confidence in system
- Verify backend integration
- Review performance metrics

## Daily Routine

### Morning (5 minutes)

1. **Check System Status**:
   ```bash
   # Terminal 1: Backend
   cd backend && npm start

   # Terminal 2: Bridge
   cd NewBot && python mt5_bridge.py
   ```

2. **Check MT5**:
   - Open MT5
   - Verify EAs attached to charts
   - Check AutoTrading ON
   - Review overnight positions

### Evening (10 minutes)

1. **Review Performance**:
   - Check closed trades
   - Note profit/loss
   - Review logs for errors
   - Check daily statistics

2. **Prepare for Next Day**:
   - Verify system will run overnight (if desired)
   - Check upcoming news events
   - Adjust settings if needed

## Next Steps

Once comfortable with basics:

1. **Enable WebSocket Integration**:
   - Set "Enable WebSocket" = TRUE in EAs
   - Implement backend signal generation
   - Test integration thoroughly

2. **Optimize Settings**:
   - Backtest different parameters
   - Forward test on demo
   - Find optimal settings for your risk tolerance

3. **Add Machine Learning** (Advanced):
   - Implement ML models in backend
   - Generate predictions via API
   - Let EAs use ML signals

4. **Go Live** (When Ready):
   - Open small live account
   - Use conservative settings
   - Start with one EA
   - Gradually increase risk as proven

## Emergency Procedures

### Stop Everything Immediately

**Method 1 - Stop EAs**:
1. Click AutoTrading button (MT5 toolbar) - turns RED
2. All EAs stop immediately

**Method 2 - Remove EA**:
1. Right-click chart
2. "Expert Advisors" → "Remove"

**Method 3 - Close Positions**:
1. Right-click position in "Trade" tab
2. "Close"

**Method 4 - Kill Switch**:
```bash
# Stop Python bridge
Ctrl+C in terminal

# Stop backend
Ctrl+C in backend terminal
```

## Getting Help

### Check Logs First

**MT5 Logs**:
- Experts tab (bottom of MT5)
- Journal tab (for system errors)

**Python Logs**:
- Console output
- `mt5_bridge_YYYYMMDD.log` file

**Backend Logs**:
- Terminal output
- Check `backend/logs/` folder

### Troubleshooting Workflow

1. **Read the error message** (don't skip!)
2. **Check this guide** for common issues
3. **Review README.md** for detailed info
4. **Check configuration files**
5. **Test on demo** to isolate issue
6. **Contact support** with specific error details

## Pro Tips

### Risk Management
- Start small (0.3-0.5% risk)
- Increase gradually as proven
- Never risk more than 2% per trade
- Use daily loss limits religiously

### System Reliability
- Keep good internet connection
- Use VPS for 24/7 operation
- Monitor logs daily
- Keep MT5/Python/Node.js updated

### Optimization
- Don't over-optimize on backtest
- Test changes on demo first
- One change at a time
- Track all changes and results

### Psychology
- Trust the system or don't use it
- Don't interfere with trades
- Review weekly, not hourly
- Focus on process, not individual trades

---

## Ready to Start?

1. ✓ Read this guide
2. ✓ Complete 5-step setup
3. ✓ Run on DEMO first
4. ✓ Monitor for 1-2 weeks
5. ✓ Review performance
6. ✓ Optimize if needed
7. ✓ Go live when confident

**Remember**: Patience and proper testing beat rushing to live trading every time!

Good luck! 🚀📈
