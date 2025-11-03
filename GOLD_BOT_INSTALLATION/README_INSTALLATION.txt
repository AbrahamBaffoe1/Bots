================================================================================
           GOLD SCALPING BOT - INSTALLATION INSTRUCTIONS
================================================================================

📁 FOLDER STRUCTURE IN THIS PACKAGE:

GOLD_BOT_INSTALLATION/
├── FOR_EXPERTS_FOLDER/
│   └── GoldScalpingBot.mq5          ← Copy this to MT5 Experts folder
│
├── FOR_INCLUDE_FOLDER/
│   └── SST_ScalpingStrategy.mqh     ← Copy this to MT5 Include folder
│
└── README_INSTALLATION.txt          ← This file


================================================================================
🚀 INSTALLATION STEPS (EASY - 3 STEPS)
================================================================================

STEP 1: Open MT5 Data Folder
-----------------------------
1. Open MetaTrader 5
2. Click: File → Open Data Folder
3. A window opens → You'll see folders like "MQL5"
4. Open the "MQL5" folder


STEP 2: Copy Files to Correct Locations
----------------------------------------

FILE 1 - Copy the EA (Expert Advisor):
---------------------------------------
FROM: FOR_EXPERTS_FOLDER/GoldScalpingBot.mq5
TO:   [MT5 Data]/MQL5/Experts/GoldScalpingBot.mq5

👉 Drag "GoldScalpingBot.mq5" into the "Experts" folder


FILE 2 - Copy the Strategy Library:
------------------------------------
FROM: FOR_INCLUDE_FOLDER/SST_ScalpingStrategy.mqh
TO:   [MT5 Data]/MQL5/Include/SST_ScalpingStrategy.mqh

👉 Drag "SST_ScalpingStrategy.mqh" into the "Include" folder


STEP 3: Compile in MetaEditor
------------------------------
1. In MT5, press F4 (opens MetaEditor)
2. Navigator panel (left side) → Experts folder
3. Find and double-click: GoldScalpingBot.mq5
4. Press F7 (or click Compile button)

✅ You should see: "0 error(s), 0 warning(s)"


================================================================================
📂 WHERE EXACTLY TO COPY FILES
================================================================================

Your MT5 folder structure should look like this AFTER copying:

[MT5 Data Folder]/
└── MQL5/
    ├── Experts/
    │   └── GoldScalpingBot.mq5        ← FILE 1 GOES HERE
    │
    └── Include/
        └── SST_ScalpingStrategy.mqh   ← FILE 2 GOES HERE


IMPORTANT:
- GoldScalpingBot.mq5 → Goes in "Experts" folder
- SST_ScalpingStrategy.mqh → Goes in "Include" folder
- They are in DIFFERENT folders!


================================================================================
✅ VERIFICATION
================================================================================

After copying and compiling, check:

1. Compilation Result:
   ✓ 0 error(s), 0 warning(s)
   ✓ GoldScalpingBot.ex5 created

2. Navigator Panel:
   ✓ Experts folder shows "GoldScalpingBot"

3. Attach to Chart:
   ✓ Open XAUUSD chart
   ✓ Set timeframe to M5
   ✓ Drag GoldScalpingBot from Navigator to chart
   ✓ Click OK

4. Check Experts Tab:
   ✓ Should see "GOLD SCALPING BOT v1.0 INITIALIZING"
   ✓ Should see "INITIALIZATION COMPLETE - READY!"


================================================================================
🚨 IF YOU CAN'T PASTE FILES INTO MT5 FOLDER
================================================================================

PROBLEM: macOS security or MT5 Wine installation prevents pasting

SOLUTION 1: Use Finder with Administrator Access
-------------------------------------------------
1. Open Finder
2. Press: Cmd+Shift+G (Go to Folder)
3. Type the path shown in "Open Data Folder"
4. Navigate to MQL5/Experts/ and MQL5/Include/
5. Copy files there
6. If asked for password, enter your Mac password


SOLUTION 2: Use Terminal (Copy-Paste Commands)
-----------------------------------------------
Open Terminal and run these commands:

# First, find your MT5 Data folder
# In MT5: File → Open Data Folder
# Copy the path shown (e.g., /Users/you/Library/...)

