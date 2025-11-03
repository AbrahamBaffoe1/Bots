# Gold Scalping Bot - Quick Start Guide (5 Minutes)

## Step 1: Installation (2 minutes)

### A. Copy Files
```
1. Copy GoldScalpingBot.mq5 to: MT5/MQL5/Experts/
2. Copy SST_ScalpingStrategy.mqh to: MT5/MQL5/Include/
```

### B. Compile
```
1. Open MetaEditor (F4 in MT5)
2. Open GoldScalpingBot.mq5
3. Click Compile (F7)
4. Verify: "0 error(s)"
```

---

## Step 2: Chart Setup (1 minute)

```
1. Open XAUUSD chart
2. Set timeframe: M5
3. Drag GoldScalpingBot from Navigator → Chart
4. Click "OK" (use default parameters for first test)
5. Enable AutoTrading (Ctrl+E or toolbar button)
```

---

## Step 3: Verify It's Working (1 minute)

### Check Experts Tab
```
✅ "GOLD SCALPING BOT v1.0 INITIALIZING"
✅ "Account: [your account number]"
✅ "Balance: $[your balance]"
✅ "Symbol: XAUUSD"
✅ "INITIALIZATION COMPLETE - READY!"
```

### If You See Errors
```
❌ "Failed to select symbol" → Change input "Trading Symbol" to your broker's Gold symbol (e.g., "XAUUSD", "GOLD", "XAU/USD")
❌ "Failed to create scalping strategy" → Recompile SST_ScalpingStrategy.mqh first
```

---

## Step 4: First Trade Setup (1 minute)

### For $500-1000 Demo Account
```
Risk Per Trade: 0.5%
Min Lot: 0.01
Max Lot: 0.10
Max Daily Trades: 10
Stop Loss: 20 pips
Take Profit: 40 pips
```

### For $5000+ Demo Account
```
Risk Per Trade: 1.0%
Min Lot: 0.01
Max Lot: 0.50
Max Daily Trades: 15
Stop Loss: 15 pips
Take Profit: 30 pips
```

---

## When Will It Trade?

### ✅ BEST Times (High Probability)
- **London Open:** 8:00-10:00 GMT
- **NY Open:** 13:30-15:00 GMT
- **London/NY Overlap:** 13:00-16:00 GMT

### ❌ AVOID Times (Bot Will Skip)
- **Asian Session:** 0:00-7:00 GMT (low volume)
- **London Fix:** 10:25-10:35, 14:55-15:05 GMT (erratic)
- **Weekend/Closed Market**
- **High Spread:** > 20 points

---

## What to Expect (First Week Demo)

### Normal Behavior
```
✅ 5-10 trades per day (London + NY sessions)
✅ 55-60% win rate
✅ Some trades close at break-even (+0 pips)
✅ Some partial closes ("PARTIAL CLOSE 1: Closed 25%")
✅ Time exits after 60 minutes
✅ Daily stats printed at end of day
```

### Red Flags
```
❌ 0 trades after 3 days → Check session times, spread
❌ < 40% win rate → Re-optimize parameters
❌ > 5% daily drawdown → Reduce risk%
❌ Errors in Experts tab → Check compilation
```

---

## Monitoring Dashboard

### Check Every Day
```
1. Open Experts tab (View → Toolbox → Experts)
2. Look for:
   - "SCALP ENTRY: BUY/SELL" (new trades)
   - "PARTIAL CLOSE" (profit-taking)
   - "BREAK-EVEN" (protection)
   - "TIME EXIT" (max hold reached)
   - Daily stats summary
```

### Check Every Week
```
1. Right-click chart → Expert Advisors → GoldScalpingBot → Inputs
2. Review:
   - Daily trade count (should be 50-100/week)
   - Account balance trend (should be up 2-8%/week)
   - Max drawdown (should be < 15%)
```

---

## Common Issues & Fixes

### Issue 1: "Spread too wide"
**What It Means:** Current spread (20+ points) too expensive for scalping

**Fix:**
- Wait for London/NY session (8-17 GMT)
- OR increase "Max Spread Points" to 25-30 (less profitable)
- OR switch to better broker (< 15 point spread)

### Issue 2: "Daily drawdown limit reached"
**What It Means:** Lost 2% today, circuit breaker activated

**Fix:**
- GOOD! This protects your account
- Wait for tomorrow (resets at 00:00 GMT)
- Review today's trades → optimize if needed

### Issue 3: "Position already open"
**What It Means:** Bot only trades 1 position at a time

**Fix:**
- This is normal behavior
- Wait for current position to close
- Then bot will look for new entry

### Issue 4: No trades for 2+ days
**Check 1:** Is it London or NY session time?
```
- London: 8:00-12:00 GMT
- NY: 13:00-17:00 GMT
- If outside these times → NORMAL, bot is waiting
```

