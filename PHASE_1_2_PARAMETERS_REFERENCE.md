# Phase 1+2 Parameters Quick Reference

## 🎛️ ALL CONFIGURABLE PARAMETERS

### **NEWS FILTER (SST_NewsFilter.mqh)**
```mql4
extern bool    UseNewsFilter         = true;         // Enable/disable news filtering
extern int     MinutesBeforeNews     = 30;           // Stop trading X min before news (15-60)
extern int     MinutesAfterNews      = 30;           // Resume trading X min after news (15-60)
extern bool    TradeHighImpactNews   = false;        // Trade during high-impact news (⚠️ RISKY!)
extern bool    TradeMediumImpactNews = false;        // Trade during medium-impact news
extern bool    AutoDetectNewsSpike   = true;         // Detect news by volatility spike
extern double  VolatilitySpikeThreshold = 3.0;       // ATR spike multiplier for news detection (2.0-5.0)
```

**Recommended Settings:**
- **Conservative**: MinutesBeforeNews = 60, TradeHighImpactNews = false
- **Moderate**: MinutesBeforeNews = 30 (default)
- **Aggressive**: MinutesBeforeNews = 15, TradeMediumImpactNews = true

---

### **CORRELATION MATRIX (SST_CorrelationMatrix.mqh)**
```mql4
extern bool    UseCorrelationFilter  = true;         // Enable correlation filtering
extern double  MaxCorrelation        = 0.70;         // Max allowed correlation between positions (0.50-0.90)
extern int     CorrelationPeriod     = 20;           // Lookback period for correlation calculation (10-50)
extern int     MaxPositionsPerSector = 3;            // Max positions in same sector (1-5)
extern double  MaxSectorExposure     = 40.0;         // Max % of account in one sector (20-60%)
```

**Recommended Settings:**
- **Conservative**: MaxCorrelation = 0.50, MaxPositionsPerSector = 2, MaxSectorExposure = 30%
- **Moderate**: MaxCorrelation = 0.70 (default), MaxPositionsPerSector = 3, MaxSectorExposure = 40%
- **Aggressive**: MaxCorrelation = 0.85, MaxPositionsPerSector = 5, MaxSectorExposure = 60%

**Sector Types:**
- SECTOR_TECHNOLOGY
- SECTOR_FINANCE
- SECTOR_HEALTHCARE
- SECTOR_ENERGY
- SECTOR_CONSUMER
- SECTOR_INDUSTRIAL
- SECTOR_MATERIALS

---

### **ADVANCED VOLATILITY (SST_AdvancedVolatility.mqh)**
```mql4
extern bool    UseVolatilityFilter   = true;         // Enable volatility filtering
extern double  MinBBW                = 0.02;         // Minimum Bollinger Band Width (0.01-0.05)
extern double  MaxBBW                = 0.15;         // Maximum Bollinger Band Width (0.10-0.25)
extern double  MinATRPercentile      = 20.0;         // Minimum ATR percentile (10-40%)
extern double  MaxATRPercentile      = 90.0;         // Maximum ATR percentile (80-95%)
```

**Recommended Settings:**
- **Conservative**: MinBBW = 0.03, MaxBBW = 0.12, MinATRPercentile = 30%, MaxATRPercentile = 80%
- **Moderate**: MinBBW = 0.02 (default), MaxBBW = 0.15, MinATRPercentile = 20%, MaxATRPercentile = 90%
- **Aggressive**: MinBBW = 0.01, MaxBBW = 0.20, MinATRPercentile = 10%, MaxATRPercentile = 95%

**Volatility Regimes:**
| Regime | BBW | ATR % | SL Mult | TP Mult | Size Mult | Trade? |
|--------|-----|-------|---------|---------|-----------|--------|
| VERY_LOW | <0.02 | <20% | 0.7x | 0.8x | 0.5x | ❌ Avoid |
| LOW | <0.04 | <40% | 0.85x | 0.9x | 0.75x | ⚠️ Reduce |
| NORMAL | 0.04-0.10 | 40-70% | 1.0x | 1.0x | 1.0x | ✅ Trade |
| HIGH | 0.10-0.15 | 70-90% | 1.3x | 1.2x | 0.8x | ⚠️ Widen |
| VERY_HIGH | >0.15 | >90% | 1.5x | 1.5x | 0.5x | ❌ Avoid |

---

