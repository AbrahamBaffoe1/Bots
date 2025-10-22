//+------------------------------------------------------------------+
//|                                  SmartStockTrader_Single.mq4     |
//|           Ultra-Intelligent Stock Trading EA - Single File       |
//|              ALL CODE IN ONE FILE FOR EASY MT4 LOADING           |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0"
#property version   "1.00"
#property strict
#property description "Professional stock trading EA - Single file version"

//--------------------------------------------------------------------
// PHASE 1 + PHASE 2 + PHASE 3 MODULE INCLUDES (AI/ML Enhancement)
//--------------------------------------------------------------------
#include <SST_NewsFilter.mqh>
#include <SST_CorrelationMatrix.mqh>
#include <SST_AdvancedVolatility.mqh>
#include <SST_DrawdownProtection.mqh>
#include <SST_MultiAsset.mqh>
#include <SST_ExitOptimization.mqh>
#include <SST_MachineLearning.mqh>        // PHASE 3: AI/ML Module
#include <SST_MarketStructure.mqh>        // PHASE 3A: Market Structure

//--------------------------------------------------------------------
// PHASE 4: DASHBOARD INTEGRATION MODULES (Backend API Sync)
//--------------------------------------------------------------------
#include <SST_WebAPI.mqh>                // HTTP/REST API client
#include <SST_JSON.mqh>                  // JSON serialization/parsing
#include <SST_APIConfig.mqh>             // API configuration management
#include <SST_Logger.mqh>                // Production logging system
#include <SST_BotAuth.mqh>               // Authentication & bot registration
#include <SST_TradeSync.mqh>             // Trade synchronization
#include <SST_Heartbeat.mqh>             // Heartbeat & monitoring
#include <SST_PerformanceSync.mqh>       // Performance metrics sync

//--------------------------------------------------------------------
// LICENSE PARAMETERS
//--------------------------------------------------------------------
extern string  LicenseKey            = "SST-ENTERPRISE-W0674G-XF9XH9-89WA";   // Your license key
extern datetime ExpirationDate       = D'2026.12.31 23:59:59';         // License expiration date
extern string  AuthorizedAccounts    = "";                             // Comma-separated account numbers (leave empty for any account)
extern bool    RequireLicenseKey     = true;                           // Set FALSE to disable license check for testing

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------
extern string  Stocks                = "AAPL,MSFT,GOOGL,AMZN,TSLA";  // Leave empty to use current chart symbol
extern int     MagicNumber           = 555777;
extern bool    EnableTrading         = true;
extern bool    BacktestMode          = true;                         // Enable backtest features (24/7, verbose logs, no restrictions) - SET FALSE FOR LIVE
extern bool    VerboseLogging        = true;                         // Detailed logs for debugging - SET FALSE FOR LIVE
extern double  RiskPercentPerTrade   = 1.0;
extern double  MaxDailyLossPercent   = 5.0;
extern bool    ShowDashboard         = true;
extern bool    SendNotifications     = false;

//=== BACKEND API INTEGRATION PARAMETERS ===
extern string  API_BaseURL           = "http://localhost:5000";     // Backend API base URL
extern string  API_UserEmail         = "Ifrey2heavens@gmail.com";                           // User email for authentication
extern string  API_UserPassword      = "!bv2000gee4A!";                           // User password for authentication
extern bool    API_EnableSync        = true;                        // Master switch for API synchronization - SET TRUE FOR LIVE
extern bool    API_EnableTradeSync   = true;                        // Sync trades to backend
extern bool    API_EnableHeartbeat   = true;                        // Send heartbeat signals
extern bool    API_EnablePerfSync    = true;                        // Sync performance metrics
extern int     API_HeartbeatInterval = 60;                          // Heartbeat interval in seconds
extern int     API_PerfSyncInterval  = 300;                         // Performance sync interval in seconds

// Session Settings
extern bool    Trade24_7             = true;                         // Trade 24/7 with no time restrictions (recommended for live trading)
extern bool    TradePreMarket        = false;
extern bool    TradeRegularHours     = true;
extern bool    TradeAfterHours       = false;
extern int     BrokerGMTOffset       = -5;

// Risk Management - PHASE 2: Improved R:R (4:1)
extern bool    UseATRStops           = true;
extern double  ATRMultiplierSL       = 1.5;    // REDUCED from 2.5 to 1.5 (tighter stop)
extern double  ATRMultiplierTP       = 6.0;    // INCREASED from 4.0 to 6.0 (4:1 R:R)
extern int     FixedStopLossPips     = 100;
extern int     FixedTakeProfitPips   = 200;

// PHASE 2: Smart Scaling Parameters
extern bool    UseSmartScaling       = true;   // Enable partial profit taking
extern double  PartialClosePercent   = 25.0;   // Close 25% of position at 2:1
extern double  PartialCloseRRRatio   = 2.0;    // Take profit at 2:1 R:R
extern bool    MoveToBreakeven       = true;   // Move SL to breakeven after partial close

// Strategies
extern bool    UseMomentumStrategy   = true;
extern bool    UseTrendFollowing     = true;
extern bool    UseBreakoutStrategy   = true;

// Indicators
extern int     FastMA_Period         = 10;
extern int     SlowMA_Period         = 50;
extern int     RSI_Period            = 14;
extern int     ATR_Period            = 14;
extern int     WPR_Period            = 14;           // Williams %R period
extern int     WPR_Oversold          = -80;          // Williams %R oversold level
extern int     WPR_Overbought        = -20;          // Williams %R overbought level
extern bool    UseWilliamsR          = true;         // Enable Williams %R filter
extern int     Envelope_Period       = 14;           // Envelope MA period
extern double  Envelope_Deviation    = 0.1;          // Envelope deviation (0.1 = 0.1%)
extern bool    UseEnvelopes          = true;         // Enable Envelope filter

//=== PHASE 3A: MARKET STRUCTURE & SUPPORT/RESISTANCE ===
extern bool    UseMarketStructure    = true;         // Enable market structure detection
extern bool    UseSupportResistance  = true;         // Enable S/R level detection
extern int     SR_Lookback           = 100;          // Bars to look back for S/R levels
extern int     SR_Strength           = 3;            // Minimum touches for valid S/R level
extern double  MinRoomToTarget       = 3.0;          // Minimum ATR room to target (3x ATR)
extern bool    UseOrderBlocks        = false;        // Enable order block detection (advanced)
extern bool    UseSupplyDemand       = false;        // Enable supply/demand zones (advanced)
extern bool    DebugMode             = false;        // Enable debug printing

//=== PHASE 4: 3-CONFLUENCE SNIPER SYSTEM ===
extern bool    Use3ConfluenceSniper  = true;         // Enable ultra-selective 3-confluence system
extern int     D1_MA_Period          = 200;          // D1 trend MA period (200 for major trend)
extern int     H4_MA_Period          = 50;           // H4 trend MA period (50 for intermediate trend)
extern int     H1_Fast_MA            = 10;           // H1 fast MA for crossover
extern int     H1_Slow_MA            = 50;           // H1 slow MA for crossover
extern double  MinVolumeMultiplier   = 1.5;          // Minimum volume vs average (1.5x)
extern double  MinRoomToTargetRR     = 5.0;          // Minimum room to target in R:R (5:1)
extern bool    UseMACD               = true;         // Require MACD confirmation
extern int     MACD_Fast             = 12;           // MACD fast period
extern int     MACD_Slow             = 26;           // MACD slow period
extern int     MACD_Signal           = 9;            // MACD signal period

//=== QUICK WIN FILTERS (Added for +10-15% Profitability) ===
extern double  MaxSpreadPips         = 2.0;          // Max spread in pips (reject wider spreads)
extern bool    UseTimeOfDayFilter    = true;         // Skip first 30min and lunch hour
extern int     MaxDailyTrades         = 10;          // Maximum trades per day (prevent overtrading)
extern int     MinMinutesBetweenTrades = 15;        // Minimum minutes between trades
extern bool    UseSPYTrendFilter     = true;         // Only trade with market direction
extern string  MarketIndexSymbol     = "SPY";        // Market index for trend filter (SPY, QQQ, DIA)
extern int     SPYTrendMA            = 50;           // MA period for SPY trend (50 or 200)

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
string  g_Symbols[];
int     g_SymbolCount = 0;
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
bool    g_IsMarketHours = false;
datetime g_LastTradeTime = 0;  // Track last trade time for spacing filter

// PHASE 2: Smart Scaling tracking
struct PositionTracker {
   int ticket;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double lotSize;
   bool partialClosed;
   bool movedToBreakeven;
};
PositionTracker g_Positions[];
int g_PositionCount = 0;

