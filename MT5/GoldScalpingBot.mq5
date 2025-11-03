//+------------------------------------------------------------------+
//|                                         GoldScalpingBot.mq5      |
//|                        Gold Scalping EA - Ultra-Fast M5 Trading  |
//|                        Copyright 2025, SmartStockTrader Team    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, SmartStockTrader Team"
#property link      "https://smartstocktrader.com"
#property version   "1.00"
#property description "Gold Scalping Bot - Optimized for M5 timeframe"
#property description "Strategies: Breakout, VWAP Bounce, Momentum"
#property description "Tight stops (10-30 pips), Fast exits (20-50 pips)"

//--- Include libraries
#include <Trade\Trade.mqh>
#include <SST_ScalpingStrategy.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== SCALPING STRATEGY ==="
input ENUM_SCALP_STRATEGY InpScalpStrategy = SCALP_HYBRID;  // Scalping Strategy
input ENUM_TIMEFRAMES InpScalpTimeframe = PERIOD_M5;        // Scalping Timeframe
input int InpStopLossPips = 20;                             // Stop Loss (pips)
input int InpTakeProfitPips = 40;                           // Take Profit (pips) 2:1 R:R
input int InpMaxHoldMinutes = 60;                           // Max Hold Time (minutes)

input group "=== RISK MANAGEMENT ==="
input double InpRiskPercent = 0.5;                          // Risk Per Trade (%) - Conservative for scalping
input double InpMinLotSize = 0.01;                          // Min Lot Size
input double InpMaxLotSize = 5.0;                           // Max Lot Size
input int InpMagicNumber = 300001;                          // Magic Number
input int InpMaxDailyTrades = 10;                           // Max Daily Trades (scalping allows more)
input double InpMaxDailyDrawdown = 2.0;                     // Max Daily Drawdown (%)

input group "=== ENTRY FILTERS ==="
input double InpMaxSpreadPoints = 20.0;                     // Max Spread (points) - CRITICAL for scalping
input double InpMinATR = 2.0;                               // Min ATR (USD) - Volatility required
input double InpVolumeMultiplier = 1.5;                     // Volume Spike Threshold
input bool InpRequirePattern = true;                        // Require Candlestick Pattern
input double InpMinPatternConfidence = 0.75;                // Min Pattern Confidence

input group "=== EXIT MANAGEMENT ==="
input int InpBreakEvenPips = 10;                            // Break-Even Trigger (pips) - FAST
input int InpTrailingStartPips = 15;                        // Trailing Start (pips) - EARLY
input int InpTrailingStepPips = 10;                         // Trailing Step (pips) - TIGHT
input bool InpUsePartialClose = true;                       // Use Partial Closes
input double InpPartial1Pips = 20;                          // Close 25% at +20 pips
input double InpPartial2Pips = 30;                          // Close 25% at +30 pips
input double InpPartial3Pips = 40;                          // Close 25% at +40 pips
// 25% remains for runners

input group "=== SESSION FILTERS ==="
input bool InpTradeLondonSession = true;                    // Trade London (8-12 GMT) - BEST for Gold
input bool InpTradeNYSession = true;                        // Trade NY (13-17 GMT) - BEST for Gold
input bool InpTradeAsianSession = false;                    // Trade Asian (0-9 GMT) - Low volume
input bool InpAvoidLondonFix = true;                        // Avoid London Fix (10:30, 15:00 GMT)
input bool InpAvoidNews = true;                             // Avoid High-Impact News

input group "=== ADVANCED ==="
input string InpTradingSymbol = "XAUUSD";                   // Trading Symbol
input int InpSlippagePoints = 30;                           // Max Slippage (points)
input bool InpEnableWebSocket = false;                      // Enable Backend Sync

//--- Global Variables
CTrade trade;
CScalpingStrategy *scalpStrategy;
datetime lastBarTime = 0;
datetime lastTradeTime = 0;
int dailyTradeCount = 0;
double dailyMaxEquity = 0.0;
datetime lastTradeDay = 0;

