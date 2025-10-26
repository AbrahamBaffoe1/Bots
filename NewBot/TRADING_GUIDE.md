# Complete Trading Guide - MT5 Expert Advisors

## Understanding the Three EAs

### When to Use Each EA

#### stocksOnlymachine.mq5
**Use For**: US Stock Market Trading

**Best Conditions**:
- High liquidity stocks (FAANG, major tech)
- Regular market hours (9:30 AM - 4:00 PM EST)
- Trending or mean-reverting markets
- Low to moderate volatility

**Avoid**:
- Earnings announcements
- Pre/post market hours
- Extremely low volume stocks
- Major market events (Fed announcements)

**Recommended Symbols**:
- AAPL (Apple)
- MSFT (Microsoft)
- GOOGL (Google)
- AMZN (Amazon)
- TSLA (Tesla)
- NVDA (Nvidia)
- META (Meta)
- NFLX (Netflix)

#### GoldTrader.mq5
**Use For**: Gold/XAU Trading

**Best Conditions**:
- High volatility periods
- London/NY session overlaps
- Clear trending markets
- Major news events (for breakout strategy)

**Avoid**:
- Asian session (unless configured)
- Low volatility consolidation
- Major holiday periods
- Thin liquidity hours

**Optimal Sessions**:
- **London**: 8:00 AM - 5:00 PM GMT (highest volume)
- **NY**: 1:00 PM - 10:00 PM GMT (good volatility)
- **Overlap**: 1:00 PM - 5:00 PM GMT (best period)

#### forexMaster.mq5
**Use For**: Major Forex Pairs

**Best Conditions**:
- High liquidity pairs
- Clear trends or ranges
- Active trading sessions
- Normal spreads

**Avoid**:
- Exotic pairs (unless very experienced)
- Extreme news events
- Low liquidity hours
- Highly correlated overexposure

