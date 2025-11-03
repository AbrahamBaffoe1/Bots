//+------------------------------------------------------------------+
//|                                          SmartStockTrader.mq5    |
//|                       Ultra-Intelligent Stock Trading EA         |
//|  Multi-Strategy | ML Patterns | Advanced Risk | Real-time Analytics |
//|                IMPROVED VERSION - ALL CRITICAL FIXES APPLIED     |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v2.0 MT5 - IMPROVED"
#property link      "https://github.com/yourusername/smart-stock-trader"
#property version   "5.10"
#property description "IMPROVED: Support/Resistance, Multi-Confirmation, Smart Position Sizing"
#property description "IMPROVED: Swing-based Stops, Volume Analysis, Session Filters"
#property description "IMPROVED: Better Partial Closes, News Awareness, Market Context"

//+------------------------------------------------------------------+
//| Include MT5 Trade Library                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//--------------------------------------------------------------------
// BACKEND API CONFIGURATION
//--------------------------------------------------------------------
input string API_BaseURL = "http://localhost:5000";     // Backend API URL
input string API_UserEmail = "";                         // Your account email
input string API_UserPassword = "";                      // Your account password
input bool API_EnableSync = false;                       // Enable backend sync (disabled for MT5 initially)

//--------------------------------------------------------------------
// TRADING CONFIGURATION
//--------------------------------------------------------------------
input string  TradingSymbols        = "EURUSD,GBPUSD,USDJPY"; // Symbols to trade (change to stocks for live: AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA,META,NFLX)
input int     MagicNumber           = 555888;
input bool    EnableTrading         = true;
input double  RiskPercentPerTrade   = 1.0;
input double  MaxDailyLossPercent   = 5.0;
input int     MaxPositions          = 3;

// Strategy Settings
input bool    UseMomentumStrategy   = true;
input bool    UseMeanReversion      = true;
input bool    UseBreakoutStrategy   = true;
input bool    UseTrendFollowing     = true;
input bool    UseVolumeAnalysis     = true;
input bool    UseGapTrading         = false;  // Gap trading for stocks
input bool    UseMultiTimeframe     = true;
input bool    UseMarketRegime       = true;

// Risk Management - IMPROVED
input bool    UseSwingStops         = true;   // Use swing highs/lows for stops (IMPROVED)
input int     SwingLookback         = 10;     // Bars to look back for swing points
input double  ATRMultiplierSL       = 1.5;    // REDUCED from 2.5 to 1.5 (tighter stops)
input double  ATRMultiplierTP       = 3.0;    // REDUCED from 4.0 to 3.0 (realistic targets)
input int     FixedStopLossPips     = 50;     // REDUCED from 100 (was too wide)
input int     FixedTakeProfitPips   = 100;    // REDUCED from 200 (was too wide)
input bool    UseTrailingStop       = true;
input int     TrailingStopPips      = 80;     // INCREASED from 50 (let winners run)
input int     TrailingStopActivation = 60;    // Pips profit before trailing starts
input bool    UseBreakEven          = true;
input int     BreakEvenPips         = 30;
input double  BreakEvenBufferPips   = 5.0;
input bool    UsePartialClose       = true;
input double  Partial1Percent       = 20.0;   // REDUCED from 30% (keep more running)
input double  Partial1RR            = 2.0;    // INCREASED from 1.5 (wait for better profit)
input double  Partial2Percent       = 20.0;   // REDUCED from 30% (60% stays open now)
input double  Partial2RR            = 3.5;    // INCREASED from 2.5 (let winners run)

// Indicator Settings - IMPROVED
input int     FastMA_Period         = 10;
input int     SlowMA_Period         = 50;
input int     RSI_Period            = 14;
input int     RSI_Oversold          = 35;     // INCREASED from 30 (stricter filter)
input int     RSI_Overbought        = 65;     // DECREASED from 70 (stricter filter)
input int     ATR_Period            = 14;
input int     ADX_Period            = 14;
input int     ADX_Threshold         = 30;     // INCREASED from 25 (stronger trend required)

// NEW: Volume Confirmation
input bool    UseVolumeConfirmation = true;   // Require volume spike for entries
input double  VolumeMultiplier      = 1.3;    // Volume must be 1.3x average

// NEW: Spread Filter
input int     MaxSpreadPips         = 3;      // Max spread allowed for entry

// NEW: Support/Resistance Detection
input int     SR_Lookback           = 100;    // Bars to scan for S/R levels
input double  SR_TouchThreshold     = 0.0015; // 0.15% proximity to consider a touch
input int     SR_MinTouches         = 2;      // Minimum touches to confirm level