// Position tracking for partial closes
struct PositionInfo
{
   ulong ticket;
   datetime openTime;
   double initialLot;
   bool partial1Closed;
   bool partial2Closed;
   bool partial3Closed;
   bool beMovedToday;
};
PositionInfo openPositions[];

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("  GOLD SCALPING BOT v1.0 INITIALIZING");
   Print("========================================");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("Symbol: ", InpTradingSymbol);
   Print("Timeframe: ", EnumToString(InpScalpTimeframe));
   Print("Strategy: ", EnumToString(InpScalpStrategy));
   Print("Stop Loss: ", InpStopLossPips, " pips | Take Profit: ", InpTakeProfitPips, " pips");
   Print("Risk per trade: ", InpRiskPercent, "%");
   Print("Max Spread: ", InpMaxSpreadPoints, " points");
   Print("Max Hold Time: ", InpMaxHoldMinutes, " minutes");

   //--- Validate symbol
   if(!SymbolSelect(InpTradingSymbol, true))
   {
      Alert("FATAL: Failed to select symbol: ", InpTradingSymbol);
      return INIT_FAILED;
   }

   //--- Initialize scalping strategy
   scalpStrategy = new CScalpingStrategy(InpTradingSymbol, InpScalpTimeframe);
   if(scalpStrategy == NULL)
   {
      Alert("FATAL: Failed to create scalping strategy");
      return INIT_FAILED;
   }

   //--- Configure CTrade
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);

   //--- Initialize arrays
   ArrayResize(openPositions, 0);

   //--- Warnings
   if(InpMaxSpreadPoints > 30)
      Print("WARNING: Max spread > 30 points may reduce scalping profitability!");

   if(InpStopLossPips < 10)
      Print("WARNING: Stop loss < 10 pips may cause frequent stop-outs!");

   if(AccountInfoDouble(ACCOUNT_BALANCE) < 500)
      Print("WARNING: Balance < $500 may be too small for Gold scalping with most brokers!");

   double point = SymbolInfoDouble(InpTradingSymbol, SYMBOL_POINT);
   Print("Symbol point size: ", point);
   Print("Symbol digits: ", _Digits);

   PrintSessionSettings();

   Print("========================================");
   Print("  INITIALIZATION COMPLETE - READY!");
   Print("========================================");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("========================================");
   Print("  GOLD SCALPING BOT SHUTTING DOWN");
   Print("========================================");

   PrintDailyStats();

   if(scalpStrategy != NULL)
   {
      delete scalpStrategy;
      scalpStrategy = NULL;
   }

   Print("Reason: ", reason);
   Print("========================================");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Process every tick for scalping (not just new bar)
   UpdateDailyStats();

   if(!CheckDailyLimits()) return;

   //--- Manage existing positions EVERY tick (critical for scalping)
   ManageOpenPositions();

   //--- Look for new entries only on new bar
   if(!IsNewBar()) return;

   if(!CanTrade()) return;

   //--- Generate scalping signal
   ScalpSignal signal = scalpStrategy.GenerateSignal(InpScalpStrategy, InpMaxSpreadPoints);

   if(signal.signal != 0 && signal.confidence >= InpMinPatternConfidence)
   {
      ExecuteScalpSignal(signal);
   }
}

