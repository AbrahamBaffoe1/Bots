//+------------------------------------------------------------------+
//|                                              SST_Dashboard.mqh |
//|                   Smart Stock Trader - Visual Dashboard          |
//|                    Real-time performance display on chart        |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// DASHBOARD CONSTANTS
//--------------------------------------------------------------------
#define DASHBOARD_NAME "SST_Dashboard"
#define DASHBOARD_X 15
#define DASHBOARD_Y 20
#define PANEL_NAME "SST_Panel"
#define PANEL_WIDTH 280
#define PANEL_HEIGHT 450

//--------------------------------------------------------------------
// DASHBOARD FUNCTIONS
//--------------------------------------------------------------------

// Create dashboard text object
void Dashboard_CreateLabel(string name, int x, int y, string text, color clr = clrWhite, int fontSize = 9) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, "Courier New");
   }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

// Update dashboard display
void Dashboard_Update() {
   if(!ShowDashboard) return;

   int yPos = DASHBOARD_Y;
   int lineHeight = 18;
   color stateColor = clrLime;
   string stateName = "READY";

   // Determine EA state
   switch(g_EAState) {
      case STATE_READY:
         stateColor = clrLime;
         stateName = "READY";
         break;
      case STATE_SUSPENDED:
         stateColor = clrRed;
         stateName = "SUSPENDED";
         break;
      case STATE_RECOVERY:
         stateColor = clrOrange;
         stateName = "RECOVERY";
         break;
      case STATE_NEWS_PAUSE:
         stateColor = clrYellow;
         stateName = "NEWS PAUSE";
         break;
   }

   // Header
   Dashboard_CreateLabel(DASHBOARD_NAME + "_Header", DASHBOARD_X, yPos,
                        "=== SMART STOCK TRADER ===", clrAqua, 11);
   yPos += lineHeight + 5;

   // EA State
   Dashboard_CreateLabel(DASHBOARD_NAME + "_State", DASHBOARD_X, yPos,
                        "State: " + stateName, stateColor, 10);
   yPos += lineHeight;

   // Account Info
   Dashboard_CreateLabel(DASHBOARD_NAME + "_Balance", DASHBOARD_X, yPos,
                        "Balance: $" + DoubleToString(AccountBalance(), 2), clrWhite);
   yPos += lineHeight;

   Dashboard_CreateLabel(DASHBOARD_NAME + "_Equity", DASHBOARD_X, yPos,
                        "Equity:  $" + DoubleToString(AccountEquity(), 2), clrWhite);
   yPos += lineHeight;

   // Daily P/L
   double dailyPL = AccountEquity() - g_DailyStartEquity;
   double dailyPct = (g_DailyStartEquity > 0) ? (dailyPL / g_DailyStartEquity * 100.0) : 0;
   color plColor = (dailyPL >= 0) ? clrLime : clrRed;
   string plSign = (dailyPL >= 0) ? "+" : "";

   Dashboard_CreateLabel(DASHBOARD_NAME + "_DailyPL", DASHBOARD_X, yPos,
                        "Daily P/L: " + plSign + "$" + DoubleToString(dailyPL, 2) +
                        " (" + plSign + DoubleToString(dailyPct, 2) + "%)", plColor);
   yPos += lineHeight + 3;

   // Session Info
   Dashboard_CreateLabel(DASHBOARD_NAME + "_Session", DASHBOARD_X, yPos,
                        "Session: " + Session_GetCurrentName(), clrYellow);
   yPos += lineHeight;

   bool isTradingTime = Session_IsTradingTime();
   Dashboard_CreateLabel(DASHBOARD_NAME + "_Trading", DASHBOARD_X, yPos,
                        "Trading: " + (isTradingTime ? "ACTIVE" : "PAUSED"),
                        isTradingTime ? clrLime : clrOrange);
   yPos += lineHeight + 3;

   // Today's Stats
   Dashboard_CreateLabel(DASHBOARD_NAME + "_TodayHeader", DASHBOARD_X, yPos,
                        "--- Today's Stats ---", clrSilver);
   yPos += lineHeight;

   Dashboard_CreateLabel(DASHBOARD_NAME + "_Trades", DASHBOARD_X, yPos,
                        "Trades: " + IntegerToString(g_DailyTrades), clrWhite);
   yPos += lineHeight;

   Dashboard_CreateLabel(DASHBOARD_NAME + "_WinsLosses", DASHBOARD_X, yPos,
                        "W/L: " + IntegerToString(g_DailyWins) + "/" + IntegerToString(g_DailyLosses),
                        clrWhite);
   yPos += lineHeight;

   double todayWR = (g_DailyTrades > 0) ? (g_DailyWins / (double)g_DailyTrades * 100.0) : 0;
   Dashboard_CreateLabel(DASHBOARD_NAME + "_WinRate", DASHBOARD_X, yPos,
                        "Win Rate: " + DoubleToString(todayWR, 1) + "%",
                        todayWR >= 50 ? clrLime : clrOrange);
   yPos += lineHeight + 3;

   // Overall Stats
   Dashboard_CreateLabel(DASHBOARD_NAME + "_OverallHeader", DASHBOARD_X, yPos,
                        "--- Overall Stats ---", clrSilver);
   yPos += lineHeight;

   Dashboard_CreateLabel(DASHBOARD_NAME + "_TotalTrades", DASHBOARD_X, yPos,
                        "Total: " + IntegerToString(g_TotalTrades), clrWhite);
   yPos += lineHeight;

   double totalWR = Analytics_GetWinRate();
   Dashboard_CreateLabel(DASHBOARD_NAME + "_TotalWR", DASHBOARD_X, yPos,
                        "Win Rate: " + DoubleToString(totalWR, 1) + "%",
                        totalWR >= 50 ? clrLime : clrOrange);
   yPos += lineHeight;

   double pf = Analytics_GetProfitFactor();
   Dashboard_CreateLabel(DASHBOARD_NAME + "_PF", DASHBOARD_X, yPos,
                        "Profit Factor: " + DoubleToString(pf, 2),
                        pf >= 1.5 ? clrLime : (pf >= 1.0 ? clrYellow : clrRed));
   yPos += lineHeight + 3;

   // Open Positions
   int openPos = ArraySize(g_OpenTrades);
   Dashboard_CreateLabel(DASHBOARD_NAME + "_OpenPos", DASHBOARD_X, yPos,
                        "Open Positions: " + IntegerToString(openPos), clrWhite);
   yPos += lineHeight;

   // Streaks
   if(g_ConsecutiveWins > 0) {
      Dashboard_CreateLabel(DASHBOARD_NAME + "_Streak", DASHBOARD_X, yPos,
                           "Win Streak: " + IntegerToString(g_ConsecutiveWins), clrLime);
      yPos += lineHeight;
   } else if(g_ConsecutiveLosses > 0) {
      Dashboard_CreateLabel(DASHBOARD_NAME + "_Streak", DASHBOARD_X, yPos,
                           "Loss Streak: " + IntegerToString(g_ConsecutiveLosses), clrRed);
      yPos += lineHeight;
   }

   // Recovery Mode Indicator
   if(g_RecoveryModeActive) {
      Dashboard_CreateLabel(DASHBOARD_NAME + "_Recovery", DASHBOARD_X, yPos,
                           "! RECOVERY MODE ACTIVE !", clrOrange);
      yPos += lineHeight;
   }

   // Time
   Dashboard_CreateLabel(DASHBOARD_NAME + "_Time", DASHBOARD_X, yPos,
                        TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), clrSilver, 8);
}