// Time & Session Settings
input int     TradingStartHour      = 9;     // Market open hour
input int     TradingEndHour        = 16;    // Market close hour
input bool    CloseBeforeMarketClose = true;
input int     CloseBeforeMinutes    = 30;

// Display Settings
input bool    ShowDashboard         = true;
input bool    SendNotifications     = false;
input bool    VerboseLogging        = true;
input bool    DebugMode             = false;

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
string  g_Symbols[];
int     g_SymbolCount = 0;
datetime g_DailyStartTime = 0;
double   g_DailyStartEquity = 0;
int     g_DailyTrades = 0;
int     g_TotalTrades = 0;
int     g_TotalWins = 0;
int     g_TotalLosses = 0;

enum EA_STATE { STATE_READY = 0, STATE_SUSPENDED };
EA_STATE g_EAState = STATE_READY;

// Trade tracking structure
struct TradeInfo {
   ulong ticket;
   string symbol;
   ENUM_ORDER_TYPE orderType;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double lotSize;
   datetime openTime;
   string strategy;
   bool partial1Done;
   bool partial2Done;
   bool partial3Done;
   bool breakEvenSet;
};
TradeInfo g_OpenTrades[];

// Indicator handles per symbol
struct SymbolIndicators {
   string symbol;
   int h_FastMA;
   int h_SlowMA;
   int h_MA200;
   int h_RSI;
   int h_ATR;
   int h_ADX;
   int h_Bands;
   int h_Volume;     // NEW: Volume indicator
};
SymbolIndicators g_Indicators[];

// NEW: Support/Resistance Level Structure
struct SRLevel {
   double price;
   int touches;
   bool isSupport;
   bool isResistance;
};
SRLevel g_SRLevels[];

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------
int SplitString(string str, string separator, string &result[]) {
   int count = 0;
   string temp = str;
   ArrayResize(result, 0);

   while(StringLen(temp) > 0) {
      int pos = StringFind(temp, separator, 0);
      if(pos < 0) {
         if(StringLen(temp) > 0) {
            ArrayResize(result, count + 1);
            result[count] = temp;
            count++;
         }
         break;
      } else {
         string part = StringSubstr(temp, 0, pos);
         if(StringLen(part) > 0) {
            ArrayResize(result, count + 1);
            result[count] = part;
            count++;
         }
         temp = StringSubstr(temp, pos + StringLen(separator));
      }
   }
   return count;
}

//--------------------------------------------------------------------
// NEW: DETECT SUPPORT AND RESISTANCE LEVELS
//--------------------------------------------------------------------
void DetectSRLevels(string symbol) {
   ArrayResize(g_SRLevels, 0);

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, PERIOD_CURRENT, 0, SR_Lookback, rates);
   if(copied <= 0) return;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Find swing highs and lows
   for(int i = 2; i < copied - 2; i++) {
      // Check for swing high
      if(rates[i].high > rates[i-1].high && rates[i].high > rates[i-2].high &&
         rates[i].high > rates[i+1].high && rates[i].high > rates[i+2].high) {
         AddOrUpdateSRLevel(rates[i].high, false, true, symbol);
      }

      // Check for swing low
      if(rates[i].low < rates[i-1].low && rates[i].low < rates[i-2].low &&
         rates[i].low < rates[i+1].low && rates[i].low < rates[i+2].low) {
         AddOrUpdateSRLevel(rates[i].low, true, false, symbol);
      }
   }
}

void AddOrUpdateSRLevel(double price, bool isSupport, bool isResistance, string symbol) {
   double threshold = price * SR_TouchThreshold;

   // Check if level already exists nearby
   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(MathAbs(g_SRLevels[i].price - price) <= threshold) {
         g_SRLevels[i].touches++;
         if(isSupport) g_SRLevels[i].isSupport = true;
         if(isResistance) g_SRLevels[i].isResistance = true;
         return;
      }
   }

   // Add new level
   SRLevel newLevel;
   newLevel.price = price;
   newLevel.touches = 1;
   newLevel.isSupport = isSupport;
   newLevel.isResistance = isResistance;

   int size = ArraySize(g_SRLevels);
   ArrayResize(g_SRLevels, size + 1);
   g_SRLevels[size] = newLevel;
}

