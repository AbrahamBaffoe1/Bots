//+------------------------------------------------------------------+
//|                          UltraFoolModeEA_Advanced.mq4            |
//|  A production–grade EA integrating advanced regime filtering,    |
//|  trend following, mean reversion, supply/demand zones, price     |
//|  action confirmation, correlation filtering, dynamic risk, and   |
//|  robust order management with trailing stops, break-even and     |
//|  partial closes.                                                 |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// External Parameters
//--------------------------------------------------------------------
extern string  Pairs                = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCHF";  // Comma-delimited list
extern double  RiskPercentPerTrade  = 1.0;       // % risk per trade
extern int     MagicNumber          = 987654;    // Unique EA identifier

// Session filtering
extern bool    UseMultiSession      = false;
extern int     Session1Start        = 8;
extern int     Session1End          = 12;
extern int     Session2Start        = 14;
extern int     Session2End          = 17;

// Primary Trend Indicators (H1 and M5)
extern int     H1_MA_Period         = 50;        // H1 SMA period (trend filter)
extern int     M5_MA_Period         = 10;        // M5 SMA period (entry timing)
extern int     RSI_Period           = 14;        // M5 RSI period

// ATR-Based Stops & Fixed SL/TP (in pips)
extern bool    UseAdaptiveStops     = true;
extern double  ATRMultiplierSL      = 2.0;
extern double  ATRMultiplierTP      = 3.0;
extern int     BaseStopLossPips     = 50;
extern int     BaseTakeProfitPips   = 100;

// Trailing Stop Settings
extern int     BaseTrailingStopPips = 20;        // initial trailing stop (pips)
extern int     AggressiveTrailPips  = 10;        // tighter trailing distance
extern double  AggressiveTrailTriggerRR = 2.0;     // if risk:reward ratio exceeds this, tighten

// Break-even Settings
extern int     BreakEvenPips        = 30;
extern double  BreakEvenBufferPips  = 2.0;

// Partial Close Settings (multi-level)
extern bool    UsePartialCloses     = true;
extern double  PartialClosePct1     = 30.0;      // Level 1: close 30%
extern double  PartialCloseRR1      = 1.5;       // Level 1 R:R threshold
extern double  PartialClosePct2     = 20.0;      // Level 2: close 20%
extern double  PartialCloseRR2      = 2.5;       // Level 2 R:R threshold

// News Filter Settings
extern bool    UseNewsFilter        = true;
extern string  NewsAPI_URL          = "https://api.tradingeconomics.com/calendar?c=guest:guest&f=json";
extern int     NewsImpactThreshold  = 3;
extern double  NewsLookAheadMinutes = 60.0;      // Skip if event is within X minutes
extern bool    SymbolSpecificNews   = true;        // Only skip if event relates to symbol’s currencies

// Additional Filters
extern bool    UseVolatilityFilter    = true;
extern double  ATR_VolatilityThreshold= 0.0010;    // Minimum acceptable ATR on M5
extern bool    UseMACDFilter          = true;      // MACD momentum filter
extern bool    UseBreakoutFilter      = false;     // Breakout confirmation filter
extern int     BreakoutBars           = 10;        // Lookback bars for breakout detection
extern double  MaxSpreadPips          = 5.0;       // Maximum acceptable spread (pips)

// Daily Drawdown Limit
extern double  DailyDrawdownLimitPct  = 5.0;       // Suspend trading if dd exceeds this %

 // Correlation Filter
extern bool    UseCorrelationFilter   = true;
extern double  CorrThreshold          = 0.8;       // Minimum correlation threshold

//--------------------------------------------------------------------
// Global Variables
//--------------------------------------------------------------------
string  CurrencyPairs[];
int     PairCount = 0;
int     logFileHandle = INVALID_HANDLE;  // Log file handle for CSV logging
datetime gDailyStartTime = 0;
double   gDailyStartEquity = 0;
datetime gLastNewsCheckTime = 0;         // For news API caching
bool     gNewsFilterActive = false;      // Cached news result
datetime gSafeModeStartTime = 0;         // Track when safe mode was activated

enum EA_STATE { EA_STATE_READY = 0, EA_STATE_SAFE_MODE, EA_STATE_SUSPENDED };
EA_STATE gEAState = EA_STATE_READY;

// Trade tracking structure for notifications and partial close management
struct TRADE_TRACKER
{
   int ticket;
   bool partialLevel0Done;
   bool partialLevel1Done;
};
TRADE_TRACKER trackedTrades[];

// Correlation cache structure
struct CORRELATION_CACHE
{
   string sym1;
   string sym2;
   double correlation;
   datetime timestamp;
};
CORRELATION_CACHE correlationCache[];
int gCorrelationCacheExpiry = 300;  // Cache expires after 5 minutes

//--------------------------------------------------------------------
// Forward Declarations
//--------------------------------------------------------------------
int RobustOrderSend(string sym, int cmd, double volume, double price, int slippage, double sl, double tp, string comment);

// Helper function to split pairs string
int SplitPairs(string str, string separator, string &result[])
{
   int pos = 0;
   int count = 0;
   string temp = str;

   ArrayResize(result, 0);

   // Simple string split using StringFind
   while(StringLen(temp) > 0)
   {
      int sepPos = StringFind(temp, separator, 0);
      if(sepPos < 0)
      {
         // No more separators, add remaining string
         if(StringLen(temp) > 0)
         {
            ArrayResize(result, count + 1);
            result[count] = temp;
            count++;
         }
         break;
      }
      else
      {
         // Found separator
         string part = StringSubstr(temp, 0, sepPos);
         if(StringLen(part) > 0)
         {
            ArrayResize(result, count + 1);
            result[count] = part;
            count++;
         }
         temp = StringSubstr(temp, sepPos + StringLen(separator));
      }
   }

   return count;
}

