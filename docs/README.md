# 🚀 Smart Stock Trader EA - Professional Trading System

![Version](https://img.shields.io/badge/version-1.0-blue)
![Platform](https://img.shields.io/badge/platform-MT4-green)
![Strategies](https://img.shields.io/badge/strategies-8-orange)
![Status](https://img.shields.io/badge/status-production-success)

## 📊 **DUAL DASHBOARD SYSTEM**

Your Smart Stock Trader EA includes **TWO professional dashboards** for monitoring trades:

### 1️⃣ **ON-CHART DASHBOARD**
*Real-time monitoring directly on your MT4 chart*

**Location:** Top-left corner of MT4 chart (auto-displays when EA is running)

**Features:**
- ✅ Dark panel with frosted glass effect
- ✅ Color-coded metrics (Green/Red/Yellow)
- ✅ Live account balance & equity
- ✅ Daily P/L tracking
- ✅ Session status (Pre-market/Regular/After-hours)
- ✅ Today's win rate & trade count
- ✅ Overall statistics
- ✅ Open positions counter
- ✅ Win/Loss streak indicators
- ✅ Support/Resistance levels drawn on chart
- ✅ Updates every 10 ticks

### 2️⃣ **WEB DASHBOARD**
*Beautiful HTML dashboard for your browser*

**Location:** `MT4_Data_Folder/MQL4/Files/SmartStockTrader_Dashboard.html`

**How to Access:**
1. MT4 → File → Open Data Folder
2. Navigate to MQL4/Files/
3. Double-click `SmartStockTrader_Dashboard.html`
4. Bookmark in browser!

**Features:**
- 🎨 Modern gradient UI with glass-morphism cards
- 📱 Fully responsive (desktop/tablet/mobile)
- 🔄 Auto-refreshes every 5 seconds
- 📊 6 interactive cards:
  - EA Status & Trading Session
  - Account Summary
  - Today's Performance (big number display)
  - Overall Statistics with Profit Factor
  - Streaks & Recovery Alerts
  - Active Trading Strategies
- ✨ Progress bars for win rates
- 💚 Color-coded values (green=profit, red=loss)
- ⚡ Status badges with icons

---

## 🎯 **FEATURES OVERVIEW**

### **8 Trading Strategies:**
1. ✅ **Momentum Trading** - Catch strong price movements with RSI/MACD
2. ✅ **Mean Reversion** - Buy low, sell high with Bollinger Bands
3. ✅ **Breakout Trading** - Volume-confirmed breakouts
4. ✅ **Trend Following** - Ride established trends
5. ✅ **Volume Analysis** - Trade with institutional flow
6. ✅ **Gap Trading** - Profit from overnight gaps
7. ✅ **Multi-Timeframe** - Signals confirmed across M5/H1/D1
8. ✅ **Market Regime Adaptive** - Switch strategies based on ADX

### **12+ Technical Indicators:**
- Moving Averages (SMA, EMA, VWAP)
- RSI, MACD, Stochastic
- Bollinger Bands
- ATR (volatility)
- ADX (trend strength)
- Ichimoku Cloud
- Volume MA, OBV

### **Pattern Recognition:**
- 🕯️ **Candlestick Patterns:** Hammer, Shooting Star, Doji, Engulfing, Morning/Evening Star
- 📈 **Chart Patterns:** Double Top/Bottom, Head & Shoulders

### **Advanced Risk Management:**
- 💰 Dynamic position sizing (ATR-based)
- 📊 Adaptive sizing (scales with wins/losses)
- 🛡️ 5% daily loss limit
- 🔗 Correlation filtering
- 📉 Spread & volatility filters
- 🔄 Recovery mode after losses

### **Trade Management:**
- 🎯 Trailing stops (ATR-based or fixed)
- ⚖️ Break-even stops
- 📊 3-level partial profit taking (25%/25%/25% at 1R/2R/3R)
- ⏰ Time-based exits

### **Session Management:**
- 🌅 Pre-market: 4:00-9:30 AM EST
- 📊 Regular: 9:30 AM-4:00 PM EST
- 🌙 After-hours: 4:00-8:00 PM EST

### **Analytics & Reporting:**
- 📈 Win rate, Profit factor, Sharpe ratio
- 📊 CSV trade logging
- 📉 R-Multiple tracking
- 📱 Push notifications

---

## 🚀 **QUICK START GUIDE**

### **1. Installation:**
```bash
Copy files to MT4:
SmartStockTrader.mq4     → MQL4/Experts/
Include/ folder          → MQL4/Experts/Include/
```

### **2. Compilation:**
1. Open MetaEditor (F4 in MT4)
2. Open `SmartStockTrader.mq4`
3. Press F7 to compile
4. Check for **0 errors, 0 warnings**

### **3. Configuration:**
1. Drag EA to any chart
2. **Set your stocks:** `AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA,META,NFLX,AMD,PYPL`
3. **Configure risk:** Default 1% per trade
4. **Select sessions:** Pre-market + Regular (default)
5. **Enable strategies:** All enabled by default
6. Click OK

### **4. Monitor:**
- **On-chart dashboard:** Visible immediately
- **Web dashboard:** Opens in 60 seconds → Check MQL4/Files/

---

## 📊 **DASHBOARD LOCATIONS**

### **Where is the On-Chart Dashboard?**
```
┌─MT4 Chart─────────────────────────────┐
│ ╔═══════════════════════╗            │
│ ║ SMART STOCK TRADER    ║ ← HERE!   │
│ ║ State: READY          ║            │
│ ║ Balance: $10,000      ║            │
│ ║ Daily P/L: +$250      ║            │
│ ║ ───────────────────── ║            │
│ ║ Today's Stats         ║            │
│ ║ Trades: 5             ║            │
│ ║ Win Rate: 80%         ║            │
│ ╚═══════════════════════╝            │
│                                       │
│    [Your Chart Candles Here]         │
└───────────────────────────────────────┘
```

### **Where is the Web Dashboard?**
```
📁 File Explorer Path:
C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\[BrokerID]\
  └─ MQL4
     └─ Files
        └─ SmartStockTrader_Dashboard.html ← Open this!

🔍 Quick Access:
MT4 → File → Open Data Folder → MQL4 → Files
```

---

## ⚙️ **DEFAULT CONFIGURATION**

```
Stocks: AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA, META, NFLX, AMD, PYPL
Risk per trade: 1%
Max daily loss: 5%
Sessions: Pre-market + Regular hours
All strategies: ENABLED
Pattern detection: ENABLED
Trailing stops: ENABLED
Partial closes: 25%@1R, 25%@2R, 25%@3R
Dashboard: ENABLED (both)
Notifications: ENABLED
CSV logging: ENABLED
```

---

## 📱 **NOTIFICATIONS**

The EA sends **push notifications** to your phone for:
- ✅ Trade entries (with strategy & confidence)
- ✅ Trade exits (with P/L & R-multiple)
- ✅ Daily loss limit warnings
- ✅ Recovery mode activation
- ✅ EA start/stop events

**Setup:**
1. MT4 → Tools → Options → Notifications
2. Enable push notifications
3. Get MetaQuotes ID from mobile app
4. Enter ID in MT4
5. Test notification

---

## 📈 **PERFORMANCE METRICS**

The dashboards track:

| Metric | Description |
|--------|-------------|
| **Win Rate** | Percentage of winning trades |
| **Profit Factor** | Gross profit / Gross loss |
| **Sharpe Ratio** | Risk-adjusted returns |
| **R-Multiple** | Risk/reward ratio per trade |
| **Expectancy** | Expected profit per trade |
| **Max Drawdown** | Largest peak-to-trough decline |
| **Daily P/L** | Today's profit/loss |
| **Consecutive Wins/Losses** | Current streak |

---

## 🎨 **DASHBOARD COLORS**

### **On-Chart Dashboard:**
- 🟢 **Green** = Profitable, Positive, Ready
- 🔴 **Red** = Loss, Negative, Suspended
- 🟡 **Yellow** = Session info, Neutral
- 🟠 **Orange** = Warning, Recovery mode
- 🔵 **Blue** = Support levels
- 🔴 **Red** = Resistance levels

### **Web Dashboard:**
- 🟢 **Green badges** = Profitable metrics
- 🔴 **Red badges** = Losses
- 🟠 **Orange badges** = Warnings
- 🔵 **Blue gradient** = Background theme
- **Frosted glass cards** = Modern design

---

## 🛠️ **TROUBLESHOOTING**

### **Dashboard not showing?**
- Check `ShowDashboard = true` in EA settings
- Look at **top-left corner** (not bottom!)
- Re-attach EA to chart
- Check Experts log for errors

### **HTML dashboard not found?**
- Wait 60 seconds after EA starts
- Check: MT4 Data Folder → MQL4 → Files
- Look for "HTML Dashboard generated" in log
- Ensure EA has write permissions

### **Dashboard not updating?**
- On-chart: Updates every 10 ticks
- Web: Generates every 60 seconds
- Browser auto-refreshes every 5 seconds
- Manually refresh browser (F5)

---

## 📂 **FILE STRUCTURE**

```
EABot/
├── SmartStockTrader.mq4           # Main EA file
├── README.md                      # This file
├── DASHBOARD_GUIDE.md             # Detailed dashboard guide
└── Include/
    ├── SST_Config.mqh             # Configuration
    ├── SST_SessionManager.mqh     # Trading hours
    ├── SST_Indicators.mqh         # Technical indicators
    ├── SST_PatternRecognition.mqh # Pattern detection
    ├── SST_MarketStructure.mqh    # S/R levels
    ├── SST_RiskManager.mqh        # Risk management
    ├── SST_Strategies.mqh         # 8 strategies
    ├── SST_Analytics.mqh          # Performance tracking
    ├── SST_Dashboard.mqh          # On-chart display
    └── SST_HTMLDashboard.mqh      # Web dashboard
```

---

## 🎯 **RECOMMENDED SETUP**

### **For Best Results:**

1. **Dual Monitor:**
   - Monitor 1: MT4 with on-chart dashboard
   - Monitor 2: Web dashboard full-screen

2. **Single Monitor:**
   - Split screen: MT4 + Browser

3. **Mobile:**
   - Copy HTML to cloud storage
   - Access from phone browser

---

## 📞 **SUPPORT**

- 📖 Read: [DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md)
- 💬 Check MT4 Experts log for messages
- 🐛 Report issues with screenshots

---

## ⚠️ **DISCLAIMER**

Trading stocks involves risk. Past performance does not guarantee future results. Always:
- ✅ Start with demo account
- ✅ Test thoroughly before going live
- ✅ Use proper risk management
- ✅ Never risk more than you can afford to lose

---

## 🎉 **YOU'RE READY!**

1. ✅ EA installed and compiled
2. ✅ Dashboards visible (chart + web)
3. ✅ All 8 strategies active
4. ✅ Risk management configured
5. ✅ Notifications enabled

**Happy Trading!** 🚀📈💰

---

*Smart Stock Trader EA v1.0 - Professional Trading System*
# Bots
