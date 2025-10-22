# 🎯 Complete Guide: License Keys & Backtesting

## Part 1: Getting Your License Key (Step-by-Step)

### **STEP 1: Open License Generator**

The License Key Generator should be open in your browser. If not:

**On Mac/Linux:**
```bash
open /Users/kwamebaffoe/Desktop/EABot/LicenseKeyGenerator.html
```

**On Windows:**
- Double-click `LicenseKeyGenerator.html` in the EABot folder

### **STEP 2: Fill in the Form**

For testing purposes, use these values:

```
Customer Name:        Your Name (e.g., "Kwame Baffoe")
Customer Email:       your@email.com
License Type:         Professional (from dropdown)
Account Number:       Leave EMPTY (works on any account)
Expiration (Days):    365 (1 year)
```

### **STEP 3: Generate the Key**

1. Click **"🚀 Generate License Key"** button
2. You'll see output like this:

```
License Key: SST-PRO-A4B9C2-X7Y3Z1-F8D4

Customer: Your Name
Email: your@email.com
Type: Professional
Expires: 2026.10.20 (365 days)

MQL4 Configuration:
LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4"
ExpirationDate = D'2026.10.20 23:59:59'
AuthorizedAccounts = "" // No restriction
```

3. **Click "📋 Copy License Key"** button

### **STEP 4: Add Key to EA**

**✅ Good news:** I've already added a test key for you!

The key `SST-PRO-TEST01-DEMO99-K7M2` is already configured in both EA files.

If you want to use YOUR generated key instead:

**Option A - In MetaEditor (before compiling):**
1. Open `SmartStockTrader_Single.mq4` in MetaEditor
2. Go to **line 14**
3. Replace the key:
   ```mql4
   extern string  LicenseKey = "YOUR-GENERATED-KEY-HERE";
   ```
4. Go to **line 81** and add your key to the array:
   ```mql4
   string g_ValidLicenseKeys[] = {
      "SST-PRO-ABC123-XYZ789",
      "SST-PRO-DEF456-UVW012",
      "SST-PRO-GHI789-RST345",
      "SST-PRO-TEST01-DEMO99-K7M2",
      "YOUR-NEW-KEY-HERE"  // ← Add here
   };
   ```
5. Press **F7** to compile

**Option B - In MT4 (after installing):**
1. Drag EA to chart
2. In "Inputs" tab, enter your license key
3. Click OK

---

## Part 2: Using the EA (With License)

### **Normal Mode (Live Trading)**

```mql4
// In EA settings:
LicenseKey = "SST-PRO-TEST01-DEMO99-K7M2"
RequireLicenseKey = true
BacktestMode = false
VerboseLogging = false
Stocks = "AAPL,MSFT,GOOGL"  // Multiple stocks
```

**What happens:**
- ✅ License validation runs
- ✅ Only trades during US market hours (9:30 AM - 4:00 PM EST)
- ✅ Trades multiple stocks
- ✅ Full production features

---

### **Backtest Mode (Testing & Strategy Tester)**

```mql4
// In EA settings:
BacktestMode = true
VerboseLogging = true
Stocks = ""  // Leave empty (uses current chart)
```

**What happens:**
- ✅ **Skips license check** automatically
- ✅ **Trades 24/7** (no time restrictions)
- ✅ **Uses current chart symbol** (EURUSD, GBPUSD, etc.)
- ✅ **Verbose logging** shows everything it's doing
- ✅ **Performance summary** when backtest ends

---

### **Testing Without License (Quick Test)**

```mql4
// In EA settings:
RequireLicenseKey = false
BacktestMode = false
```

**What happens:**
- ⚠️ License check disabled
- ✅ EA runs normally
- ⚠️ **Remember to re-enable before selling!**

---

## Part 3: Running a Backtest

### **Quick Backtest (5 Minutes)**

1. **Open MetaEditor** (F4 in MT4)
2. **Open** `SmartStockTrader_Single.mq4`
3. **Press F7** to compile
4. **Open Strategy Tester** (Ctrl+R in MT4)
5. **Configure:**
   - Expert Advisor: `SmartStockTrader_Single`
   - Symbol: `EURUSD`
   - Period: `H1`
   - Date: Last year (e.g., 2024.01.01 - 2025.01.01)
   - Model: `Every tick`
   - Visual mode: ✅ Check it