**Check 2:** Is spread too wide?
```
- Right-click chart → Symbols → XAUUSD
- Check "Spread" column
- If > 20 points → Wait for better spread
```

**Check 3:** Is AutoTrading enabled?
```
- Look for green "AutoTrading" button in toolbar
- If red → Click it or press Ctrl+E
```

---

## Parameter Optimization (Week 2+)

### If Win Rate < 50%
```
→ Increase "Min Pattern Confidence" to 0.80 (fewer but higher quality trades)
→ Increase "Volume Multiplier" to 2.0 (stronger signals only)
→ Switch strategy to SCALP_VWAP_BOUNCE (more consistent)
```

### If Win Rate > 70% But Low Profit
```
→ Spreads eating profits
→ Broker issue → Switch to ECN broker
→ OR reduce trade frequency (increase filters)
```

### If Too Many Trades (15+ per day)
```
→ Increase "Min ATR" to 3.0 (trade only high volatility)
→ Reduce "Max Daily Trades" to 8
→ Disable Asian session (if enabled)
```

### If Too Few Trades (< 3 per day)
```
→ Decrease "Min Pattern Confidence" to 0.70
→ Decrease "Min ATR" to 1.5
→ Enable both London AND NY sessions
→ Increase "Max Spread Points" to 25
```

---

## Strategy Testing (Backtest)

### Run Strategy Tester
```
1. View → Strategy Tester (Ctrl+R)
2. Expert: GoldScalpingBot
3. Symbol: XAUUSD
4. Period: M5
5. Date: Last 3 months
6. Model: "Every tick" (most accurate)
7. Click "Start"
```

### Good Backtest Results
```
✅ Profit Factor > 1.3
✅ Max Drawdown < 20%
✅ Win Rate > 50%
✅ Total Trades > 100
✅ Recovery Factor > 3.0
```

### Poor Backtest Results
```
❌ Profit Factor < 1.1 → Optimize parameters
❌ Max Drawdown > 30% → Reduce risk%
❌ Win Rate < 45% → Tighten entry filters
```

---

## Going Live (After 2-4 Weeks Demo)

### Pre-Live Checklist
```
☐ Demo traded successfully for 2+ weeks
☐ Win rate > 50%
☐ Profit Factor > 1.3
☐ Max drawdown < 20%
☐ VPS set up (if using)
☐ Live broker has < 20 point spread
☐ Account balance > $500 minimum
☐ Risk% set to 0.5% or lower for live
```

### First Week Live
```
- Start with 0.25% risk (VERY conservative)
- Max 3-5 trades per day
- Monitor EVERY trade closely
- Expect 20-30% worse results than demo (normal)
- If > 10% drawdown in first week → STOP and re-evaluate
```

### After 1 Month Live
```
- If profitable → Increase risk to 0.5%
- If breakeven → Continue with 0.25%, optimize
- If losing → STOP, analyze, re-optimize on demo
```

---

## Critical Rules for Live Trading

### DO:
✅ Start with 0.25-0.5% risk maximum
✅ Run on VPS (24/5 uptime)
✅ Monitor daily stats
✅ Stop trading after 10% drawdown (manual review)
✅ Keep detailed log of all trades
✅ Re-optimize every 3 months

### DON'T:
❌ Increase risk after losses (revenge trading)
❌ Disable safety features (daily limits, stop loss)
❌ Trade during major news without testing
❌ Use with balance < $500
❌ Expect 20%+ monthly returns consistently
❌ Let it run unmonitored for weeks

---

## Emergency Stop Procedure

### If Things Go Wrong
```
1. IMMEDIATELY click "AutoTrading" button (disable bot)
2. Manually close all open positions
3. Remove EA from chart
4. Review Experts log for errors
5. Contact support: support@smartstocktrader.com
```

### Warning Signs
```
🚨 5+ consecutive losses
🚨 Drawdown > 15% in single day
🚨 Spread suddenly > 50 points (broker issue)
🚨 Trades opening outside session times
🚨 Position sizes larger than expected
```

---

## Next Steps

### Week 1-2: Demo Testing
- Monitor bot behavior
- Verify entries match strategy
- Check partial closes working
- Track win rate and profit factor

### Week 3-4: Optimization
- Backtest last 6 months
- Optimize risk%, SL, TP parameters
- Test different strategies (breakout vs VWAP vs momentum)
- Forward test optimized parameters

### Month 2+: Live Trading
- Start with micro capital ($500-1000)
- 0.25% risk only
- Scale up SLOWLY if profitable

---

## Support

**Questions?**
- Email: support@smartstocktrader.com
- Documentation: GoldScalpingBot_README.md (full guide)

**Bugs/Issues?**
- Check Experts log first
- Send log file + screenshot to support

---

**Good luck and trade safely!** 🚀

Remember: Scalping is HIGH RISK. Start small, test thoroughly, and never risk more than you can afford to lose.