**Recommended Pairs**:
- EURUSD (most liquid)
- GBPUSD (high volatility)
- USDJPY (technical trader's favorite)
- AUDUSD (commodity correlation)
- USDCAD (oil correlation)

## Strategy Deep Dive

### Stock EA: RSI + MA Strategy

**Entry Conditions**:

**BUY Signal**:
1. Price > 200 MA (uptrend)
2. RSI < 30 (oversold)
3. Current close > Previous close (bullish candle)
4. Spread < Max Spread
5. Within trading hours

**SELL Signal**:
1. Price < 200 MA (downtrend)
2. RSI > 70 (overbought)
3. Current close < Previous close (bearish candle)
4. Spread < Max Spread
5. Within trading hours

**Position Management**:
- Stop Loss: Entry ± (ATR × 2.0)
- Take Profit: Entry ± (SL Distance × 2.0)
- Trailing Stop: Activates at 50% profit
- Partial Close: 50% at first TP level (optional)

### Gold EA: Multi-Strategy System

#### 1. Breakout Strategy

**Logic**:
- Find highest high and lowest low of last N bars
- Enter when price breaks out with volume confirmation
- Best in ranging-to-trending transitions

**BUY Breakout**:
1. Close > Highest High (20 bars)
2. Close > Trend MA (200)
3. Volume > Average Volume × 1.5 (if filter enabled)

**SELL Breakout**:
1. Close < Lowest Low (20 bars)
2. Close < Trend MA (200)
3. Volume > Average Volume × 1.5

**Stops**:
- SL: Entry ± (ATR × 1.5)
- TP: Entry ± (ATR × 3.0)

#### 2. Mean Reversion Strategy

**Logic**:
- Trade Bollinger Band extremes
- Require oscillator confirmation
- Target return to middle band

**BUY Signal**:
1. Close < Lower Bollinger Band
2. RSI < 20 (oversold)
3. Stochastic < 20 (oversold)

**SELL Signal**:
1. Close > Upper Bollinger Band
2. RSI > 80 (overbought)
3. Stochastic > 80 (overbought)

**Targets**:
- SL: Entry ± (ATR × 1.5)
- TP: Middle Bollinger Band

#### 3. Trend Following Strategy

**Logic**:
- EMA crossover with trend filter
- Require strong ADX (trending market)
- Momentum confirmation via MACD

**BUY Signal**:
1. Fast EMA crosses above Slow EMA
2. Close > Trend MA (200)
3. ADX > 25 (strong trend)
4. MACD > Signal Line and MACD > 0

**SELL Signal**:
1. Fast EMA crosses below Slow EMA
2. Close < Trend MA (200)
3. ADX > 25
4. MACD < Signal Line and MACD < 0

**Stops**:
- SL: Entry ± (ATR × 1.5)
- TP: Entry ± (ATR × 3.0)

#### 4. Hybrid Strategy

**Logic**:
- Evaluates all three strategies
- Selects highest confidence signal
- Combines strengths of each approach

**Confidence Scoring**:
- Breakout: 75%
- Mean Reversion: 70%
- Trend: 80%
- Minimum threshold: 60%

### Forex EA: Multi-Currency Trading

#### Trend Strategy (MACD + EMA)

**BUY Signal**:
1. Fast EMA > Slow EMA (crossover)
2. MACD > MACD Signal
3. MACD > 0 (bullish territory)
4. ADX > 25 (minimum trend strength)

**SELL Signal**:
1. Fast EMA < Slow EMA (crossover)
2. MACD < MACD Signal
3. MACD < 0 (bearish territory)
4. ADX > 25

**Position Sizing**:
- Base Risk: 1.0% / (Active Trades + 1)
- Confidence Weighting: Applied
- Correlation Adjustment: Applied

#### Scalping Strategy

**BUY Signal**:
1. Close > Fast EMA (5-period)
2. RSI > 50 and RSI < 70
3. Recent bullish momentum

**SELL Signal**:
1. Close < Fast EMA
2. RSI < 50 and RSI > 30
3. Recent bearish momentum

**Targets**:
- SL: 5 pips
- TP: 10 pips
- Risk:Reward: 1:2

#### Correlation Management

**How It Works**:
1. Calculates correlation between active pairs
2. Avoids adding correlated positions in same direction
3. Prevents overexposure to single currency

**Example**:
- Already LONG EURUSD
- GBPUSD BUY signal appears
- Both contain USD and are positively correlated
- Signal rejected to avoid overexposure

## Risk Management Mastery

### Position Sizing Calculation

**ATR-Based Method** (Recommended):

```
Risk Amount = Account Balance × Risk%
ATR = Average True Range (14 periods)
SL Distance = ATR × Multiplier

Lot Size = Risk Amount / (SL Distance / Point × Tick Value)
```

**Example**:
```
Account: $10,000
Risk: 1% = $100
ATR: 20 points
ATR Multiplier: 2.0
SL Distance: 40 points

Lot Size = $100 / (40 / 0.0001 × $1)
         = $100 / $400
         = 0.25 lots
```

**Fixed Percentage Method**:
```
SL Distance = Entry Price × Risk%
Lot Size = Risk Amount / SL Distance
```

### Daily Limits Strategy

**Why Daily Limits Matter**:
- Prevents revenge trading
- Controls drawdown
- Enforces discipline
- Protects capital

**Setting Appropriate Limits**:

**Conservative**:
- Max Daily Trades: 3-5
- Max Daily Loss: 1.5-2%
- Recovery needed: 1-2 winning trades

**Moderate**:
- Max Daily Trades: 8-12
- Max Daily Loss: 2.5-3%
- Recovery needed: 2-3 winning trades

**Aggressive**:
- Max Daily Trades: 15-20
- Max Daily Loss: 4-5%
- Recovery needed: 4-5 winning trades

### Trailing Stop Strategies

**Fixed Pip Trailing**:
```
Activation: 20 pips profit
Step: 10 pips
```

**ATR-Based Trailing**:
```
Activation: ATR × 1.5
Step: ATR × 0.5
```

**Percentage-Based Trailing**:
```
Activation: 50% of TP distance
Step: 25% of TP distance
```

### Break Even Strategy

**When to Move to BE**:

**Conservative**:
- Profit > 1.5× SL distance
- Locks in 5-10 pips profit

**Aggressive**:
- Profit > 0.5× SL distance
- Moves to exact entry (0 profit/loss)

**Recommended**:
- Profit > 1.0× SL distance
- Locks in small profit (5 pips)

## Optimal Settings by Account Size

### Small Account ($500 - $2,000)

**Stock EA**:
```
Risk Per Trade: 0.5%
Max Lot Size: 0.05
Max Daily Trades: 5
Max Daily Loss: 1.5%
Use Fixed Lot: FALSE
```

**Gold EA**:
```
Risk Per Trade: 0.3%
Max Lot Size: 0.03
Strategy: TREND (less risky)
Max Daily Trades: 3
Max Daily Loss: 1.0%
```

**Forex EA**:
```
Risk Per Trade: 0.5%
Max Lot Size: 0.05
Max Simultaneous: 2
Strategy: TREND
Max Daily Trades: 8
```

### Medium Account ($2,000 - $10,000)

**Stock EA**:
```
Risk Per Trade: 0.75%
Max Lot Size: 0.2
Max Daily Trades: 8
Max Daily Loss: 2.0%
Partial Close: TRUE
```

**Gold EA**:
```
Risk Per Trade: 0.5%
Max Lot Size: 0.1
Strategy: HYBRID
Max Daily Trades: 5
Max Daily Loss: 1.5%
```

**Forex EA**:
```
Risk Per Trade: 0.75%
Max Lot Size: 0.2
Max Simultaneous: 4
Strategy: MULTI
Max Daily Trades: 12
Use Correlation: TRUE
```

### Large Account ($10,000+)

**Stock EA**:
```
Risk Per Trade: 1.0%
Max Lot Size: 1.0
Max Daily Trades: 10
Max Daily Loss: 2.5%
Partial Close: TRUE
Trailing Stop: TRUE
```

**Gold EA**:
```
Risk Per Trade: 0.75%
Max Lot Size: 0.5
Strategy: HYBRID
Max Daily Trades: 8
Max Daily Loss: 2.0%
Scale Out: TRUE
```

**Forex EA**:
```
Risk Per Trade: 1.0%
Max Lot Size: 1.0
Max Simultaneous: 5
Strategy: MULTI
Max Daily Trades: 20
Use Correlation: TRUE
Equity Stop: 5.0%
```

## Market Condition Adaptation

### Trending Markets

**Best EAs**: Gold (Trend), Forex (Trend)

**Settings Adjustments**:
- Increase ATR multiplier for TP
- Use wider trailing stops
- Reduce partial close percentage
- Allow positions to run longer

**Example**:
```
ATR Multiplier TP: 3.0 → 4.0
Trailing Step: 10 pips → 15 pips
Partial Close: 50% → 30%
```

### Ranging Markets

**Best EAs**: Gold (Mean Reversion), Stock (RSI)

**Settings Adjustments**:
- Tighter stops
- Faster profit taking
- Increase oscillator sensitivity
- Use Bollinger Band strategies

**Example**:
```
ATR Multiplier SL: 2.0 → 1.5
Risk:Reward: 1:2 → 1:1.5
RSI Levels: 30/70 → 35/65
```

### High Volatility

**Best Approach**: Reduce risk, widen stops

**Adjustments**:
```
Risk Per Trade: 1.0% → 0.5%
ATR Multiplier: 2.0 → 2.5
Max Spread: 20 pips → 30 pips
Partial Close: Enable at 50%
```

### Low Volatility

**Best Approach**: Scalp or wait for breakout

**Adjustments**:
```
Strategy: Switch to SCALPING
Target Pips: Reduce to 5-10
Min ATR: Increase threshold
Or pause trading until volatility returns
```

## Performance Monitoring

### Key Metrics to Track

**Win Rate**:
- Target: 50-60% for trend
- Target: 60-70% for mean reversion
- Formula: Wins / Total Trades × 100

**Risk:Reward Ratio**:
- Minimum: 1:1.5
- Target: 1:2 or better
- Formula: Avg Win / Avg Loss

**Profit Factor**:
- Minimum: 1.2
- Target: 1.5+
- Formula: Gross Profit / Gross Loss

**Maximum Drawdown**:
- Warning: > 10%
- Critical: > 20%
- Formula: (Peak - Trough) / Peak × 100

**Sharpe Ratio**:
- Good: > 1.0
- Excellent: > 2.0
- Formula: (Return - Risk-Free Rate) / StdDev

### Weekly Review Checklist

**Trading Performance**:
- [ ] Total trades executed
- [ ] Win rate %
- [ ] Average profit per trade
- [ ] Average loss per trade
- [ ] Largest win and loss
- [ ] Current drawdown %

**System Health**:
- [ ] Any connection errors?
- [ ] All trades executed properly?
- [ ] Slippage within acceptable range?
- [ ] Backend communication working?
- [ ] No duplicate trades?

**Settings Review**:
- [ ] Risk % still appropriate?
- [ ] Daily limits working?
- [ ] Strategy performing as expected?
- [ ] Need to adjust for market conditions?

### Monthly Optimization

**Statistical Analysis**:
1. Export trade history from MT5
2. Calculate all key metrics
3. Compare to previous month
4. Identify patterns

**Questions to Ask**:
- Which EA performed best?
- Which symbols were most profitable?
- What times of day worked best?
- Were there any anomalies?
- Do settings need adjustment?

**Action Items**:
- Adjust underperforming EA settings
- Increase allocation to best performers
- Remove problematic symbols
- Update risk parameters if needed

## Advanced Techniques

### Compounding Profits

**Method 1: Fixed Risk % Compounding**:
- Always risk 1% of current balance
- Automatically compounds as account grows
- Natural position sizing increase

**Method 2: Partial Compounding**:
```
Risk Amount = (Starting Balance × 1%) + (Profit × 0.5%)
```
- Compounds 50% of profits
- Keeps 50% as cushion

**Method 3: Threshold Compounding**:
- Risk 0.5% until +20% account growth
- Then increase to 1%
- At +50%, increase to 1.5%

### Multi-EA Portfolio

**Diversification Strategy**:

**Setup 1: Balanced**:
- 40% Stock EA (AAPL, MSFT)
- 30% Gold EA (XAUUSD)
- 30% Forex EA (EURUSD, GBPUSD)

**Setup 2: Conservative**:
- 50% Stock EA (low volatility stocks)
- 30% Forex EA (major pairs only)
- 20% Gold EA (trend strategy only)

**Setup 3: Aggressive**:
- 30% Stock EA (tech stocks)
- 40% Gold EA (hybrid strategy)
- 30% Forex EA (5+ pairs, all strategies)

### News Trading Integration

**High-Impact News**:
- Fed Announcements
- NFP (Non-Farm Payrolls)
- CPI/Inflation Data
- Earnings Reports

**Strategies**:

**1. Avoid Completely** (Safest):
- Set "Avoid News" = TRUE
- EA pauses 30 min before/after news

**2. Widen Stops** (Moderate):
- Increase ATR multiplier before news
- Reduce position size
- Faster break-even trigger

**3. Trade the Breakout** (Aggressive):
- Use Gold EA Breakout strategy
- Wait for initial move
- Enter on retest with momentum

## Troubleshooting Performance

### Low Win Rate (< 45%)

**Possible Causes**:
- Poor entry timing
- Stops too tight
- Wrong strategy for market conditions
- High slippage

**Solutions**:
- Review entry signals
- Increase ATR multiplier for SL
- Switch strategies
- Change broker/check execution

### Good Win Rate, Still Losing

**Cause**: Poor Risk:Reward Ratio

**Solutions**:
- Increase TP targets
- Tighten stops
- Let winners run longer
- Use trailing stops more aggressively

### Excessive Drawdown

**Causes**:
- Risk per trade too high
- No daily limits
- Consecutive losses
- Over-trading

**Solutions**:
- Reduce risk to 0.5%
- Enable/reduce daily loss limit
- Pause after 3 losses
- Reduce max daily trades

### Too Few Trades

**Causes**:
- Filters too strict
- Wrong timeframe
- Inappropriate symbols
- Risk settings preventing trades

**Solutions**:
- Relax spread filter
- Try lower timeframes (M30, M15)
- Add more symbols
- Check lot size calculations

## Best Practices Summary

### Do's ✓

1. **Always test on demo first** (minimum 2 weeks)
2. **Start with small risk** (0.3-0.5%)
3. **Use daily limits** religiously
4. **Monitor logs daily**
5. **Keep good records** of all changes
6. **Review performance weekly**
7. **Adjust based on data**, not emotions
8. **Use VPS** for 24/7 reliability
9. **Backup settings** regularly
10. **Stay updated** on market conditions

### Don'ts ✗

1. **Don't skip demo testing**
2. **Don't over-leverage**
3. **Don't ignore daily limits**
4. **Don't interfere with trades**
5. **Don't over-optimize**
6. **Don't trade on unstable internet**
7. **Don't neglect logs/monitoring**
8. **Don't use on untested symbols**
9. **Don't risk more than you can afford**
10. **Don't blame the EA** - review your settings

---

## Final Thoughts

Successful automated trading requires:
- **Patience**: Results take time
- **Discipline**: Follow the system
- **Monitoring**: Stay aware but don't interfere
- **Adaptation**: Markets change, adjust accordingly
- **Risk Management**: Protect capital above all

The EAs are tools - your success depends on how you use them.

**Start small, test thoroughly, scale carefully.** 🎯
