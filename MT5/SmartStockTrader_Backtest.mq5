//+------------------------------------------------------------------+
//|                              SmartStockTrader_Backtest.mq5       |
//|              BACKTEST VERSION - No time/license restrictions     |
//|                  Optimized for MT5 Strategy Tester               |
//|              CONVERTED FROM MQ4 TO MQ5                           |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0 - Backtest Edition MT5"
#property link      ""
#property version   "5.00"
#property description "Backtest-optimized version - trades 24/7 on any symbol"

//+------------------------------------------------------------------+
//| Include MT5 Trade Library                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------
input string  TestSymbol            = "";                     // Leave empty to use current chart symbol
input int     MagicNumber           = 555777;
input bool    EnableTrading         = true;
input double  RiskPercentPerTrade   = 1.0;
input double  MaxDailyLossPercent   = 5.0;
input bool    ShowDashboard         = true;
input bool    VerboseLogging        = true;                  // Detailed logs for debugging

// Risk Management
input bool    UseATRStops           = true;
input double  ATRMultiplierSL       = 2.5;
input double  ATRMultiplierTP       = 4.0;
input int     FixedStopLossPips     = 100;
input int     FixedTakeProfitPips   = 200;

// Strategy Settings
input bool    UseMomentumStrategy   = true;
input bool    UseTrendFollowing     = true;
input bool    UseBreakoutStrategy   = true;
input double  MinConfidence         = 0.65;                  // 0-1 (0.65 = 65% confidence required)

// Indicators
input int     FastMA_Period         = 10;
input int     SlowMA_Period         = 50;
input int     RSI_Period            = 14;
input int     RSI_Oversold          = 30;
input int     RSI_Overbought        = 70;
input int     ATR_Period            = 14;

// Backtest Options
input bool    DisableTimeRestrictions = true;               // Trade 24/7 in backtest
input bool    DisableLicenseCheck   = true;                 // Skip license validation
input int     MinBarsBetweenTrades  = 5;                    // Minimum bars between trades

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