6. **Click "Expert properties"** button → "Inputs" tab
7. **Set these parameters:**
   ```
   BacktestMode = true
   VerboseLogging = true
   Stocks = ""
   EnableTrading = true
   ```
8. **Click "Start"** ▶️

### **What You'll See:**

```
╔════════════════════════════════════════╗
║      BACKTEST MODE ENABLED            ║
║  - Trading 24/7 (no time limits)      ║
║  - Verbose logging enabled            ║
║  - Single symbol: EURUSD              ║
╚════════════════════════════════════════╝

▶ Analyzing EURUSD at 2024.03.15 10:00
  Momentum: BUY (75.0%)
  Trend Following: BUY (70.0%)
  ✓ Final signal: BUY (2 strategies agree, 72.5%)

╔════════════════════════════════════╗
║       NEW TRADE OPENED (#12345)    ║
╠════════════════════════════════════╣
║ Ticket:   12345
║ Symbol:   EURUSD
║ Type:     BUY
║ Price:    1.08567
║ Lot Size: 0.10
║ Stop Loss: 1.08350
║ Take Profit: 1.08924
║ Strategy: Momentum
║ Confidence: 75.0%
╚════════════════════════════════════╝
```

**At the end:**

```
╔════════════════════════════════════════╗
║     PERFORMANCE SUMMARY               ║
╠════════════════════════════════════════╣
║ Starting Equity:  $10000.00
║ Final Equity:     $10845.00
║ Total P/L:        $845.00 (8.45%)
║ Total Trades:     127
║ Win Rate:         53.5%
║ Profit Factor:    1.67
╚════════════════════════════════════════╝
```

---

## Part 4: All Features Added

### ✅ **Features Now in SmartStockTrader.mq4 & SmartStockTrader_Single.mq4:**

1. **✅ Trades current chart symbol**
   - When `BacktestMode = true` OR `Stocks = ""`
   - Works on EURUSD, GBPUSD, Gold, stocks, anything

2. **✅ Verbose logging**
   - Shows indicator values
   - Shows strategy signals
   - Shows why it's trading
   - Automatic in BacktestMode

3. **✅ Detailed trade logs**
   - Entry reason
   - Strategy name
   - Confidence level
   - All parameters

4. **✅ Results summary**
   - Win rate
   - Total P/L
   - Profit factor
   - Total trades
   - Shows on shutdown

5. **✅ Visual dashboard**
   - Already existed
   - Shows real-time stats on chart

6. **✅ No time restrictions in backtest**
   - Trades 24/7 when `BacktestMode = true`
   - Bypasses all session checks

7. **✅ License integration**
   - Works with or without license
   - Skips check in backtest mode
   - Easy to disable for testing

---

## Part 5: Quick Reference

### **For Backtesting:**

```mql4
BacktestMode = true
VerboseLogging = true
Stocks = ""
EnableTrading = true
```

Result: Works in Strategy Tester, shows everything, trades 24/7

---

### **For Live Trading:**

```mql4
BacktestMode = false
VerboseLogging = false
Stocks = "AAPL,MSFT,GOOGL"
LicenseKey = "YOUR-KEY-HERE"
RequireLicenseKey = true
EnableTrading = true
```

Result: Production mode, requires license, trades only market hours

---

### **For Testing Without License:**

```mql4
RequireLicenseKey = false
BacktestMode = false
```