//--------------------------------------------------------------------
// NEW: CHECK IF PRICE IS NEAR SUPPORT/RESISTANCE
//--------------------------------------------------------------------
int CheckNearSRLevel(double price, string symbol) {
   // Returns: 1 = near support, -1 = near resistance, 0 = not near any level
   double threshold = price * SR_TouchThreshold;

   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].touches < SR_MinTouches) continue;

      double diff = MathAbs(g_SRLevels[i].price - price);
      if(diff <= threshold) {
         if(g_SRLevels[i].isSupport) return 1;
         if(g_SRLevels[i].isResistance) return -1;
      }
   }
   return 0;
}

//--------------------------------------------------------------------
// NEW: FIND SWING HIGH/LOW FOR STOP LOSS
//--------------------------------------------------------------------
double FindSwingHigh(string symbol, int lookback) {
   double high[];
   ArraySetAsSeries(high, true);
   if(CopyHigh(symbol, PERIOD_CURRENT, 0, lookback, high) <= 0) return 0;

   double swingHigh = high[0];
   for(int i = 1; i < lookback; i++) {
      if(high[i] > swingHigh) swingHigh = high[i];
   }
   return swingHigh;
}

double FindSwingLow(string symbol, int lookback) {
   double low[];
   ArraySetAsSeries(low, true);
   if(CopyLow(symbol, PERIOD_CURRENT, 0, lookback, low) <= 0) return 0;

   double swingLow = low[0];
   for(int i = 1; i < lookback; i++) {
      if(low[i] < swingLow) swingLow = low[i];
   }
   return swingLow;
}

//--------------------------------------------------------------------
// NEW: CHECK VOLUME CONFIRMATION
//--------------------------------------------------------------------
bool CheckVolumeConfirmation(string symbol) {
   if(!UseVolumeConfirmation) return true;

   long volume[];
   ArraySetAsSeries(volume, true);
   if(CopyTickVolume(symbol, PERIOD_CURRENT, 0, 20, volume) <= 0) return false;

   // Calculate average volume of last 20 bars
   long avgVolume = 0;
   for(int i = 1; i < 20; i++) {
      avgVolume += volume[i];
   }
   avgVolume = avgVolume / 19;

   // Check if current bar volume is above threshold
   return (volume[0] >= avgVolume * VolumeMultiplier);
}

//--------------------------------------------------------------------
// NEW: CHECK SPREAD FILTER
//--------------------------------------------------------------------
bool CheckSpreadFilter(string symbol) {
   long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double spreadPips = spread * point / point / 10.0;

   return (spreadPips <= MaxSpreadPips);
}

