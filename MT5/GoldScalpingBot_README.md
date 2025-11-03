# Gold Scalping Bot v1.0 - Complete Guide

## Overview

The **Gold Scalping Bot** is a high-frequency trading Expert Advisor (EA) specifically designed for XAUUSD (Gold) scalping on the M5 timeframe. It implements three proven scalping strategies with ultra-tight risk management optimized for capturing small, frequent profits.

---

## Key Features

### Core Strategies
1. **Breakout Scalping** - Trades 5-bar range breakouts with volume confirmation
2. **VWAP Bounce Scalping** - Trades bounces from VWAP (support/resistance)
3. **Momentum Scalping** - Trades volume spikes with candlestick pattern confirmation
4. **Hybrid Mode** - Automatically selects highest-confidence signal

### Scalping-Specific Features
- ✅ **Tight Stops**: 10-30 pips (default 20 pips)
- ✅ **Fast Targets**: 20-50 pips (default 40 pips, 2:1 R:R)
- ✅ **Time-Based Exit**: Auto-close after 60 minutes if target not hit
- ✅ **Rapid Break-Even**: Moves SL to BE at +10 pips profit
- ✅ **Aggressive Trailing**: Starts at +15 pips, trails by 10 pips
- ✅ **Partial Closes**: 25% at +20/+30/+40 pips (keeps 25% for runners)
- ✅ **Spread Monitoring**: Rejects entries if spread > 20 points
- ✅ **Session Filtering**: London (8-12 GMT), NY (13-17 GMT)
- ✅ **London Fix Avoidance**: Blocks trading during fix times
- ✅ **Daily Limits**: Max 10 trades/day, 2% max drawdown

---

## Installation

### 1. Copy Files to MT5

```bash
# Main EA file
MT5/MQL5/Experts/GoldScalpingBot.mq5

# Strategy library
MT5/MQL5/Include/SST_ScalpingStrategy.mqh
```

### 2. Compile in MetaEditor

1. Open **MetaEditor** (F4 in MT5)
2. Open `GoldScalpingBot.mq5`
3. Click **Compile** (F7)
4. Verify: "0 error(s), 0 warning(s)"

### 3. Attach to Chart

1. Open **XAUUSD** chart
2. Set timeframe to **M5**
3. Drag **GoldScalpingBot** from Navigator
4. Configure parameters (see below)
5. Enable **AutoTrading** (Ctrl+E or button in toolbar)

---

## Recommended Parameters (CONSERVATIVE)

### For $500-1000 Accounts (Micro Lots)

```
=== SCALPING STRATEGY ===
Scalping Strategy: SCALP_HYBRID
Scalping Timeframe: M5
Stop Loss: 20 pips
Take Profit: 40 pips
Max Hold Time: 60 minutes

=== RISK MANAGEMENT ===
Risk Per Trade: 0.5%        ← Conservative
Min Lot Size: 0.01          ← Micro lot
Max Lot Size: 0.10          ← Cap to prevent over-leverage
Magic Number: 300001
Max Daily Trades: 10        ← Scalping allows more trades
Max Daily Drawdown: 2.0%    ← Circuit breaker

=== ENTRY FILTERS ===
Max Spread: 20 points       ← CRITICAL - reject if wider
Min ATR: 2.0 USD            ← Require volatility
Volume Multiplier: 1.5      ← Volume spike threshold
Require Pattern: true       ← Candlestick confirmation
Min Pattern Confidence: 0.75 ← 75% minimum confidence

=== EXIT MANAGEMENT ===
Break-Even Trigger: 10 pips  ← Move SL to BE quickly
Trailing Start: 15 pips      ← Start trailing early
Trailing Step: 10 pips       ← Tight trailing
Use Partial Close: true
  Partial 1: 20 pips (close 25%)
  Partial 2: 30 pips (close 25%)
  Partial 3: 40 pips (close 25%)
  → 25% remains for big runners

=== SESSION FILTERS ===
Trade London: true          ← 8-12 GMT (BEST)
Trade NY: true              ← 13-17 GMT (BEST)
Trade Asian: false          ← Low volume, avoid
Avoid London Fix: true      ← 10:30, 15:00 GMT
Avoid News: true            ← Block high-impact news

=== ADVANCED ===
Trading Symbol: XAUUSD
Max Slippage: 30 points
Enable WebSocket: false     ← For backend integration
```

