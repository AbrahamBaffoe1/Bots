# 🚀 Gold Scalping Bot - Installation Instructions

## ✅ EASIEST METHOD (Recommended for You)

Your EA has been updated to use **local include**, which means both files can be in the same folder!

### Step-by-Step Installation

#### 1. Find Your MT5 Data Folder

**In MT5:**
- Open MetaTrader 5
- Go to: **File → Open Data Folder** (or `Cmd+Shift+D` on Mac)
- A window will open - navigate to the **MQL5** folder
- Then go into the **Experts** folder

**You should now be in:**
```
[Some path]/MQL5/Experts/
```

---

#### 2. Copy BOTH Files to Experts Folder

Copy these 2 files from your project:

**FROM:**
```
/Users/kwamebaffoe/Desktop/EABot/MT5/GoldScalpingBot.mq5
/Users/kwamebaffoe/Desktop/EABot/MT5/SST_ScalpingStrategy.mqh
```

**TO:**
```
[MT5 Data Folder]/MQL5/Experts/GoldScalpingBot.mq5
[MT5 Data Folder]/MQL5/Experts/SST_ScalpingStrategy.mqh
```

**Both files go in the SAME folder (Experts/)!**

---

#### 3. Compile in MetaEditor

1. Close MetaEditor (if open)
2. In MT5, press **F4** to open MetaEditor
3. In Navigator panel (left side), expand **Experts** folder
4. Double-click **GoldScalpingBot.mq5** to open it
5. Click **Compile** button (or press **F7**)

**Expected Result:**
```
0 error(s), 0 warning(s), 20 ms
Result: GoldScalpingBot.ex5 successfully created!
```

✅ **If you see this, you're done! Skip to "Testing" section below.**

---

## 🔄 ALTERNATIVE METHODS (If Method 1 Fails)

### Method 2: Using Include Folder (Traditional Way)

**Copy files to different folders:**

1. **Main EA:**
   ```
   FROM: /Users/kwamebaffoe/Desktop/EABot/MT5/GoldScalpingBot.mq5
   TO:   [MT5 Data]/MQL5/Experts/GoldScalpingBot.mq5
   ```

2. **Strategy Library:**
   ```
   FROM: /Users/kwamebaffoe/Desktop/EABot/Include/SST_ScalpingStrategy.mqh
   TO:   [MT5 Data]/MQL5/Include/SST_ScalpingStrategy.mqh
   ```

3. **Change include line in EA:**

   Open `GoldScalpingBot.mq5` in MetaEditor, find line 15:
   ```cpp
   #include "SST_ScalpingStrategy.mqh"  // Local include
   ```

   Change to:
   ```cpp
   #include <SST_ScalpingStrategy.mqh>  // System include
   ```

4. Compile (F7)

---

### Method 3: Automatic Script (Mac Terminal)

```bash
cd /Users/kwamebaffoe/Desktop/EABot
chmod +x INSTALL_TO_MT5.sh
./INSTALL_TO_MT5.sh
```

This will auto-detect your MT5 folder and copy files.

---

## ✅ Testing After Installation

### Test 1: Verify Compilation

**In MetaEditor:**
```
✓ 0 error(s), 0 warning(s)
✓ GoldScalpingBot.ex5 created
```

### Test 2: Attach to Chart

1. In MT5, open **XAUUSD** chart
2. Set timeframe to **M5** (5-minute)
3. In Navigator panel, expand **Experts**
4. Drag **GoldScalpingBot** onto the chart
5. In the dialog:
   - Check "Allow algo trading"
   - Check "Allow DLL imports" (if asked)
   - Click **OK**

### Test 3: Check Initialization

Open **Experts** tab (View → Toolbox → Experts, or press `Ctrl+T`)

**Should see:**
```
GOLD SCALPING BOT v1.0 INITIALIZING
========================================
Account: [your account number]
Balance: $[your balance]
Symbol: XAUUSD
Timeframe: M5
Strategy: SCALP_HYBRID
Stop Loss: 20 pips | Take Profit: 40 pips
Risk per trade: 0.5%
Max Spread: 20.0 points
Max Hold Time: 60 minutes
--- TRADING SESSIONS ---
London: 08:00-12:00 GMT [ACTIVE]
NY: 13:00-17:00 GMT [ACTIVE]
London Fix: AVOIDED (10:25-10:35, 14:55-15:05 GMT)
High-Impact News: AVOIDED
========================================
  INITIALIZATION COMPLETE - READY!
========================================
```

