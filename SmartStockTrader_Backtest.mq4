//+------------------------------------------------------------------+
//|                              SmartStockTrader_Backtest.mq4       |
//|              BACKTEST VERSION - No time/license restrictions     |
//|                  Optimized for MT4 Strategy Tester               |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0 - Backtest Edition"
#property version   "1.00"
#property strict
#property description "Backtest-optimized version - trades 24/7 on any symbol"

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------
extern string  TestSymbol            = "";                     // Leave empty to use current chart symbol
extern int     MagicNumber           = 555777;
extern bool    EnableTrading         = true;
extern double  RiskPercentPerTrade   = 1.0;
extern double  MaxDailyLossPercent   = 5.0;
extern bool    ShowDashboard         = true;
extern bool    VerboseLogging        = true;                  // Detailed logs for debugging

// Risk Management
extern bool    UseATRStops           = true;
extern double  ATRMultiplierSL       = 2.5;
extern double  ATRMultiplierTP       = 4.0;
extern int     FixedStopLossPips     = 100;
extern int     FixedTakeProfitPips   = 200;

// Strategy Settings
extern bool    UseMomentumStrategy   = true;
extern bool    UseTrendFollowing     = true;
extern bool    UseBreakoutStrategy   = true;
extern double  MinConfidence         = 0.65;                  // 0-1 (0.65 = 65% confidence required)

// Indicators
extern int     FastMA_Period         = 10;
extern int     SlowMA_Period         = 50;
extern int     RSI_Period            = 14;
extern int     RSI_Oversold          = 30;
extern int     RSI_Overbought        = 70;
extern int     ATR_Period            = 14;

// Backtest Options
extern bool    DisableTimeRestrictions = true;               // Trade 24/7 in backtest
extern bool    DisableLicenseCheck   = true;                 // Skip license validation
extern int     MinBarsBetweenTrades  = 5;                    // Minimum bars between trades

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
string  g_Symbol;
datetime g_DailyStartTime = 0;
double   g_DailyStartEquity = 0;
int     g_DailyTrades = 0;
int     g_DailyWins = 0;
int     g_DailyLosses = 0;
int     g_TotalTrades = 0;
int     g_TotalWins = 0;
int     g_TotalLosses = 0;
double  g_TotalProfit = 0;
double  g_TotalLoss = 0;
datetime g_LastTradeTime = 0;

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════╗");
   Print("║  SMART STOCK TRADER - BACKTEST MODE   ║");
   Print("╚════════════════════════════════════════╝");

   // Determine symbol to trade
   g_Symbol = (TestSymbol == "") ? Symbol() : TestSymbol;

   Print("Trading Symbol: ", g_Symbol);
   Print("Time Restrictions: ", DisableTimeRestrictions ? "DISABLED (24/7)" : "ENABLED");
   Print("License Check: ", DisableLicenseCheck ? "DISABLED" : "ENABLED");
   Print("Risk Per Trade: ", RiskPercentPerTrade, "%");
   Print("Stop Loss: ", UseATRStops ? "ATR-based" : IntegerToString(FixedStopLossPips) + " pips");
   Print("Verbose Logging: ", VerboseLogging ? "ON" : "OFF");

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountEquity();

   if(ShowDashboard) {
      UpdateDashboard();
   }

   Print("=== INITIALIZATION COMPLETE ===");
   Print("Ready to backtest!\n");

   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("\n╔════════════════════════════════════════╗");
   Print("║     BACKTEST RESULTS SUMMARY          ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Total Trades:    ", g_TotalTrades);
   Print("║ Wins:            ", g_TotalWins);
   Print("║ Losses:          ", g_TotalLosses);
   if(g_TotalTrades > 0) {
      double winRate = (double)g_TotalWins / g_TotalTrades * 100.0;
      Print("║ Win Rate:        ", DoubleToString(winRate, 1), "%");
      Print("║ Total Profit:    $", DoubleToString(g_TotalProfit, 2));
      Print("║ Total Loss:      $", DoubleToString(g_TotalLoss, 2));
      Print("║ Net P/L:         $", DoubleToString(g_TotalProfit - g_TotalLoss, 2));
   }
   Print("╚════════════════════════════════════════╝\n");

   ObjectsDeleteAll(0, "SST_", 0, OBJ_LABEL);
}