### For $1000-5000 Accounts (Standard Risk)

```
Risk Per Trade: 0.75%
Min Lot Size: 0.01
Max Lot Size: 0.50
Max Daily Trades: 15
```

### For $5000+ Accounts (Aggressive)

```
Risk Per Trade: 1.0%
Min Lot Size: 0.01
Max Lot Size: 2.0
Max Daily Trades: 20
Stop Loss: 15 pips          ← Tighter stops
Take Profit: 30 pips        ← Faster targets
```

---

## Strategy Details

### 1. Breakout Scalping

**Entry Conditions:**
- Price breaks above/below 5-bar range high/low
- Breakout confirmed by 3+ pips beyond range
- Volume > 1.5x average volume
- Spread < 20 points

**Stop Loss:** Range opposite extreme (high for sells, low for buys)

**Take Profit:** 2x risk distance

**Confidence:** 75% base + 15% if volume spike

**Example:**
```
5-bar range: 2650.00 - 2655.00 (50 pips)
Breakout: Price closes at 2655.50 (3 pips above high)
Volume: 2.1x average (volume spike confirmed)
→ BUY signal, SL: 2650.00, TP: 2660.00
→ Confidence: 90% (75% + 15% volume bonus)
```

### 2. VWAP Bounce Scalping

**Entry Conditions:**
- Price within 5 pips of VWAP (20-bar)
- For BUY: Price ≤ VWAP AND RSI < 50
- For SELL: Price ≥ VWAP AND RSI > 50
- Spread < 20 points

**Stop Loss:** 0.5x ATR from entry

**Take Profit:** 1.0x ATR from entry

**Confidence:** 70% base + 10% if RSI extreme (<40 or >60)

**Example:**
```
VWAP: 2652.50
Current Price: 2652.30 (0.2 pips from VWAP)
RSI: 38 (oversold)
ATR: 5.0
→ BUY signal (bounce from VWAP support)
→ SL: 2650.00 (entry - 0.5*ATR)
→ TP: 2657.50 (entry + 1.0*ATR)
→ Confidence: 80% (70% + 10% RSI bonus)
```

### 3. Momentum Scalping

**Entry Conditions:**
- Strong bullish/bearish candle (body > 60% of range)
- Volume > 1.5x average
- RSI in momentum zone (50-70 for BUY, 30-50 for SELL)
- Spread < 20 points

**Stop Loss:** Recent swing low/high - 0.3x ATR buffer

**Take Profit:** 2x risk distance

**Confidence:** 75% base + 10% if RSI in ideal zone (55-65 BUY, 35-45 SELL)

**Example:**
```
Candle: Open 2650, Close 2655 (50 pip bullish body)
Body %: 75% of total range (strong candle)
Volume: 1.8x average
RSI: 58 (ideal momentum zone)
→ BUY signal
→ SL: 2649.00 (recent swing low - 0.3*ATR)
→ TP: 2667.00 (2x risk)
→ Confidence: 85%
```

---

## Exit Management (Critical for Scalping)

### 1. Time-Based Exit
If position not closed within **60 minutes**, auto-close at market price.

**Rationale:** Scalping is short-term. Holding > 1 hour means setup failed.

### 2. Rapid Break-Even
At **+10 pips profit**, SL moves to entry (break-even).

**Rationale:** Protect capital quickly. Gold can reverse fast.

### 3. Partial Closes (Maximize Profits)
- **+20 pips:** Close 25% (lock initial profit)
- **+30 pips:** Close 25% (secure more profit)
- **+40 pips:** Close 25% (hit take profit target)
- **Remaining 25%:** Let run with trailing stop for big moves

