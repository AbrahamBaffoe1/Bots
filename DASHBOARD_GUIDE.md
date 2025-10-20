# Smart Stock Trader - Dashboard Guide

## 📊 Where to See Your Trading Dashboard

The Smart Stock Trader EA provides **TWO dashboard options** for monitoring your trading activity:

---

## 1. 🖥️ **MT4 CHART DASHBOARD** (Real-time On-Chart Display)

### Location:
- **Automatically appears on the TOP-LEFT corner of your MT4 chart** when the EA is running

### What You'll See:
```
╔════════════════════════════════╗
║  === SMART STOCK TRADER ===   ║
╠════════════════════════════════╣
║ State: READY                   ║
║ Balance: $10,000.00            ║
║ Equity: $10,250.50             ║
║ Daily P/L: +$250.50 (+2.51%)   ║
║                                ║
║ Session: Regular Hours         ║
║ Trading: ACTIVE                ║
║                                ║
║ --- Today's Stats ---          ║
║ Trades: 5                      ║
║ W/L: 4/1                       ║
║ Win Rate: 80.0%                ║
║                                ║
║ --- Overall Stats ---          ║
║ Total: 50                      ║
║ Win Rate: 65.0%                ║
║ Profit Factor: 2.15            ║
║                                ║
║ Open Positions: 2              ║
║ Win Streak: 3                  ║
╚════════════════════════════════╝
```

### Features:
✅ **Dark panel background** with color-coded text
✅ **Green** = Positive/Profitable
✅ **Red** = Negative/Loss
✅ **Yellow** = Session info
✅ **Updates every 10 ticks** (real-time)
✅ **Support/Resistance levels** drawn on chart as horizontal lines

### How to Toggle:
- Set `ShowDashboard = true` in EA settings (default: ON)
- Dashboard appears automatically when EA is attached to chart

---

## 2. 🌐 **WEB BROWSER DASHBOARD** (Beautiful HTML View)

### Location:
```
C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[BrokerID]\MQL4\Files\
SmartStockTrader_Dashboard.html
```

**Quick Access Path:**
1. In MT4, click **File → Open Data Folder**
2. Navigate to: **MQL4 → Files**
3. Find: **SmartStockTrader_Dashboard.html**
4. **Double-click** to open in your web browser

### What You'll See:
A **gorgeous, modern web dashboard** with:

#### 📱 Responsive Cards Layout:
- **EA Status Card** - Current state, session, trading status
- **Account Summary Card** - Balance, equity, margin
- **Today's Performance Card** - Big number P/L display, win rate progress bar
- **Overall Statistics Card** - Total trades, profit factor, net P/L
- **Streaks & Alerts Card** - Win/loss streaks, recovery mode alerts
- **Active Strategies Card** - Visual list of enabled trading strategies

#### 🎨 Visual Features:
✨ **Gradient blue background**
✨ **Glass-morphism cards** (frosted glass effect)
✨ **Color-coded statistics** (Green/Red/Orange)
✨ **Progress bars** for win rates
✨ **Status badges** with icons
✨ **Auto-refresh every 5 seconds**
✨ **Responsive design** (works on phone, tablet, desktop)

### Update Frequency:
- **Generates new HTML every 60 seconds** while EA is running
- **Auto-refreshes in browser every 5 seconds**
- Always shows live data

---

## 📍 **How to Access Each Dashboard:**

### On-Chart Dashboard:
1. ✅ Already visible when EA is running
2. Look at **top-left corner** of your chart
3. If not visible, check `ShowDashboard = true` in EA settings