//--------------------------------------------------------------------
// ON TICK
//--------------------------------------------------------------------
void OnTick() {
   // Reset daily stats if new day
   if(TimeDay(TimeCurrent()) != TimeDay(g_DailyStartTime)) {
      if(VerboseLogging) Print("━━━ NEW DAY - Resetting daily stats ━━━");
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountEquity();
      g_DailyTrades = 0;
      g_DailyWins = 0;
      g_DailyLosses = 0;
   }

   // Update dashboard
   static int tickCount = 0;
   tickCount++;
   if(ShowDashboard && tickCount % 10 == 0) {
      UpdateDashboard();
   }

   // Check if trading is allowed
   if(!EnableTrading) {
      if(VerboseLogging && tickCount == 1) Print("⚠ Trading disabled by parameter");
      return;
   }

   // Check daily loss limit
   if(CheckDailyLossLimit()) {
      if(VerboseLogging && tickCount % 100 == 0) Print("⚠ Daily loss limit reached");
      return;
   }

   // Check if already have position on this symbol
   bool hasPosition = false;
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == g_Symbol && OrderMagicNumber() == MagicNumber) {
            hasPosition = true;
            break;
         }
      }
   }

   if(hasPosition) return;

   // Check minimum bars between trades
   if(TimeCurrent() - g_LastTradeTime < MinBarsBetweenTrades * Period() * 60) {
      return;
   }

   // Check for new bar (trade on bar open)
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(g_Symbol, 0, 0);
   if(currentBarTime == lastBarTime) return;
   lastBarTime = currentBarTime;

   // ANALYZE MARKET AND LOOK FOR TRADE SIGNAL
   AnalyzeAndTrade();
}