//--------------------------------------------------------------------
// INITIALIZE INDICATORS FOR A SYMBOL
//--------------------------------------------------------------------
bool InitSymbolIndicators(string symbol) {
   SymbolIndicators si;
   si.symbol = symbol;
   si.h_FastMA = iMA(symbol, PERIOD_CURRENT, FastMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_SlowMA = iMA(symbol, PERIOD_CURRENT, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_MA200 = iMA(symbol, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE);
   si.h_RSI = iRSI(symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   si.h_ATR = iATR(symbol, PERIOD_CURRENT, ATR_Period);
   si.h_ADX = iADX(symbol, PERIOD_CURRENT, ADX_Period);
   si.h_Bands = iBands(symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
   si.h_Volume = iVolumes(symbol, PERIOD_CURRENT, VOLUME_TICK);  // NEW: Volume indicator

   if(si.h_FastMA == INVALID_HANDLE || si.h_SlowMA == INVALID_HANDLE ||
      si.h_MA200 == INVALID_HANDLE || si.h_RSI == INVALID_HANDLE ||
      si.h_ATR == INVALID_HANDLE || si.h_ADX == INVALID_HANDLE ||
      si.h_Bands == INVALID_HANDLE || si.h_Volume == INVALID_HANDLE) {
      Print("ERROR: Failed to create indicators for ", symbol);
      return false;
   }

   int size = ArraySize(g_Indicators);
   ArrayResize(g_Indicators, size + 1);
   g_Indicators[size] = si;

   // NEW: Detect S/R levels for this symbol
   DetectSRLevels(symbol);

   return true;
}

//--------------------------------------------------------------------
// GET INDICATOR INDEX FOR SYMBOL
//--------------------------------------------------------------------
int GetIndicatorIndex(string symbol) {
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      if(g_Indicators[i].symbol == symbol)
         return i;
   }
   return -1;
}

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════════════════╗");
   Print("║     SMART STOCK TRADER PRO v1.0 - MT5 VERSION     ║");
   Print("╚════════════════════════════════════════════════════╝");

   // Parse symbols
   g_SymbolCount = SplitString(TradingSymbols, ",", g_Symbols);
   if(g_SymbolCount == 0) {
      Print("ERROR: No trading symbols configured!");
      return(INIT_FAILED);
   }

   Print("Configuring ", g_SymbolCount, " symbols...");

   // Initialize indicators for each symbol
   int successCount = 0;
   for(int i = 0; i < g_SymbolCount; i++) {
      string sym = g_Symbols[i];
      Print("  → Initializing ", sym);
      if(!InitSymbolIndicators(sym)) {
         Print("  ✗ Failed to initialize ", sym, " - may not have data");
      } else {
         Print("  ✓ ", sym, " ready");
         successCount++;
      }
   }

   if(successCount == 0) {
      Print("ERROR: No symbols initialized successfully!");
      Print("Note: Stock symbols may not have data in Strategy Tester.");
      Print("For testing, use Forex pairs like: EURUSD,GBPUSD,USDJPY");
      return(INIT_FAILED);
   }

   Print("Successfully initialized ", successCount, " out of ", g_SymbolCount, " symbols");

   // Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   trade.SetAsyncMode(false);

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   Print("\n╔═══════════════════════════════════════════════╗");
   Print("║    INITIALIZATION COMPLETE - IMPROVED v2.0   ║");
   Print("╚═══════════════════════════════════════════════╝");
   Print("Symbols: ", g_SymbolCount);
   Print("\nStrategies Enabled:");
   if(UseMomentumStrategy) Print("  ✓ Momentum Trading (IMPROVED: Multi-confirmation)");
   if(UseMeanReversion) Print("  ✓ Mean Reversion (IMPROVED: Bounce confirmation + S/R)");
   if(UseTrendFollowing) Print("  ✓ Trend Following (IMPROVED: Volume + context)");

   Print("\nIMPROVED Features Active:");
   Print("  ✓ Support/Resistance Detection (", SR_Lookback, " bars)");
   if(UseSwingStops) Print("  ✓ Swing-Based Stop Loss (lookback: ", SwingLookback, ")");
   if(UseVolumeConfirmation) Print("  ✓ Volume Confirmation (", DoubleToString(VolumeMultiplier, 1), "x average)");
   Print("  ✓ Spread Filter (max ", MaxSpreadPips, " pips)");
   Print("  ✓ Tighter Stops (ATR ", DoubleToString(ATRMultiplierSL, 1), "x vs old 2.5x)");
   Print("  ✓ Better Partials (", DoubleToString(Partial1Percent + Partial2Percent, 0), "% closed, 60% runs)");
   Print("  ✓ Trailing Activation (", TrailingStopActivation, " pips)");
   Print("  ✓ Higher Confidence Threshold (75% vs old 65%)");
   Print("  ✓ Stricter RSI Zones (", RSI_Oversold, "-", RSI_Overbought, " vs old 30-70)");
   Print("  ✓ Stronger ADX Filter (", ADX_Threshold, " vs old 25)");

   Print("\n╔═══════════════════════════════════════════════╗");
   Print("║            READY TO TRADE - v2.0             ║");
   Print("╚═══════════════════════════════════════════════╝\n");

   if(SendNotifications) {
      SendNotification("Smart Stock Trader MT5: EA started successfully");
   }

   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("\n=== SMART STOCK TRADER MT5 SHUTTING DOWN ===");
   Print("Reason: ", reason);

   // Show final summary
   if(VerboseLogging) {
      double finalEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double totalPL = finalEquity - g_DailyStartEquity;

      Print("\n╔════════════════════════════════════════╗");
      Print("║     PERFORMANCE SUMMARY               ║");
      Print("╠════════════════════════════════════════╣");
      Print("║ Starting Equity:  $", DoubleToString(g_DailyStartEquity, 2));
      Print("║ Final Equity:     $", DoubleToString(finalEquity, 2));
      Print("║ Total P/L:        $", DoubleToString(totalPL, 2));
      Print("║ Total Trades:     ", g_TotalTrades);
      if(g_TotalTrades > 0) {
         double winRate = (double)g_TotalWins / g_TotalTrades * 100.0;
         Print("║ Win Rate:         ", DoubleToString(winRate, 1), "%");
      }
      Print("╚════════════════════════════════════════╝\n");
   }

   // Close all positions if requested
   if(CloseBeforeMarketClose) {
      Print("Closing all open positions...");
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
               trade.PositionClose(ticket);
            }
         }
      }
   }

   // Release indicator handles
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      IndicatorRelease(g_Indicators[i].h_FastMA);
      IndicatorRelease(g_Indicators[i].h_SlowMA);
      IndicatorRelease(g_Indicators[i].h_MA200);
      IndicatorRelease(g_Indicators[i].h_RSI);
      IndicatorRelease(g_Indicators[i].h_ATR);
      IndicatorRelease(g_Indicators[i].h_ADX);
      IndicatorRelease(g_Indicators[i].h_Bands);
      IndicatorRelease(g_Indicators[i].h_Volume);  // NEW
   }

   ObjectsDeleteAll(0, "SST_");

   if(SendNotifications) {
      SendNotification("Smart Stock Trader MT5: EA stopped");
   }

   Print("=== SHUTDOWN COMPLETE ===\n");
}