# Replace [MT5_DATA_PATH] with your actual path:
MT5_PATH="[PASTE YOUR MT5 DATA FOLDER PATH HERE]"

# Copy files (run these commands):
cp ~/Desktop/EABot/GOLD_BOT_INSTALLATION/FOR_EXPERTS_FOLDER/GoldScalpingBot.mq5 "$MT5_PATH/MQL5/Experts/"

cp ~/Desktop/EABot/GOLD_BOT_INSTALLATION/FOR_INCLUDE_FOLDER/SST_ScalpingStrategy.mqh "$MT5_PATH/MQL5/Include/"

# Verify files copied
ls -la "$MT5_PATH/MQL5/Experts/GoldScalpingBot.mq5"
ls -la "$MT5_PATH/MQL5/Include/SST_ScalpingStrategy.mqh"


SOLUTION 3: Change File Permissions
------------------------------------
If folders are read-only:

1. Right-click on MQL5 folder → Get Info
2. Bottom section "Sharing & Permissions"
3. Click lock icon (enter password)
4. Change "Privilege" to "Read & Write"
5. Click gear icon → "Apply to enclosed items"
6. Try copying again


SOLUTION 4: Use MetaEditor File Menu
-------------------------------------
1. Open MetaEditor (F4 in MT5)
2. File → Open
3. Navigate to Desktop/EABot/GOLD_BOT_INSTALLATION/FOR_EXPERTS_FOLDER/
4. Open GoldScalpingBot.mq5
5. File → Save As
6. Save to: [MT5 Data]/MQL5/Experts/GoldScalpingBot.mq5
7. Repeat for SST_ScalpingStrategy.mqh → save to Include/


================================================================================
🔍 TROUBLESHOOTING
================================================================================

ERROR: "file not found"
-----------------------
FIX: Make sure SST_ScalpingStrategy.mqh is in Include/ folder
     Check spelling (case-sensitive!)


ERROR: "Cannot paste files"
----------------------------
FIX: Use Terminal method (Solution 2 above)
     Or use MetaEditor Save As (Solution 4)


ERROR: "Permission denied"
--------------------------
FIX: Change folder permissions (Solution 3)
     Or run Terminal with sudo


Compilation successful but EA won't attach?
-------------------------------------------
FIX: Enable AutoTrading (Ctrl+E in MT5 - button turns GREEN)
     Check you're on XAUUSD symbol
     Check timeframe is M5


================================================================================
📞 NEED HELP?
================================================================================

If still having issues:

1. Take screenshot of:
   - Error message in MetaEditor
   - Your MQL5 folder structure (show Experts/ and Include/ folders)
   - Where you tried to paste files

2. Note:
   - Your MT5 broker name
   - macOS version
   - Whether MT5 is Wine-based or native

3. Share details and I'll provide custom solution


================================================================================
✅ SUCCESS CHECKLIST
================================================================================

Before testing:
□ GoldScalpingBot.mq5 copied to Experts/ folder
□ SST_ScalpingStrategy.mqh copied to Include/ folder
□ Compiled with 0 errors
□ .ex5 file created
□ EA shows in Navigator → Experts
□ Attached to XAUUSD M5 chart
□ Initialization message shows in Experts tab
□ AutoTrading enabled (green button)

If all checked → You're ready to demo trade! 🎉


================================================================================
🎯 QUICK SUMMARY
================================================================================

1. Open MT5 → File → Open Data Folder → MQL5/

2. Copy:
   - GoldScalpingBot.mq5 → to Experts/ folder
   - SST_ScalpingStrategy.mqh → to Include/ folder

3. Compile in MetaEditor (F4, then F7)

4. Attach to XAUUSD M5 chart

Done! ✅


================================================================================
📚 NEXT STEPS AFTER INSTALLATION
================================================================================

1. Demo Test (2-4 weeks minimum)
2. Backtest (Strategy Tester)
3. Optimize parameters
4. VPS setup (optional)
5. Go live with small capital

See full documentation:
- QUICK_START_GUIDE.md
- GoldScalpingBot_README.md
- PARAMETER_PRESETS.txt


================================================================================
Good luck! 🚀
================================================================================