// Draw S/R levels on chart
void Dashboard_DrawSRLevels() {
   if(!UseSupportResistance) return;

   // Draw support and resistance lines
   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].symbol == _Symbol) {
         string name = "SR_Level_" + IntegerToString(i);
         color lineColor = g_SRLevels[i].isSupport ? clrBlue : clrRed;

         if(ObjectFind(0, name) < 0) {
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, g_SRLevels[i].level);
            ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            ObjectSetString(0, name, OBJPROP_TEXT,
                           (g_SRLevels[i].isSupport ? "Support " : "Resistance ") +
                           DoubleToString(g_SRLevels[i].level, _Digits));
         } else {
            ObjectSetDouble(0, name, OBJPROP_PRICE1, g_SRLevels[i].level);
         }
      }
   }
}

// Remove dashboard objects
void Dashboard_Remove() {
   ObjectsDeleteAll(0, DASHBOARD_NAME, 0, OBJ_LABEL);
   ObjectsDeleteAll(0, "SR_Level_", 0, OBJ_HLINE);
}

// Create background panel
void Dashboard_CreatePanel() {
   if(ObjectFind(0, PANEL_NAME) < 0) {
      ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, 15);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, PANEL_WIDTH);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, PANEL_HEIGHT);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_BGCOLOR, C'25,25,35');  // Dark background
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, clrDarkSlateGray);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_BACK, true);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);
   }
}

// Initialize dashboard
void Dashboard_Init() {
   if(ShowDashboard) {
      Print("=== Dashboard Module Initialized ===");
      Dashboard_CreatePanel();
      Dashboard_Update();
   }
}

//+------------------------------------------------------------------+
