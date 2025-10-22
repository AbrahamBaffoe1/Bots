# UltraBot EA - Setup & Usage Guide

## What Was Fixed

### 1. **Now Monitors ALL Major Forex Pairs**
The EA now monitors 21 major forex pairs by default:
- EURUSD, GBPUSD, USDJPY, AUDUSD, USDCHF, NZDUSD
- EURGBP, EURJPY, GBPJPY, AUDJPY, EURAUD, GBPAUD
- EURNZD, GBPNZD, USDCAD, EURCAD, GBPCAD, AUDCAD
- NZDCAD, CADCHF, CADJPY

### 2. **Disabled Blocking Filters**
By default, these filters are now **DISABLED** to allow easier trading:
- ❌ News Filter (was blocking all trades)
- ❌ Volatility Filter (too strict)
- ❌ MACD Filter (too strict)
- ❌ Correlation Filter (too strict)

### 3. **Added Detailed Logging**
- Clear initialization messages showing which pairs are available
- Detailed rejection messages (why trades aren't taken)
- Clear confirmation messages when trades are opened
- Enhanced dashboard showing EA status

### 4. **Dashboard Now Visible**
- Moved to **TOP LEFT** corner (easier to see)
- Shows EA status, account info, and filter settings
- Updates in real-time

### 5. **Increased Tolerances**
- Max spread: 5 pips → **10 pips**
- Daily drawdown limit: 5% → **10%**
- ATR volatility threshold: 0.0010 → **0.0005**

---

## How to Use

### Method 1: Trade All Pairs (Recommended)
1. Open MetaTrader 4
2. Open **ANY** chart (EURUSD recommended)
3. Drag `ultraBot.mq4` onto the chart
4. In EA settings, make sure:
   - `TradeCurrentChartOnly = false`
5. Click OK
6. Check the **Experts** tab for initialization messages

### Method 2: Trade Current Chart Only
1. Open the chart of the pair you want to trade
2. Drag `ultraBot.mq4` onto the chart
3. In EA settings, set:
   - `TradeCurrentChartOnly = true`
4. Click OK

---

## How to Check If It's Working

### 1. Check the Dashboard (Top Left)
You should see:
```
=== ULTRABOT EA ===
STATUS: READY
Chart: EURUSD
Account: $XXXX
Monitoring: 21 pairs
Filters: V:N M:N N:N C:N
```

### 2. Check the Experts Log
Go to: **Terminal → Experts tab**

You should see:
```
========================================
=== UltraBot EA STARTING ===
========================================
Current Chart Symbol: EURUSD
...
✓ EURUSD - Available (spread: 15 points)
✓ GBPUSD - Available (spread: 20 points)
...
=== UltraBot EA READY TO TRADE ===
```

### 3. Watch for Trade Signals
The EA will print detailed messages like:
```
[EURUSD] BUY rejected: H1 price below MA
[GBPUSD] SELL rejected: No M5 MA crossover
[USDJPY] *** BUY SIGNAL CONFIRMED ***
✓ BUY order opened successfully! Ticket #12345
```

---

## Trading Strategy

The EA uses a **multi-timeframe trend-following strategy**:

### For Trending Markets:
1. **H1 Filter**: Price must be above/below H1 MA(50)
2. **M5 Crossover**: M5 price crosses M5 MA(10)
3. **RSI Confirmation**: RSI > 50 for BUY, RSI < 50 for SELL

### For Ranging Markets:
1. **Bollinger Bands**: Price at extreme bands
2. **RSI**: Oversold (< 30) or Overbought (> 70)
3. **Price Action**: Pin bar confirmation
4. **Supply/Demand Zone**: Near daily pivot

---

## Risk Management

- **Position Sizing**: Dynamic based on SL distance and account risk %
- **Default Risk**: 1% per trade (adjustable)
- **Stop Loss**: 50 pips (or 2x ATR if adaptive)
- **Take Profit**: 100 pips (or 3x ATR if adaptive)
- **Trailing Stop**: 20 pips (adaptive based on ATR)
- **Break-Even**: Moves SL to entry +2 pips after 30 pips profit
- **Partial Closes**:
  - 30% at 1.5R (risk:reward)
  - 20% at 2.5R

---

## Customization Options

### Enable Strict Filters (Expert Traders)
If you want more conservative trading, set these to `true`:
- `UseVolatilityFilter = true` (requires minimum ATR)
- `UseMACDFilter = true` (requires MACD confirmation)
- `UseCorrelationFilter = true` (avoids correlated pairs)
- `UseNewsFilter = true` (requires working news API)

### Adjust Risk
- `RiskPercentPerTrade` - default 1%, increase for aggressive trading
- `BaseStopLossPips` - default 50 pips
- `BaseTakeProfitPips` - default 100 pips

### Session Trading
To trade only specific hours:
- `UseMultiSession = true`
- `Session1Start = 8` (London open)
- `Session1End = 12`
- `Session2Start = 14` (New York session)
- `Session2End = 17`

---

## Troubleshooting

### ❌ Dashboard Not Showing
- Make sure AutoTrading is enabled (green button)
- Check if EA is attached to the chart (top right corner should show "ultraBot")
- Recompile the EA in MetaEditor

### ❌ No Trades Being Taken
Check the Experts log for rejection messages:
- `[SYMBOL] BUY rejected: H1 price below MA` → Wait for H1 trend to align
- `[SYMBOL] SELL rejected: No M5 MA crossover` → Wait for crossover
- `[SYMBOL] Skipped: No market data` → Pair not available with your broker

### ❌ "No market data available"
- Your broker doesn't offer that pair
- The pair name is different (e.g., EURUSDm, EURUSD.raw)
- Add your broker's pairs to the `Pairs` parameter

### ❌ Trades Fail to Open
- Check if AutoTrading is enabled
- Check if you have enough margin
- Check the error code in Experts log

---

## Important Notes

⚠️ **Backtest Before Live Trading**
- Test on demo account first
- Backtest with tick data for accuracy
- Different brokers have different spreads

⚠️ **One EA Per Chart**
- Only attach the EA to ONE chart
- It will monitor all pairs from that one chart

⚠️ **Broker Compatibility**
- Not all brokers offer all 21 pairs
- Check your broker's available symbols
- Adjust the `Pairs` parameter if needed

---

## Support

For issues or questions:
1. Check the **Experts log** for detailed error messages
2. Review rejection messages to understand why trades aren't taken
3. Enable/disable filters to adjust trading frequency

**Version**: 2.0 - Multi-Pair Enhanced
**Last Updated**: 2025
