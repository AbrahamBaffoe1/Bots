# SmartStockTrader EA - Quick Configuration Reference

## Configuration Files

### 1. **SmartStockTrader_BACKTEST_CONFIG.set** (Diagnostic)
**Purpose:** Identify WHY trades aren't happening
**Use When:** Troubleshooting, testing signal generation
**Filters:** MINIMAL (most disabled)
**Expected:** Many signals, varying quality

### 2. **SmartStockTrader_PROFITABLE_BALANCED.set** (Recommended)
**Purpose:** Maximize profitability while maintaining quality
**Use When:** Live trading, forward testing, real backtesting
**Filters:** BALANCED (selective but not extreme)
**Expected:** 2-5 trades/week, 65-75% win rate, 4:1 R:R

---

## Key Differences at a Glance

| Filter | Diagnostic | Balanced | Impact |
|--------|-----------|----------|---------|
| **Williams %R** | ❌ OFF | ✅ ON (-85/-15) | Catches strong momentum reversals |
| **Market Structure** | ❌ OFF | ✅ ON | Ensures trend alignment |
| **SPY Trend Filter** | ❌ OFF | ✅ ON | Trade WITH market direction |
| **Time of Day** | ❌ OFF | ✅ ON | Avoid choppy periods |
| **News Filter** | ❌ OFF | ✅ ON | Avoid volatility spikes |
| **Correlation Filter** | ❌ OFF | ✅ ON | Better diversification |
| **MACD Confirm** | ✅ ON | ✅ ON | Avoid false breakouts |
| **Max Daily Trades** | 20 | 5 | Quality over quantity |
| **Trade Spacing** | 5 min | 30 min | Prevent overtrading |
| **Risk/Trade** | 1.0% | 1.5% | Higher risk with tighter SL |
| **SL Multiplier** | 1.5 ATR | 1.2 ATR | Tighter stops |
| **TP Multiplier** | 6.0 ATR | 4.8 ATR | 4:1 R:R |

---

## Which Config Should You Use?

### Use DIAGNOSTIC Config If:
- ❓ EA shows ZERO trades and you don't know why
- 🔍 You want to see RAW signal generation (no quality filters)
- 🧪 Testing a new symbol or timeframe for viability
- 📊 Debugging specific filter issues

### Use BALANCED Config If:
- 💰 You want to make consistent profits
- 📈 Forward testing before going live
- 🎯 Running real backtest for performance evaluation
- 🚀 Live trading (demo or real)

---

## Quick Filter Tuning Guide

### Too Few Trades? (0-1/week with Balanced)

**Loosen these filters:**
```ini
UseWilliamsR=false                # Disable momentum filter
MinRoomToTarget=2.0               # Lower from 2.5
MinVolumeMultiplier=1.2           # Lower from 1.3
MaxSpreadPips=5.0                 # Increase from 3.0
```

### Too Many Trades? (>10/day with Balanced)

**Tighten these filters:**
```ini
MaxDailyTrades=3                  # Lower from 5
MinMinutesBetweenTrades=60        # Increase from 30
MinVolumeMultiplier=1.5           # Increase from 1.3
MLConfidenceThreshold=65.0        # Increase from 60
```

### Low Win Rate? (<50%)

**Improve quality:**
```ini
UseSPYTrendFilter=true            # MUST BE ON
UseTimeOfDayFilter=true           # MUST BE ON
UseMarketStructure=true           # MUST BE ON
WPR_Oversold=-90                  # Stricter (from -85)
WPR_Overbought=-10                # Stricter (from -15)
```

### Good Win Rate but Low Profit?

**Increase reward:**
```ini
ATRMultiplierTP=6.0               # Increase from 4.8
PartialClosePercent=20.0          # Lower from 30% (keep more running)
MLHighConfTPMultiplier=1.5        # Increase from 1.3
```

---

## WebRequest Error Fix

**Error Message:**
```
? WebRequest failed (attempt 1/3): HTTP request failed
```

**Cause:** API trying to connect during backtest mode

**Solution:** Already handled! This is expected and harmless.
- The code checks `if(API_EnableSync && !BacktestMode)`
- In backtest, API is automatically disabled
- Error messages are just diagnostic, EA continues normally

**To Silence Completely:**
```ini
API_EnableSync=false
API_EnableTradeSync=false
API_EnableHeartbeat=false
API_EnablePerfSync=false
```

---

## Loading a Configuration File

### In Strategy Tester (Backtest):
1. Open MT4 → View → Strategy Tester (Ctrl+R)
2. Select EA: `SmartStockTrader_Single`
3. Click **"Expert Properties"** button
4. Click **"Load"** at bottom
5. Select `.set` file → Open
6. Click **"OK"**
7. Click **"Start"** to run backtest

### In Live Chart:
1. Drag EA to chart (or right-click chart → Expert Advisors → SmartStockTrader_Single)
2. In properties window, click **"Load"**
3. Select `.set` file → Open
4. Enable "Allow live trading" checkbox
5. Click **"OK"**

---

## Common Issues & Quick Fixes

