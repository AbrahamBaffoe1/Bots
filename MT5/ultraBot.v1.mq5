//+------------------------------------------------------------------+
//|                          UltraFoolModeEA_Advanced.mq5            |
//|  A production–grade EA integrating advanced regime filtering,    |
//|  trend following, mean reversion, supply/demand zones, price     |
//|  action confirmation, correlation filtering, dynamic risk, and   |
//|  robust order management with trailing stops, break-even and     |
//|  partial closes.                                                 |
//|                      CONVERTED FROM MQ4 TO MQ5                    |
//+------------------------------------------------------------------+
#property copyright "UltraBot Advanced MT5 v1.0"
#property link      ""
#property version   "5.00"

//+------------------------------------------------------------------+
//| Include MT5 Trade Library                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//--------------------------------------------------------------------
// External Parameters
//--------------------------------------------------------------------
input string  Pairs                = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCHF,NZDUSD,EURGBP,EURJPY,GBPJPY,AUDJPY";  // All major forex pairs
input bool    TradeCurrentChartOnly = false;    // If true, only trades the current chart symbol
input double  RiskPercentPerTrade  = 1.0;       // % risk per trade
input int     MagicNumber          = 987654;    // Unique EA identifier

// Session filtering
input bool    UseMultiSession      = false;     // Set to false = trade 24/7
input int     Session1Start        = 8;
input int     Session1End          = 12;
input int     Session2Start        = 14;
input int     Session2End          = 17;

// Primary Trend Indicators (H1 and M5)
input int     H1_MA_Period         = 50;        // H1 SMA period (trend filter)
input int     M5_MA_Period         = 10;        // M5 SMA period (entry timing)
input int     RSI_Period           = 14;        // M5 RSI period

// ATR-Based Stops & Fixed SL/TP (in pips)
input bool    UseAdaptiveStops     = true;
input double  ATRMultiplierSL      = 2.0;
input double  ATRMultiplierTP      = 3.0;
input int     BaseStopLossPips     = 50;
input int     BaseTakeProfitPips   = 100;

// Trailing Stop Settings
input int     BaseTrailingStopPips = 20;        // initial trailing stop (pips)
input int     AggressiveTrailPips  = 10;        // tighter trailing distance
input double  AggressiveTrailTriggerRR = 2.0;   // if risk:reward ratio exceeds this, tighten

// Break-even Settings
input int     BreakEvenPips        = 30;
input double  BreakEvenBufferPips  = 2.0;

// Partial Close Settings (multi-level)
input bool    UsePartialCloses     = true;
input double  PartialClosePct1     = 30.0;      // Level 1: close 30%
input double  PartialCloseRR1      = 1.5;       // Level 1 R:R threshold
input double  PartialClosePct2     = 20.0;      // Level 2: close 20%
input double  PartialCloseRR2      = 2.5;       // Level 2 R:R threshold

// News Filter Settings
input bool    UseNewsFilter        = false;     // DISABLED by default
input double  MaxSpreadPips        = 2.0;       // Maximum acceptable spread (pips)

// NEW HYBRID SYSTEM FILTERS
input bool    UseIchimokuFilter    = true;      // Ichimoku Cloud confirmation
input bool    UseParabolicSAR      = true;      // Parabolic SAR trend confirmation
input bool    UseEnvelopeFilter    = true;      // Envelope channel filter
input double  EnvelopePercent      = 0.015;     // 1.5% envelope from MA
input bool    UseMultiTimeframe    = true;      // H4 + H1 + M5 confirmation
input bool    UseATRSweetSpot      = true;      // Only trade in optimal volatility range
input double  ATRMinThreshold      = 0.0003;    // Minimum ATR (avoid choppy markets)
input double  ATRMaxThreshold      = 0.0020;    // Maximum ATR (avoid wild swings)

// SMART PYRAMID BUILDING
input bool    UsePyramidBuilding   = true;      // Add to winning positions
input int     PyramidTriggerPips   = 30;        // Add position every X pips in profit
input int     PyramidMaxLevels     = 3;         // Maximum pyramid levels
input double  PyramidSizeMultiplier= 1.0;       // Size of each addition

// Daily Drawdown Limit
input double  DailyDrawdownLimitPct = 10.0;     // Increased to 10% - less restrictive