**Example:**
```
Entry: 0.10 lot BUY at 2650.00
+20 pips (2670.00): Close 0.025 lot → $50 locked
+30 pips (2680.00): Close 0.025 lot → $75 more locked
+40 pips (2690.00): Close 0.025 lot → $100 more locked
Remaining: 0.025 lot runs with trailing stop
→ If hits +100 pips: $150 more = $375 total
→ Total: $50 + $75 + $100 + $150 = $375 on 0.10 lot
```

### 4. Aggressive Trailing
- **Activation:** +15 pips profit
- **Trail Distance:** 10 pips behind current price
- **Never moves backwards:** Only tightens

**Example:**
```
Entry: 2650.00 (BUY)
Price: 2665.00 (+15 pips) → Trailing activates
→ SL: 2655.00 (10 pips behind)

Price: 2670.00 (+20 pips)
→ SL: 2660.00 (10 pips behind)

Price: 2675.00 (+25 pips)
→ SL: 2665.00 (10 pips behind, +15 pips locked)
```

---

## Session & Time Filters

### Best Trading Times (Gold Volatility)

**1. London Session (8:00-12:00 GMT) ⭐⭐⭐⭐⭐**
- **Why:** London open = massive volume, tight spreads
- **Best hours:** 8:00-10:00 GMT (overlap with European markets)
- **Characteristics:** Strong directional moves, ideal for breakouts

**2. NY Session (13:00-17:00 GMT) ⭐⭐⭐⭐⭐**
- **Why:** US data releases, high liquidity
- **Best hours:** 13:30-15:00 GMT (US market open + data)
- **Characteristics:** Momentum plays, news-driven moves

**3. Asian Session (0:00-9:00 GMT) ⭐⭐☆☆☆**
- **Why:** Low volume, wider spreads
- **Avoid:** Unless you're in Asia timezone
- **Characteristics:** Range-bound, harder to scalp profitably

### London Fix Times (AVOID)

**Morning Fix:** 10:25-10:35 GMT
**Afternoon Fix:** 14:55-15:05 GMT

**Why Avoid:**
- Erratic price action (banks hedging positions)
- Spread widens dramatically (3-5x normal)
- Stop hunts common
- Not suitable for scalping

### News Events (AVOID)

**High-Impact Events:**
- NFP (First Friday, 13:30 GMT)
- FOMC (Fed meetings, 19:00 GMT)
- CPI (Inflation data, 13:30 GMT)
- Unemployment Claims (Thursday, 13:30 GMT)

**Why Avoid:**
- Extreme volatility spikes
- Slippage > 10 pips common
- Spread > 50 points possible
- Gaps and whipsaws

**Bot Behavior:**
- No new entries 15 min before/after high-impact news
- Existing positions remain open (protected by SL)

---

## Risk Management

### Position Sizing

The bot uses **fixed percentage risk** based on stop loss distance:

```
Risk Amount = Account Balance × Risk% × Confidence
Lot Size = Risk Amount / (SL Distance in $ per lot)
```

**Example 1: $1000 account, 0.5% risk, 75% confidence**
```
Risk Amount = $1000 × 0.5% × 0.75 = $3.75
SL Distance = 20 pips = $20 per 0.01 lot (Gold)
Lot Size = $3.75 / $20 = 0.01875 → Rounds to 0.01 lot
```

**Example 2: $5000 account, 1.0% risk, 85% confidence**
```
Risk Amount = $5000 × 1.0% × 0.85 = $42.50
SL Distance = 20 pips = $20 per 0.01 lot
Lot Size = $42.50 / $20 = 0.02125 → Rounds to 0.02 lot
```

### Daily Limits (Circuit Breakers)

**1. Max Daily Trades:**
- Default: 10 trades/day
- Prevents over-trading
- Resets at 00:00 GMT

**2. Max Daily Drawdown:**
- Default: 2% of starting equity
- If equity drops 2% from day's high → STOP trading
- Prevents runaway losses
- Example: Start with $1000 equity, max drops to $980
  - If equity hits $980 → No more trades today
  - Resumes next day