//+------------------------------------------------------------------+
//| Check if new bar                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentTime = iTime(InpTradingSymbol, InpScalpTimeframe, 0);
   if(currentTime != lastBarTime)
   {
      lastBarTime = currentTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Execute scalp signal                                             |
//+------------------------------------------------------------------+
void ExecuteScalpSignal(ScalpSignal &signal)
{
   //--- Don't open new position if one already exists
   if(PositionSelect(InpTradingSymbol))
   {
      Print("Position already open on ", InpTradingSymbol);
      return;
   }

   //--- Calculate lot size
   double lotSize = CalculateLotSize(signal.entry_price, signal.stop_loss, signal.confidence);
   if(lotSize < InpMinLotSize)
   {
      Print("Lot size too small: ", lotSize, " (min: ", InpMinLotSize, ")");
      return;
   }

   //--- Prepare order
   string comment = StringFormat("%s|Conf:%.0f%%", signal.reason, signal.confidence * 100);
   if(StringLen(comment) > 31) comment = StringSubstr(comment, 0, 31); // MT5 limit

   //--- Execute trade
   bool result = false;
   if(signal.signal > 0)
   {
      result = trade.Buy(lotSize, InpTradingSymbol, signal.entry_price, signal.stop_loss, signal.take_profit, comment);
   }
   else if(signal.signal < 0)
   {
      result = trade.Sell(lotSize, InpTradingSymbol, signal.entry_price, signal.stop_loss, signal.take_profit, comment);
   }

   if(result)
   {
      ulong ticket = trade.ResultOrder();
      Print("========================================");
      Print("SCALP ENTRY: ", (signal.signal > 0 ? "BUY" : "SELL"));
      Print("Ticket: ", ticket);
      Print("Strategy: ", EnumToString(signal.strategy_type));
      Print("Lot: ", lotSize);
      Print("Entry: ", signal.entry_price);
      Print("SL: ", signal.stop_loss, " (", InpStopLossPips, " pips)");
      Print("TP: ", signal.take_profit, " (", InpTakeProfitPips, " pips)");
      Print("Confidence: ", DoubleToString(signal.confidence * 100, 0), "%");
      Print("Spread: ", DoubleToString(signal.spread_points, 1), " points");
      Print("ATR: ", DoubleToString(signal.atr_value, 2));
      Print("Reason: ", signal.reason);
      Print("========================================");

      dailyTradeCount++;
      lastTradeTime = TimeCurrent();

      //--- Add to position tracking
      AddPositionToTracking(ticket, lotSize);
   }
   else
   {
      Print("ERROR: Trade execution failed: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry, double stopLoss, double confidence)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;

   //--- Adjust risk based on confidence (higher confidence = higher position size)
   riskAmount *= confidence;

   double slDistance = MathAbs(entry - stopLoss);
   if(slDistance == 0) return InpMinLotSize;

   double tickValue = SymbolInfoDouble(InpTradingSymbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(InpTradingSymbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep = SymbolInfoDouble(InpTradingSymbol, SYMBOL_VOLUME_STEP);

   double lots = riskAmount / (slDistance / tickSize * tickValue);
   lots = MathFloor(lots / lotStep) * lotStep;

   //--- Normalize
   double minLot = SymbolInfoDouble(InpTradingSymbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(InpTradingSymbol, SYMBOL_VOLUME_MAX);

   lots = MathMax(lots, InpMinLotSize);
   lots = MathMin(lots, InpMaxLotSize);
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   lots = MathRound(lots / lotStep) * lotStep;

   return lots;
}

//+------------------------------------------------------------------+
//| Manage open positions - CRITICAL FOR SCALPING                    |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != InpTradingSymbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      //--- Time-based exit (scalping specific)
      CheckTimeBasedExit(ticket);

      //--- Break-even (fast for scalping)
      MoveToBreakEven(ticket);

      //--- Partial closes (scalping profit-taking)
      if(InpUsePartialClose) ManagePartialCloses(ticket);

      //--- Trailing stop (tight for scalping)
      TrailPosition(ticket);
   }
}

//+------------------------------------------------------------------+
//| Time-based exit for scalping                                     |
//+------------------------------------------------------------------+
void CheckTimeBasedExit(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
   int minutesOpen = (int)((TimeCurrent() - openTime) / 60);

   if(minutesOpen >= InpMaxHoldMinutes)
   {
      double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ?
                           SymbolInfoDouble(InpTradingSymbol, SYMBOL_BID) :
                           SymbolInfoDouble(InpTradingSymbol, SYMBOL_ASK);

      if(trade.PositionClose(ticket))
      {
         Print("TIME EXIT: Position ", ticket, " closed after ", minutesOpen, " minutes (max: ", InpMaxHoldMinutes, ")");
      }
   }
}

//+------------------------------------------------------------------+
//| Move to break-even (FAST for scalping)                           |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   int posIndex = FindPositionIndex(ticket);
   if(posIndex < 0) return;
   if(openPositions[posIndex].beMovedToday) return; // Already moved

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_BID) :
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_ASK);

   double point = SymbolInfoDouble(InpTradingSymbol, SYMBOL_POINT);
   double beDistance = InpBreakEvenPips * point * 10; // Convert pips to price units

   double profitDistance = posType == POSITION_TYPE_BUY ?
                          (currentPrice - openPrice) :
                          (openPrice - currentPrice);

   if(profitDistance >= beDistance)
   {
      if(trade.PositionModify(ticket, openPrice, PositionGetDouble(POSITION_TP)))
      {
         Print("BREAK-EVEN: Position ", ticket, " moved to BE at +", InpBreakEvenPips, " pips profit");
         openPositions[posIndex].beMovedToday = true;
      }
   }
}

//+------------------------------------------------------------------+
//| Manage partial closes (SCALPING PROFIT-TAKING)                   |
//+------------------------------------------------------------------+
void ManagePartialCloses(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   int posIndex = FindPositionIndex(ticket);
   if(posIndex < 0) return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentLot = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_BID) :
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_ASK);

   double point = SymbolInfoDouble(InpTradingSymbol, SYMBOL_POINT);
   double profitPips = (posType == POSITION_TYPE_BUY ?
                       (currentPrice - openPrice) :
                       (openPrice - currentPrice)) / (point * 10);

   double lotStep = SymbolInfoDouble(InpTradingSymbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(InpTradingSymbol, SYMBOL_VOLUME_MIN);
   double closeAmount = MathFloor((openPositions[posIndex].initialLot * 0.25) / lotStep) * lotStep;
   if(closeAmount < minLot) return; // Can't close partial if too small

   //--- Partial close 1: 25% at +20 pips
   if(!openPositions[posIndex].partial1Closed && profitPips >= InpPartial1Pips)
   {
      if(trade.PositionClosePartial(ticket, closeAmount))
      {
         Print("PARTIAL CLOSE 1: Closed 25% (", closeAmount, " lots) at +", DoubleToString(profitPips, 1), " pips");
         openPositions[posIndex].partial1Closed = true;
      }
   }
   //--- Partial close 2: 25% at +30 pips
   else if(!openPositions[posIndex].partial2Closed && profitPips >= InpPartial2Pips)
   {
      if(trade.PositionClosePartial(ticket, closeAmount))
      {
         Print("PARTIAL CLOSE 2: Closed 25% (", closeAmount, " lots) at +", DoubleToString(profitPips, 1), " pips");
         openPositions[posIndex].partial2Closed = true;
      }
   }
   //--- Partial close 3: 25% at +40 pips (leaves 25% for runners)
   else if(!openPositions[posIndex].partial3Closed && profitPips >= InpPartial3Pips)
   {
      if(trade.PositionClosePartial(ticket, closeAmount))
      {
         Print("PARTIAL CLOSE 3: Closed 25% (", closeAmount, " lots) at +", DoubleToString(profitPips, 1), " pips (25% remains for runner)");
         openPositions[posIndex].partial3Closed = true;
      }
   }
}