✅ **If you see this, the bot is working perfectly!**

---

## 🚨 Troubleshooting

### Error: "file not found"

**Solution 1:** Use Method 1 (both files in Experts folder)
**Solution 2:** Check file names (spelling, case-sensitive!)
**Solution 3:** Restart MetaEditor

### Error: "declaration without type"

**Cause:** SST_ScalpingStrategy.mqh not loading properly

**Fix:**
1. Verify `SST_ScalpingStrategy.mqh` is in same folder as `GoldScalpingBot.mq5`
2. Check include line uses quotes: `#include "SST_ScalpingStrategy.mqh"`
3. Recompile

### Error: "'CScalpingStrategy' - unexpected token"

**Cause:** Include file not found before class is used

**Fix:**
1. Ensure include line is at TOP of file (line 15)
2. Ensure file exists in same folder
3. Restart MetaEditor

### No errors but EA won't attach to chart

**Possible causes:**
- AutoTrading disabled → Enable with Ctrl+E (button should be GREEN)
- Wrong symbol → Bot is for XAUUSD only
- Wrong timeframe → Must be M5
- EA restrictions in MT5 settings → Check Tools → Options → Expert Advisors

---

## 📁 Final File Structure

**After installation, your MT5 should have:**

```
[MT5 Data Folder]/
└── MQL5/
    ├── Experts/
    │   ├── GoldScalpingBot.mq5        ← Source code
    │   ├── GoldScalpingBot.ex5        ← Compiled (auto-created)
    │   └── SST_ScalpingStrategy.mqh   ← Strategy library (Method 1)
    │
    └── Include/                        ← (Optional for Method 2)
        └── SST_ScalpingStrategy.mqh   ← Strategy library (Method 2)
```

**Note:** You only need ONE copy of `SST_ScalpingStrategy.mqh` - either in Experts/ (Method 1) OR Include/ (Method 2), not both!

---

## 🎯 Quick Verification Commands (Mac Terminal)

Check if files are in your project:
```bash
ls -la /Users/kwamebaffoe/Desktop/EABot/MT5/GoldScalpingBot.mq5
ls -la /Users/kwamebaffoe/Desktop/EABot/MT5/SST_ScalpingStrategy.mqh
```

Both should show file sizes:
```
GoldScalpingBot.mq5: ~27 KB
SST_ScalpingStrategy.mqh: ~22 KB
```

---

## ✅ Installation Complete Checklist

Before testing on demo:

- [ ] Both files copied to MT5 Experts folder
- [ ] Compiled successfully (0 errors)
- [ ] .ex5 file created
- [ ] EA appears in Navigator → Experts
- [ ] Attached to XAUUSD M5 chart successfully
- [ ] Initialization message appears in Experts tab
- [ ] AutoTrading enabled (green button)

**If all checked, you're ready to demo trade!** 🎉

---

## 📞 Still Having Issues?

If none of the methods work:

1. **Take screenshots of:**
   - Error messages in MetaEditor
   - Your MQL5 folder structure
   - File locations where you copied files

2. **Share:**
   - MT5 broker name
   - Operating system version
   - Exact error messages

3. **I'll provide a custom fix!**

---

## 🎓 Understanding Include Methods

### Angle Brackets `#include <File.mqh>`
- Searches in: `MQL5/Include/` folder
- Used for: System libraries, reusable libraries
- Example: `#include <Trade\Trade.mqh>`

### Quotes `#include "File.mqh"`
- Searches in: Same folder as current file first
- Then searches: `MQL5/Include/` folder
- Used for: Local includes, project-specific files
- Example: `#include "SST_ScalpingStrategy.mqh"`

**We use quotes** so both files can live together in the Experts folder!

---

**Bottom line:** Copy both files to the Experts folder, compile, and you're done! 🚀