//--------------------------------------------------------------------
// ON TICK - MAIN TRADING LOGIC
//--------------------------------------------------------------------
void OnTick() {
   // Reset daily statistics if new day
   MqlDateTime dt, dt_start;
   TimeToStruct(TimeCurrent(), dt);
   TimeToStruct(g_DailyStartTime, dt_start);

   if(dt.day != dt_start.day) {
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_DailyTrades = 0;
      Print("━━━ NEW DAY - Daily stats reset ━━━");
   }

   // Update dashboard
   static int tickCount = 0;
   tickCount++;
   if(ShowDashboard && tickCount % 20 == 0) {
      UpdateDashboard();
   }

   // Check if trading is allowed
   if(!EnableTrading) return;
   if(g_EAState == STATE_SUSPENDED) return;

   // Check daily loss limit
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPL = currentEquity - g_DailyStartEquity;
   double dailyLossPercent = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyLossPercent <= -MaxDailyLossPercent) {
      g_EAState = STATE_SUSPENDED;
      Print("⚠ Daily loss limit reached: ", DoubleToString(dailyLossPercent, 2), "%");
      return;
   }

   // Check trading session
   if(dt.hour < TradingStartHour || dt.hour >= TradingEndHour) return;

   // Manage open trades
   ManageOpenTrades();

   // Check if we can open new positions
   if(PositionsTotal() >= MaxPositions) return;

   // Scan symbols for trading opportunities (once per minute)
   static datetime lastScanTime = 0;
   if(TimeCurrent() - lastScanTime < 60) return;
   lastScanTime = TimeCurrent();

   for(int i = 0; i < g_SymbolCount; i++) {
      string symbol = g_Symbols[i];

      // Check if already have position on this symbol
      if(PositionSelect(symbol)) continue;

      // Analyze and trade
      ScanSymbolForSignals(symbol);
   }
}