//+------------------------------------------------------------------+
//| Trail position (TIGHT for scalping)                              |
//+------------------------------------------------------------------+
void TrailPosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_BID) :
                        SymbolInfoDouble(InpTradingSymbol, SYMBOL_ASK);

   double point = SymbolInfoDouble(InpTradingSymbol, SYMBOL_POINT);
   double trailStart = InpTrailingStartPips * point * 10;
   double trailStep = InpTrailingStepPips * point * 10;

   double profitDistance = posType == POSITION_TYPE_BUY ?
                          (currentPrice - openPrice) :
                          (openPrice - currentPrice);

   if(profitDistance < trailStart) return; // Not profitable enough yet

   double newSL = 0;
   if(posType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - trailStep;
      if(newSL <= currentSL || newSL <= openPrice) return; // Don't move SL backwards or below entry
   }
   else
   {
      newSL = currentPrice + trailStep;
      if(currentSL > 0 && newSL >= currentSL) return; // Don't move SL backwards
      if(newSL >= openPrice) return; // Don't move above entry
   }

   if(trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
   {
      Print("TRAILING STOP: Position ", ticket, " SL moved to ", newSL);
   }
}

//+------------------------------------------------------------------+
//| Position tracking helpers                                        |
//+------------------------------------------------------------------+
void AddPositionToTracking(ulong ticket, double initialLot)
{
   int size = ArraySize(openPositions);
   ArrayResize(openPositions, size + 1);

   openPositions[size].ticket = ticket;
   openPositions[size].openTime = TimeCurrent();
   openPositions[size].initialLot = initialLot;
   openPositions[size].partial1Closed = false;
   openPositions[size].partial2Closed = false;
   openPositions[size].partial3Closed = false;
   openPositions[size].beMovedToday = false;
}

int FindPositionIndex(ulong ticket)
{
   for(int i = 0; i < ArraySize(openPositions); i++)
   {
      if(openPositions[i].ticket == ticket)
         return i;
   }
   return -1;
}