**3. Maximum Spread:**
- Default: 20 points
- If spread > 20 points → Reject entry
- Critical for scalping profitability
- Example: 20 point spread = 20% of 40 pip target

---

## Spread Impact (CRITICAL)

Gold scalping profitability heavily depends on spread:

### Spread Examples

| Spread | 40 Pip Target | Profit After Spread | Impact    |
|--------|---------------|---------------------|-----------|
| 10 pts | 40 pips       | 30 pips (75%)       | ✅ Good   |
| 20 pts | 40 pips       | 20 pips (50%)       | ⚠️ OK     |
| 30 pts | 40 pips       | 10 pips (25%)       | ❌ Bad    |
| 50 pts | 40 pips       | -10 pips (-25%)     | ❌ Fatal  |

**Recommendation:**
- **Ideal:** < 15 points (75%+ of target retained)
- **Acceptable:** 15-20 points (50-75% retained)
- **Avoid:** > 20 points (< 50% retained)

### Broker Selection

Choose brokers with:
- ✅ **ECN/Raw Spread:** 5-15 points typical
- ✅ **Low Commission:** $3-7 per lot round-turn
- ✅ **Fast Execution:** < 50ms average
- ✅ **VPS Near Server:** < 5ms ping
- ❌ **Avoid Market Makers:** 30-50+ point spreads

**Recommended:**
- IC Markets (ECN, 8-12 point spread)
- Pepperstone (Razor, 10-15 point spread)
- FP Markets (Raw, 8-12 point spread)

---

## Expected Performance (Realistic)

### Conservative Parameters (0.5% risk, 20 pip SL, 40 pip TP)

**Assumptions:**
- Win Rate: 55-60%
- Average Win: 30 pips (after partial closes)
- Average Loss: 20 pips (full SL)
- Trades per day: 5-8
- Spread: 15 points average

**Monthly Projection ($1000 account):**
```
Trades/month: 100 (5/day × 20 trading days)
Wins: 58 trades × $6 avg = $348
Losses: 42 trades × $4 avg = -$168
Net: $180/month = 18% monthly return

Drawdown: 10-15% max expected
```

**Reality Check:**
- ⚠️ **18% monthly is AGGRESSIVE** - don't expect this every month
- ⚠️ Losing weeks/months WILL happen
- ⚠️ Drawdowns of 20-25% possible during bad periods
- ⚠️ Live results typically 30-50% worse than backtest

### Aggressive Parameters (1.0% risk, 15 pip SL, 30 pip TP)

**Higher risk = higher returns AND higher drawdowns**
```
Monthly potential: 25-35%
Max drawdown: 20-30%
```

---

## Backtest Requirements

### Minimum Backtest Period
- **3-6 months** of M5 tick data (Quality: 99%)
- Include **multiple market conditions:**
  - Trending (Sep-Oct 2024: strong uptrend)
  - Ranging (July-Aug 2024: choppy)
  - High volatility (Mar 2024: banking crisis)

### Key Metrics to Track
```
Win Rate: > 50% required
Profit Factor: > 1.3 minimum (1.5+ ideal)
Max Drawdown: < 20% acceptable
Sharpe Ratio: > 1.0 good
Recovery Factor: > 3.0 (profit/max DD)
Average Trade: > 0 (after spread)
```

### Strategy Tester Settings
```
Model: Every tick (most accurate)
Spread: Current (or 15 points fixed)
Period: 2024-01-01 to 2024-06-30 (6 months)
Deposit: $1000
Optimization: Genetic algorithm
  - Optimize: Risk%, SL pips, TP pips
  - Criteria: Custom (Profit Factor × Recovery Factor)
```

---

## Troubleshooting

### "Not enough money" Error
**Cause:** Position size too large for account balance
**Fix:**
- Increase account balance
- Reduce `Risk Per Trade %` (try 0.25%)
- Reduce `Max Lot Size` (try 0.01)