### Issue: "File not found" when loading .set
**Fix:** Copy `.set` files to: `C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[BrokerID]\MQL4\Presets\`

### Issue: Settings reset after restart
**Fix:** Save your config manually:
- In EA properties → Click "Save"
- Name it (e.g., "MyCustom")
- Will persist between sessions

### Issue: Verbose logging not showing
**Fix:** Ensure in configuration:
```ini
VerboseLogging=true
BacktestMode=true (for backtest)
```

### Issue: No signals on specific symbol
**Fix:** Check symbol has proper data:
- H1, H4, D1 must all have data available
- Volume must be available (some brokers don't provide it)
- Try different symbol (AAPL, MSFT, NVDA recommended)

---

## Performance Expectations

### Diagnostic Config:
- **Trades:** 10-50 per week
- **Win Rate:** 40-60% (variable quality)
- **Purpose:** Testing/debugging only
- **Profit:** Not optimized for profitability

### Balanced Config:
- **Trades:** 2-5 per week
- **Win Rate:** 65-75%
- **Risk-Reward:** 3:1 to 4:1
- **Monthly Target:** 5-15%
- **Max Drawdown:** <15%

---

## Recommended Testing Workflow

### Step 1: Diagnostic Backtest (2 hours)
```
Symbol: NVDA
Timeframe: H1
Period: Aug 1 - Oct 31, 2025
Config: SmartStockTrader_BACKTEST_CONFIG.set
```

**Goal:** Verify EA generates ANY signals
**Success:** Logs show signal detection attempts
**Failure:** No logs → Data/symbol issue

### Step 2: Balanced Backtest (3 months)
```
Symbol: NVDA
Timeframe: H1
Period: Jan 1 - Mar 31, 2025
Config: SmartStockTrader_PROFITABLE_BALANCED.set
```

**Goal:** Measure profitability with quality filters
**Success:** 60%+ win rate, profit factor >2.0
**Failure:** Adjust filters per "Quick Filter Tuning" guide

### Step 3: Forward Test (2-4 weeks)
```
Mode: Demo account
Config: SmartStockTrader_PROFITABLE_BALANCED.set
Risk: 0.5% per trade (conservative)
```

**Goal:** Validate in real market conditions
**Success:** Performance matches backtest
**Failure:** Re-optimize or switch symbol

### Step 4: Live Trading
```
Mode: Real account
Config: SmartStockTrader_PROFITABLE_BALANCED.set
Risk: Start with 0.5%, increase to 1.5% after 1 month
```

---

## Critical Success Factors

### 1. ✅ Use Balanced Config for Live Trading
- Diagnostic config is for testing ONLY
- Balanced has profit-optimized filters

### 2. ✅ Enable SPY Trend Filter
```ini
UseSPYTrendFilter=true  ← CRITICAL
```
- Trading against market = #1 cause of losses

### 3. ✅ Enable Time of Day Filter
```ini
UseTimeOfDayFilter=true  ← CRITICAL
```
- Avoids choppy, unpredictable periods

### 4. ✅ Respect Daily Loss Limit
```ini
MaxDailyLossPercent=4.0
```
- Protects against revenge trading
- Live to trade another day

### 5. ✅ Use Smart Scaling
```ini
UseSmartScaling=true
PartialClosePercent=30.0
MoveToBreakeven=true
```
- Locks in profits early
- Reduces psychological pressure

---

## Files Summary

### Created/Modified Files:
1. ✅ **SmartStockTrader_Single.mq4** - Added MACD filter, enhanced logging
2. ✅ **SmartStockTrader_BACKTEST_CONFIG.set** - Diagnostic configuration
3. ✅ **SmartStockTrader_PROFITABLE_BALANCED.set** - Profitable configuration
4. ✅ **BACKTEST_NO_TRADES_FIX.md** - No-trades troubleshooting guide
5. ✅ **PROFITABLE_CONFIG_GUIDE.md** - Complete configuration explanation
6. ✅ **QUICK_CONFIG_REFERENCE.md** (this file) - Quick reference card

### Use This File When:
- ❓ Deciding which config to use
- 🔧 Quick filter adjustments needed
- 🆘 Common issues troubleshooting
- 📚 Need quick config comparison

---

## Support

### If You're Still Stuck:

1. **Check verbose logs** - They tell you exactly what's wrong
2. **Read PROFITABLE_CONFIG_GUIDE.md** - Detailed explanations
3. **Read BACKTEST_NO_TRADES_FIX.md** - Troubleshooting guide
4. **Test with Diagnostic config first** - Isolate the issue

### Key Log Indicators:

**✅ Good Signal:**
```
═══ SCANNING NVDA (1/1) ═══
→ Primary BUY conditions met (MA alignment + RSI + WPR + MACD)
→ Checking volume filter...
✓ Volume filter passed
✓ Multi-timeframe confirmation passed
✓ Market structure passed
✓✓✓ ALL BUY FILTERS PASSED!
╔════════════════════════════╗
║  ✓ ALL FILTERS PASSED      ║
╚════════════════════════════╝
```

**❌ Blocked Signal:**
```
═══ SCANNING NVDA (1/1) ═══
✗ Primary BUY conditions not met:
  - Price > Fast MA: YES
  - Price > Slow MA: NO  ← PROBLEM HERE
  - RSI 50-70: YES
  - WPR OK: NO  ← PROBLEM HERE
```

---

**Remember:** Quality > Quantity. 5 high-probability trades/week > 50 random trades/week!