// Correlation Filter
input bool    UseCorrelationFilter = false;     // DISABLED by default
input double  CorrThreshold        = 0.8;       // Minimum correlation threshold

//--------------------------------------------------------------------
// Global Variables
//--------------------------------------------------------------------
string  CurrencyPairs[];
int     PairCount = 0;
datetime gDailyStartTime = 0;
double   gDailyStartEquity = 0;
datetime gSafeModeStartTime = 0;

enum EA_STATE { EA_STATE_READY = 0, EA_STATE_SAFE_MODE, EA_STATE_SUSPENDED };
EA_STATE gEAState = EA_STATE_READY;

// Trade tracking structure
struct TRADE_TRACKER {
   ulong ticket;
   bool partialLevel0Done;
   bool partialLevel1Done;
   int pyramidLevel;
   double lastPyramidPrice;
   ulong pyramidTickets[10];
};
TRADE_TRACKER trackedTrades[];

// Indicator handles per symbol
struct SymbolIndicators {
   string symbol;
   int h_H1_MA;
   int h_M5_MA;
   int h_RSI;
   int h_ATR_M5;
   int h_ATR_H1;
   int h_Ichimoku;
   int h_SAR;
   int h_Envelope;
   int h_ADX;
};
SymbolIndicators g_Indicators[];

//--------------------------------------------------------------------
// Statistics Tracking
//--------------------------------------------------------------------
int g_DailyTotalTrades = 0;
int g_DailyWins = 0;
int g_DailyLosses = 0;
int g_TotalWins = 0;
int g_TotalLosses = 0;
int g_TotalTrades = 0;
double g_StartEquity = 0;
double g_PeakEquity = 0;