### No Trades Executing
**Cause 1:** Spread too wide
- Check: "Spread too wide" in Experts log
- Fix: Trade during London/NY sessions only
- Fix: Increase `Max Spread Points` to 25-30 (less profitable)

**Cause 2:** Daily limit reached
- Check: "Daily drawdown limit reached" in log
- Fix: Wait for next day (00:00 GMT)

**Cause 3:** Outside trading session
- Check: Current time vs session settings
- Fix: Adjust session inputs or wait for London/NY

### Positions Closing Too Early
**Cause:** Break-even or trailing stop triggered
**Fix:**
- Increase `Break-Even Trigger` (try 15-20 pips)
- Increase `Trailing Start` (try 20-25 pips)
- Increase `Trailing Step` (try 15 pips)

### Too Many Losses
**Cause 1:** Market conditions not suitable
- Gold ranging/choppy → Breakout strategy fails
- Fix: Switch to `SCALP_VWAP_BOUNCE` or `SCALP_MOMENTUM`

**Cause 2:** Spread eating profits
- 20 point spread = 50% of 40 pip target
- Fix: Better broker or avoid Asian session

**Cause 3:** Slippage
- Check execution prices vs intended entry
- Fix: VPS closer to broker server

---

## VPS Requirements

### Why VPS Needed
- ✅ **24/5 uptime** - Catch all London/NY opportunities
- ✅ **Low latency** - < 5ms to broker = less slippage
- ✅ **No interruptions** - PC crashes/power outages don't stop bot

### Recommended Specs
```
CPU: 2 cores minimum
RAM: 2 GB minimum
Storage: 20 GB SSD
Location: London or New York (near broker server)
OS: Windows Server 2016+ or Linux (MT5 Wine)
Network: 100 Mbps+, < 5ms ping to broker
```

### Providers
- **Forex VPS:** $20-30/month, optimized for MT5
- **Beeks VPS:** $40/month, ultra-low latency
- **Vultr/DigitalOcean:** $10-20/month, DIY setup

---

## FAQ

### Q: What's the minimum account size?
**A:** $500-1000 recommended for micro lots (0.01). Lower balances struggle with margin requirements for Gold.

### Q: Can I trade other pairs?
**A:** No - optimized for Gold (XAUUSD) only. Different assets have different characteristics.

### Q: What's the realistic monthly return?
**A:** 5-15% monthly is realistic long-term. 18%+ possible short-term but not sustainable.

### Q: How often should I optimize parameters?
**A:** Every 3-6 months or after major market regime change (e.g., Fed policy shift).

### Q: Can I use with prop firm accounts?
**A:** Yes - but check rules:
- Max daily loss limits (usually 5%)
- Max position sizes
- Banned news trading
- Scalping allowed?

### Q: What's the max drawdown I should expect?
**A:** 15-25% drawdowns are normal for scalping. If > 30%, stop and re-evaluate.

---

## Support & Updates

### Logs Location
```
MT5/MQL5/Logs/[Date].log
```

Check logs for:
- Entry/exit reasons
- Spread warnings
- Daily stats
- Error messages

### Performance Monitoring
- Check **daily stats** printed at end of each day
- Track **win rate, profit factor** weekly
- Review **max drawdown** monthly

### Version History
- **v1.0** (2025-01-XX): Initial release
  - 3 scalping strategies
  - Partial closes
  - London Fix avoidance
  - Time-based exits

---

## Disclaimer

**RISK WARNING:** Gold scalping is high-risk trading. Past performance does not guarantee future results. Only trade with money you can afford to lose. This EA is provided "as-is" without warranty. Test thoroughly on demo before live trading.

**NOT FINANCIAL ADVICE:** This bot is a tool, not a financial advisor. You are responsible for your trading decisions and risk management.

---

## Contact

- Website: https://smartstocktrader.com
- Support: support@smartstocktrader.com
- GitHub: [Repository Link]

---

**Last Updated:** 2025-01-XX
**Version:** 1.0
**Author:** SmartStockTrader Team