void RemoveClosedPositionsFromTracking()
{
   for(int i = ArraySize(openPositions) - 1; i >= 0; i--)
   {
      if(!PositionSelectByTicket(openPositions[i].ticket))
      {
         // Position closed, remove from tracking
         ArrayRemove(openPositions, i, 1);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if can trade                                               |
//+------------------------------------------------------------------+
bool CanTrade()
{
   //--- Session check
   if(!IsWithinTradingSession())
   {
      return false;
   }

   //--- London Fix avoidance
   if(InpAvoidLondonFix && IsLondonFixTime())
   {
      return false;
   }

   //--- News check
   if(InpAvoidNews && IsNewsTime())
   {
      return false;
   }

   //--- Spread check (CRITICAL for scalping)
   double spread = SymbolInfoInteger(InpTradingSymbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPoints)
   {
      Print("Spread too wide: ", spread, " points (max: ", InpMaxSpreadPoints, ")");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check trading session                                             |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   int hour = now.hour;
   int minute = now.min;

   //--- Asian: 00:00-09:00 GMT
   if(InpTradeAsianSession && hour >= 0 && hour < 9) return true;

   //--- London: 08:00-12:00 GMT (BEST for Gold)
   if(InpTradeLondonSession && hour >= 8 && hour < 12) return true;

   //--- NY: 13:00-17:00 GMT (BEST for Gold)
   if(InpTradeNYSession && hour >= 13 && hour < 17) return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check London Fix times (10:30 AM, 3:00 PM GMT)                   |
//+------------------------------------------------------------------+
bool IsLondonFixTime()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   int hour = now.hour;
   int minute = now.min;

   //--- Morning fix: 10:25-10:35 GMT (avoid 10 min window)
   if(hour == 10 && minute >= 25 && minute <= 35) return true;

   //--- Afternoon fix: 14:55-15:05 GMT (avoid 10 min window)
   if(hour == 14 && minute >= 55) return true;
   if(hour == 15 && minute <= 5) return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check news time (placeholder)                                    |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   //--- TODO: Integrate with economic calendar
   //--- For now, avoid first Friday of month (NFP) around 8:30-9:30 AM EST (13:30-14:30 GMT)
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   if(now.day_of_week == 5 && now.day <= 7) // First Friday
   {
      if(now.hour == 13 && now.min >= 15) return true;
      if(now.hour == 14 && now.min <= 45) return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                           |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   datetime currentDay = iTime(InpTradingSymbol, PERIOD_D1, 0);

   if(currentDay != lastTradeDay)
   {
      //--- New day
      if(dailyTradeCount > 0)
      {
         Print("=== END OF DAY STATS ===");
         PrintDailyStats();
      }

      dailyTradeCount = 0;
      dailyMaxEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      lastTradeDay = currentDay;

      //--- Clean up tracking array
      ArrayResize(openPositions, 0);
   }

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   dailyMaxEquity = MathMax(dailyMaxEquity, currentEquity);

   //--- Clean closed positions
   RemoveClosedPositionsFromTracking();
}

//+------------------------------------------------------------------+
//| Check daily limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
   //--- Max trades
   if(dailyTradeCount >= InpMaxDailyTrades)
   {
      return false;
   }

   //--- Max drawdown
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(dailyMaxEquity == 0) dailyMaxEquity = currentEquity;

   double drawdown = (dailyMaxEquity - currentEquity) / dailyMaxEquity * 100.0;

   if(drawdown > InpMaxDailyDrawdown)
   {
      Print("CIRCUIT BREAKER: Daily drawdown limit reached: ", DoubleToString(drawdown, 2), "% (max: ", InpMaxDailyDrawdown, "%)");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Print session settings                                           |
//+------------------------------------------------------------------+
void PrintSessionSettings()
{
   Print("--- TRADING SESSIONS ---");
   if(InpTradeLondonSession) Print("London: 08:00-12:00 GMT [ACTIVE]");
   if(InpTradeNYSession) Print("NY: 13:00-17:00 GMT [ACTIVE]");
   if(InpTradeAsianSession) Print("Asian: 00:00-09:00 GMT [ACTIVE]");
   if(InpAvoidLondonFix) Print("London Fix: AVOIDED (10:25-10:35, 14:55-15:05 GMT)");
   if(InpAvoidNews) Print("High-Impact News: AVOIDED");
}

//+------------------------------------------------------------------+
//| Print daily stats                                                |
//+------------------------------------------------------------------+
void PrintDailyStats()
{
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floatingPL = currentEquity - balance;
   double dailyPL = currentEquity - (dailyMaxEquity - (dailyMaxEquity * InpMaxDailyDrawdown / 100.0));

   Print("========================================");
   Print("  DAILY STATISTICS");
   Print("========================================");
   Print("Trades Today: ", dailyTradeCount, " / ", InpMaxDailyTrades);
   Print("Current Balance: $", DoubleToString(balance, 2));
   Print("Current Equity: $", DoubleToString(currentEquity, 2));
   Print("Floating P/L: $", DoubleToString(floatingPL, 2));
   Print("Max Equity Today: $", DoubleToString(dailyMaxEquity, 2));
   double currentDrawdown = (dailyMaxEquity - currentEquity) / dailyMaxEquity * 100.0;
   Print("Current Drawdown: ", DoubleToString(currentDrawdown, 2), "% / ", InpMaxDailyDrawdown, "%");
   Print("========================================");
}
//+------------------------------------------------------------------+