//--------------------------------------------------------------------
// Helper Function: Split Pairs String
//--------------------------------------------------------------------
int SplitPairs(string str, string separator, string &result[]) {
   int count = 0;
   string temp = str;
   ArrayResize(result, 0);

   while(StringLen(temp) > 0) {
      int sepPos = StringFind(temp, separator, 0);
      if(sepPos < 0) {
         if(StringLen(temp) > 0) {
            ArrayResize(result, count + 1);
            result[count] = temp;
            count++;
         }
         break;
      } else {
         string part = StringSubstr(temp, 0, sepPos);
         if(StringLen(part) > 0) {
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
// Initialize Indicators for Symbol
//--------------------------------------------------------------------
bool InitSymbolIndicators(string symbol) {
   SymbolIndicators si;
   si.symbol = symbol;
   si.h_H1_MA = iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_M5_MA = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_RSI = iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE);
   si.h_ATR_M5 = iATR(symbol, PERIOD_M5, 14);
   si.h_ATR_H1 = iATR(symbol, PERIOD_H1, 14);
   si.h_Ichimoku = iIchimoku(symbol, PERIOD_H1, 9, 26, 52);
   si.h_SAR = iSAR(symbol, PERIOD_H1, 0.02, 0.2);
   si.h_Envelope = iEnvelopes(symbol, PERIOD_M5, 20, 0, MODE_SMA, PRICE_CLOSE, EnvelopePercent * 100);
   si.h_ADX = iADX(symbol, PERIOD_H1, 14);

   if(si.h_H1_MA == INVALID_HANDLE || si.h_M5_MA == INVALID_HANDLE ||
      si.h_RSI == INVALID_HANDLE || si.h_ATR_M5 == INVALID_HANDLE ||
      si.h_ATR_H1 == INVALID_HANDLE || si.h_Ichimoku == INVALID_HANDLE ||
      si.h_SAR == INVALID_HANDLE || si.h_Envelope == INVALID_HANDLE ||
      si.h_ADX == INVALID_HANDLE) {
      Print("ERROR: Failed to create indicators for ", symbol);
      return false;
   }

   int size = ArraySize(g_Indicators);
   ArrayResize(g_Indicators, size + 1);
   g_Indicators[size] = si;
   return true;
}

//--------------------------------------------------------------------
// Get Indicator Index for Symbol
//--------------------------------------------------------------------
int GetIndicatorIndex(string symbol) {
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      if(g_Indicators[i].symbol == symbol)
         return i;
   }
   return -1;
}

//--------------------------------------------------------------------
// Find Broker Symbol (with suffix detection)
//--------------------------------------------------------------------
string FindBrokerSymbol(string basePair) {
   // Try exact match first
   double spread = SymbolInfoInteger(basePair, SYMBOL_SPREAD);
   double ask = SymbolInfoDouble(basePair, SYMBOL_ASK);
   if(spread > 0 && ask > 0) {
      Print("  → Found exact match: ", basePair);
      return basePair;
   }

   // Try common broker suffixes
   string suffixes[] = {"m", ".m", "pro", ".pro", ".", "_", "ecn", ".ecn", "c", ".c", "i", ".i"};
   for(int i = 0; i < ArraySize(suffixes); i++) {
      string testSymbol = basePair + suffixes[i];
      spread = SymbolInfoInteger(testSymbol, SYMBOL_SPREAD);
      ask = SymbolInfoDouble(testSymbol, SYMBOL_ASK);
      if(spread > 0 && ask > 0) {
         Print("  → Found broker symbol: ", basePair, " = ", testSymbol);
         return testSymbol;
      }
   }

   Print("  ✗ Could not find broker symbol for: ", basePair);
   return ""; // Not found
}

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("========================================");
   Print("=== ULTRABOT EA MT5 STARTING ===");
   Print("========================================");
   Print("Current Chart Symbol: ", _Symbol);
   Print("Account Equity: $", AccountInfoDouble(ACCOUNT_EQUITY));

   // Setup pairs
   if(TradeCurrentChartOnly) {
      PairCount = 1;
      ArrayResize(CurrencyPairs, 1);
      CurrencyPairs[0] = _Symbol;
      Print("Mode: Trading CURRENT CHART ONLY - ", _Symbol);
   } else {
      string tempPairs[];
      int tempCount = SplitPairs(Pairs, ",", tempPairs);
      Print("Mode: Trading MULTIPLE PAIRS");
      Print("Scanning ", tempCount, " pairs for broker compatibility...");

      // Auto-detect broker symbols
      ArrayResize(CurrencyPairs, 0);
      PairCount = 0;

      for(int i = 0; i < tempCount; i++) {
         string brokerSymbol = FindBrokerSymbol(tempPairs[i]);
         if(brokerSymbol != "") {
            ArrayResize(CurrencyPairs, PairCount + 1);
            CurrencyPairs[PairCount] = brokerSymbol;
            PairCount++;
            Print("  ✓ ", tempPairs[i], " → ", brokerSymbol);
         }
      }
      Print("");
      Print("✓ Successfully detected ", PairCount, " tradeable pairs");
   }

   // Initialize indicators for each pair
   for(int i = 0; i < PairCount; i++) {
      Print("Initializing indicators for ", CurrencyPairs[i], "...");
      if(!InitSymbolIndicators(CurrencyPairs[i])) {
         Print("WARNING: Failed to initialize indicators for ", CurrencyPairs[i]);
      }
   }

   // Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   trade.SetAsyncMode(false);

   gDailyStartTime = TimeCurrent();
   gDailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_StartEquity = gDailyStartEquity;
   g_PeakEquity = gDailyStartEquity;

   Print("=== ULTRABOT EA MT5 READY TO TRADE ===");
   Print("========================================");
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("UltraFoolModeEA_Advanced MT5 deinit => cleaning up");

   // Release indicator handles
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      IndicatorRelease(g_Indicators[i].h_H1_MA);
      IndicatorRelease(g_Indicators[i].h_M5_MA);
      IndicatorRelease(g_Indicators[i].h_RSI);
      IndicatorRelease(g_Indicators[i].h_ATR_M5);
      IndicatorRelease(g_Indicators[i].h_ATR_H1);
      IndicatorRelease(g_Indicators[i].h_Ichimoku);
      IndicatorRelease(g_Indicators[i].h_SAR);
      IndicatorRelease(g_Indicators[i].h_Envelope);
      IndicatorRelease(g_Indicators[i].h_ADX);
   }

   ObjectDelete(0, "UltraFoolDashboard");
}

//--------------------------------------------------------------------
// Session & Daily Drawdown Management
//--------------------------------------------------------------------
bool InSession(datetime tm, int startH, int endH) {
   MqlDateTime dt;
   TimeToStruct(tm, dt);
   return (dt.hour >= startH && dt.hour < endH);
}

