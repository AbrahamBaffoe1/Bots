//+------------------------------------------------------------------+
//|                                                   SST_Config.mqh |
//|                         Smart Stock Trader - Configuration       |
//|                    All external parameters and global variables  |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------

//=== General Settings ===
extern string  Stocks                = "AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA,META,NFLX,AMD,PYPL";  // Comma-delimited stock list
extern int     MagicNumber           = 555777;       // Unique EA identifier
extern bool    EnableTrading         = true;         // Master on/off switch

//=== Risk Management ===
extern double  RiskPercentPerTrade   = 1.0;          // % risk per trade
extern double  MaxDailyLossPercent   = 5.0;          // Maximum daily drawdown %
extern int     MaxPositionsPerStock  = 1;            // Max simultaneous positions per symbol
extern int     MaxTotalPositions     = 10;           // Max total open positions
extern bool    UseAdaptivePosition   = true;         // Scale position size based on performance
extern double  WinStreakMultiplier   = 1.2;          // Increase size after wins
extern double  LoseStreakDivisor     = 1.5;          // Decrease size after losses
extern int     StreakThreshold       = 3;            // Number of consecutive wins/losses to trigger

//=== Trading Session Settings ===
extern bool    TradePreMarket        = true;         // Trade 4:00-9:30 AM EST
extern bool    TradeRegularHours     = true;         // Trade 9:30 AM-4:00 PM EST
extern bool    TradeAfterHours       = false;        // Trade 4:00-8:00 PM EST
extern bool    AvoidFirstMinutes     = true;         // Skip first 15 min of regular session
extern bool    AvoidLastMinutes      = true;         // Skip last 15 min of regular session
extern bool    CloseBeforeMarketClose= true;         // Close all positions before market close
extern int     MinutesBeforeClose    = 30;           // Minutes before close to exit positions
extern int     BrokerGMTOffset       = -5;           // EST = GMT-5

//=== Stop Loss & Take Profit ===
extern bool    UseATRStops           = true;         // Use ATR-based dynamic stops
extern double  ATRMultiplierSL       = 2.5;          // ATR multiplier for stop loss
extern double  ATRMultiplierTP       = 4.0;          // ATR multiplier for take profit
extern int     FixedStopLossPips     = 100;          // Fixed SL if not using ATR (in pips)
extern int     FixedTakeProfitPips   = 200;          // Fixed TP if not using ATR (in pips)

//=== Trailing Stop Settings ===
extern bool    UseTrailingStop       = true;         // Enable trailing stops
extern double  TrailingATRMultiplier = 2.0;          // ATR multiplier for trailing distance
extern int     TrailingStopPips      = 50;           // Fixed trailing distance (if not using ATR)

//=== Break-even & Partial Profits ===
extern bool    UseBreakEven          = true;         // Move SL to break-even
extern int     BreakEvenPips         = 50;           // Profit in pips to trigger BE
extern double  BreakEvenBufferPips   = 5.0;          // Buffer above/below entry

extern bool    UsePartialClose       = true;         // Enable partial profit taking
extern double  Partial1Percent       = 25.0;         // First partial close %
extern double  Partial1RR            = 1.0;          // R:R ratio for first partial
extern double  Partial2Percent       = 25.0;         // Second partial close %
extern double  Partial2RR            = 2.0;          // R:R ratio for second partial
extern double  Partial3Percent       = 25.0;         // Third partial close %
extern double  Partial3RR            = 3.0;          // R:R ratio for third partial

//=== Strategy Enables ===
extern bool    UseMomentumStrategy   = true;         // Momentum trading
extern bool    UseMeanReversion      = true;         // Mean reversion
extern bool    UseBreakoutStrategy   = true;         // Breakout trading
extern bool    UseTrendFollowing     = true;         // Trend following
extern bool    UseVolumeAnalysis     = true;         // Volume-based signals
extern bool    UseGapTrading         = true;         // Gap trading
extern bool    UseMultiTimeframe     = true;         // Multi-timeframe confirmation
extern bool    UseMarketRegime       = true;         // Regime-based strategy selection

//=== Technical Indicator Settings ===
extern int     FastMA_Period         = 10;           // Fast moving average
extern int     SlowMA_Period         = 50;           // Slow moving average
extern int     TrendMA_Period        = 200;          // Trend filter MA
extern int     RSI_Period            = 14;           // RSI period
extern int     RSI_Overbought        = 70;           // RSI overbought level
extern int     RSI_Oversold          = 30;           // RSI oversold level
extern int     MACD_Fast             = 12;           // MACD fast EMA
extern int     MACD_Slow             = 26;           // MACD slow EMA
extern int     MACD_Signal           = 9;            // MACD signal line
extern int     BB_Period             = 20;           // Bollinger Bands period
extern double  BB_Deviation          = 2.0;          // Bollinger Bands std dev
extern int     ATR_Period            = 14;           // ATR period
extern int     ADX_Period            = 14;           // ADX period
extern double  ADX_TrendThreshold    = 25.0;         // ADX level for trending market
extern int     Stoch_K               = 14;           // Stochastic %K
extern int     Stoch_D               = 3;            // Stochastic %D
extern int     Stoch_Slowing         = 3;            // Stochastic slowing
extern int     VolumeMA_Period       = 20;           // Volume MA period

//=== Multi-Timeframe Settings ===
extern int     MTF_Timeframe1        = PERIOD_M15;   // Primary timeframe
extern int     MTF_Timeframe2        = PERIOD_H1;    // Secondary timeframe
extern int     MTF_Timeframe3        = PERIOD_D1;    // Tertiary timeframe
extern int     MTF_MinConfluence     = 2;            // Minimum timeframes that must agree