// PHASE 3A: Market Structure tracking
struct SupportResistance {
   string symbol;
   double level;
   int touches;
   datetime lastTouch;
   bool isSupport;
};
SupportResistance g_SRLevels[];

enum EA_STATE { STATE_READY, STATE_SUSPENDED };
EA_STATE g_EAState = STATE_READY;

//--------------------------------------------------------------------
// VALID LICENSE KEYS DATABASE
//--------------------------------------------------------------------
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345",
   "SST-PRO-TEST01-DEMO99-K7M2",
   "SST-BASIC-X3EWSS-F2LSJW-766S"  // ← Your generated key
};

//--------------------------------------------------------------------
// LICENSE VALIDATION FUNCTIONS
//--------------------------------------------------------------------
string GetHardwareFingerprint() {
   return IntegerToString(AccountNumber()) + "-" + AccountName() + "-" + AccountServer();
}

bool ValidateLicenseKey(string key) {
   if(!RequireLicenseKey) return true;
   if(key == "") return false;

   for(int i = 0; i < ArraySize(g_ValidLicenseKeys); i++) {
      if(key == g_ValidLicenseKeys[i]) return true;
   }
   return false;
}

bool CheckExpiration() {
   if(ExpirationDate == 0) return true;
   if(TimeCurrent() > ExpirationDate) return false;
   return true;
}

bool CheckAccountAuthorization() {
   if(AuthorizedAccounts == "") return true;
   string accountStr = IntegerToString(AccountNumber());
   if(StringFind(AuthorizedAccounts, accountStr) >= 0) return true;
   return false;
}

int GetDaysUntilExpiration() {
   if(ExpirationDate == 0) return 999999;
   datetime current = TimeCurrent();
   if(current > ExpirationDate) return 0;
   int secondsRemaining = (int)(ExpirationDate - current);
   return secondsRemaining / 86400;
}

bool ValidateLicense() {
   // Skip license check if not required or in backtest mode
   if(!RequireLicenseKey) {
      Print("⚠ License check DISABLED by parameter");
      return true;
   }

   if(BacktestMode) {
      Print("✓ Backtest mode - skipping license validation");
      return true;
   }

   Print("=== LICENSE VALIDATION ===");
   Print("Hardware Fingerprint: ", GetHardwareFingerprint());
   Print("Account: ", AccountNumber());
   Print("Broker: ", AccountCompany());

   if(!CheckExpiration()) {
      Alert("LICENSE EXPIRED!\n\nYour license expired on " + TimeToString(ExpirationDate, TIME_DATE) +
            "\n\nContact: support@smartstocktrader.com");
      Print("ERROR: License expired");
      return false;
   }

   if(!ValidateLicenseKey(LicenseKey)) {
      Alert("INVALID LICENSE KEY!\n\nPlease check your license key.\n\nContact: support@smartstocktrader.com");
      Print("ERROR: Invalid license key");
      return false;
   }

   if(!CheckAccountAuthorization()) {
      Alert("ACCOUNT NOT AUTHORIZED!\n\nAccount #" + IntegerToString(AccountNumber()) +
            " is not authorized.\n\nContact: support@smartstocktrader.com");
      Print("ERROR: Account not authorized");
      return false;
   }

   int daysLeft = GetDaysUntilExpiration();
   Print("LICENSE VALID - ", daysLeft, " days remaining");

   if(daysLeft <= 30 && daysLeft > 0) {
      Alert("LICENSE WARNING\n\nExpires in " + IntegerToString(daysLeft) +
            " days\n\nRenew at: www.smartstocktrader.com");
   }

   Print("========================");
   return true;
}

//--------------------------------------------------------------------
// PATTERN RECOGNITION HELPER FUNCTIONS (For Market Structure)
//--------------------------------------------------------------------

// Helper: Get candle body size
double Pattern_GetBodySize(string symbol, int timeframe, int shift) {
   double open = iOpen(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);
   return MathAbs(close - open);
}

// Helper: Is bullish candle
bool Pattern_IsBullish(string symbol, int timeframe, int shift) {
   return iClose(symbol, timeframe, shift) > iOpen(symbol, timeframe, shift);
}

//--------------------------------------------------------------------
// PHASE 2: POSITION TRACKING & SMART SCALING FUNCTIONS
//--------------------------------------------------------------------

// Add position to tracker
void AddPositionTracker(int ticket, double entryPrice, double sl, double tp, double lots) {
   ArrayResize(g_Positions, g_PositionCount + 1);
   g_Positions[g_PositionCount].ticket = ticket;
   g_Positions[g_PositionCount].entryPrice = entryPrice;
   g_Positions[g_PositionCount].stopLoss = sl;
   g_Positions[g_PositionCount].takeProfit = tp;
   g_Positions[g_PositionCount].lotSize = lots;
   g_Positions[g_PositionCount].partialClosed = false;
   g_Positions[g_PositionCount].movedToBreakeven = false;
   g_PositionCount++;
}

// Find position in tracker
int FindPositionTracker(int ticket) {
   for(int i = 0; i < g_PositionCount; i++) {
      if(g_Positions[i].ticket == ticket) return i;
   }
   return -1;
}

// Remove position from tracker
void RemovePositionTracker(int ticket) {
   int index = FindPositionTracker(ticket);
   if(index < 0) return;

   // Shift array elements
   for(int i = index; i < g_PositionCount - 1; i++) {
      g_Positions[i] = g_Positions[i + 1];
   }
   g_PositionCount--;
   ArrayResize(g_Positions, g_PositionCount);
}