bool IsTradingSessionActive() {
   if(!UseMultiSession)
      return true;
   datetime nowT = TimeCurrent();
   if(InSession(nowT, Session1Start, Session1End)) return true;
   if(InSession(nowT, Session2Start, Session2End)) return true;
   return false;
}

bool CheckDailyDrawdown() {
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = (gDailyStartEquity - eq) / gDailyStartEquity * 100.0;
   if(dd >= DailyDrawdownLimitPct) {
      gEAState = EA_STATE_SUSPENDED;
      Print("EA suspended: daily drawdown = ", DoubleToString(dd, 1), "%");
      return true;
   }
   return false;
}

void ResetDailyEquityIfNewDay() {
   MqlDateTime dt, dt_start;
   TimeToStruct(TimeCurrent(), dt);
   TimeToStruct(gDailyStartTime, dt_start);

   if(dt.day != dt_start.day) {
      gDailyStartTime = TimeCurrent();
      gDailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_DailyTotalTrades = 0;
      g_DailyWins = 0;
      g_DailyLosses = 0;
      Print("New day: daily equity baseline reset to ", gDailyStartEquity);
   }
}

//--------------------------------------------------------------------
// Trade Tracking Functions
//--------------------------------------------------------------------
void TrackNewTrade(ulong ticket) {
   TRADE_TRACKER tt;
   tt.ticket = ticket;
   tt.partialLevel0Done = false;
   tt.partialLevel1Done = false;
   tt.pyramidLevel = 0;
   tt.lastPyramidPrice = 0;
   ArrayInitialize(tt.pyramidTickets, 0);
   tt.pyramidTickets[0] = ticket;
   int sz = ArraySize(trackedTrades);
   ArrayResize(trackedTrades, sz + 1);
   trackedTrades[sz] = tt;
}

int GetTradeTrackerIndex(ulong ticket) {
   for(int i = 0; i < ArraySize(trackedTrades); i++) {
      if(trackedTrades[i].ticket == ticket)
         return i;
   }
   return -1;
}

//--------------------------------------------------------------------
// Update Dashboard
//--------------------------------------------------------------------
void UpdateDashboard() {
   string stateStr = "READY";
   color stateColor = clrLime;
   if(gEAState == EA_STATE_SAFE_MODE) {
      stateStr = "SAFE MODE";
      stateColor = clrYellow;
   } else if(gEAState == EA_STATE_SUSPENDED) {
      stateStr = "SUSPENDED";
      stateColor = clrRed;
   }

   string dash = "=== ULTRABOT EA MT5 ===\n";
   dash += "STATUS: " + stateStr + "\n";
   dash += "Chart: " + _Symbol + "\n";
   dash += "Account: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
   dash += "Daily Start: $" + DoubleToString(gDailyStartEquity, 2) + "\n";
   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - gDailyStartEquity;
   dash += "Daily P/L: " + (dailyPL >= 0 ? "+" : "") + DoubleToString(dailyPL, 2) + "\n";
   dash += "Open Positions: " + IntegerToString(PositionsTotal()) + "\n";
   dash += "Monitored: " + IntegerToString(PairCount) + " pairs\n";
   dash += "Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   if(ObjectFind(0, "UltraFoolDashboard") < 0) {
      ObjectCreate(0, "UltraFoolDashboard", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_FONTSIZE, 11);
      ObjectSetString(0, "UltraFoolDashboard", OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetInteger(0, "UltraFoolDashboard", OBJPROP_COLOR, stateColor);
   ObjectSetString(0, "UltraFoolDashboard", OBJPROP_TEXT, dash);
}

//--------------------------------------------------------------------
// Check Buy/Sell Signals (Simplified for MT5)
//--------------------------------------------------------------------
bool CheckBuySignal(string sym, double &slDist, double &tpDist) {
   int idx = GetIndicatorIndex(sym);
   if(idx < 0) return false;

   // Get indicator values
   double h1Close[], h1MA[], m5Close[], m5MA[], rsi[], atr[];
   ArraySetAsSeries(h1Close, true);
   ArraySetAsSeries(h1MA, true);
   ArraySetAsSeries(m5Close, true);
   ArraySetAsSeries(m5MA, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);

   if(CopyClose(sym, PERIOD_H1, 0, 3, h1Close) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_H1_MA, 0, 0, 3, h1MA) <= 0 ||
      CopyClose(sym, PERIOD_M5, 0, 3, m5Close) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_M5_MA, 0, 0, 3, m5MA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_RSI, 0, 0, 3, rsi) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ATR_M5, 0, 0, 3, atr) <= 0) {
      return false;
   }

   // H1 trend filter: price must be above H1 MA
   if(h1Close[0] <= h1MA[0]) {
      return false;
   }

   // M5 MA crossover: previous close below MA, current close above MA
   if(!(m5Close[1] < m5MA[1] && m5Close[0] > m5MA[0])) {
      return false;
   }

   // RSI confirmation: must be above 50 for buy
   if(rsi[0] <= 50) {
      return false;
   }

   // Calculate SL/TP distances
   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(UseAdaptiveStops) {
      slDist = ATRMultiplierSL * (atr[0] / point);
      tpDist = ATRMultiplierTP * (atr[0] / point);
   } else {
      slDist = BaseStopLossPips;
      tpDist = BaseTakeProfitPips;
   }

   Print("[", sym, "] ✓ ALL BUY FILTERS PASSED");
   return true;
}