Result: Runs without license (⚠️ don't forget to re-enable!)

---

## Part 6: License System Options

### **Option 1: Pre-set License (Compile with key)**

```mql4
// Line 14 in SmartStockTrader_Single.mq4
extern string  LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4";
```

- Customer gets .EX4 file
- License already embedded
- Can't change it
- ✅ Best for selling

### **Option 2: Customer Enters License**

```mql4
// Line 14 in SmartStockTrader_Single.mq4
extern string  LicenseKey = "";  // Empty
```

- Customer enters key in MT4 settings
- More flexible
- Can transfer licenses
- ✅ Best for trials

### **Option 3: No License (Testing)**

```mql4
extern bool RequireLicenseKey = false;
```

- Bypasses all checks
- Use only for testing
- ⚠️ **Never distribute like this!**

---

## Part 7: Common Issues & Solutions

### **Issue: "Invalid License Key"**

**Solution:**
1. Check if key is in `g_ValidLicenseKeys[]` array (line ~81)
2. Make sure you recompiled (F7) after adding key
3. Or set `RequireLicenseKey = false` for testing

### **Issue: "No trades in backtest"**

**Solution:**
1. Set `BacktestMode = true`
2. Set `EnableTrading = true`
3. Leave `Stocks = ""`
4. Use enough historical data (at least 6 months)

### **Issue: "License Generator not working"**

**Solution:**
- Make sure JavaScript is enabled in browser
- Try different browser (Chrome, Firefox, Safari)
- Check browser console for errors (F12)

### **Issue: "Can't find the license key line"**

**Locations:**
- **SmartStockTrader_Single.mq4:** Line 14 (parameter), Line 81 (database)
- **SmartStockTrader.mq4:** Uses Include/SST_LicenseManager.mqh (line ~27)

---

## Part 8: Next Steps

### **1. Test the License System:**

```bash
☐ Open License Generator
☐ Generate a test key
☐ Add key to EA (line 81)
☐ Set key as default (line 14)
☐ Compile (F7)
☐ Load in MT4
☐ Check Experts tab - should see "LICENSE VALID"
```

### **2. Run Your First Backtest:**

```bash
☐ Set BacktestMode = true
☐ Set VerboseLogging = true
☐ Set Stocks = ""
☐ Compile (F7)
☐ Open Strategy Tester (Ctrl+R)
☐ Select EA, symbol (EURUSD), period (H1)
☐ Click Start
☐ Watch the logs!
```

### **3. Prepare for Commercial Release:**

```bash
☐ Generate real license keys for customers
☐ Add keys to database
☐ Compile to .EX4
☐ Test with valid/invalid keys
☐ Create sales page
☐ Set pricing
☐ Launch! 🚀
```

---

## 📋 Summary

### **What You Have Now:**

1. ✅ **Professional license system** with key generation
2. ✅ **Backtest-ready EA** that works in Strategy Tester
3. ✅ **Verbose logging** that shows everything
4. ✅ **Flexible symbol trading** (single or multiple stocks)
5. ✅ **Test key already configured** (`SST-PRO-TEST01-DEMO99-K7M2`)
6. ✅ **Complete documentation** for everything

### **What to Do:**

1. **Generate your own license key** (use the HTML tool)
2. **Run a backtest** (set `BacktestMode = true`)
3. **See the detailed logs** (strategy signals, trade entries)
4. **View the results summary** (win rate, P/L, profit factor)

### **Files You Need:**

| File | Purpose |
|------|---------|
| `LicenseKeyGenerator.html` | Generate license keys |
| `SmartStockTrader_Single.mq4` | Main EA (easiest to use) |
| `SmartStockTrader.mq4` | Modular version (more organized) |
| `SmartStockTrader_Backtest.mq4` | Pure backtest version (alternative) |
| `LICENSE_SYSTEM_GUIDE.md` | Detailed license docs |
| `BACKTEST_GUIDE.md` | Detailed backtest docs |

---

## 🎉 You're All Set!

**The EA is ready to:**
- ✅ Validate licenses
- ✅ Trade live (with restrictions)
- ✅ Backtest thoroughly
- ✅ Show detailed logs
- ✅ Track performance

**Try it now:**
1. Open the License Generator (should be in your browser)
2. Generate a key
3. Run a backtest with `BacktestMode = true`
4. Watch the magic happen! 🚀

---

**Questions?**
- All license info: See `LICENSE_SYSTEM_GUIDE.md`
- All backtest info: See `BACKTEST_GUIDE.md`
- Quick start: See `QUICK_START_LICENSING.md`