### **DRAWDOWN PROTECTION (SST_DrawdownProtection.mqh)**
```mql4
extern bool    UseDrawdownProtection = true;         // Enable drawdown protection
extern double  DrawdownLevel1        = 5.0;          // Level 1 protection threshold (3-7%)
extern double  DrawdownLevel2        = 10.0;         // Level 2 protection threshold (7-12%)
extern double  DrawdownLevel3        = 15.0;         // Level 3 protection threshold (12-18%)
extern double  SizeReductionLevel1   = 0.75;         // Size multiplier at Level 1 (0.50-0.90)
extern double  SizeReductionLevel2   = 0.50;         // Size multiplier at Level 2 (0.30-0.70)
extern double  SizeReductionLevel3   = 0.25;         // Size multiplier at Level 3 (0.10-0.50)
extern double  EmergencyStopLevel    = 20.0;         // Emergency stop threshold (15-25%)
extern bool    UseRecoveryMode       = true;         // Enable recovery mode
extern int     ConsecutiveLossLimit  = 3;            // Consecutive losses to trigger recovery (2-5)
extern int     RecoveryWinsRequired  = 2;            // Consecutive wins to exit recovery (2-4)
extern double  RecoveryMultiplier    = 0.50;         // Size multiplier in recovery mode (0.25-0.75)
```

**Recommended Settings:**
- **Conservative**:
  - DrawdownLevel1 = 3%, DrawdownLevel2 = 7%, DrawdownLevel3 = 12%
  - SizeReductionLevel1 = 0.50, SizeReductionLevel2 = 0.30, SizeReductionLevel3 = 0.10
  - EmergencyStopLevel = 15%
  - ConsecutiveLossLimit = 2

- **Moderate** (default):
  - DrawdownLevel1 = 5%, DrawdownLevel2 = 10%, DrawdownLevel3 = 15%
  - SizeReductionLevel1 = 0.75, SizeReductionLevel2 = 0.50, SizeReductionLevel3 = 0.25
  - EmergencyStopLevel = 20%
  - ConsecutiveLossLimit = 3

- **Aggressive**:
  - DrawdownLevel1 = 7%, DrawdownLevel2 = 12%, DrawdownLevel3 = 18%
  - SizeReductionLevel1 = 0.90, SizeReductionLevel2 = 0.70, SizeReductionLevel3 = 0.50
  - EmergencyStopLevel = 25%
  - ConsecutiveLossLimit = 4

**Drawdown Table:**
| Drawdown % | Status | Position Size | Action |
|------------|--------|---------------|--------|
| 0-5% | ✅ Normal | 100% | Trade normally |
| 5-10% | ⚠️ Level 1 | 75% | Reduce size |
| 10-15% | ⚠️ Level 2 | 50% | Half size |
| 15-20% | 🚨 Level 3 | 25% | Quarter size |
| >20% | 🛑 Emergency | STOP | No trading |

---

### **MULTI-ASSET CONFIRMATION (SST_MultiAsset.mqh)**
```mql4
extern bool    UseMultiAssetFilter   = true;         // Enable multi-asset confirmation
extern string  MarketIndex           = "SPY";        // Market index symbol (SPY, QQQ, DIA, SPX500)
extern int     MarketTrendMA         = 50;           // MA period for market trend (20, 50, 100, 200)
extern double  VIXLowThreshold       = 15.0;         // VIX low threshold (10-20)
extern double  VIXHighThreshold      = 30.0;         // VIX high threshold (25-40)
extern bool    RequireSectorConfirmation = true;     // Require sector ETF confirmation
extern double  MinConfirmationPercent = 75.0;        // Min % of signals that must agree (60-90%)
```

**Recommended Settings:**
- **Conservative**: MarketTrendMA = 200, VIXLowThreshold = 12, VIXHighThreshold = 25, MinConfirmationPercent = 80%
- **Moderate**: MarketTrendMA = 50 (default), VIXLowThreshold = 15, VIXHighThreshold = 30, MinConfirmationPercent = 75%
- **Aggressive**: MarketTrendMA = 20, VIXLowThreshold = 20, VIXHighThreshold = 35, MinConfirmationPercent = 60%

**Market Indices:**
- SPY = S&P 500 (broad market)
- QQQ = Nasdaq 100 (tech-heavy)
- DIA = Dow Jones 30 (blue chips)
- SPX500 = S&P 500 CFD

**Sector ETFs:**
- XLK = Technology
- XLF = Finance
- XLV = Healthcare
- XLE = Energy
- XLY = Consumer Discretionary
- XLI = Industrial

**Market Regimes:**
| Regime | SPY | VIX | Bonds | Action |
|--------|-----|-----|-------|--------|
| RISK_ON | ↑ Bullish | <20 | ↓ Falling | ✅ Long stocks |
| RISK_OFF | ↓ Bearish | >30 | ↑ Rising | ❌ Avoid longs, SHORT |
| ROTATION | Mixed | 20-30 | Flat | ⚠️ Sector-specific |
| UNCERTAIN | Mixed | Mixed | Mixed | ⚠️ Reduce size |