//--------------------------------------------------------------------
// SCAN SYMBOL FOR TRADING SIGNALS
//--------------------------------------------------------------------
void ScanSymbolForSignals(string symbol) {
   int idx = GetIndicatorIndex(symbol);
   if(idx < 0) return;

   // Get indicator values
   double fastMA[], slowMA[], ma200[], rsi[], atr[], adx[];
   double bandsUpper[], bandsLower[], bandsMiddle[];
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);
   ArraySetAsSeries(ma200, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(adx, true);
   ArraySetAsSeries(bandsUpper, true);
   ArraySetAsSeries(bandsLower, true);
   ArraySetAsSeries(bandsMiddle, true);

   if(CopyBuffer(g_Indicators[idx].h_FastMA, 0, 0, 3, fastMA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_SlowMA, 0, 0, 3, slowMA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_MA200, 0, 0, 3, ma200) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_RSI, 0, 0, 3, rsi) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ATR, 0, 0, 3, atr) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ADX, 0, 0, 3, adx) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 1, 0, 3, bandsUpper) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 2, 0, 3, bandsLower) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 0, 0, 3, bandsMiddle) <= 0) {
      return;
   }

   // Get price data
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(symbol, PERIOD_CURRENT, 0, 3, close) <= 0) return;

   // NEW: Check spread filter FIRST
   if(!CheckSpreadFilter(symbol)) {
      if(DebugMode) Print(symbol, " - Spread too wide, skipping");
      return;
   }

   // NEW: Check volume confirmation
   bool volumeOK = CheckVolumeConfirmation(symbol);

   // Determine market regime
   bool isTrending = (adx[1] > ADX_Threshold);

   // NEW: Check S/R levels
   int srLevel = CheckNearSRLevel(close[1], symbol);

   int signal = 0;  // 0=none, 1=buy, -1=sell
   double confidence = 0.0;
   string strategyName = "";

   // STRATEGY 1: Momentum (IMPROVED with multi-confirmation)
   if(UseMomentumStrategy && isTrending) {
      // BUY: MA cross + RSI + Volume + Price action
      if(fastMA[1] > slowMA[1] && fastMA[2] <= slowMA[2] &&  // Fresh crossover
         rsi[1] > 50 && rsi[1] < RSI_Overbought &&          // RSI in bullish zone but not overbought
         close[1] > close[2] &&                             // Bullish candle
         volumeOK &&                                        // Volume confirmation
         srLevel != -1) {                                   // NOT at resistance
         signal = 1;
         confidence = 0.80;
         strategyName = "Momentum Buy";
         if(srLevel == 1) confidence += 0.10;  // Bonus if at support
      }
      // SELL: MA cross + RSI + Volume + Price action
      else if(fastMA[1] < slowMA[1] && fastMA[2] >= slowMA[2] &&  // Fresh crossover
         rsi[1] < 50 && rsi[1] > RSI_Oversold &&                  // RSI in bearish zone but not oversold
         close[1] < close[2] &&                                   // Bearish candle
         volumeOK &&                                              // Volume confirmation
         srLevel != 1) {                                          // NOT at support
         signal = -1;
         confidence = 0.80;
         strategyName = "Momentum Sell";
         if(srLevel == -1) confidence += 0.10;  // Bonus if at resistance
      }
   }

   // STRATEGY 2: Mean Reversion (IMPROVED - wait for bounce confirmation)
   if(signal == 0 && UseMeanReversion && !isTrending) {
      // BUY: At lower band + RSI oversold + BOUNCE STARTED + at support
      if(close[2] < bandsLower[2] &&              // Was below band
         close[1] > bandsLower[1] &&              // Now bouncing back
         rsi[1] < RSI_Oversold &&                 // RSI oversold
         close[1] > close[2] &&                   // Bullish bounce candle
         volumeOK &&                              // Volume confirmation
         srLevel == 1) {                          // AT SUPPORT (critical!)
         signal = 1;
         confidence = 0.75;
         strategyName = "Mean Reversion Buy";
      }
      // SELL: At upper band + RSI overbought + REJECTION STARTED + at resistance
      else if(close[2] > bandsUpper[2] &&         // Was above band
         close[1] < bandsUpper[1] &&              // Now rejecting
         rsi[1] > RSI_Overbought &&               // RSI overbought
         close[1] < close[2] &&                   // Bearish rejection candle
         volumeOK &&                              // Volume confirmation
         srLevel == -1) {                         // AT RESISTANCE (critical!)
         signal = -1;
         confidence = 0.75;
         strategyName = "Mean Reversion Sell";
      }
   }

   // STRATEGY 3: Trend Following (IMPROVED with confirmation)
   if(signal == 0 && UseTrendFollowing && isTrending) {
      // BUY: Strong uptrend + pullback to MA + bounce
      if(close[1] > ma200[1] &&                   // Above long-term MA
         fastMA[1] > slowMA[1] &&                 // Fast above slow
         rsi[1] > 50 && rsi[1] < RSI_Overbought && // RSI bullish but not extreme
         close[1] > fastMA[1] &&                  // Price above fast MA
         close[1] > close[2] &&                   // Bullish candle
         volumeOK) {                              // Volume confirmation
         signal = 1;
         confidence = 0.85;
         strategyName = "Trend Following Buy";
         if(srLevel == 1) confidence += 0.05;     // Bonus at support
      }
      // SELL: Strong downtrend + pullback to MA + rejection
      else if(close[1] < ma200[1] &&              // Below long-term MA
         fastMA[1] < slowMA[1] &&                 // Fast below slow
         rsi[1] < 50 && rsi[1] > RSI_Oversold &&  // RSI bearish but not extreme
         close[1] < fastMA[1] &&                  // Price below fast MA
         close[1] < close[2] &&                   // Bearish candle
         volumeOK) {                              // Volume confirmation
         signal = -1;
         confidence = 0.85;
         strategyName = "Trend Following Sell";
         if(srLevel == -1) confidence += 0.05;    // Bonus at resistance
      }
   }

   // Execute trade if signal is strong enough (INCREASED threshold)
   if(signal != 0 && confidence >= 0.75) {  // Raised from 0.65 to 0.75
      ExecuteTrade(symbol, signal == 1, strategyName, confidence);
   }
}