// Indicator Handles (MT5 style)
int h_FastMA;
int h_SlowMA;
int h_MA200;
int h_RSI;
int h_ATR;

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════╗");
   Print("║  SMART STOCK TRADER - BACKTEST MODE   ║");
   Print("║           MT5 VERSION                  ║");
   Print("╚════════════════════════════════════════╝");

   // Determine symbol to trade
   g_Symbol = (TestSymbol == "") ? _Symbol : TestSymbol;

   // Initialize indicator handles
   h_FastMA = iMA(g_Symbol, PERIOD_CURRENT, FastMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   h_SlowMA = iMA(g_Symbol, PERIOD_CURRENT, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   h_MA200 = iMA(g_Symbol, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE);
   h_RSI = iRSI(g_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   h_ATR = iATR(g_Symbol, PERIOD_CURRENT, ATR_Period);

   if(h_FastMA == INVALID_HANDLE || h_SlowMA == INVALID_HANDLE ||
      h_MA200 == INVALID_HANDLE || h_RSI == INVALID_HANDLE || h_ATR == INVALID_HANDLE) {
      Print("ERROR: Failed to create indicator handles!");
      return(INIT_FAILED);
   }

   // Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   trade.SetAsyncMode(false);

   Print("Trading Symbol: ", g_Symbol);
   Print("Time Restrictions: ", DisableTimeRestrictions ? "DISABLED (24/7)" : "ENABLED");
   Print("License Check: ", DisableLicenseCheck ? "DISABLED" : "ENABLED");
   Print("Risk Per Trade: ", RiskPercentPerTrade, "%");
   Print("Stop Loss: ", UseATRStops ? "ATR-based" : IntegerToString(FixedStopLossPips) + " pips");
   Print("Verbose Logging: ", VerboseLogging ? "ON" : "OFF");

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);

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

   // Release indicator handles
   IndicatorRelease(h_FastMA);
   IndicatorRelease(h_SlowMA);
   IndicatorRelease(h_MA200);
   IndicatorRelease(h_RSI);
   IndicatorRelease(h_ATR);

   ObjectsDeleteAll(0, "SST_", 0, OBJ_LABEL);
}

//--------------------------------------------------------------------
// ON TICK
//--------------------------------------------------------------------
void OnTick() {
   // Reset daily stats if new day
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   MqlDateTime dt_start;
   TimeToStruct(g_DailyStartTime, dt_start);

   if(dt.day != dt_start.day) {
      if(VerboseLogging) Print("━━━ NEW DAY - Resetting daily stats ━━━");
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
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
   if(PositionSelect(g_Symbol)) {
      return;  // Already have a position
   }

   // Check minimum bars between trades
   if(TimeCurrent() - g_LastTradeTime < MinBarsBetweenTrades * PeriodSeconds(PERIOD_CURRENT)) {
      return;
   }

   // Check for new bar (trade on bar open)
   static datetime lastBarTime = 0;
   datetime rates[];
   if(CopyTime(g_Symbol, PERIOD_CURRENT, 0, 1, rates) <= 0) return;
   datetime currentBarTime = rates[0];
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

   // Get indicator values using CopyBuffer (MT5 style)
   double fastMA_buffer[], slowMA_buffer[], ma200_buffer[], rsi_buffer[], atr_buffer[];
   ArraySetAsSeries(fastMA_buffer, true);
   ArraySetAsSeries(slowMA_buffer, true);
   ArraySetAsSeries(ma200_buffer, true);
   ArraySetAsSeries(rsi_buffer, true);
   ArraySetAsSeries(atr_buffer, true);

   if(CopyBuffer(h_FastMA, 0, 0, 3, fastMA_buffer) <= 0 ||
      CopyBuffer(h_SlowMA, 0, 0, 3, slowMA_buffer) <= 0 ||
      CopyBuffer(h_MA200, 0, 0, 3, ma200_buffer) <= 0 ||
      CopyBuffer(h_RSI, 0, 0, 3, rsi_buffer) <= 0 ||
      CopyBuffer(h_ATR, 0, 0, 3, atr_buffer) <= 0) {
      if(VerboseLogging) Print("  ✗ Failed to copy indicator buffers");
      return;
   }

   double fastMA = fastMA_buffer[1];
   double slowMA = slowMA_buffer[1];
   double ma200 = ma200_buffer[1];
   double rsi = rsi_buffer[1];
   double atr = atr_buffer[1];

   // Get close prices
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(g_Symbol, PERIOD_CURRENT, 0, 3, close) <= 0) {
      if(VerboseLogging) Print("  ✗ Failed to copy close prices");
      return;
   }
   double close1 = close[1];
   double close2 = close[2];

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
      double high[], low[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      if(CopyHigh(g_Symbol, PERIOD_CURRENT, 2, 20, high) > 0 &&
         CopyLow(g_Symbol, PERIOD_CURRENT, 2, 20, low) > 0) {
         double highestHigh = high[ArrayMaximum(high)];
         double lowestLow = low[ArrayMinimum(low)];

         if(close1 > highestHigh) {
            signal = 1;
            confidence = 0.80;
            strategyName = "Breakout Buy";
            if(VerboseLogging) Print("  ✓ Breakout BUY signal detected (broke above ", DoubleToString(highestHigh, _Digits), ")");
         } else if(close1 < lowestLow) {
            signal = -1;
            confidence = 0.80;
            strategyName = "Breakout Sell";
            if(VerboseLogging) Print("  ✓ Breakout SELL signal detected (broke below ", DoubleToString(lowestLow, _Digits), ")");
         }
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
   double point = SymbolInfoDouble(g_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(g_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_Symbol, SYMBOL_BID);

   // Calculate stop loss and take profit
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   if(CopyBuffer(h_ATR, 0, 0, 2, atr_buffer) <= 0) return;
   double atr = atr_buffer[1];

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

   // Send order using CTrade
   bool result = false;
   if(isBuy) {
      result = trade.Buy(lotSize, g_Symbol, price, sl, tp, "SST: " + strategy);
   } else {
      result = trade.Sell(lotSize, g_Symbol, price, sl, tp, "SST: " + strategy);
   }

   if(result) {
      ulong ticket = trade.ResultOrder();
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
      Print("✗ ERROR opening trade - Code: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//--------------------------------------------------------------------
// CALCULATE LOT SIZE
//--------------------------------------------------------------------
double CalculateLotSize(double slPips) {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercentPerTrade / 100.0;
   double tickValue = SymbolInfoDouble(g_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(g_Symbol, SYMBOL_POINT);

   double lotSize = riskAmount / (slPips * 10.0 * tickValue);

   // Apply broker limits
   double minLot = SymbolInfoDouble(g_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(g_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(g_Symbol, SYMBOL_VOLUME_STEP);

   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);

   return lotSize;
}

//--------------------------------------------------------------------
// CHECK DAILY LOSS LIMIT
//--------------------------------------------------------------------
bool CheckDailyLossLimit() {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
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

   CreateLabel("SST_Title", "Smart Stock Trader - BACKTEST MT5", 10, y, clrWhite, 10); y += lineHeight + 5;
   CreateLabel("SST_Symbol", "Symbol: " + g_Symbol, 10, y, clrYellow, 9); y += lineHeight;
   CreateLabel("SST_Equity", "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), 10, y, clrLime, 9); y += lineHeight;

   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - g_DailyStartEquity;
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

//+------------------------------------------------------------------+