//--------------------------------------------------------------------
// SECTION 1: LOGGING & NOTIFICATIONS
//--------------------------------------------------------------------
void OpenLogFile()
{
   if(logFileHandle == INVALID_HANDLE)
   {
      string fname = "UltraFoolModeEA_Log_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
      logFileHandle = FileOpen(fname, FILE_CSV | FILE_WRITE, ',');
      if(logFileHandle != INVALID_HANDLE)
      {
         FileWrite(logFileHandle, "Ticket", "Dir", "OpenTime", "OpenPrice", "CloseTime", "ClosePrice", "Pips", "Profit", "Comment");
         FileFlush(logFileHandle);
      }
      else
         Print("Error opening log file: ", GetLastError());
   }
}

void LogTrade(int ticket, string direction, datetime openT, double openP,
              datetime closeT, double closeP, string comment = "")
{
   OpenLogFile();
   if(logFileHandle == INVALID_HANDLE) return;

   // Get actual profit if order is closed
   double profit = 0;
   double pips = 0;
   if(OrderSelect(ticket, SELECT_BY_TICKET))
   {
      profit = OrderProfit() + OrderSwap() + OrderCommission();
      double pipVal = MarketInfo(OrderSymbol(), MODE_POINT);
      if(closeP > 0 && openP > 0 && pipVal > 0)
      {
         pips = (closeP - openP) / pipVal;
         if(direction == "SELL") pips = -pips;
      }
   }

   string row = IntegerToString(ticket) + "," + direction + "," +
                TimeToString(openT, TIME_DATE|TIME_MINUTES) + "," +
                DoubleToString(openP, _Digits) + "," +
                TimeToString(closeT, TIME_DATE|TIME_MINUTES) + "," +
                DoubleToString(closeP, _Digits) + "," +
                DoubleToString(pips, 1) + "," +
                DoubleToString(profit, 2) + "," + comment;
   FileWriteString(logFileHandle, row + "\r\n");
   FileFlush(logFileHandle);
}

void Notify(string msg)
{
   SendNotification(msg);
}

// Add trade to tracking system
void TrackNewTrade(int ticket)
{
   TRADE_TRACKER tt;
   tt.ticket = ticket;
   tt.partialLevel0Done = false;
   tt.partialLevel1Done = false;
   int sz = ArraySize(trackedTrades);
   ArrayResize(trackedTrades, sz + 1);
   trackedTrades[sz] = tt;
}

// Remove trade from tracking system
void UntrackTrade(int ticket)
{
   for(int i = 0; i < ArraySize(trackedTrades); i++)
   {
      if(trackedTrades[i].ticket == ticket)
      {
         for(int j = i; j < ArraySize(trackedTrades) - 1; j++)
            trackedTrades[j] = trackedTrades[j + 1];
         ArrayResize(trackedTrades, ArraySize(trackedTrades) - 1);
         break;
      }
   }
}

// Get trade tracker reference
int GetTradeTrackerIndex(int ticket)
{
   for(int i = 0; i < ArraySize(trackedTrades); i++)
   {
      if(trackedTrades[i].ticket == ticket)
         return i;
   }
   return -1;
}

// Clean up tracked trades that no longer exist (manually closed)
void CleanupStaleTrackedTrades()
{
   for(int i = ArraySize(trackedTrades) - 1; i >= 0; i--)
   {
      bool found = false;
      for(int j = 0; j < OrdersTotal(); j++)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderTicket() == trackedTrades[i].ticket && OrderMagicNumber() == MagicNumber)
            {
               found = true;
               break;
            }
         }
      }
      if(!found)
      {
         // Trade was closed (manually or by SL/TP) - remove from tracking
         Print("Removing stale tracked trade: ", trackedTrades[i].ticket);
         for(int k = i; k < ArraySize(trackedTrades) - 1; k++)
            trackedTrades[k] = trackedTrades[k + 1];
         ArrayResize(trackedTrades, ArraySize(trackedTrades) - 1);
      }
   }
}

//--------------------------------------------------------------------
// SECTION 2: SESSION & DAILY DRAWDOWN MANAGEMENT
//--------------------------------------------------------------------
bool InSession(datetime tm, int startH, int endH)
{
   int h = TimeHour(tm);
   return (h >= startH && h < endH);
}

bool IsTradingSessionActive()
{
   if(!UseMultiSession)
      return true;
   datetime nowT = TimeCurrent();
   if(InSession(nowT, Session1Start, Session1End)) return true;
   if(InSession(nowT, Session2Start, Session2End)) return true;
   return false;
}

bool CheckDailyDrawdown()
{
   double eq = AccountEquity();
   double dd = (gDailyStartEquity - eq) / gDailyStartEquity * 100.0;
   if(dd >= DailyDrawdownLimitPct)
   {
      gEAState = EA_STATE_SUSPENDED;
      Notify("EA suspended: daily drawdown = " + DoubleToString(dd, 1) + "%");
      return true;
   }
   return false;
}