---

### **EXIT OPTIMIZATION (SST_ExitOptimization.mqh)**
```mql4
extern bool    UseAdvancedExits      = true;         // Enable advanced exit logic
extern bool    UseStructureExits     = true;         // Exit at S/R levels
extern bool    UseTimeBasedExits     = true;         // Exit if trade open too long
extern int     MaxHoursInTrade       = 8;            // Max hours before forced exit (4-24)
extern bool    UseProfitLock         = true;         // Lock in profits at milestones
extern double  ProfitLockLevel1      = 1.0;          // Lock at 1R (0.5-2.0)
extern double  ProfitLockLevel2      = 2.0;          // Lock at 2R (1.5-4.0)
extern double  ProfitLockPercent     = 50.0;         // Lock in X% of profit at Level 2 (30-70%)
extern bool    UseVolatilityTrailing = true;         // Trail based on current volatility
extern bool    ExitOnReversal        = true;         // Exit on pattern reversal
extern bool    ExitBeforeNews        = true;         // Close before major news
```

**Recommended Settings:**
- **Day Trading**:
  - MaxHoursInTrade = 4
  - ProfitLockLevel1 = 0.5, ProfitLockLevel2 = 1.5
  - ProfitLockPercent = 30%

- **Swing Trading** (default):
  - MaxHoursInTrade = 8
  - ProfitLockLevel1 = 1.0, ProfitLockLevel2 = 2.0
  - ProfitLockPercent = 50%

- **Position Trading**:
  - MaxHoursInTrade = 24 (1 day)
  - ProfitLockLevel1 = 2.0, ProfitLockLevel2 = 4.0
  - ProfitLockPercent = 70%

**Profit Locking Table:**
| R-Multiple | Action | SL Position |
|------------|--------|-------------|
| 0-1R | Standard trail | 2x ATR below price |
| 1R+ | Move to BE | At entry price (no loss) |
| 2R+ | Lock 50% profit | At entry + 1R |
| 3R+ | Tighten trail | 1.5x ATR below price |
| 5R+ | Tight trail | 1.0x ATR below price |

**Exit Triggers:**
- ⏰ Time: Trade open > MaxHoursInTrade
- 🎯 Structure: Within 10 pips of round number (psychological level)
- 🔄 Reversal: Bearish/Bullish Engulfing, Shooting Star, Hammer
- 📰 News: Major event in next 30 minutes

---

## 🎚️ PRESET CONFIGURATIONS

### **1. CONSERVATIVE (Low Risk, High Confidence)**
```mql4
// News Filter
UseNewsFilter = true
MinutesBeforeNews = 60
TradeHighImpactNews = false
TradeMediumImpactNews = false

// Correlation
MaxCorrelation = 0.50
MaxPositionsPerSector = 2
MaxSectorExposure = 30.0

// Volatility
MinBBW = 0.03
MaxBBW = 0.12
MinATRPercentile = 30
MaxATRPercentile = 80

// Drawdown
DrawdownLevel1 = 3.0
DrawdownLevel2 = 7.0
DrawdownLevel3 = 12.0
EmergencyStopLevel = 15.0
ConsecutiveLossLimit = 2

// Multi-Asset
MarketTrendMA = 200
VIXHighThreshold = 25
MinConfirmationPercent = 80

// Exit
MaxHoursInTrade = 6
ProfitLockLevel1 = 0.5
ProfitLockLevel2 = 1.5
```

**Expected Results:**
- Trades: 3-5 per day
- Win Rate: 58-65%
- Max Drawdown: 10-15%
- Profit Factor: 2.0-2.5

---

### **2. MODERATE (Balanced - DEFAULT)**
```mql4
// News Filter
UseNewsFilter = true
MinutesBeforeNews = 30
TradeHighImpactNews = false
TradeMediumImpactNews = false

// Correlation
MaxCorrelation = 0.70
MaxPositionsPerSector = 3
MaxSectorExposure = 40.0

// Volatility
MinBBW = 0.02
MaxBBW = 0.15
MinATRPercentile = 20
MaxATRPercentile = 90

// Drawdown
DrawdownLevel1 = 5.0
DrawdownLevel2 = 10.0
DrawdownLevel3 = 15.0
EmergencyStopLevel = 20.0
ConsecutiveLossLimit = 3

// Multi-Asset
MarketTrendMA = 50
VIXHighThreshold = 30
MinConfirmationPercent = 75

// Exit
MaxHoursInTrade = 8
ProfitLockLevel1 = 1.0
ProfitLockLevel2 = 2.0
```