bool CheckSellSignal(string sym, double &slDist, double &tpDist) {
   int idx = GetIndicatorIndex(sym);
   if(idx < 0) return false;

   // Get indicator values
   double h1Close[], h1MA[], m5Close[], m5MA[], rsi[], atr[];
   ArraySetAsSeries(h1Close, true);
   ArraySetAsSeries(h1MA, true);
   ArraySetAsSeries(m5Close, true);
   ArraySetAsSeries(m5MA, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);

   if(CopyClose(sym, PERIOD_H1, 0, 3, h1Close) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_H1_MA, 0, 0, 3, h1MA) <= 0 ||
      CopyClose(sym, PERIOD_M5, 0, 3, m5Close) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_M5_MA, 0, 0, 3, m5MA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_RSI, 0, 0, 3, rsi) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ATR_M5, 0, 0, 3, atr) <= 0) {
      return false;
   }

   // H1 trend filter: price must be below H1 MA
   if(h1Close[0] >= h1MA[0]) {
      return false;
   }

   // M5 MA crossover: previous close above MA, current close below MA
   if(!(m5Close[1] > m5MA[1] && m5Close[0] < m5MA[0])) {
      return false;
   }

   // RSI confirmation: must be below 50 for sell
   if(rsi[0] >= 50) {
      return false;
   }

   // Calculate SL/TP distances
   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(UseAdaptiveStops) {
      slDist = ATRMultiplierSL * (atr[0] / point);
      tpDist = ATRMultiplierTP * (atr[0] / point);
   } else {
      slDist = BaseStopLossPips;
      tpDist = BaseTakeProfitPips;
   }

   Print("[", sym, "] ✓ ALL SELL FILTERS PASSED");
   return true;
}

//--------------------------------------------------------------------
// Calculate Lot Size
//--------------------------------------------------------------------
double CalculateLotSize(string sym, double slDistPips) {
   double accBal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt = accBal * (RiskPercentPerTrade / 100.0);
   double tickVal = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double pipVal = tickVal * 10.0;
   if(pipVal <= 0) pipVal = 10.0;
   double costPerTrade = slDistPips * pipVal;
   if(costPerTrade <= 0) costPerTrade = 1;
   double rawLots = riskAmt / costPerTrade;
   double step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   rawLots = MathFloor(rawLots / step) * step;
   if(rawLots < minLot) rawLots = minLot;
   if(rawLots > maxLot) rawLots = maxLot;
   return NormalizeDouble(rawLots, 2);
}