void ResetDailyEquityIfNewDay()
{
   if(gDailyStartTime == 0)
   {
      gDailyStartTime = TimeCurrent();
      gDailyStartEquity = AccountEquity();
      return;
   }
   if(TimeDay(TimeCurrent()) != TimeDay(gDailyStartTime))
   {
      gDailyStartTime = TimeCurrent();
      gDailyStartEquity = AccountEquity();
      Print("New day: daily equity baseline reset to ", gDailyStartEquity);
   }
}

//--------------------------------------------------------------------
// SECTION 3: CORRELATION FILTERING
//--------------------------------------------------------------------
double CalculateSymbolCorrelation(string sym1, string sym2, int period = 200)
{
   // MQL4 compatible implementation using iClose()
   double arr1[], arr2[];
   ArrayResize(arr1, period);
   ArrayResize(arr2, period);

   // Fill arrays with close prices
   for(int i = 0; i < period; i++)
   {
      arr1[i] = iClose(sym1, PERIOD_M5, i);
      arr2[i] = iClose(sym2, PERIOD_M5, i);
      if(arr1[i] == 0 || arr2[i] == 0) return 0;  // Data not available
   }

   int n = period - 1;
   double changes1[], changes2[];
   ArrayResize(changes1, n);
   ArrayResize(changes2, n);
   double mean1 = 0, mean2 = 0;

   for(int i = 0; i < n; i++)
   {
      changes1[i] = arr1[i] - arr1[i+1];
      changes2[i] = arr2[i] - arr2[i+1];
      mean1 += changes1[i];
      mean2 += changes2[i];
   }
   mean1 /= n;
   mean2 /= n;

   double num = 0, den1 = 0, den2 = 0;
   for(int i = 0; i < n; i++)
   {
      double d1 = changes1[i] - mean1;
      double d2 = changes2[i] - mean2;
      num += d1 * d2;
      den1 += d1 * d1;
      den2 += d2 * d2;
   }

   double corr = 0;
   if(den1 > 0 && den2 > 0)
      corr = num / MathSqrt(den1 * den2);
   return corr;
}

// Get cached correlation or calculate new one
double GetCachedCorrelation(string sym1, string sym2)
{
   // Check cache first
   for(int i = 0; i < ArraySize(correlationCache); i++)
   {
      if((correlationCache[i].sym1 == sym1 && correlationCache[i].sym2 == sym2) ||
         (correlationCache[i].sym1 == sym2 && correlationCache[i].sym2 == sym1))
      {
         // Check if cache is still valid
         if(TimeCurrent() - correlationCache[i].timestamp < gCorrelationCacheExpiry)
            return correlationCache[i].correlation;
      }
   }

   // Calculate new correlation
   double corr = CalculateSymbolCorrelation(sym1, sym2, 100);

   // Add to cache
   CORRELATION_CACHE cc;
   cc.sym1 = sym1;
   cc.sym2 = sym2;
   cc.correlation = corr;
   cc.timestamp = TimeCurrent();
   int sz = ArraySize(correlationCache);
   ArrayResize(correlationCache, sz + 1);
   correlationCache[sz] = cc;

   return corr;
}

bool CheckCorrelationOpposite(string sym, int cmd)
{
   if(!UseCorrelationFilter)
      return false;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber)
         {
            string osym = OrderSymbol();
            int ocmd = OrderType();
            if(osym == sym)
               continue;
            double cor = GetCachedCorrelation(sym, osym);
            if(MathAbs(cor) > CorrThreshold)
            {
               bool opposite = ((cmd == OP_BUY && ocmd == OP_SELL) || (cmd == OP_SELL && ocmd == OP_BUY));
               if(opposite && cor > 0)
               {
                  Print("Correlation check: skipping ", sym, " due to ", osym, " (corr=", cor, ")");
                  return true;
               }
            }
         }
      }
   }
   return false;
}

//--------------------------------------------------------------------
// SECTION 4: ROBUST ORDER MANAGEMENT
//--------------------------------------------------------------------
int RobustOrderSend(string sym, int cmd, double volume, double price, int slippage, double sl, double tp, string comment)
{
   int ticket = -1;
   for(int attempt = 0; attempt < 3; attempt++)  // using RetryMax = 3
   {
      ticket = OrderSend(sym, cmd, volume, price, slippage, sl, tp, comment, MagicNumber, 0, clrBlue);
      if(ticket >= 0)
      {
         Print("OrderSend succeeded on attempt ", attempt + 1, "; ticket=", ticket);
         return ticket;
      }
      else
      {
         int err = GetLastError();
         Print("OrderSend error on attempt ", attempt + 1, "; error code=", err);
         Sleep(1000);
         RefreshRates();
      }
   }
   return ticket;
}

bool RobustOrderModify(int ticket, double openPrice, double stoploss, double takeprofit)
{
   for(int attempt = 0; attempt < 3; attempt++)
   {
      if(OrderModify(ticket, openPrice, stoploss, takeprofit, 0, clrYellow))
         return true;
      else
      {
         int err = GetLastError();
         Print("OrderModify error on attempt ", attempt + 1, "; error code=", err);
         Sleep(500);
         RefreshRates();
      }
   }
   return false;
}

//--------------------------------------------------------------------
// SECTION 5: ADVANCED STRATEGY MODULES
//--------------------------------------------------------------------