### Web Dashboard:
1. ✅ Open MT4
2. Click **File → Open Data Folder**
3. Go to **MQL4/Files/**
4. Double-click **SmartStockTrader_Dashboard.html**
5. **Bookmark it** in your browser for quick access!
6. Keep the browser tab open - it will auto-refresh

---

## 🎯 **Pro Tips:**

### For Best Experience:
1. **Dual Monitor Setup:**
   - MT4 with on-chart dashboard on Monitor 1
   - Web dashboard full-screen on Monitor 2

2. **Single Monitor:**
   - Keep web dashboard in a browser window on top
   - Use MT4 split-screen view

3. **Mobile Monitoring:**
   - The HTML dashboard is mobile-responsive
   - Copy the HTML file to Dropbox/Google Drive
   - Access from your phone's browser

4. **Customization:**
   - On-chart dashboard colors auto-adjust (green/red/yellow)
   - Web dashboard has beautiful pre-designed theme
   - Modify `SST_HTMLDashboard.mqh` CSS section for custom styling

---

## 🔧 **Troubleshooting:**

### Can't See On-Chart Dashboard?
- Check `ShowDashboard = true` in EA parameters
- Look at **top-left corner** of chart (not bottom)
- Try re-attaching EA to chart
- Check Experts log for initialization messages

### Can't Find HTML Dashboard File?
```
Path: MT4 Data Folder → MQL4 → Files → SmartStockTrader_Dashboard.html
```
- File is created **60 seconds after EA starts**
- Check MT4 Experts tab for "HTML Dashboard generated" message
- Make sure EA has write permissions

### HTML Dashboard Not Updating?
- File updates every **60 seconds** while EA runs
- Browser auto-refreshes every **5 seconds**
- If stuck, manually refresh browser (F5)
- Check that EA is still running in MT4

---

## 📊 **Dashboard Data Explained:**

### Key Metrics:

**State:**
- `READY` = Trading normally (Green)
- `RECOVERY` = Risk reduced after losses (Orange)
- `SUSPENDED` = Daily loss limit hit (Red)

**Session:**
- `Pre-Market` = 4:00-9:30 AM EST
- `Regular Hours` = 9:30 AM-4:00 PM EST
- `After Hours` = 4:00-8:00 PM EST
- `Market Closed` = Weekends/holidays

**Win Rate:**
- **>60%** = Excellent (Dark Green)
- **50-60%** = Good (Green)
- **<50%** = Needs improvement (Orange)

**Profit Factor:**
- **>2.0** = Excellent (Dark Green)
- **1.5-2.0** = Good (Green)
- **1.0-1.5** = Acceptable (Yellow)
- **<1.0** = Losing (Red)

---

## 🎨 **Visual Examples:**

### On-Chart Dashboard Position:
```
┌─────────────────────────────────────────┐
│ ╔═══ DASHBOARD ═══╗                    │
│ ║ Stats here      ║  [Chart Area]      │
│ ║ Live updates    ║                    │
│ ╚═════════════════╝                    │
│                                         │
│         [Price Candles & Indicators]   │
│                                         │
│─────────[S/R Level Line]───────────────│
│                                         │
└─────────────────────────────────────────┘
```

### Web Dashboard Layout:
```
┌───────────────────────────────────────────┐
│    🚀 SMART STOCK TRADER DASHBOARD       │
├─────────┬─────────┬─────────┬───────────┤
│ EA      │ Account │ Today's │ Overall   │
│ Status  │ Summary │ Perf.   │ Stats     │
├─────────┼─────────┼─────────┼───────────┤
│ Streaks │ Active  │         │           │
│ &Alerts │ Strats  │         │           │
└─────────┴─────────┴─────────┴───────────┘
```

---

## ✅ **Quick Start Checklist:**

- [ ] EA running on MT4 chart
- [ ] On-chart dashboard visible (top-left)
- [ ] Located HTML dashboard file
- [ ] Opened HTML in browser
- [ ] Bookmarked HTML dashboard
- [ ] Both dashboards updating
- [ ] Understanding all metrics

---

**You now have TWO powerful ways to monitor your trading!**
🎯 Use the on-chart dashboard for **quick glances**
🌐 Use the web dashboard for **detailed analysis**

Happy Trading! 🚀📈