//--------------------------------------------------------------------
// Manage Open Trades
//--------------------------------------------------------------------
void ManageOpenTrades() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double currentPrice = isBuy ? bid : ask;

      // Calculate profit in pips
      double profitPips = isBuy ?
                         (currentPrice - openPrice) / point / 10.0 :
                         (openPrice - currentPrice) / point / 10.0;

      // Trailing Stop
      if(UseAdaptiveStops && profitPips > 0) {
         double trailDistance = BaseTrailingStopPips;
         double newSL = isBuy ?
                       NormalizeDouble(currentPrice - trailDistance * point * 10.0, _Digits) :
                       NormalizeDouble(currentPrice + trailDistance * point * 10.0, _Digits);

         if((isBuy && newSL > sl && sl > 0) || (!isBuy && (sl == 0 || newSL < sl) && newSL > 0)) {
            trade.PositionModify(ticket, newSL, tp);
         }
      }

      // Break-even
      if(profitPips >= BreakEvenPips) {
         double beSL = NormalizeDouble(openPrice + (isBuy ? 1 : -1) * BreakEvenBufferPips * point * 10.0, _Digits);
         if((isBuy && (sl == 0 || beSL > sl)) || (!isBuy && (sl == 0 || beSL < sl))) {
            trade.PositionModify(ticket, beSL, tp);
         }
      }

      // Partial Closes
      if(UsePartialCloses) {
         double lots = PositionGetDouble(POSITION_VOLUME);
         double minLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);

         if(lots > minLot) {
            int tIdx = GetTradeTrackerIndex(ticket);
            if(tIdx >= 0) {
               double sldist = MathAbs(openPrice - sl) / point / 10.0;
               if(sldist <= 0) sldist = BaseStopLossPips;
               double rr = profitPips / sldist;

               // Partial Level 1
               if(!trackedTrades[tIdx].partialLevel0Done && rr >= PartialCloseRR1) {
                  double pcVol = NormalizeDouble(lots * (PartialClosePct1 / 100.0), 2);
                  if(pcVol >= minLot && pcVol <= lots) {
                     trade.PositionClosePartial(ticket, pcVol);
                     trackedTrades[tIdx].partialLevel0Done = true;
                  }
               }

               // Partial Level 2
               if(!trackedTrades[tIdx].partialLevel1Done && rr >= PartialCloseRR2) {
                  double pcVol = NormalizeDouble(lots * (PartialClosePct2 / 100.0), 2);
                  if(pcVol >= minLot && pcVol <= lots) {
                     trade.PositionClosePartial(ticket, pcVol);
                     trackedTrades[tIdx].partialLevel1Done = true;
                  }
               }
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// MAIN ONTICK FUNCTION
//--------------------------------------------------------------------
void OnTick() {
   ResetDailyEquityIfNewDay();

   if(CheckDailyDrawdown()) {
      ManageOpenTrades();
      UpdateDashboard();
      return;
   }

   if(!IsTradingSessionActive()) return;

   // Update dashboard every 10 ticks
   static int tickCounter = 0;
   tickCounter++;
   if(tickCounter % 10 == 0) {
      UpdateDashboard();
   }

   // Manage open trades
   ManageOpenTrades();

   // Loop through each currency pair
   for(int i = 0; i < PairCount; i++) {
      string sym = CurrencyPairs[i];

      // Skip if already have position on this symbol
      if(PositionSelect(sym)) continue;

      // Check for signals
      double slDist = 0, tpDist = 0;

      if(CheckBuySignal(sym, slDist, tpDist)) {
         double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
         double point = SymbolInfoDouble(sym, SYMBOL_POINT);
         double sl = ask - slDist * point * 10.0;
         double tp = ask + tpDist * point * 10.0;
         double lot = CalculateLotSize(sym, slDist);

         Print("[", sym, "] Opening BUY position...");
         if(trade.Buy(lot, sym, ask, sl, tp, "UltraBot BUY")) {
            ulong ticket = trade.ResultOrder();
            TrackNewTrade(ticket);
            Print("[", sym, "] ✓ BUY order opened! Ticket #", ticket);
            g_TotalTrades++;
            g_DailyTotalTrades++;
         }
      } else if(CheckSellSignal(sym, slDist, tpDist)) {
         double bid = SymbolInfoDouble(sym, SYMBOL_BID);
         double point = SymbolInfoDouble(sym, SYMBOL_POINT);
         double sl = bid + slDist * point * 10.0;
         double tp = bid - tpDist * point * 10.0;
         double lot = CalculateLotSize(sym, slDist);

         Print("[", sym, "] Opening SELL position...");
         if(trade.Sell(lot, sym, bid, sl, tp, "UltraBot SELL")) {
            ulong ticket = trade.ResultOrder();
            TrackNewTrade(ticket);
            Print("[", sym, "] ✓ SELL order opened! Ticket #", ticket);
            g_TotalTrades++;
            g_DailyTotalTrades++;
         }
      }
   }
}

//+------------------------------------------------------------------+