//=== Pattern Recognition ===
extern bool    DetectCandlePatterns  = true;         // Enable candlestick patterns
extern bool    DetectChartPatterns   = true;         // Enable chart patterns
extern double  PatternMinConfidence  = 0.6;          // Minimum pattern confidence (0-1)
extern int     PatternLookback       = 50;           // Bars to look back for patterns

//=== Market Structure ===
extern bool    UseSupportResistance  = true;         // Use S/R levels
extern int     SR_Lookback           = 100;          // Bars to find S/R levels
extern double  SR_Strength           = 3;            // Minimum touches for valid S/R
extern bool    UseOrderBlocks        = true;         // Detect order blocks
extern bool    UseSupplyDemand       = true;         // Use supply/demand zones

//=== Filters ===
extern bool    UseSpreadFilter       = true;         // Filter by spread
extern double  MaxSpreadPips         = 10.0;         // Maximum acceptable spread
extern bool    UseVolatilityFilter   = true;         // Filter by volatility
extern double  MinATRValue           = 0.50;         // Minimum ATR value
extern bool    UseCorrelationFilter  = true;         // Avoid correlated positions
extern double  MaxCorrelation        = 0.80;         // Maximum allowed correlation
extern bool    UseNewsFilter         = false;        // Filter during news (requires API)
extern int     NewsAvoidMinutes      = 60;           // Minutes to avoid before/after news

//=== Volume Analysis ===
extern double  VolumeSpikeThreshold = 2.0;          // Volume must be X times average
extern bool    RequireVolumeConfirm  = true;         // Require volume confirmation for breakouts

//=== Gap Trading ===
extern double  MinGapPercent         = 0.5;          // Minimum gap % to trade
extern double  MaxGapPercent         = 5.0;          // Maximum gap % to avoid
extern bool    FadeGaps              = true;         // Fade gaps (mean reversion)
extern bool    FollowGaps            = true;         // Follow gaps (momentum)

//=== Recovery Mode ===
extern bool    UseRecoveryMode       = true;         // Reduce risk after losses
extern int     RecoveryAfterLosses   = 3;            // Consecutive losses to trigger
extern double  RecoveryRiskPercent   = 0.5;          // Reduced risk % in recovery

//=== Notifications & Logging ===
extern bool    SendNotifications     = true;         // Send push notifications
extern bool    LogToCSV              = true;         // Log trades to CSV
extern bool    ShowDashboard         = true;         // Display on-chart dashboard
extern bool    DebugMode             = false;        // Enable debug logging

//=== Backtesting & Optimization ===
extern bool    BacktestMode          = false;        // Enable backtest optimizations
extern bool    ShowBacktestStats     = true;         // Show detailed backtest stats

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------

// Stock symbols array
string g_Symbols[];
int g_SymbolCount = 0;

// Session management
datetime g_MarketOpenTime = 0;
datetime g_MarketCloseTime = 0;
bool g_IsMarketHours = false;

// Daily tracking
datetime g_DailyStartTime = 0;
double g_DailyStartEquity = 0;
double g_DailyProfit = 0;
int g_DailyTrades = 0;
int g_DailyWins = 0;
int g_DailyLosses = 0;

// Performance tracking
int g_ConsecutiveWins = 0;
int g_ConsecutiveLosses = 0;
double g_TotalProfit = 0;
double g_TotalLoss = 0;
int g_TotalTrades = 0;
int g_TotalWins = 0;
int g_TotalLosses = 0;
bool g_RecoveryModeActive = false;

// Trading state
enum EA_STATE {
   STATE_READY,
   STATE_SUSPENDED,
   STATE_RECOVERY,
   STATE_NEWS_PAUSE
};
EA_STATE g_EAState = STATE_READY;

// File handles
int g_LogFileHandle = INVALID_HANDLE;

// Trade tracking structure
struct TradeInfo {
   int ticket;
   string symbol;
   int orderType;
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

// Correlation matrix
struct CorrelationData {
   string sym1;
   string sym2;
   double correlation;
   datetime calculated;
};
CorrelationData g_CorrelationCache[];
int g_CorrelationCacheExpiry = 300;  // 5 minutes

// Market structure data
struct SupportResistance {
   string symbol;
   double level;
   int touches;
   datetime lastTouch;
   bool isSupport;
};
SupportResistance g_SRLevels[];

// Pattern detection
struct DetectedPattern {
   string symbol;
   string patternName;
   int timeframe;
   datetime detected;
   double confidence;
   bool isBullish;
   int barIndex;
};
DetectedPattern g_Patterns[];

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------

// Parse stock symbols from comma-delimited string
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

// Initialize configuration
void Config_Init() {
   g_SymbolCount = ParseSymbols(Stocks, g_Symbols);
   Print("Smart Stock Trader initialized with ", g_SymbolCount, " symbols");

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountEquity();

   ArrayResize(g_OpenTrades, 0);
   ArrayResize(g_CorrelationCache, 0);
   ArrayResize(g_SRLevels, 0);
   ArrayResize(g_Patterns, 0);
}

// Reset daily statistics
void Config_ResetDaily() {
   if(TimeDay(TimeCurrent()) != TimeDay(g_DailyStartTime)) {
      Print("New trading day - resetting daily statistics");
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountEquity();
      g_DailyProfit = 0;
      g_DailyTrades = 0;
      g_DailyWins = 0;
      g_DailyLosses = 0;

      // Reset EA state
      if(g_EAState == STATE_SUSPENDED) {
         g_EAState = STATE_READY;
         Print("Daily loss limit reset - resuming trading");
      }
   }
}

//+------------------------------------------------------------------+