// 5.1 Market Regime Filtering using ADX on H1
int GetMarketRegime(string sym)
{
   double adx = iADX(sym, PERIOD_H1, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double atr = iATR(sym, PERIOD_H1, 14, 0);
   // If ADX is high and ATR is moderately high, consider it trending.
   if(adx >= 25 && atr > 0.0010)
      return 1;  // Trend
   return 2;      // Range
}

// 5.2 Supply/Demand Zone using previous daily pivot
bool CheckSupplyDemandZone(string sym, double price)
{
   // MQL4 compatible implementation
   double high = iHigh(sym, PERIOD_D1, 1);
   double low = iLow(sym, PERIOD_D1, 1);
   double close = iClose(sym, PERIOD_D1, 1);

   if(high == 0 || low == 0 || close == 0) return false;

   double pivot = (high + low + close) / 3.0;
   double threshold = (high - low) * 0.1;
   return (MathAbs(price - pivot) <= threshold);
}

// 5.3 Mean Reversion Strategy using Bollinger Bands and RSI on M5
bool CheckMeanReversionBuySignal(string sym, double &slDist, double &tpDist)
{
   double lowerBand = iBands(sym, PERIOD_M5, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double price = iClose(sym, PERIOD_M5, 0);
   double rsi = iRSI(sym, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(price <= lowerBand && rsi < 30)
   {
      if(UseAdaptiveStops)
      {
         double atrVal = iATR(sym, PERIOD_M5, 14, 0);
         double pip = MarketInfo(sym, MODE_POINT);
         slDist = ATRMultiplierSL * (atrVal / pip);
         tpDist = ATRMultiplierTP * (atrVal / pip);
      }
      else
      {
         slDist = BaseStopLossPips;
         tpDist = BaseTakeProfitPips;
      }
      return true;
   }
   return false;
}

bool CheckMeanReversionSellSignal(string sym, double &slDist, double &tpDist)
{
   double upperBand = iBands(sym, PERIOD_M5, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double price = iClose(sym, PERIOD_M5, 0);
   double rsi = iRSI(sym, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(price >= upperBand && rsi > 70)
   {
      if(UseAdaptiveStops)
      {
         double atrVal = iATR(sym, PERIOD_M5, 14, 0);
         double pip = MarketInfo(sym, MODE_POINT);
         slDist = ATRMultiplierSL * (atrVal / pip);
         tpDist = ATRMultiplierTP * (atrVal / pip);
      }
      else
      {
         slDist = BaseStopLossPips;
         tpDist = BaseTakeProfitPips;
      }
      return true;
   }
   return false;
}

// 5.4 Price Action Confirmation (Pin Bar Detection)
bool CheckPriceActionConfirmation(string sym, bool isBuy)
{
   // MQL4 compatible implementation
   double open = iOpen(sym, PERIOD_M5, 1);
   double high = iHigh(sym, PERIOD_M5, 1);
   double low = iLow(sym, PERIOD_M5, 1);
   double close = iClose(sym, PERIOD_M5, 1);

   if(open == 0 || high == 0 || low == 0 || close == 0) return false;

   double body = MathAbs(close - open);
   double range = high - low;
   if(range == 0) return false;

   double lowerShadow = MathMin(open, close) - low;
   double upperShadow = high - MathMax(open, close);

   if(isBuy)
   {
      if(body < 0.3 * range && lowerShadow > 2 * body && upperShadow < 0.1 * range)
         return true;
   }
   else
   {
      if(body < 0.3 * range && upperShadow > 2 * body && lowerShadow < 0.1 * range)
         return true;
   }
   return false;
}

// 5.5 Breakout Filter Strategy
bool CheckBreakoutFilter(string sym, bool isBuy, int lookbackBars = 10)
{
   double cClose = iClose(sym, PERIOD_M5, 0);
   double extreme = (isBuy ? -1e10 : 1e10);
   for(int i = 1; i <= lookbackBars; i++)
   {
      if(isBuy)
      {
         double h = iHigh(sym, PERIOD_M5, i);
         if(h > extreme) extreme = h;
      }
      else
      {
         double l = iLow(sym, PERIOD_M5, i);
         if(l < extreme) extreme = l;
      }
   }
   if(isBuy && cClose > extreme) return true;
   if(!isBuy && cClose < extreme) return true;
   return false;
}

// 5.6 MACD Filter Functions
bool CheckMACDBuy(string sym)
{
   double mc = iMACD(sym, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double mp = iMACD(sym, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (mc > mp && mc > 0);
}

bool CheckMACDSell(string sym)
{
   double mc = iMACD(sym, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double mp = iMACD(sym, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (mc < mp && mc < 0);
}

// 5.7 Trend-Following Buy Signal (for trending markets)
bool CheckBuySignal(string sym, double &slDist, double &tpDist)
{
   // H1 trend filter: price must be above H1 MA
   double h1c = iClose(sym, PERIOD_H1, 0);
   double h1ma = iMA(sym, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   if(h1c <= h1ma) return false;

   // M5 MA crossover: previous close below MA, current close above MA
   double cM5 = iClose(sym, PERIOD_M5, 0);
   double pM5 = iClose(sym, PERIOD_M5, 1);
   double maC = iMA(sym, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maP = iMA(sym, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5 < maP && cM5 > maC)) return false;

   // RSI confirmation: must be above 50 for buy
   double rsi = iRSI(sym, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi <= 50) return false;

   // Volatility filter
   if(UseVolatilityFilter)
   {
      double atr = iATR(sym, PERIOD_M5, 14, 0);
      if(atr < ATR_VolatilityThreshold) return false;
   }

   // Spread filter
   double spreadPts = MarketInfo(sym, MODE_SPREAD);
   double pip = MarketInfo(sym, MODE_POINT);
   double spreadPips = spreadPts * pip / (pip * 10);  // Convert points to pips
   if(spreadPips > MaxSpreadPips) return false;

   // MACD filter
   if(UseMACDFilter && !CheckMACDBuy(sym)) return false;

   // Breakout filter
   if(UseBreakoutFilter && !CheckBreakoutFilter(sym, true, BreakoutBars)) return false;

   // Calculate SL/TP distances
   if(UseAdaptiveStops)
   {
      double atrVal = iATR(sym, PERIOD_M5, 14, 0);
      slDist = ATRMultiplierSL * (atrVal / pip);
      tpDist = ATRMultiplierTP * (atrVal / pip);
   }
   else
   {
      slDist = BaseStopLossPips;
      tpDist = BaseTakeProfitPips;
   }
   return true;
}

// 5.8 Trend-Following Sell Signal (for trending markets)
bool CheckSellSignal(string sym, double &slDist, double &tpDist)
{
   // H1 trend filter: price must be below H1 MA
   double h1c = iClose(sym, PERIOD_H1, 0);
   double h1ma = iMA(sym, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   if(h1c >= h1ma) return false;

   // M5 MA crossover: previous close above MA, current close below MA
   double cM5 = iClose(sym, PERIOD_M5, 0);
   double pM5 = iClose(sym, PERIOD_M5, 1);
   double maC = iMA(sym, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maP = iMA(sym, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5 > maP && cM5 < maC)) return false;

   // RSI confirmation: must be below 50 for sell
   double rsi = iRSI(sym, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi >= 50) return false;

   // Volatility filter
   if(UseVolatilityFilter)
   {
      double atr = iATR(sym, PERIOD_M5, 14, 0);
      if(atr < ATR_VolatilityThreshold) return false;
   }

   // Spread filter
   double spreadPts = MarketInfo(sym, MODE_SPREAD);
   double pip = MarketInfo(sym, MODE_POINT);
   double spreadPips = spreadPts * pip / (pip * 10);  // Convert points to pips
   if(spreadPips > MaxSpreadPips) return false;

   // MACD filter
   if(UseMACDFilter && !CheckMACDSell(sym)) return false;

   // Breakout filter
   if(UseBreakoutFilter && !CheckBreakoutFilter(sym, false, BreakoutBars)) return false;

   // Calculate SL/TP distances
   if(UseAdaptiveStops)
   {
      double atrVal = iATR(sym, PERIOD_M5, 14, 0);
      slDist = ATRMultiplierSL * (atrVal / pip);
      tpDist = ATRMultiplierTP * (atrVal / pip);
   }
   else
   {
      slDist = BaseStopLossPips;
      tpDist = BaseTakeProfitPips;
   }
   return true;
}

//--------------------------------------------------------------------
// SECTION 6: DYNAMIC POSITION SIZING
//--------------------------------------------------------------------
double CalculateLotSize(string sym, double slDistPips)
{
   double accBal = AccountBalance();
   double riskAmt = accBal * (RiskPercentPerTrade / 100.0);
   double tickVal = MarketInfo(sym, MODE_TICKVALUE);
   double tickSize = MarketInfo(sym, MODE_TICKSIZE);
   if(tickSize <= 0) tickSize = 0.00001;
   double pipVal = (tickVal * (MarketInfo(sym, MODE_POINT) / tickSize) * 10.0);
   if(pipVal <= 0) pipVal = 10.0;
   double costPerTrade = slDistPips * pipVal;
   if(costPerTrade <= 0) costPerTrade = 1;
   double rawLots = riskAmt / costPerTrade;
   double step = MarketInfo(sym, MODE_LOTSTEP);
   double minLot = MarketInfo(sym, MODE_MINLOT);
   double maxLot = MarketInfo(sym, MODE_MAXLOT);
   rawLots = MathFloor(rawLots / step) * step;
   if(rawLots < minLot) rawLots = minLot;
   if(rawLots > maxLot) rawLots = maxLot;
   return NormalizeDouble(rawLots, 2);
}

//--------------------------------------------------------------------
// SECTION 7: NEWS FILTERING (Symbol-Specific)
//--------------------------------------------------------------------
bool ParseNewsForSymbol(string text, string sym)
{
   string cur1 = StringSubstr(sym, 0, 3);
   string cur2 = StringSubstr(sym, 3, 3);
   int pos = 0;
   while(true)
   {
      int dtPos = StringFind(text, "\"DateTime\":\"", pos);
      if(dtPos < 0) break;
      dtPos += StringLen("\"DateTime\":\"");
      int dtEnd = StringFind(text, "\"", dtPos);
      if(dtEnd < 0) break;
      string dtStr = StringSubstr(text, dtPos, dtEnd - dtPos);
      datetime eTime = StrToTime(dtStr);
      
      int impPos = StringFind(text, "\"Impact\":\"", dtEnd);
      if(impPos < 0) break;
      impPos += StringLen("\"Impact\":\"");
      int impEnd = StringFind(text, "\"", impPos);
      if(impEnd < 0) break;
      string impStr = StringSubstr(text, impPos, impEnd - impPos);
      int impVal = (int)StringToInteger(impStr);
      
      int curPos = StringFind(text, "\"Country\":\"", dtEnd);
      if(curPos < 0) break;
      curPos += StringLen("\"Country\":\"");
      int curEnd = StringFind(text, "\"", curPos);
      if(curEnd < 0) break;
      string cStr = StringSubstr(text, curPos, curEnd - curPos);
      
      if(eTime > 0 && impVal >= NewsImpactThreshold)
      {
         double minutesAway = MathAbs((eTime - TimeCurrent()) / 60.0);
         if(minutesAway <= NewsLookAheadMinutes)
         {
            if(!SymbolSpecificNews)
               return true;
            // MQL4 compatible: Use StringToUpper
            string upC = cStr;
            StringToUpper(upC);
            string upCur1 = cur1;
            StringToUpper(upCur1);
            string upCur2 = cur2;
            StringToUpper(upCur2);
            if(upCur1 == upC || upCur2 == upC)
               return true;
         }
      }
      pos = curEnd + 1;
   }
   return false;
}

bool IsMajorNewsTimeForSymbol(string sym)
{
   if(!UseNewsFilter)
      return false;

   // Use cached result if recent (60 seconds)
   if(TimeCurrent() - gLastNewsCheckTime < 60)
      return gNewsFilterActive;

   string hdr = "Content-Type: application/json\r\n";
   char req[], resp[];
   string respHdr;
   int r = WebRequest("GET", NewsAPI_URL, hdr, 5000, req, resp, respHdr);
   if(r < 0)
   {
      Print("News API error for ", sym, "; error code=", GetLastError());
      return false;
   }
   string json = CharArrayToString(resp, 0, ArraySize(resp));
   gNewsFilterActive = ParseNewsForSymbol(json, sym);
   gLastNewsCheckTime = TimeCurrent();
   return gNewsFilterActive;
}

//--------------------------------------------------------------------
// SECTION 8: MANAGE OPEN TRADES (TRAILING, BREAK-EVEN, PARTIAL CLOSES)
//--------------------------------------------------------------------
void ManageOpenTrades()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber)
         continue;
      
      string sym = OrderSymbol();
      double bid = MarketInfo(sym, MODE_BID);
      double ask = MarketInfo(sym, MODE_ASK);
      double pip = MarketInfo(sym, MODE_POINT);
      double sl = OrderStopLoss();
      double newSL;
      double trailingDist = BaseTrailingStopPips;
      if(UseAdaptiveStops)
      {
         double a = iATR(sym, PERIOD_M5, 14, 0);
         trailingDist = 1.5 * (a / pip);
      }
      double currentPrice = (OrderType() == OP_BUY ? bid : ask);
      
      // Trailing Stop Adjustment
      if(OrderType() == OP_BUY)
      {
         newSL = NormalizeDouble(currentPrice - trailingDist * pip, _Digits);
         if(newSL > sl && sl > 0)
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      else if(OrderType() == OP_SELL)
      {
         newSL = NormalizeDouble(currentPrice + trailingDist * pip, _Digits);
         if((sl == 0 || newSL < sl) && newSL > 0)
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      
      // Break-even Adjustment (buffer is on the safe side of entry)
      double profitPips = (OrderType() == OP_BUY ? (bid - OrderOpenPrice()) : (OrderOpenPrice() - ask)) / pip;
      if(profitPips >= BreakEvenPips)
      {
         // For BUY: BE is entry + buffer (slightly in profit)
         // For SELL: BE is entry - buffer (slightly in profit)
         double beSL = NormalizeDouble(OrderOpenPrice() + ((OrderType() == OP_BUY ? 1 : -1) * BreakEvenBufferPips * pip), _Digits);
         if(OrderType() == OP_BUY)
         {
            if(OrderStopLoss() == 0 || beSL > OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
         else
         {
            if(OrderStopLoss() == 0 || beSL < OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
      }
      
      // Multi-Level Partial Closes with proper tracking and error handling
      if(UsePartialCloses && OrderLots() > 0.01)
      {
         int tIdx = GetTradeTrackerIndex(OrderTicket());
         if(tIdx >= 0)
         {
            double sldist = (OrderType() == OP_BUY ? (OrderOpenPrice() - OrderStopLoss()) : (OrderStopLoss() - OrderOpenPrice())) / pip;
            if(sldist <= 0)
               sldist = BaseStopLossPips;
            double rr = profitPips / sldist;

            // Check level 0
            if(!trackedTrades[tIdx].partialLevel0Done && rr >= PartialCloseRR1)
            {
               double pcVol = NormalizeDouble(OrderLots() * (PartialClosePct1 / 100.0), 2);
               if(pcVol >= 0.01 && pcVol <= OrderLots())
               {
                  double cPrice = (OrderType() == OP_BUY ? bid : ask);
                  if(OrderClose(OrderTicket(), pcVol, cPrice, 3, clrAqua))
                  {
                     trackedTrades[tIdx].partialLevel0Done = true;
                     LogTrade(OrderTicket(), (OrderType() == OP_BUY ? "BUY" : "SELL"),
                        OrderOpenTime(), OrderOpenPrice(), TimeCurrent(), cPrice,
                        "PartialClose lvl #1");
                     Notify("PartialClose lvl #1 => ticket=" + IntegerToString(OrderTicket()) +
                            " @ R:R=" + DoubleToString(rr, 1));
                  }
                  else
                  {
                     Print("Partial close level 1 failed for ticket ", OrderTicket(), "; Error: ", GetLastError());
                  }
               }
            }

            // Check level 1
            if(!trackedTrades[tIdx].partialLevel1Done && rr >= PartialCloseRR2)
            {
               double pcVol = NormalizeDouble(OrderLots() * (PartialClosePct2 / 100.0), 2);
               if(pcVol >= 0.01 && pcVol <= OrderLots())
               {
                  double cPrice = (OrderType() == OP_BUY ? bid : ask);
                  if(OrderClose(OrderTicket(), pcVol, cPrice, 3, clrAqua))
                  {
                     trackedTrades[tIdx].partialLevel1Done = true;
                     LogTrade(OrderTicket(), (OrderType() == OP_BUY ? "BUY" : "SELL"),
                        OrderOpenTime(), OrderOpenPrice(), TimeCurrent(), cPrice,
                        "PartialClose lvl #2");
                     Notify("PartialClose lvl #2 => ticket=" + IntegerToString(OrderTicket()) +
                            " @ R:R=" + DoubleToString(rr, 1));
                  }
                  else
                  {
                     Print("Partial close level 2 failed for ticket ", OrderTicket(), "; Error: ", GetLastError());
                  }
               }
            }
         }
      }
      
      // Aggressive (Second-Tier) Trailing
      if(AggressiveTrailTriggerRR > 0)
      {
         double sld = (OrderType() == OP_BUY ? (OrderOpenPrice() - OrderStopLoss()) : (OrderStopLoss() - OrderOpenPrice())) / pip;
         if(sld < 0)
            sld = BaseStopLossPips;
         double rrr = profitPips / sld;
         if(rrr >= AggressiveTrailTriggerRR)
         {
            double newTrail = AggressiveTrailPips;
            if(UseAdaptiveStops)
            {
               double a2 = iATR(sym, PERIOD_M5, 14, 0);
               newTrail = MathMin(newTrail, (1.0) * (a2 / pip));
            }
            if(OrderType() == OP_BUY)
            {
               double advSL = NormalizeDouble(currentPrice - newTrail * pip, _Digits);
               if(advSL > sl)
                  RobustOrderModify(OrderTicket(), OrderOpenPrice(), advSL, OrderTakeProfit());
            }
            else
            {
               double advSL = NormalizeDouble(currentPrice + newTrail * pip, _Digits);
               if((sl == 0 || advSL < sl) && advSL > 0)
                  RobustOrderModify(OrderTicket(), OrderOpenPrice(), advSL, OrderTakeProfit());
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// SECTION 9: ON-CHART DASHBOARD & LOGGING
//--------------------------------------------------------------------
void UpdateDashboard()
{
   string stateStr = "READY";
   color stateColor = clrLime;
   if(gEAState == EA_STATE_SAFE_MODE)
   {
      stateStr = "SAFE MODE";
      stateColor = clrYellow;
   }
   else if(gEAState == EA_STATE_SUSPENDED)
   {
      stateStr = "SUSPENDED";
      stateColor = clrRed;
   }

   string dash = "=== UltraFoolModeEA ===\n";
   dash += "State: " + stateStr + "\n";
   dash += "Account: $" + DoubleToString(AccountEquity(), 2) + "\n";
   dash += "Daily Start: $" + DoubleToString(gDailyStartEquity, 2) + "\n";
   double dailyPL = AccountEquity() - gDailyStartEquity;
   dash += "Daily P/L: " + (dailyPL >= 0 ? "+" : "") + DoubleToString(dailyPL, 2) + "\n";
   dash += "Open Trades: " + IntegerToString(OrdersTotal()) + "\n";
   dash += "Tracked: " + IntegerToString(ArraySize(trackedTrades)) + "\n";
   dash += "Pairs: " + IntegerToString(PairCount) + "\n";
   dash += "Filters: V:" + (UseVolatilityFilter ? "Y" : "N") +
           " M:" + (UseMACDFilter ? "Y" : "N") +
           " N:" + (UseNewsFilter ? "Y" : "N") +
           " C:" + (UseCorrelationFilter ? "Y" : "N") + "\n";
   dash += "Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   if(ObjectFind(0, "UltraFoolDashboard") < 0)
   {
      ObjectCreate(0, "UltraFoolDashboard", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, "UltraFoolDashboard", OBJPROP_FONT, "Courier New");
   }
   ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_COLOR, stateColor);
   ObjectSetString(0, "UltraFoolDashboard", OBJPROP_TEXT, dash);
}

//--------------------------------------------------------------------
// SECTION 10: ONINIT and ONDEINIT FUNCTIONS
//--------------------------------------------------------------------
int OnInit()
{
   Print("=== UltraFoolModeEA_Advanced init => starting initialization ===");
   PairCount = SplitPairs(Pairs, ",", CurrencyPairs);
   Print("Detected ", PairCount, " pairs: ", Pairs);

   gDailyStartTime = TimeCurrent();
   gDailyStartEquity = AccountEquity();
   Print("Daily equity baseline set to ", gDailyStartEquity);

   // Track existing open orders (in case EA was restarted)
   int existingOrders = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber)
         {
            TrackNewTrade(OrderTicket());
            existingOrders++;
         }
      }
   }
   if(existingOrders > 0)
      Print("Tracked ", existingOrders, " existing open orders");

   Print("=== UltraFoolModeEA initialization complete ===");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("UltraFoolModeEA_Advanced deinit => closing log and removing dashboard");
   if(logFileHandle != INVALID_HANDLE)
      FileClose(logFileHandle);
   ObjectDelete(0, "UltraFoolDashboard");
}

//--------------------------------------------------------------------
// SECTION 11: MAIN ONTICK FUNCTION
//--------------------------------------------------------------------
void OnTick()
{
   ResetDailyEquityIfNewDay();

   // Clean up stale tracked trades (manually closed, etc.)
   CleanupStaleTrackedTrades();

   if(CheckDailyDrawdown())
   {
      ManageOpenTrades();
      UpdateDashboard();
      return;
   }

   // Safe mode recovery: Exit safe mode if no news for 2 hours
   if(gEAState == EA_STATE_SAFE_MODE)
   {
      if(TimeCurrent() - gSafeModeStartTime > 7200)  // 2 hours
      {
         gEAState = EA_STATE_READY;
         Print("Safe mode timeout - returning to READY state");
         Notify("EA exited safe mode - resuming trading");
      }
      ManageOpenTrades();
      UpdateDashboard();
      return;
   }

   if(gEAState == EA_STATE_SUSPENDED)
   {
      ManageOpenTrades();
      UpdateDashboard();
      return;
   }

   if(!IsTradingSessionActive())
      return;

   RefreshRates();
   
   // Loop through each currency pair
   for(int i = 0; i < PairCount; i++)
   {
      string sym = CurrencyPairs[i];
      if(MarketInfo(sym, MODE_SPREAD) <= 0)
         continue;
      
      // Skip if there's already an open order on this symbol
      int openCount = 0;
      for(int j = 0; j < OrdersTotal(); j++)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == sym && OrderMagicNumber() == MagicNumber)
               openCount++;
         }
      }
      if(openCount > 0)
         continue;
      
      // Check news filter and enter safe mode if needed
      if(UseNewsFilter)
      {
         if(IsMajorNewsTimeForSymbol(sym))
         {
            if(gEAState != EA_STATE_SAFE_MODE)
            {
               gEAState = EA_STATE_SAFE_MODE;
               gSafeModeStartTime = TimeCurrent();
               Print("High-impact news detected - entering SAFE MODE");
               Notify("EA entered safe mode due to major news event");
            }
            Print("Skipping ", sym, " due to imminent major news");
            continue;
         }
      }
      
      // Determine market regime using ADX on H1
      int regime = GetMarketRegime(sym);  // 1 = Trend, 2 = Range

      // Initialize signal variables
      double slDist = 0, tpDist = 0;
      bool techBuy = false, techSell = false;
      bool mrBuy = false, mrSell = false;
      bool paBuy = false, paSell = false;
      bool sdZone = false;
      
      // For trend regime (market trending), use traditional technical signals
      if(regime == 1)
      {
         techBuy = CheckBuySignal(sym, slDist, tpDist);
         techSell = CheckSellSignal(sym, slDist, tpDist);
      }
      else // for range regime, use mean reversion + price action confirmation + S/D zone
      {
         mrBuy = CheckMeanReversionBuySignal(sym, slDist, tpDist);
         mrSell = CheckMeanReversionSellSignal(sym, slDist, tpDist);
         if(mrBuy)
            paBuy = CheckPriceActionConfirmation(sym, true);
         if(mrSell)
            paSell = CheckPriceActionConfirmation(sym, false);
         sdZone = CheckSupplyDemandZone(sym, iClose(sym, PERIOD_M1, 0));
      }
      
      // Final decision logic based on regime
      bool finalBuy = false;
      bool finalSell = false;
      if(regime == 1)
      {
         if(techBuy)
            finalBuy = true;
         else if(techSell)
            finalSell = true;
      }
      else
      {
         if(mrBuy && paBuy && sdZone)
            finalBuy = true;
         else if(mrSell && paSell && sdZone)
            finalSell = true;
      }
      
      // Correlation filtering
      if(finalBuy && CheckCorrelationOpposite(sym, OP_BUY))
         finalBuy = false;
      if(finalSell && CheckCorrelationOpposite(sym, OP_SELL))
         finalSell = false;
      
      double pip = MarketInfo(sym, MODE_POINT);
      if(finalBuy)
      {
         double ask = MarketInfo(sym, MODE_ASK);
         double sl = ask - slDist * pip;
         double tp = ask + tpDist * pip;
         double lot = CalculateLotSize(sym, slDist);
         int ticket = RobustOrderSend(sym, OP_BUY, lot, ask, 3, sl, tp, "Final Trend BUY");
         if(ticket >= 0)
         {
            LogTrade(ticket, "BUY", TimeCurrent(), ask, 0, 0, "Opened");
            TrackNewTrade(ticket);
            Notify("New BUY trade: " + sym + " @ " + DoubleToString(ask, _Digits) +
                   " | Lot=" + DoubleToString(lot, 2) + " | SL=" + DoubleToString(slDist, 1) + "pips");
         }
      }
      else if(finalSell)
      {
         double bid = MarketInfo(sym, MODE_BID);
         double sl = bid + slDist * pip;
         double tp = bid - tpDist * pip;
         double lot = CalculateLotSize(sym, slDist);
         int ticket = RobustOrderSend(sym, OP_SELL, lot, bid, 3, sl, tp, "Final Trend SELL");
         if(ticket >= 0)
         {
            LogTrade(ticket, "SELL", TimeCurrent(), bid, 0, 0, "Opened");
            TrackNewTrade(ticket);
            Notify("New SELL trade: " + sym + " @ " + DoubleToString(bid, _Digits) +
                   " | Lot=" + DoubleToString(lot, 2) + " | SL=" + DoubleToString(slDist, 1) + "pips");
         }
      }
   }
   
   // Manage open orders and update dashboard
   ManageOpenTrades();
   UpdateDashboard();
}

//+------------------------------------------------------------------+