**Expected Results:**
- Trades: 5-10 per day
- Win Rate: 52-58%
- Max Drawdown: 15-20%
- Profit Factor: 1.6-2.0

---

### **3. AGGRESSIVE (High Volume)**
```mql4
// News Filter
UseNewsFilter = true
MinutesBeforeNews = 15
TradeHighImpactNews = false
TradeMediumImpactNews = true

// Correlation
MaxCorrelation = 0.85
MaxPositionsPerSector = 5
MaxSectorExposure = 60.0

// Volatility
MinBBW = 0.01
MaxBBW = 0.20
MinATRPercentile = 10
MaxATRPercentile = 95

// Drawdown
DrawdownLevel1 = 7.0
DrawdownLevel2 = 12.0
DrawdownLevel3 = 18.0
EmergencyStopLevel = 25.0
ConsecutiveLossLimit = 4

// Multi-Asset
MarketTrendMA = 20
VIXHighThreshold = 35
MinConfirmationPercent = 60

// Exit
MaxHoursInTrade = 12
ProfitLockLevel1 = 1.5
ProfitLockLevel2 = 3.0
```

**Expected Results:**
- Trades: 10-20 per day
- Win Rate: 48-52%
- Max Drawdown: 20-25%
- Profit Factor: 1.4-1.7

**⚠️ WARNING**: Higher risk = larger potential drawdowns!

---

## 🔧 TROUBLESHOOTING GUIDE

### **Too Few Trades:**
```mql4
// Relax filters
MaxCorrelation = 0.80              // Allow more correlation
MinATRPercentile = 10              // Lower volatility threshold
MinConfirmationPercent = 60        // Lower multi-asset requirement
UseTimeOfDayFilter = false         // Trade all day
```

### **Too Many Trades:**
```mql4
// Tighten filters
MaxCorrelation = 0.60              // Stricter correlation
MinATRPercentile = 30              // Higher volatility threshold
MinConfirmationPercent = 80        // Higher multi-asset requirement
MaxDailyTrades = 5                 // Hard limit on trades
```

### **Too Many Rejections from News Filter:**
```mql4
MinutesBeforeNews = 15             // Shorter window
AutoDetectNewsSpike = false        // Disable spike detection
VolatilitySpikeThreshold = 4.0     // Higher spike threshold
```

### **Too Many Rejections from Volatility:**
```mql4
MinBBW = 0.01                      // Allow lower volatility
MaxBBW = 0.20                      // Allow higher volatility
MinATRPercentile = 10              // Lower percentile
MaxATRPercentile = 95              // Higher percentile
```

### **Too Much Drawdown Protection:**
```mql4
DrawdownLevel1 = 7                 // Delay protection
SizeReductionLevel1 = 0.85         // Less reduction
EmergencyStopLevel = 25            // Higher stop threshold
```

### **Not Enough Drawdown Protection:**
```mql4
DrawdownLevel1 = 3                 // Earlier protection
SizeReductionLevel1 = 0.50         // More reduction
EmergencyStopLevel = 15            // Lower stop threshold
ConsecutiveLossLimit = 2           // Trigger recovery sooner
```

---

## 📊 MONITORING PARAMETERS

### **Check These Daily:**
1. **Drawdown Level**: Should stay below 10%
2. **Win Rate**: Should be 50%+
3. **Trade Count**: Should match expectations (5-10 for moderate)
4. **Filter Rejections**: Which filter rejects most trades?

### **Check These Weekly:**
1. **Sector Exposure**: Are you over-concentrated?
2. **Correlation**: Are trades too similar?
3. **Volatility Regime**: Trading in right conditions?
4. **Market Regime**: Following market trend?

### **Check These Monthly:**
1. **Parameter Optimization**: Should you tighten/relax?
2. **Win Rate by Filter**: Which filters improve performance?
3. **Drawdown Recovery**: How fast do you recover?
4. **Equity Curve Health**: Is it smooth and upward?

---

## ✅ RECOMMENDED STARTING POINT:

**For first 1 month of trading:**
- Use **MODERATE (DEFAULT)** settings
- Enable all filters (UseXXX = true)
- Set VerboseLogging = true
- Monitor results daily
- Adjust parameters weekly based on performance

**After 1 month:**
- Review filter rejection rates
- Optimize parameters based on your account performance
- Move toward CONSERVATIVE or AGGRESSIVE as needed

---

**All parameters can be changed in the EA inputs without recompiling!** 🎛️