//--------------------------------------------------------------------
// ANALYZE MARKET AND EXECUTE TRADE
//--------------------------------------------------------------------
void AnalyzeAndTrade() {
   if(VerboseLogging) Print("\n▶ Analyzing market at ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));

   // Get indicator values
   double fastMA = iMA(g_Symbol, 0, FastMA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double slowMA = iMA(g_Symbol, 0, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double rsi = iRSI(g_Symbol, 0, RSI_Period, PRICE_CLOSE, 1);
   double atr = iATR(g_Symbol, 0, ATR_Period, 1);

   double close1 = iClose(g_Symbol, 0, 1);
   double close2 = iClose(g_Symbol, 0, 2);

   if(VerboseLogging) {
      Print("  FastMA: ", DoubleToString(fastMA, _Digits));
      Print("  SlowMA: ", DoubleToString(slowMA, _Digits));
      Print("  RSI: ", DoubleToString(rsi, 2));
      Print("  ATR: ", DoubleToString(atr, _Digits));
   }

   // SIGNAL DETECTION
   int signal = 0;  // 0=none, 1=buy, -1=sell
   double confidence = 0.0;
   string strategyName = "";

   // Strategy 1: Momentum (MA Crossover + RSI)
   if(UseMomentumStrategy) {
      if(fastMA > slowMA && rsi < RSI_Overbought && close1 > close2) {
         signal = 1;
         confidence = 0.75;
         strategyName = "Momentum Buy";
         if(VerboseLogging) Print("  ✓ Momentum BUY signal detected");
      } else if(fastMA < slowMA && rsi > RSI_Oversold && close1 < close2) {
         signal = -1;
         confidence = 0.75;
         strategyName = "Momentum Sell";
         if(VerboseLogging) Print("  ✓ Momentum SELL signal detected");
      }
   }

   // Strategy 2: Trend Following
   if(signal == 0 && UseTrendFollowing) {
      double ma200 = iMA(g_Symbol, 0, 200, 0, MODE_SMA, PRICE_CLOSE, 1);
      if(close1 > ma200 && fastMA > slowMA && rsi > 50) {
         signal = 1;
         confidence = 0.70;
         strategyName = "Trend Following Buy";
         if(VerboseLogging) Print("  ✓ Trend Following BUY signal detected");
      } else if(close1 < ma200 && fastMA < slowMA && rsi < 50) {
         signal = -1;
         confidence = 0.70;
         strategyName = "Trend Following Sell";
         if(VerboseLogging) Print("  ✓ Trend Following SELL signal detected");
      }
   }

   // Strategy 3: Breakout
   if(signal == 0 && UseBreakoutStrategy) {
      double high = iHigh(g_Symbol, 0, iHighest(g_Symbol, 0, MODE_HIGH, 20, 2));
      double low = iLow(g_Symbol, 0, iLowest(g_Symbol, 0, MODE_LOW, 20, 2));

      if(close1 > high) {
         signal = 1;
         confidence = 0.80;
         strategyName = "Breakout Buy";
         if(VerboseLogging) Print("  ✓ Breakout BUY signal detected (broke above ", DoubleToString(high, _Digits), ")");
      } else if(close1 < low) {
         signal = -1;
         confidence = 0.80;
         strategyName = "Breakout Sell";
         if(VerboseLogging) Print("  ✓ Breakout SELL signal detected (broke below ", DoubleToString(low, _Digits), ")");
      }
   }

   // Execute trade if signal is strong enough
   if(signal != 0 && confidence >= MinConfidence) {
      ExecuteTrade(signal == 1, strategyName, confidence);
   } else {
      if(VerboseLogging) {
         if(signal == 0) {
            Print("  ✗ No signal detected");
         } else {
            Print("  ✗ Signal confidence too low (", DoubleToString(confidence * 100, 1), "% < ", DoubleToString(MinConfidence * 100, 1), "%)");
         }
      }
   }
}

//--------------------------------------------------------------------
// EXECUTE TRADE
//--------------------------------------------------------------------
void ExecuteTrade(bool isBuy, string strategy, double confidence) {
   double point = MarketInfo(g_Symbol, MODE_POINT);
   double ask = MarketInfo(g_Symbol, MODE_ASK);
   double bid = MarketInfo(g_Symbol, MODE_BID);

   // Calculate stop loss and take profit
   double atr = iATR(g_Symbol, 0, ATR_Period, 1);
   double slPips, tpPips;

   if(UseATRStops) {
      slPips = atr / point / 10.0 * ATRMultiplierSL;
      tpPips = atr / point / 10.0 * ATRMultiplierTP;
   } else {
      slPips = FixedStopLossPips;
      tpPips = FixedTakeProfitPips;
   }

   // Calculate position size
   double lotSize = CalculateLotSize(slPips);

   // Calculate SL/TP prices
   double price = isBuy ? ask : bid;
   double sl = isBuy ? (price - slPips * point * 10.0) : (price + slPips * point * 10.0);
   double tp = isBuy ? (price + tpPips * point * 10.0) : (price - tpPips * point * 10.0);

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   // Send order
   int ticket = OrderSend(g_Symbol, isBuy ? OP_BUY : OP_SELL, lotSize, price, 5, sl, tp,
                         "SST: " + strategy, MagicNumber, 0, isBuy ? clrBlue : clrRed);

   if(ticket > 0) {
      g_TotalTrades++;
      g_DailyTrades++;
      g_LastTradeTime = TimeCurrent();

      Print("\n╔════════════════════════════════════╗");
      Print("║       NEW TRADE OPENED (#", ticket, ")    ║");
      Print("╠════════════════════════════════════╣");
      Print("║ Type:       ", isBuy ? "BUY" : "SELL");
      Print("║ Symbol:     ", g_Symbol);
      Print("║ Price:      ", DoubleToString(price, _Digits));
      Print("║ Lot Size:   ", DoubleToString(lotSize, 2));
      Print("║ Stop Loss:  ", DoubleToString(sl, _Digits), " (", DoubleToString(slPips, 1), " pips)");
      Print("║ Take Profit:", DoubleToString(tp, _Digits), " (", DoubleToString(tpPips, 1), " pips)");
      Print("║ Strategy:   ", strategy);
      Print("║ Confidence: ", DoubleToString(confidence * 100, 1), "%");
      Print("╚════════════════════════════════════╝\n");
   } else {
      int error = GetLastError();
      Print("✗ ERROR opening trade - Code: ", error, " - ", ErrorDescription(error));
   }
}

//--------------------------------------------------------------------
// CALCULATE LOT SIZE
//--------------------------------------------------------------------
double CalculateLotSize(double slPips) {
   double riskAmount = AccountBalance() * RiskPercentPerTrade / 100.0;
   double tickValue = MarketInfo(g_Symbol, MODE_TICKVALUE);
   double tickSize = MarketInfo(g_Symbol, MODE_TICKSIZE);
   double point = MarketInfo(g_Symbol, MODE_POINT);

   double lotSize = riskAmount / (slPips * 10.0 * tickValue);

   // Apply broker limits
   double minLot = MarketInfo(g_Symbol, MODE_MINLOT);
   double maxLot = MarketInfo(g_Symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(g_Symbol, MODE_LOTSTEP);

   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;

   return lotSize;
}

//--------------------------------------------------------------------
// CHECK DAILY LOSS LIMIT
//--------------------------------------------------------------------
bool CheckDailyLossLimit() {
   double currentEquity = AccountEquity();
   double dailyPL = currentEquity - g_DailyStartEquity;
   double dailyLossPercent = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyLossPercent <= -MaxDailyLossPercent) {
      return true;  // Stop trading
   }

   return false;
}

//--------------------------------------------------------------------
// UPDATE DASHBOARD
//--------------------------------------------------------------------
void UpdateDashboard() {
   int y = 20;
   int lineHeight = 18;

   CreateLabel("SST_Title", "Smart Stock Trader - BACKTEST", 10, y, clrWhite, 10); y += lineHeight + 5;
   CreateLabel("SST_Symbol", "Symbol: " + g_Symbol, 10, y, clrYellow, 9); y += lineHeight;
   CreateLabel("SST_Equity", "Equity: $" + DoubleToString(AccountEquity(), 2), 10, y, clrLime, 9); y += lineHeight;

   double dailyPL = AccountEquity() - g_DailyStartEquity;
   color plColor = dailyPL >= 0 ? clrLime : clrRed;
   CreateLabel("SST_DailyPL", "Daily P/L: $" + DoubleToString(dailyPL, 2), 10, y, plColor, 9); y += lineHeight;

   CreateLabel("SST_Trades", "Total Trades: " + IntegerToString(g_TotalTrades), 10, y, clrWhite, 9); y += lineHeight;
   CreateLabel("SST_Wins", "Wins: " + IntegerToString(g_TotalWins) + " | Losses: " + IntegerToString(g_TotalLosses), 10, y, clrWhite, 9); y += lineHeight;

   if(g_TotalTrades > 0) {
      double winRate = (double)g_TotalWins / g_TotalTrades * 100.0;
      CreateLabel("SST_WinRate", "Win Rate: " + DoubleToString(winRate, 1) + "%", 10, y, winRate >= 50 ? clrLime : clrOrange, 9);
   }
}

void CreateLabel(string name, string text, int x, int y, color clr, int size) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//--------------------------------------------------------------------
// ERROR DESCRIPTION
//--------------------------------------------------------------------
string ErrorDescription(int errorCode) {
   switch(errorCode) {
      case 0: return "No error";
      case 1: return "No error but result unknown";
      case 2: return "Common error";
      case 3: return "Invalid trade parameters";
      case 4: return "Trade server is busy";
      case 5: return "Old version of client terminal";
      case 6: return "No connection";
      case 7: return "Not enough rights";
      case 8: return "Too frequent requests";
      case 9: return "Malfunctional trade operation";
      case 64: return "Account disabled";
      case 65: return "Invalid account";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid trade volume";
      case 132: return "Market is closed";
      case 133: return "Trade is disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 137: return "Broker is busy";
      case 138: return "Requote";
      case 139: return "Order is locked";
      case 140: return "Long positions only allowed";
      case 141: return "Too many requests";
      case 145: return "Modification denied";
      case 146: return "Trade context is busy";
      case 147: return "Expiration denied";
      case 148: return "Too many open orders";
      default: return "Unknown error";
   }
}

//+------------------------------------------------------------------+