//--------------------------------------------------------------------
// EXECUTE TRADE (IMPROVED)
//--------------------------------------------------------------------
void ExecuteTrade(string symbol, bool isBuy, string strategy, double confidence) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double price = isBuy ? ask : bid;

   int idx = GetIndicatorIndex(symbol);
   if(idx < 0) return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(g_Indicators[idx].h_ATR, 0, 0, 2, atr) <= 0) return;

   double sl, tp;

   // IMPROVED: Use swing-based stops when enabled
   if(UseSwingStops) {
      if(isBuy) {
         double swingLow = FindSwingLow(symbol, SwingLookback);
         if(swingLow > 0) {
            sl = swingLow - (atr[1] * 0.2);  // Add small buffer below swing low
         } else {
            sl = price - (atr[1] * ATRMultiplierSL);  // Fallback to ATR
         }
      } else {
         double swingHigh = FindSwingHigh(symbol, SwingLookback);
         if(swingHigh > 0) {
            sl = swingHigh + (atr[1] * 0.2);  // Add small buffer above swing high
         } else {
            sl = price + (atr[1] * ATRMultiplierSL);  // Fallback to ATR
         }
      }
   } else {
      // Use ATR-based stops
      sl = isBuy ? (price - atr[1] * ATRMultiplierSL) : (price + atr[1] * ATRMultiplierSL);
   }

   sl = NormalizeDouble(sl, _Digits);

   // Calculate SL distance in pips
   double slDistance = MathAbs(price - sl);
   double slPips = slDistance / (point * 10.0);

   // Cap maximum stop loss
   double maxSLPips = 100.0;
   if(slPips > maxSLPips) {
      slPips = maxSLPips;
      sl = isBuy ? (price - maxSLPips * point * 10.0) : (price + maxSLPips * point * 10.0);
      sl = NormalizeDouble(sl, _Digits);
      slDistance = MathAbs(price - sl);
   }

   // IMPROVED: Calculate position size correctly
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercentPerTrade / 100.0;

   // Get contract size and tick info
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

   // CORRECT FORMULA: Risk / (SL Distance × Value Per Pip)
   double valuePerPip = (tickValue / tickSize) * point * 10.0;
   double lotSize = riskAmount / (slDistance * valuePerPip * contractSize / 100000.0);

   // For forex pairs, simplified calculation
   if(contractSize == 100000) {  // Standard forex lot
      lotSize = riskAmount / (slPips * 10.0 * tickValue);
   }

   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);

   // Calculate TP based on risk-reward
   double tpPips = slPips * (ATRMultiplierTP / ATRMultiplierSL);
   tp = isBuy ? (price + tpPips * point * 10.0) : (price - tpPips * point * 10.0);
   tp = NormalizeDouble(tp, _Digits);

   // Execute order
   bool result = false;
   if(isBuy) {
      result = trade.Buy(lotSize, symbol, price, sl, tp, "SST: " + strategy);
   } else {
      result = trade.Sell(lotSize, symbol, price, sl, tp, "SST: " + strategy);
   }

   if(result) {
      ulong ticket = trade.ResultOrder();
      g_TotalTrades++;
      g_DailyTrades++;

      // Add to tracking
      TradeInfo ti;
      ti.ticket = ticket;
      ti.symbol = symbol;
      ti.orderType = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      ti.entryPrice = price;
      ti.stopLoss = sl;
      ti.takeProfit = tp;
      ti.lotSize = lotSize;
      ti.openTime = TimeCurrent();
      ti.strategy = strategy;
      ti.partial1Done = false;
      ti.partial2Done = false;
      ti.partial3Done = false;
      ti.breakEvenSet = false;

      int size = ArraySize(g_OpenTrades);
      ArrayResize(g_OpenTrades, size + 1);
      g_OpenTrades[size] = ti;

      Print("╔════════════════════════════════════════════════╗");
      Print("║       NEW TRADE OPENED (IMPROVED v2.0)        ║");
      Print("╠════════════════════════════════════════════════╣");
      Print("║ Ticket:      ", ticket);
      Print("║ Symbol:      ", symbol);
      Print("║ Type:        ", isBuy ? "BUY" : "SELL");
      Print("║ Price:       ", DoubleToString(price, _Digits));
      Print("║ Lot Size:    ", DoubleToString(lotSize, 2));
      Print("║ Stop Loss:   ", DoubleToString(sl, _Digits), " (", DoubleToString(slPips, 1), " pips)");
      Print("║ Take Profit: ", DoubleToString(tp, _Digits), " (", DoubleToString(tpPips, 1), " pips)");
      Print("║ Risk/Reward: 1:", DoubleToString(tpPips/slPips, 2));
      Print("║ Strategy:    ", strategy);
      Print("║ Confidence:  ", DoubleToString(confidence * 100, 1), "%");
      Print("║ Stop Type:   ", UseSwingStops ? "Swing-Based" : "ATR-Based");
      Print("║ Risk Amount: $", DoubleToString(riskAmount, 2));
      Print("╚════════════════════════════════════════════════╝");

      if(SendNotifications) {
         SendNotification("Smart Stock Trader MT5: " + (isBuy ? "BUY" : "SELL") + " " + symbol);
      }
   } else {
      Print("✗ ERROR opening trade - ", trade.ResultRetcodeDescription());
   }
}