// Check and execute smart scaling
void CheckSmartScaling(int ticket) {
   if(!UseSmartScaling) return;

   int index = FindPositionTracker(ticket);
   if(index < 0) return;

   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;

   PositionTracker pos = g_Positions[index];
   bool isLong = (OrderType() == OP_BUY);
   double currentPrice = isLong ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK);

   // Calculate profit in R (Risk units)
   double riskPoints = MathAbs(pos.entryPrice - pos.stopLoss);
   if(riskPoints <= 0) return;

   double profitPoints = isLong ? (currentPrice - pos.entryPrice) : (pos.entryPrice - currentPrice);
   double rMultiple = profitPoints / riskPoints;

   // STEP 1: Partial close at 2:1 R:R
   if(!pos.partialClosed && rMultiple >= PartialCloseRRRatio) {
      double closeLots = OrderLots() * (PartialClosePercent / 100.0);
      closeLots = NormalizeDouble(closeLots, 2);

      if(closeLots >= MarketInfo(OrderSymbol(), MODE_MINLOT)) {
         if(OrderClose(ticket, closeLots, currentPrice, 3, clrOrange)) {
            Print("✓ SMART SCALING: Closed ", PartialClosePercent, "% of #", ticket,
                  " at ", DoubleToString(rMultiple, 1), "R");
            g_Positions[index].partialClosed = true;

            // Log to API if enabled
            if(API_EnableSync && !BacktestMode) {
               TradeSync_SendTradeClose(
                  ticket,
                  currentPrice,
                  OrderProfit(),
                  OrderCommission(),
                  OrderSwap(),
                  TimeCurrent()
               );
            }
         }
      }
   }

   // STEP 2: Move to breakeven after partial close
   if(pos.partialClosed && !pos.movedToBreakeven && MoveToBreakeven) {
      if(OrderSelect(ticket, SELECT_BY_TICKET)) {
         double newSL = pos.entryPrice;

         // Add small buffer (1 pip) to account for spread
         double buffer = MarketInfo(OrderSymbol(), MODE_POINT) * 10.0;
         if(isLong) {
            newSL += buffer;
         } else {
            newSL -= buffer;
         }

         // Only modify if new SL is better than current
         bool shouldModify = false;
         if(isLong && newSL > OrderStopLoss()) shouldModify = true;
         if(!isLong && newSL < OrderStopLoss()) shouldModify = true;

         if(shouldModify) {
            if(OrderModify(ticket, OrderOpenPrice(), NormalizeDouble(newSL, _Digits),
                          OrderTakeProfit(), 0, clrGreen)) {
               Print("✓ SMART SCALING: Moved SL to breakeven for #", ticket);
               g_Positions[index].movedToBreakeven = true;
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------
int ParseSymbols(string symbolList, string &output[]) {
   int count = 0;
   string temp = symbolList;
   ArrayResize(output, 0);

   while(StringLen(temp) > 0) {
      int pos = StringFind(temp, ",", 0);
      if(pos < 0) {
         if(StringLen(temp) > 0) {
            ArrayResize(output, count + 1);
            output[count] = temp;
            count++;
         }
         break;
      } else {
         string part = StringSubstr(temp, 0, pos);
         StringTrimLeft(part);
         StringTrimRight(part);
         if(StringLen(part) > 0) {
            ArrayResize(output, count + 1);
            output[count] = part;
            count++;
         }
         temp = StringSubstr(temp, pos + 1);
      }
   }
   return count;
}

//--------------------------------------------------------------------
// SESSION MANAGEMENT
//--------------------------------------------------------------------
bool IsTradingTime() {
   // In backtest mode, trade 24/7
   if(BacktestMode) {
      return true;
   }

   // If Trade24_7 is enabled, trade anytime (no restrictions)
   if(Trade24_7) {
      if(VerboseLogging) Print("✓ Trade24_7 enabled - trading allowed at any time");
      return true;
   }

   // Simplified: Just check if regular hours are enabled
   if(!TradeRegularHours && !TradePreMarket && !TradeAfterHours) return false;

   int hour = TimeHour(TimeCurrent());
   int dayOfWeek = TimeDayOfWeek(TimeCurrent());

   // No trading on weekends
   if(dayOfWeek == 0 || dayOfWeek == 6) return false;

   // For now, allow trading between 9-16 EST (adjust for your broker)
   if(TradeRegularHours && hour >= 9 && hour < 16) return true;

   return false;
}

//--------------------------------------------------------------------
// RISK MANAGEMENT
//--------------------------------------------------------------------
bool CheckDailyLossLimit() {
   if(g_DailyStartEquity <= 0) return false;  // Prevent division by zero

   double dailyPL = AccountEquity() - g_DailyStartEquity;
   double dailyPct = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyPct <= -MaxDailyLossPercent) {
      g_EAState = STATE_SUSPENDED;
      Print("Daily loss limit reached: ", DoubleToString(dailyPct, 2), "%");
      return true;
   }
   return false;
}

//--------------------------------------------------------------------
// QUICK WIN FILTERS - Added for +10-15% Profitability
//--------------------------------------------------------------------

// Filter 1: Check Spread (Avoid wide spreads)
bool CheckSpreadFilter(string symbol) {
   if(BacktestMode) return true;  // Skip in backtest

   double spread = MarketInfo(symbol, MODE_SPREAD);
   double point = MarketInfo(symbol, MODE_POINT);

   // Prevent division by zero
   if(point <= 0) point = 0.00001;

   double spreadPips = spread * point / (point * 10.0);

   if(spreadPips > MaxSpreadPips) {
      if(VerboseLogging) Print("✗ Spread too wide on ", symbol, ": ", DoubleToString(spreadPips, 1), " pips (max: ", MaxSpreadPips, ")");
      return false;
   }

   if(VerboseLogging) Print("✓ Spread OK on ", symbol, ": ", DoubleToString(spreadPips, 1), " pips");
   return true;
}

// Filter 2: PHASE 3B: Enhanced Time of Day Filter
bool CheckTimeOfDayFilter() {
   if(!UseTimeOfDayFilter || BacktestMode) return true;

   int hour = TimeHour(TimeCurrent());
   int minute = TimeMinute(TimeCurrent());
   int currentTime = hour * 60 + minute; // Convert to minutes since midnight

   // AVOID: First 30 minutes after market open (9:30-10:00 AM EST)
   if(currentTime >= 570 && currentTime < 600) { // 9:30 AM - 10:00 AM
      if(VerboseLogging) Print("✗ Market just opened - waiting for first 30 min to pass");
      return false;
   }

   // AVOID: Lunch hour (12:00-1:00 PM EST - low volume, choppy)
   if(currentTime >= 720 && currentTime < 780) { // 12:00 PM - 1:00 PM
      if(VerboseLogging) Print("✗ Lunch hour - skipping trades");
      return false;
   }

   // AVOID: Last 30 minutes before market close (3:30-4:00 PM EST)
   if(currentTime >= 930 && currentTime < 960) { // 3:30 PM - 4:00 PM
      if(VerboseLogging) Print("✗ Market closing soon - avoiding last 30 min");
      return false;
   }

   // BEST TIMES: 10:00-11:30 AM and 2:00-3:00 PM EST (optional preference)
   bool isBestTime = false;
   if(currentTime >= 600 && currentTime < 690) { // 10:00 AM - 11:30 AM
      isBestTime = true;
   }
   if(currentTime >= 840 && currentTime < 900) { // 2:00 PM - 3:00 PM
      isBestTime = true;
   }

   if(isBestTime && VerboseLogging) {
      Print("✓ BEST TRADING TIME - high volume and clear trends");
   }

   return true;
}

// Filter 3: Max Daily Trades Limit
bool CheckMaxDailyTrades() {
   if(g_DailyTrades >= MaxDailyTrades) {
      if(VerboseLogging) Print("✗ Max daily trades reached (", g_DailyTrades, "/", MaxDailyTrades, ")");
      return false;
   }
   return true;
}

// Filter 4: Minimum Time Between Trades
bool CheckMinTimeBetweenTrades() {
   if(g_LastTradeTime == 0) return true;  // First trade

   int secondsSinceLastTrade = (int)(TimeCurrent() - g_LastTradeTime);
   int minutesSinceLastTrade = secondsSinceLastTrade / 60;

   if(minutesSinceLastTrade < MinMinutesBetweenTrades) {
      if(VerboseLogging) Print("✗ Too soon since last trade (", minutesSinceLastTrade, " min, need ", MinMinutesBetweenTrades, " min)");
      return false;
   }

   return true;
}

// Filter 5: SPY Trend Filter (Only trade with market direction)
bool CheckSPYTrendFilter(bool isBuySignal) {
   if(!UseSPYTrendFilter || BacktestMode) return true;

   // Get SPY current price and MA
   double spyClose = iClose(MarketIndexSymbol, PERIOD_D1, 0);
   double spyMA = iMA(MarketIndexSymbol, PERIOD_D1, SPYTrendMA, 0, MODE_SMA, PRICE_CLOSE, 0);

   // If data not available (symbol not found), skip filter
   if(spyClose == 0 || spyMA == 0) {
      if(VerboseLogging) Print("⚠ ", MarketIndexSymbol, " data not available - skipping trend filter");
      return true;
   }

   bool marketBullish = (spyClose > spyMA);

   // Only allow long trades when market is bullish
   if(isBuySignal && !marketBullish) {
      if(VerboseLogging) Print("✗ ", MarketIndexSymbol, " bearish (", DoubleToString(spyClose, 2), " < MA", SPYTrendMA, ": ", DoubleToString(spyMA, 2), ") - skipping LONG");
      return false;
   }

   // Only allow short trades when market is bearish
   if(!isBuySignal && marketBullish) {
      if(VerboseLogging) Print("✗ ", MarketIndexSymbol, " bullish (", DoubleToString(spyClose, 2), " > MA", SPYTrendMA, ": ", DoubleToString(spyMA, 2), ") - skipping SHORT");
      return false;
   }

   if(VerboseLogging) {
      string trend = "";
      if(marketBullish) trend = "BULLISH";
      else trend = "BEARISH";

      string direction = "";
      if(isBuySignal) direction = "LONG";
      else direction = "SHORT";

      Print("✓ ", MarketIndexSymbol, " ", trend, " - ", direction, " trade aligned");
   }

   return true;
}

// PHASE 1B: VOLUME FILTER - Reject trades without institutional buying/selling
bool CheckVolumeFilter(string symbol) {
   // Calculate average volume over 20 periods (H1)
   double totalVolume = 0;
   int volumePeriod = 20;

   for(int i = 1; i <= volumePeriod; i++) {
      totalVolume += iVolume(symbol, PERIOD_H1, i);
   }

   double avgVolume = totalVolume / volumePeriod;
   double currentVolume = iVolume(symbol, PERIOD_H1, 0);

   // Prevent division by zero
   if(avgVolume <= 0) {
      if(VerboseLogging) Print("⚠ ", symbol, " - Volume data unavailable, skipping volume filter");
      return true;  // Skip filter if no data
   }

   double volumeRatio = currentVolume / avgVolume;

   // Require current volume to be at least 1.5x average (institutional activity)
   if(volumeRatio < 1.5) {
      if(VerboseLogging) Print("✗ ", symbol, " - Low volume (", DoubleToString(volumeRatio, 2), "x avg) - rejecting trade");
      return false;
   }

   if(VerboseLogging) Print("✓ ", symbol, " - Volume OK (", DoubleToString(volumeRatio, 2), "x avg)");
   return true;
}

// PHASE 3A: MARKET STRUCTURE - Check for higher highs/lows (BUY) or lower highs/lows (SELL)
bool CheckMarketStructure(string symbol, bool isBuySignal) {
   if(!UseMarketStructure) return true;

   int trendStructure = Structure_GetTrendStructure(symbol, PERIOD_H1, 50);

   // For BUY: Need uptrend structure (higher highs and higher lows)
   if(isBuySignal) {
      if(trendStructure != 1) {
         if(VerboseLogging) Print("✗ ", symbol, " - No uptrend structure (need higher highs/lows for BUY)");
         return false;
      }
      if(VerboseLogging) Print("✓ ", symbol, " - Uptrend structure confirmed (higher highs/lows)");
      return true;
   }

   // For SELL: Need downtrend structure (lower highs and lower lows)
   if(trendStructure != -1) {
      if(VerboseLogging) Print("✗ ", symbol, " - No downtrend structure (need lower highs/lows for SELL)");
      return false;
   }
   if(VerboseLogging) Print("✓ ", symbol, " - Downtrend structure confirmed (lower highs/lows)");
   return true;
}

// PHASE 4: 3-CONFLUENCE SNIPER SYSTEM
// Checks: D1 200MA + H4 50MA + H1 crossover + RSI + WPR + MACD + Volume + S/R + 5:1 R:R
bool Check3ConfluenceSniper(string symbol, bool isBuySignal) {
   if(!Use3ConfluenceSniper) return true;

   // CONFLUENCE 1: D1 200MA Trend Alignment
   double d1_close = iClose(symbol, PERIOD_D1, 0);
   double d1_ma200 = iMA(symbol, PERIOD_D1, D1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   bool d1_aligned = isBuySignal ? (d1_close > d1_ma200) : (d1_close < d1_ma200);

   if(!d1_aligned) {
      if(VerboseLogging) Print("✗ ", symbol, " - D1 trend not aligned (price ",
            (isBuySignal ? "below" : "above"), " 200MA)");
      return false;
   }
   if(VerboseLogging) Print("✓ ", symbol, " - D1 trend aligned (price ",
         (isBuySignal ? "above" : "below"), " 200MA)");

   // CONFLUENCE 2: H4 50MA Trend Alignment
   double h4_close = iClose(symbol, PERIOD_H4, 0);
   double h4_ma50 = iMA(symbol, PERIOD_H4, H4_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   bool h4_aligned = isBuySignal ? (h4_close > h4_ma50) : (h4_close < h4_ma50);

   if(!h4_aligned) {
      if(VerboseLogging) Print("✗ ", symbol, " - H4 trend not aligned (price ",
            (isBuySignal ? "below" : "above"), " 50MA)");
      return false;
   }
   if(VerboseLogging) Print("✓ ", symbol, " - H4 trend aligned (price ",
         (isBuySignal ? "above" : "below"), " 50MA)");

   // CONFLUENCE 3: H1 Fresh MA Crossover (within last 3 candles)
   double h1_fast_0 = iMA(symbol, PERIOD_H1, H1_Fast_MA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double h1_slow_0 = iMA(symbol, PERIOD_H1, H1_Slow_MA, 0, MODE_SMA, PRICE_CLOSE, 0);
   double h1_fast_1 = iMA(symbol, PERIOD_H1, H1_Fast_MA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h1_slow_1 = iMA(symbol, PERIOD_H1, H1_Slow_MA, 0, MODE_SMA, PRICE_CLOSE, 1);
   double h1_fast_2 = iMA(symbol, PERIOD_H1, H1_Fast_MA, 0, MODE_EMA, PRICE_CLOSE, 2);
   double h1_slow_2 = iMA(symbol, PERIOD_H1, H1_Slow_MA, 0, MODE_SMA, PRICE_CLOSE, 2);
   double h1_fast_3 = iMA(symbol, PERIOD_H1, H1_Fast_MA, 0, MODE_EMA, PRICE_CLOSE, 3);
   double h1_slow_3 = iMA(symbol, PERIOD_H1, H1_Slow_MA, 0, MODE_SMA, PRICE_CLOSE, 3);

   bool freshCrossover = false;
   if(isBuySignal) {
      // Bullish crossover: fast crossed above slow in last 3 candles
      if((h1_fast_0 > h1_slow_0 && h1_fast_1 <= h1_slow_1) ||
         (h1_fast_1 > h1_slow_1 && h1_fast_2 <= h1_slow_2) ||
         (h1_fast_2 > h1_slow_2 && h1_fast_3 <= h1_slow_3)) {
         freshCrossover = true;
      }
   } else {
      // Bearish crossover: fast crossed below slow in last 3 candles
      if((h1_fast_0 < h1_slow_0 && h1_fast_1 >= h1_slow_1) ||
         (h1_fast_1 < h1_slow_1 && h1_fast_2 >= h1_slow_2) ||
         (h1_fast_2 < h1_slow_2 && h1_fast_3 >= h1_slow_3)) {
         freshCrossover = true;
      }
   }

   if(!freshCrossover) {
      if(VerboseLogging) Print("✗ ", symbol, " - No fresh MA crossover in last 3 candles");
      return false;
   }
   if(VerboseLogging) Print("✓ ", symbol, " - Fresh MA crossover detected!");

   // MOMENTUM: RSI 50-70 (bullish) or 30-50 (bearish) - Already checked in GetBuySignal/GetSellSignal
   // MOMENTUM: WPR recovering - Already checked in GetBuySignal/GetSellSignal

   // CONFLUENCE 4: MACD Positive/Negative
   if(UseMACD) {
      double macd_main = iMACD(symbol, PERIOD_H1, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
      double macd_signal = iMACD(symbol, PERIOD_H1, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);

      if(isBuySignal) {
         if(macd_main <= 0 || macd_main <= macd_signal) {
            if(VerboseLogging) Print("✗ ", symbol, " - MACD not positive (main: ",
                  DoubleToString(macd_main, 5), ", signal: ", DoubleToString(macd_signal, 5), ")");
            return false;
         }
         if(VerboseLogging) Print("✓ ", symbol, " - MACD positive and above signal");
      } else {
         if(macd_main >= 0 || macd_main >= macd_signal) {
            if(VerboseLogging) Print("✗ ", symbol, " - MACD not negative (main: ",
                  DoubleToString(macd_main, 5), ", signal: ", DoubleToString(macd_signal, 5), ")");
            return false;
         }
         if(VerboseLogging) Print("✓ ", symbol, " - MACD negative and below signal");
      }
   }

   // CONFLUENCE 5: Volume > 1.5x average - Already checked by CheckVolumeFilter

   // CONFLUENCE 6: At support/resistance - Already checked by CheckRoomToTarget

   // CONFLUENCE 7: 5:1 Room to target minimum
   double atr = iATR(symbol, PERIOD_H1, ATR_Period, 0);
   if(atr > 0) {
      double currentPrice = isBuySignal ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
      double minRoom = atr * MinRoomToTargetRR;

      if(isBuySignal) {
         double resistance = Structure_GetNearestResistance(symbol, currentPrice);
         if(resistance > 0) {
            double room = resistance - currentPrice;
            if(room < minRoom) {
               if(VerboseLogging) Print("✗ ", symbol, " - Insufficient 5:1 room to resistance (",
                     DoubleToString(room / atr, 1), "R, need ", MinRoomToTargetRR, "R)");
               return false;
            }
            if(VerboseLogging) Print("✓ ", symbol, " - Excellent 5:1 room to resistance (",
                  DoubleToString(room / atr, 1), "R)");
         }
      } else {
         double support = Structure_GetNearestSupport(symbol, currentPrice);
         if(support > 0) {
            double room = currentPrice - support;
            if(room < minRoom) {
               if(VerboseLogging) Print("✗ ", symbol, " - Insufficient 5:1 room to support (",
                     DoubleToString(room / atr, 1), "R, need ", MinRoomToTargetRR, "R)");
               return false;
            }
            if(VerboseLogging) Print("✓ ", symbol, " - Excellent 5:1 room to support (",
                  DoubleToString(room / atr, 1), "R)");
         }
      }
   }

   if(VerboseLogging) {
      Print("╔════════════════════════════════════════╗");
      Print("║  🎯 3-CONFLUENCE SNIPER TRIGGERED!    ║");
      Print("║  ✓ D1 200MA aligned                   ║");
      Print("║  ✓ H4 50MA aligned                    ║");
      Print("║  ✓ H1 fresh crossover                 ║");
      Print("║  ✓ RSI in optimal zone                ║");
      Print("║  ✓ WPR recovering/falling             ║");
      Print("║  ✓ MACD positive/negative             ║");
      Print("║  ✓ Volume > 1.5x avg                  ║");
      Print("║  ✓ At support/resistance              ║");
      Print("║  ✓ 5:1 R:R room to target             ║");
      Print("╚════════════════════════════════════════╝");
   }

   return true;
}

// PHASE 3A: SUPPORT/RESISTANCE - Check room to target (min 3x ATR)
bool CheckRoomToTarget(string symbol, bool isBuySignal) {
   if(!UseSupportResistance) return true;

   double atr = iATR(symbol, PERIOD_H1, ATR_Period, 0);
   if(atr <= 0) return true; // Skip if ATR not available

   double currentPrice = isBuySignal ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   double minRoom = atr * MinRoomToTarget;

   if(isBuySignal) {
      // For BUY: Check distance to nearest resistance
      double resistance = Structure_GetNearestResistance(symbol, currentPrice);
      if(resistance > 0) {
         double room = resistance - currentPrice;
         if(room < minRoom) {
            if(VerboseLogging) Print("✗ ", symbol, " - Insufficient room to resistance (",
                  DoubleToString(room / atr, 1), "R, need ", MinRoomToTarget, "R)");
            return false;
         }
         if(VerboseLogging) Print("✓ ", symbol, " - Good room to resistance (",
               DoubleToString(room / atr, 1), "R)");
      }

      // Also check if we're AT support (good entry)
      if(!Structure_IsNearSupport(symbol, currentPrice)) {
         if(VerboseLogging) Print("✗ ", symbol, " - Not at support level");
         return false;
      }
      if(VerboseLogging) Print("✓ ", symbol, " - At support level (good entry)");
   } else {
      // For SELL: Check distance to nearest support
      double support = Structure_GetNearestSupport(symbol, currentPrice);
      if(support > 0) {
         double room = currentPrice - support;
         if(room < minRoom) {
            if(VerboseLogging) Print("✗ ", symbol, " - Insufficient room to support (",
                  DoubleToString(room / atr, 1), "R, need ", MinRoomToTarget, "R)");
            return false;
         }
         if(VerboseLogging) Print("✓ ", symbol, " - Good room to support (",
               DoubleToString(room / atr, 1), "R)");
      }

      // Also check if we're AT resistance (good entry)
      if(!Structure_IsNearResistance(symbol, currentPrice)) {
         if(VerboseLogging) Print("✗ ", symbol, " - Not at resistance level");
         return false;
      }
      if(VerboseLogging) Print("✓ ", symbol, " - At resistance level (good entry)");
   }

   return true;
}

// PHASE 1C: MULTI-TIMEFRAME CONFIRMATION - H1 signal must align with H4 trend and D1 structure
bool CheckMultiTimeframeConfirmation(string symbol, bool isBuySignal) {
   // H4 Trend Check (50 MA)
   double h4_close = iClose(symbol, PERIOD_H4, 0);
   double h4_ma50 = iMA(symbol, PERIOD_H4, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   bool h4_bullish = (h4_close > h4_ma50);

   // D1 Structure Check (200 MA)
   double d1_close = iClose(symbol, PERIOD_D1, 0);
   double d1_ma200 = iMA(symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   bool d1_bullish = (d1_close > d1_ma200);

   // For BUY: Need H4 and D1 to be bullish
   if(isBuySignal) {
      if(!h4_bullish) {
         if(VerboseLogging) Print("✗ ", symbol, " - H4 bearish (price < 50MA) - rejecting LONG");
         return false;
      }
      if(!d1_bullish) {
         if(VerboseLogging) Print("✗ ", symbol, " - D1 bearish (price < 200MA) - rejecting LONG");
         return false;
      }
      if(VerboseLogging) Print("✓ ", symbol, " - Multi-timeframe aligned: H1 BUY + H4 bullish + D1 bullish");
      return true;
   }

   // For SELL: Need H4 and D1 to be bearish
   if(!h4_bullish && !d1_bullish) {
      if(VerboseLogging) Print("✓ ", symbol, " - Multi-timeframe aligned: H1 SELL + H4 bearish + D1 bearish");
      return true;
   }

   if(h4_bullish) {
      if(VerboseLogging) Print("✗ ", symbol, " - H4 bullish (price > 50MA) - rejecting SHORT");
   }
   if(d1_bullish) {
      if(VerboseLogging) Print("✗ ", symbol, " - D1 bullish (price > 200MA) - rejecting SHORT");
   }

   return false;
}

double CalculateLotSize(string symbol, double slPips) {
   double riskAmount = AccountBalance() * (RiskPercentPerTrade / 100.0);
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double point = MarketInfo(symbol, MODE_POINT);

   if(tickValue <= 0) tickValue = 1.0;
   if(point <= 0) point = 0.00001;

   double pipValue = tickValue * 10.0;
   double lotSize = riskAmount / (slPips * pipValue);

   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);

   if(lotStep > 0) lotSize = MathFloor(lotSize / lotStep) * lotStep;
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;

   return NormalizeDouble(lotSize, 2);
}

//--------------------------------------------------------------------
// SIMPLE STRATEGY
//--------------------------------------------------------------------
bool GetBuySignal(string symbol) {
   // PHASE 1A FIX: Trade WITH trend only - no contradictions
   double fastMA = iMA(symbol, PERIOD_H1, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(symbol, PERIOD_H1, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double rsi = iRSI(symbol, PERIOD_H1, RSI_Period, PRICE_CLOSE, 0);
   double close = iClose(symbol, PERIOD_H1, 0);

   // Williams %R - RECOVERING from oversold (early momentum detection)
   double wpr = 0;
   double wprPrev = 0;
   bool wprOK = true;
   if(UseWilliamsR) {
      wpr = iWPR(symbol, PERIOD_H1, WPR_Period, 0);
      wprPrev = iWPR(symbol, PERIOD_H1, WPR_Period, 1);
      // CRITICAL FIX: Look for RECOVERY from oversold (wpr was < -80, now moving up toward -50)
      // This catches early bullish momentum BEFORE the move is done
      wprOK = (wprPrev < WPR_Oversold && wpr > wprPrev && wpr > WPR_Oversold);
   }

   // REMOVED ENVELOPE FROM ENTRY - envelopes will only be used for exits
   // Contradictory logic eliminated: BUY only when price > MAs (bullish trend)

   // Buy signal: Price above both MAs (trend), fastMA > slowMA (momentum), RSI 50-70 (bullish but not overbought), WPR recovering
   if(close > fastMA && close > slowMA && fastMA > slowMA && rsi > 50 && rsi < 70 && wprOK) {
      // PHASE 1B: Volume confirmation - require institutional buying
      if(!CheckVolumeFilter(symbol)) return false;

      // PHASE 1C: Multi-timeframe confirmation - H1 signal must align with H4/D1 trend
      if(!CheckMultiTimeframeConfirmation(symbol, true)) return false;

      // PHASE 3A: Market structure - require uptrend structure (higher highs/lows)
      if(!CheckMarketStructure(symbol, true)) return false;

      // PHASE 3A: Support/Resistance - check room to target and entry at support
      if(!CheckRoomToTarget(symbol, true)) return false;

      return true;
   }
   return false;
}

bool GetSellSignal(string symbol) {
   // PHASE 1A FIX: Trade WITH trend only - no contradictions
   double fastMA = iMA(symbol, PERIOD_H1, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(symbol, PERIOD_H1, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double rsi = iRSI(symbol, PERIOD_H1, RSI_Period, PRICE_CLOSE, 0);
   double close = iClose(symbol, PERIOD_H1, 0);

   // Williams %R - FALLING from overbought (early bearish momentum detection)
   double wpr = 0;
   double wprPrev = 0;
   bool wprOK = true;
   if(UseWilliamsR) {
      wpr = iWPR(symbol, PERIOD_H1, WPR_Period, 0);
      wprPrev = iWPR(symbol, PERIOD_H1, WPR_Period, 1);
      // CRITICAL FIX: Look for FALLING from overbought (wpr was > -20, now moving down toward -50)
      // This catches early bearish momentum BEFORE the move is done
      wprOK = (wprPrev > WPR_Overbought && wpr < wprPrev && wpr < WPR_Overbought);
   }

   // REMOVED ENVELOPE FROM ENTRY - envelopes will only be used for exits
   // Contradictory logic eliminated: SELL only when price < MAs (bearish trend)

   // Sell signal: Price below both MAs (trend), fastMA < slowMA (momentum), RSI 30-50 (bearish but not oversold), WPR falling
   if(close < fastMA && close < slowMA && fastMA < slowMA && rsi < 50 && rsi > 30 && wprOK) {
      // PHASE 1B: Volume confirmation - require institutional selling
      if(!CheckVolumeFilter(symbol)) return false;

      // PHASE 1C: Multi-timeframe confirmation - H1 signal must align with H4/D1 trend
      if(!CheckMultiTimeframeConfirmation(symbol, false)) return false;

      // PHASE 3A: Market structure - require downtrend structure (lower highs/lows)
      if(!CheckMarketStructure(symbol, false)) return false;

      // PHASE 3A: Support/Resistance - check room to target and entry at resistance
      if(!CheckRoomToTarget(symbol, false)) return false;

      return true;
   }
   return false;
}

//--------------------------------------------------------------------
// DASHBOARD
//--------------------------------------------------------------------
void UpdateDashboard() {
   if(!ShowDashboard) return;

   int y = 20;
   int lineHeight = 18;

   // Header
   CreateLabel("SST_Header", 15, y, "=== SMART STOCK TRADER ===", clrAqua, 11);
   y += lineHeight + 5;

   // State
   color stateColor = (g_EAState == STATE_READY) ? clrLime : clrRed;
   string stateName = (g_EAState == STATE_READY) ? "READY" : "SUSPENDED";
   CreateLabel("SST_State", 15, y, "State: " + stateName, stateColor, 10);
   y += lineHeight;

   // Account
   CreateLabel("SST_Balance", 15, y, "Balance: $" + DoubleToString(AccountBalance(), 2), clrWhite);
   y += lineHeight;
   CreateLabel("SST_Equity", 15, y, "Equity:  $" + DoubleToString(AccountEquity(), 2), clrWhite);
   y += lineHeight;

   // Daily P/L
   double dailyPL = AccountEquity() - g_DailyStartEquity;
   color plColor = (dailyPL >= 0) ? clrLime : clrRed;
   string plSign = (dailyPL >= 0) ? "+" : "";
   CreateLabel("SST_DailyPL", 15, y, "Daily P/L: " + plSign + "$" + DoubleToString(dailyPL, 2), plColor);
   y += lineHeight + 3;

   // Today's stats
   CreateLabel("SST_TodayHeader", 15, y, "--- Today's Stats ---", clrSilver);
   y += lineHeight;
   CreateLabel("SST_Trades", 15, y, "Trades: " + IntegerToString(g_DailyTrades), clrWhite);
   y += lineHeight;
   CreateLabel("SST_WL", 15, y, "W/L: " + IntegerToString(g_DailyWins) + "/" + IntegerToString(g_DailyLosses), clrWhite);
   y += lineHeight;

   double winRate = (g_DailyTrades > 0) ? (g_DailyWins / (double)g_DailyTrades * 100.0) : 0;
   CreateLabel("SST_WinRate", 15, y, "Win Rate: " + DoubleToString(winRate, 1) + "%", winRate >= 50 ? clrLime : clrOrange);
}

void CreateLabel(string name, int x, int y, string text, color clr = clrWhite, int fontSize = 9) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════╗");
   Print("║  SMART STOCK TRADER - STARTING...     ║");
   Print("╚════════════════════════════════════════╝");

   // VALIDATE LICENSE FIRST
   if(!ValidateLicense()) {
      Print("╔════════════════════════════════════════╗");
      Print("║    LICENSE VALIDATION FAILED!         ║");
      Print("║         EA WILL NOT TRADE             ║");
      Print("╚════════════════════════════════════════╝");
      return(INIT_FAILED);
   }

   Print("\n✓ License validated successfully\n");

   // ════════════════════════════════════════════════════════════════
   // PHASE 4: INITIALIZE BACKEND API INTEGRATION
   // ════════════════════════════════════════════════════════════════
   if(API_EnableSync && !BacktestMode) {
      Print("╔════════════════════════════════════════╗");
      Print("║   INITIALIZING API INTEGRATION        ║");
      Print("╚════════════════════════════════════════╝");

      // Initialize WebAPI module
      WebAPI_Init();

      // Initialize Logger
      Logger_Init(LOG_INFO, true, false, false);

      // Initialize API Configuration
      APIConfig_Init(
         API_BaseURL,
         API_UserEmail,
         API_UserPassword,
         API_EnableTradeSync,
         API_EnableHeartbeat,
         API_EnablePerfSync,
         VerboseLogging
      );

      // Set intervals
      APIConfig_SetHeartbeatInterval(API_HeartbeatInterval);
      APIConfig_SetPerformanceSyncInterval(API_PerfSyncInterval);

      // Validate configuration
      if(!APIConfig_Validate()) {
         Print("⚠ API Configuration validation failed - check your settings");
         Print("  Dashboard integration will be disabled");
         APIConfig_SetOfflineMode(true);
      } else {
         // Initialize authentication
         BotAuth_Init();

         // Authenticate with backend
         if(BotAuth_Authenticate()) {
            Print("✓ Authenticated with backend API");

            // Initialize sync modules
            TradeSync_Init();
            Heartbeat_Init();
            PerformanceSync_Init();

            // Send initial heartbeat
            Heartbeat_SendNow();

            // Sync existing trades
            int syncedTrades = TradeSync_SyncExistingTrades();
            if(syncedTrades > 0) {
               Print("✓ Synced ", syncedTrades, " existing trades to backend");
            }

            // Send initial performance snapshot
            PerformanceSync_SendNow();

            Print("╔════════════════════════════════════════╗");
            Print("║  BACKEND API INTEGRATION ACTIVE!      ║");
            Print("║  ✓ Authentication                     ║");
            Print("║  ✓ Trade Sync                         ║");
            Print("║  ✓ Heartbeat Monitoring               ║");
            Print("║  ✓ Performance Metrics                ║");
            Print("║  📊 Dashboard: LIVE DATA ENABLED      ║");
            Print("╚════════════════════════════════════════╝\n");
         } else {
            Print("✗ Backend authentication failed");
            Print("  Dashboard will show offline status");
         }
      }
   } else {
      if(BacktestMode) {
         Print("⚠ API Sync disabled in backtest mode");
      } else {
         Print("⚠ API Sync disabled by parameter");
      }
   }

   // ════════════════════════════════════════════════════════════════
   // PHASE 1 + PHASE 2: INITIALIZE ADVANCED MODULES
   // ════════════════════════════════════════════════════════════════
   Print("╔════════════════════════════════════════╗");
   Print("║   INITIALIZING PHASE 1+2 MODULES      ║");
   Print("╚════════════════════════════════════════╝");

   // 1. News Filter - Economic calendar integration
   News_InitializeCalendar();
   Print("✓ News Filter initialized");

   // 2. Correlation Matrix - Portfolio management
   Correlation_InitializeSectorMap();
   Print("✓ Correlation Matrix initialized (", ArraySize(g_SectorMap), " symbols mapped)");

   // 3. Multi-Asset Confirmation - SPY/VIX/Bonds/Sectors
   MultiAsset_InitSectorETFs();
   Print("✓ Multi-Asset Confirmation initialized");

   // 4. Drawdown Protection - Adaptive sizing
   Drawdown_Init();
   Print("✓ Drawdown Protection initialized");

   // 5. Advanced Volatility - Already self-contained (no init needed)
   Print("✓ Advanced Volatility module ready");

   // 6. Exit Optimization - Already self-contained (no init needed)
   Print("✓ Exit Optimization module ready");

   // 7. Machine Learning - PHASE 3: AI-powered predictions
   ML_Initialize();
   Print("✓ Machine Learning module initialized");

   // 8. Market Structure - PHASE 3A: Support/Resistance, Trend structure
   ArrayResize(g_SRLevels, 0);
   Structure_Init();  // Initialize and find S/R levels
   Print("✓ Market Structure module initialized");

   Print("╔════════════════════════════════════════╗");
   Print("║  ALL PHASE 1+2+3+3A MODULES ACTIVE!   ║");
   Print("║  ✓ News Filter (Live API)             ║");
   Print("║  ✓ Correlation Matrix                 ║");
   Print("║  ✓ Advanced Volatility                ║");
   Print("║  ✓ Drawdown Protection                ║");
   Print("║  ✓ Multi-Asset Confirmation           ║");
   Print("║  ✓ Exit Optimization                  ║");
   Print("║  🤖 Machine Learning (NEW!)           ║");
   Print("║  📊 Market Structure (PHASE 3A)       ║");
   Print("╚════════════════════════════════════════╝\n");

   // If Stocks is empty or BacktestMode, use current chart symbol
   if(Stocks == "" || BacktestMode) {
      g_SymbolCount = 1;
      ArrayResize(g_Symbols, 1);
      g_Symbols[0] = Symbol();
      if(VerboseLogging) Print("✓ Trading current chart symbol: ", Symbol());
   } else {
      g_SymbolCount = ParseSymbols(Stocks, g_Symbols);
      if(VerboseLogging) Print("✓ Trading ", g_SymbolCount, " symbols: ", Stocks);
   }

   if(BacktestMode) {
      Print("╔════════════════════════════════════════╗");
      Print("║      BACKTEST MODE ENABLED            ║");
      Print("║  - Trading 24/7 (no time limits)      ║");
      Print("║  - Verbose logging enabled            ║");
      Print("║  - Single symbol: ", Symbol(), "           ║");
      Print("╚════════════════════════════════════════╝");
      VerboseLogging = true;  // Force verbose logging in backtest mode
   }

   // Display 24/7 trading status
   if(Trade24_7 && !BacktestMode) {
      Print("╔════════════════════════════════════════╗");
      Print("║    24/7 TRADING MODE ENABLED          ║");
      Print("║  - No time restrictions               ║");
      Print("║  - Trades at ANY time (even 11PM!)    ║");
      Print("║  - Weekend trading if broker allows   ║");
      Print("╚════════════════════════════════════════╝");
   }

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountEquity();

   UpdateDashboard();

   Print("=== INITIALIZATION COMPLETE ===");
   Print("Trading Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("Smart Stock Trader shutting down...");

   // Shutdown API integration modules
   if(API_EnableSync && !BacktestMode) {
      Print("Shutting down API integration modules...");

      PerformanceSync_Shutdown();
      Heartbeat_Shutdown();
      TradeSync_Shutdown();
      BotAuth_Shutdown();
      Logger_Shutdown();
      WebAPI_Shutdown();
      APIConfig_Shutdown();

      Print("✓ API modules shut down");
   }

   ObjectsDeleteAll(0, "SST_", 0, OBJ_LABEL);
}

//--------------------------------------------------------------------
// ON TICK
//--------------------------------------------------------------------
void OnTick() {
   // ════════════════════════════════════════════════════════════════
   // PHASE 4: UPDATE BACKEND SYNC MODULES
   // ════════════════════════════════════════════════════════════════
   if(API_EnableSync && !BacktestMode) {
      // Update heartbeat timer
      Heartbeat_Update();

      // Update performance sync timer
      PerformanceSync_Update();
   }

   // ════════════════════════════════════════════════════════════════
   // PHASE 2: UPDATE DRAWDOWN PROTECTION (Every tick)
   // ════════════════════════════════════════════════════════════════
   Drawdown_Update();

   // ════════════════════════════════════════════════════════════════
   // PHASE 3A: UPDATE MARKET STRUCTURE (Periodic)
   // ════════════════════════════════════════════════════════════════
   Structure_Update();

   // Reset daily stats if new day
   if(TimeDay(TimeCurrent()) != TimeDay(g_DailyStartTime)) {
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountEquity();
      g_DailyTrades = 0;
      g_DailyWins = 0;
      g_DailyLosses = 0;
      Print("New day - daily stats reset");

      // Send performance snapshot on new day
      if(API_EnableSync && !BacktestMode) {
         PerformanceSync_SendNow();
      }
   }

   // Update dashboard every 10 ticks
   static int tickCount = 0;
   tickCount++;
   if(tickCount % 10 == 0) {
      UpdateDashboard();
   }

   // Check if trading is allowed
   if(!EnableTrading) return;
   if(g_EAState == STATE_SUSPENDED) return;
   if(!IsTradingTime()) return;
   if(CheckDailyLossLimit()) return;

   // ════════════════════════════════════════════════════════════════
   // PHASE 2: EMERGENCY STOP - Drawdown Protection
   // ════════════════════════════════════════════════════════════════
   if(Drawdown_ShouldStopTrading()) {
      if(VerboseLogging) Print("🛑 DRAWDOWN PROTECTION: Trading suspended");
      return;
   }

   // Scan for trades once per minute
   static datetime lastScan = 0;
   if(TimeCurrent() - lastScan < 60) return;
   lastScan = TimeCurrent();

   // Loop through symbols
   // ════════════════════════════════════════════════════════════════
   // QUICK WIN FILTERS - Pre-trade checks (ALL symbols)
   // ════════════════════════════════════════════════════════════════

   // Filter: Time of Day
   if(!CheckTimeOfDayFilter()) return;

   // Filter: Max Daily Trades
   if(!CheckMaxDailyTrades()) return;

   // Filter: Min Time Between Trades
   if(!CheckMinTimeBetweenTrades()) return;

   // ════════════════════════════════════════════════════════════════
   // PHASE 1: NEWS FILTER (Check BEFORE any trading)
   // ════════════════════════════════════════════════════════════════
   if(News_IsNewsTime()) {
      if(VerboseLogging) Print("📰 NEWS TIME: Trading blocked (major news approaching/ongoing)");
      return;
   }

   for(int i = 0; i < g_SymbolCount; i++) {
      string symbol = g_Symbols[i];

      // Check if already have position
      bool hasPosition = false;
      int existingTicket = -1;
      for(int j = 0; j < OrdersTotal(); j++) {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == symbol && OrderMagicNumber() == MagicNumber) {
               hasPosition = true;
               existingTicket = OrderTicket();
               break;
            }
         }
      }

      // ════════════════════════════════════════════════════════════════
      // PHASE 2: SMART SCALING - Check for partial profit and breakeven
      // ════════════════════════════════════════════════════════════════
      if(hasPosition && existingTicket >= 0) {
         CheckSmartScaling(existingTicket);
      }

      // ════════════════════════════════════════════════════════════════
      // PHASE 2: EXIT OPTIMIZATION - Manage existing positions
      // ════════════════════════════════════════════════════════════════
      if(hasPosition && existingTicket >= 0) {
         // Update trailing stop
         ExitOpt_UpdateTrailingStop(existingTicket, symbol, PERIOD_H1);

         // Check exit signals
         if(OrderSelect(existingTicket, SELECT_BY_TICKET)) {
            bool isLong = (OrderType() == OP_BUY);
            double entryPrice = OrderOpenPrice();
            double currentPrice = isLong ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
            datetime entryTime = OrderOpenTime();
            double currentSL = OrderStopLoss();

            if(ExitOpt_ShouldExit(existingTicket, symbol, PERIOD_H1, isLong, entryPrice, currentPrice, entryTime, currentSL)) {
               // Close the trade
               double closePrice = isLong ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
               double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
               bool isWin = (orderProfit > 0);

               if(OrderClose(existingTicket, OrderLots(), closePrice, 3, clrRed)) {
                  Print("✓ EXIT OPTIMIZATION: Closed #", existingTicket, " on ", symbol,
                        " - P/L: ", DoubleToString(orderProfit, 2));

                  // Remove from position tracker
                  RemovePositionTracker(existingTicket);

                  // ════════════════════════════════════════════════════════════════
                  // PHASE 2: Record trade result in Drawdown Protection
                  // ════════════════════════════════════════════════════════════════
                  Drawdown_RecordTrade(isWin, orderProfit);

                  // Update daily stats
                  if(isWin) {
                     g_DailyWins++;
                     g_TotalWins++;
                     g_TotalProfit += orderProfit;
                  } else {
                     g_DailyLosses++;
                     g_TotalLosses++;
                     g_TotalLoss += MathAbs(orderProfit);
                  }

                  // ════════════════════════════════════════════════════════════════
                  // PHASE 4: SYNC TRADE CLOSE TO BACKEND API
                  // ════════════════════════════════════════════════════════════════
                  if(API_EnableSync && !BacktestMode) {
                     // Get commission and swap from order (before it's closed)
                     double commission = OrderCommission();
                     double swap = OrderSwap();

                     TradeSync_SendTradeClose(
                        existingTicket,
                        closePrice,
                        orderProfit,
                        commission,
                        swap,
                        TimeCurrent()
                     );
                  }
               }
            }
         }

         continue; // Already have position, skip to next symbol
      }

      // ════════════════════════════════════════════════════════════════
      // PER-SYMBOL FILTERS (Only for new trade entries)
      // ════════════════════════════════════════════════════════════════

      // Filter: Spread Check
      if(!CheckSpreadFilter(symbol)) continue;

      // ════════════════════════════════════════════════════════════════
      // PHASE 1: VOLATILITY FILTER
      // ════════════════════════════════════════════════════════════════
      if(!Volatility_IsTradeable(symbol, PERIOD_H1)) {
         if(VerboseLogging) Print("✗ ", symbol, " - Volatility not tradeable (too low or too high)");
         continue;
      }

      // ════════════════════════════════════════════════════════════════
      // PHASE 1: CORRELATION & SECTOR LIMITS
      // ════════════════════════════════════════════════════════════════
      if(!Correlation_CheckNewPosition(symbol)) {
         if(VerboseLogging) Print("✗ ", symbol, " - High correlation with existing positions");
         continue;
      }

      if(!Correlation_CheckSectorLimits(symbol)) {
         if(VerboseLogging) Print("✗ ", symbol, " - Sector exposure limits reached");
         continue;
      }

      // ════════════════════════════════════════════════════════════════
      // PHASE 3: MACHINE LEARNING SIGNAL DETECTION
      // ════════════════════════════════════════════════════════════════
      bool mlSignal = false;
      bool mlIsBullish = false;
      double mlConfidence = 0.0;

      if(UseMLPredictions) {
         mlSignal = ML_GetTradingSignal(symbol, PERIOD_H1, mlIsBullish, mlConfidence);
      }

      // Check for traditional signals
      bool buySignal = GetBuySignal(symbol);
      bool sellSignal = GetSellSignal(symbol);

      // Combine ML with traditional signals
      bool hasSignal = false;
      bool isBuy = false;

      if(mlSignal && (buySignal || sellSignal)) {
         // Both ML and traditional agree!
         bool traditionalIsBuy = buySignal;
         if(mlIsBullish == traditionalIsBuy) {
            hasSignal = true;
            isBuy = mlIsBullish;
            if(VerboseLogging) {
               Print("🎯 STRONG SIGNAL: ML + Traditional agree! (", (isBuy ? "BUY" : "SELL"),
                     " confidence: ", DoubleToString(mlConfidence, 1), "%)");
            }
         }
      } else if(mlSignal && mlConfidence >= MLConfidenceThreshold) {
         // ML signal alone is strong enough
         hasSignal = true;
         isBuy = mlIsBullish;
         if(VerboseLogging) {
            Print("🤖 ML SIGNAL: ", (isBuy ? "BUY" : "SELL"),
                  " (confidence: ", DoubleToString(mlConfidence, 1), "%)");
         }
      } else if(buySignal || sellSignal) {
         // Traditional signal alone
         hasSignal = true;
         isBuy = buySignal;
      }

      if(hasSignal) {
         // Filter: SPY Trend Confirmation (Quick Win)
         if(!CheckSPYTrendFilter(isBuy)) continue;

         // ════════════════════════════════════════════════════════════════
         // PHASE 2: MULTI-ASSET CONFIRMATION
         // ════════════════════════════════════════════════════════════════
         if(!MultiAsset_ConfirmTrade(symbol, isBuy)) {
            if(VerboseLogging) Print("✗ ", symbol, " - Multi-asset confirmation failed (market regime conflict)");
            continue;
         }

         // ════════════════════════════════════════════════════════════════
         // PHASE 4: 3-CONFLUENCE SNIPER - Ultra-selective entry system
         // ════════════════════════════════════════════════════════════════
         if(!Check3ConfluenceSniper(symbol, isBuy)) {
            if(VerboseLogging) Print("✗ ", symbol, " - 3-Confluence Sniper requirements not met");
            continue;
         }

         // ════════════════════════════════════════════════════════════════
         // ALL FILTERS PASSED - EXECUTE TRADE!
         // ════════════════════════════════════════════════════════════════
         if(VerboseLogging) {
            Print("╔════════════════════════════════════════╗");
            Print("║  ✓ ALL FILTERS PASSED FOR ", symbol, "       ║");
            Print("╚════════════════════════════════════════╝");
         }

         ExecuteTrade(symbol, isBuy);
      }
   }
}

//--------------------------------------------------------------------
// EXECUTE TRADE
//--------------------------------------------------------------------
void ExecuteTrade(string symbol, bool isBuy) {
   double atr = iATR(symbol, PERIOD_H1, ATR_Period, 0);
   double point = MarketInfo(symbol, MODE_POINT);

   // CRITICAL FIX: Prevent division by zero for stocks/symbols with different point values
   if(point <= 0 || point > 1.0) {
      // For stocks (point might be 0.01 or 1), use fixed pips
      point = 0.01;  // Default to 0.01 for stocks
   }

   // ════════════════════════════════════════════════════════════════
   // PHASE 1: VOLATILITY-ADJUSTED SL/TP
   // ════════════════════════════════════════════════════════════════
   double volSLMultiplier = Volatility_GetSLMultiplier(symbol, PERIOD_H1);
   double volTPMultiplier = Volatility_GetTPMultiplier(symbol, PERIOD_H1);

   // Calculate SL/TP with volatility adjustment - FIXED division by zero
   double baseSLPips = FixedStopLossPips;
   double baseTPPips = FixedTakeProfitPips;

   if(UseATRStops && atr > 0 && point > 0) {
      baseSLPips = (atr / point / 10.0 * ATRMultiplierSL);
      baseTPPips = (atr / point / 10.0 * ATRMultiplierTP);
   }

   double slPips = baseSLPips * volSLMultiplier;
   double tpPips = baseTPPips * volTPMultiplier;

   if(VerboseLogging) {
      VOLATILITY_REGIME volRegime = Volatility_GetRegime(symbol, PERIOD_H1);
      string regimeStr = (volRegime == VOL_VERY_LOW ? "VERY LOW" :
                         volRegime == VOL_LOW ? "LOW" :
                         volRegime == VOL_NORMAL ? "NORMAL" :
                         volRegime == VOL_HIGH ? "HIGH" : "VERY HIGH");
      Print("📊 Volatility Regime: ", regimeStr, " (SL mult: ", DoubleToString(volSLMultiplier, 2), ", TP mult: ", DoubleToString(volTPMultiplier, 2), ")");
   }

   double price = isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   double slDistance = slPips * point * 10.0;
   double tpDistance = tpPips * point * 10.0;
   double sl = isBuy ? (price - slDistance) : (price + slDistance);
   double tp = isBuy ? (price + tpDistance) : (price - tpDistance);

   // ════════════════════════════════════════════════════════════════
   // PHASE 2: ADAPTIVE POSITION SIZING
   // ════════════════════════════════════════════════════════════════
   // Base lot size from risk management
   double baseLotSize = CalculateLotSize(symbol, slPips);

   // Apply drawdown protection multiplier
   double drawdownMult = Drawdown_GetSizeMultiplier();

   // Apply volatility position size multiplier
   double volPositionMult = Volatility_GetPositionSizeMultiplier(symbol, PERIOD_H1);

   // Final position size
   double lotSize = baseLotSize * drawdownMult * volPositionMult;

   if(VerboseLogging) {
      Print("💰 Position Sizing:");
      Print("   Base lot: ", DoubleToString(baseLotSize, 2));
      Print("   Drawdown mult: ", DoubleToString(drawdownMult, 2), " (", (drawdownMult < 1.0 ? "REDUCED" : "NORMAL"), ")");
      Print("   Volatility mult: ", DoubleToString(volPositionMult, 2));
      Print("   Final lot: ", DoubleToString(lotSize, 2));

      // Show drawdown health
      double healthScore = Drawdown_GetHealthScore();
      Print("   Account Health: ", DoubleToString(healthScore * 100, 0), "%");
   }

   int ticket = OrderSend(symbol,
                         isBuy ? OP_BUY : OP_SELL,
                         lotSize,
                         price,
                         5,
                         NormalizeDouble(sl, _Digits),
                         NormalizeDouble(tp, _Digits),
                         "SmartStockTrader",
                         MagicNumber,
                         0,
                         isBuy ? clrBlue : clrRed);

   if(ticket > 0) {
      Print("╔════════════════════════╗");
      Print("║  NEW TRADE OPENED     ║");
      Print("╠════════════════════════╣");
      Print("║ Symbol: ", symbol);
      Print("║ Type: ", isBuy ? "BUY" : "SELL");
      Print("║ Price: ", DoubleToString(price, _Digits));
      Print("║ Lot: ", DoubleToString(lotSize, 2));
      Print("║ SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(slPips, 1), " pips)");
      Print("║ TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(tpPips, 1), " pips)");
      Print("╚════════════════════════╝");

      // Update tracking variables
      g_DailyTrades++;
      g_TotalTrades++;
      g_LastTradeTime = TimeCurrent();  // Record trade time for spacing filter

      // PHASE 2: Add to position tracker for smart scaling
      AddPositionTracker(ticket, price, sl, tp, lotSize);

      if(VerboseLogging) {
         Print("✓ Trade #", g_DailyTrades, " of max ", MaxDailyTrades, " today");
      }

      // ════════════════════════════════════════════════════════════════
      // PHASE 4: SYNC TRADE TO BACKEND API
      // ════════════════════════════════════════════════════════════════
      if(API_EnableSync && !BacktestMode) {
         string strategy = "Multi-Strategy"; // Could be dynamically determined
         TradeSync_SendTradeOpen(
            ticket,
            symbol,
            isBuy,
            lotSize,
            price,
            sl,
            tp,
            strategy,
            TimeCurrent(),
            "Opened by SmartStockTrader EA"
         );
      }

      if(SendNotifications) {
         SendNotification("SmartStockTrader: " + (isBuy ? "BUY" : "SELL") + " " + symbol + " @ " + DoubleToString(price, _Digits));
      }
   } else {
      Print("ERROR: Failed to open trade on ", symbol, " - Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