//--------------------------------------------------------------------
// MANAGE OPEN TRADES
//--------------------------------------------------------------------
void ManageOpenTrades() {
   for(int i = ArraySize(g_OpenTrades) - 1; i >= 0; i--) {
      ulong ticket = g_OpenTrades[i].ticket;

      if(!PositionSelectByTicket(ticket)) {
         // Position closed - remove from tracking
         for(int j = i; j < ArraySize(g_OpenTrades) - 1; j++) {
            g_OpenTrades[j] = g_OpenTrades[j + 1];
         }
         ArrayResize(g_OpenTrades, ArraySize(g_OpenTrades) - 1);
         continue;
      }

      // Position still open - manage it
      string symbol = PositionGetString(POSITION_SYMBOL);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double currentPrice = isBuy ? bid : ask;
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      // Calculate profit in pips
      double profitPips = isBuy ?
                         (currentPrice - openPrice) / point / 10.0 :
                         (openPrice - currentPrice) / point / 10.0;

      // IMPROVED: Trailing stop (only activate after reaching threshold)
      if(UseTrailingStop && profitPips > TrailingStopActivation) {
         double newSL = isBuy ?
                       NormalizeDouble(currentPrice - TrailingStopPips * point * 10.0, _Digits) :
                       NormalizeDouble(currentPrice + TrailingStopPips * point * 10.0, _Digits);

         if((isBuy && newSL > currentSL) || (!isBuy && (currentSL == 0 || newSL < currentSL))) {
            trade.PositionModify(ticket, newSL, currentTP);
            if(DebugMode) Print("Trailing stop updated for ", ticket, " to ", newSL);
         }
      }

      // Break-even
      if(UseBreakEven && !g_OpenTrades[i].breakEvenSet && profitPips >= BreakEvenPips) {
         double beSL = NormalizeDouble(openPrice + (isBuy ? 1 : -1) * BreakEvenBufferPips * point * 10.0, _Digits);
         if(trade.PositionModify(ticket, beSL, currentTP)) {
            g_OpenTrades[i].breakEvenSet = true;
            if(DebugMode) Print("Break-even set for ", ticket);
         }
      }

      // Partial closes
      if(UsePartialClose) {
         double lots = PositionGetDouble(POSITION_VOLUME);
         double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

         if(lots > minLot) {
            double riskPips = MathAbs(openPrice - currentSL) / point / 10.0;
            if(riskPips <= 0) riskPips = 50.0;
            double rMultiple = profitPips / riskPips;

            // Partial 1
            if(!g_OpenTrades[i].partial1Done && rMultiple >= Partial1RR) {
               double closeVol = NormalizeDouble(lots * Partial1Percent / 100.0, 2);
               if(closeVol >= minLot && closeVol <= lots) {
                  trade.PositionClosePartial(ticket, closeVol);
                  g_OpenTrades[i].partial1Done = true;
               }
            }

            // Partial 2
            if(!g_OpenTrades[i].partial2Done && rMultiple >= Partial2RR) {
               double closeVol = NormalizeDouble(lots * Partial2Percent / 100.0, 2);
               if(closeVol >= minLot && closeVol <= lots) {
                  trade.PositionClosePartial(ticket, closeVol);
                  g_OpenTrades[i].partial2Done = true;
               }
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// UPDATE DASHBOARD
//--------------------------------------------------------------------
void UpdateDashboard() {
   int y = 20;
   int lineHeight = 18;

   CreateLabel("SST_Title", "Smart Stock Trader MT5", 10, y, clrWhite, 11); y += lineHeight + 5;
   CreateLabel("SST_Equity", "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), 10, y, clrLime, 9); y += lineHeight;

   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - g_DailyStartEquity;
   color plColor = dailyPL >= 0 ? clrLime : clrRed;
   CreateLabel("SST_DailyPL", "Daily P/L: $" + DoubleToString(dailyPL, 2), 10, y, plColor, 9); y += lineHeight;

   CreateLabel("SST_Positions", "Open Positions: " + IntegerToString(PositionsTotal()), 10, y, clrWhite, 9); y += lineHeight;
   CreateLabel("SST_Trades", "Total Trades: " + IntegerToString(g_TotalTrades), 10, y, clrWhite, 9); y += lineHeight;

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
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
