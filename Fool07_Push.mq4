//+------------------------------------------------------------------+
//|                                               Fool007ModeEA.mq4  |
//|  A real-time advanced EA with adaptive stops, robust JSON        |
//|  parsing via cJSON, push notifications, an on-chart dashboard,    |
//|  and advanced trade management designed for live trading on       |
//|  Exness.                                                         |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// Includes: Make sure you have downloaded and placed cJSON.mqh but here we have json.mqh
#include <cJSON.mqh>
#include <json.mqh>

//--------------------------------------------------------------------
// External Parameters
//--------------------------------------------------------------------
extern string  Pairs                = "EURUSD,USDJPY,GBPUSD,AUDUSD,USDCHF"; 
extern double  RiskPercentPerTrade  = 1.0;      
extern int     BaseStopLossPips     = 50;       
extern int     BaseTakeProfitPips   = 100;      
extern int     MagicNumber          = 123456;   

// Session windows (if using multi-session)
extern bool    UseMultiSession      = false;
extern int     Session1Start        = 8;        
extern int     Session1End          = 11;
extern int     Session2Start        = 14;       
extern int     Session2End          = 17;

// Indicator settings
extern int     H1_MA_Period         = 50;
extern int     M5_MA_Period         = 10;
extern int     RSI_Period           = 14;

// Advanced trade management
extern bool    UseAdaptiveStops     = true;     
extern double  ATRMultiplierSL      = 2.0;      
extern double  ATRMultiplierTP      = 3.0;      
extern int     BaseTrailingStopPips = 20;
extern int     BreakEvenPips        = 30;
extern double  PartialClosePct      = 50.0;      
extern double  PartialCloseRR       = 1.5;       

// News & safe mode settings
extern bool    UseNewsFilter         = true;
extern string  NewsAPI_URL           = "https://api.tradingeconomics.com/calendar?c=guest:guest&f=json";
extern int     NewsImpactThreshold   = 3;
extern bool    UseSymbolSpecificNews = false;  
extern double  MaxSpreadPips         = 5.0;    

// Additional strategy filters
extern bool    UseVolatilityFilter    = true;
extern double  ATR_VolatilityThreshold= 0.0010;
extern bool    UseBreakoutStrategy    = true;
extern int     BreakoutBars           = 10;
extern bool    UseMACDFilter          = true;

// Daily drawdown limit
extern double  DailyDrawdownLimitPct  = 5.0; 

//--------------------------------------------------------------------
// Global Variables
//--------------------------------------------------------------------
string  CurrencyPairs[];
int     PairCount = 0;
int     RetryMax  = 3;           
int     logFileHandle = INVALID_HANDLE;

datetime gDailyStartTime = 0;  
double   gDailyStartEquity = 0;

enum EA_STATE { EA_STATE_READY=0, EA_STATE_SAFE_MODE, EA_STATE_SUSPENDED };
EA_STATE gEAState = EA_STATE_READY;

struct TRADE_DATA
{
   int      ticket;
   string   symbol;
   string   direction; 
   datetime openTime;
   double   openPrice;
   double   riskReward;
};
TRADE_DATA openTrades[]; 

//--------------------------------------------------------------------
// 1) Logging Functions and Push Notifications
//--------------------------------------------------------------------
void OpenLogFile()
{
   if(logFileHandle == INVALID_HANDLE)
   {
      string filename = "Fool007ModeEA_Log_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
      logFileHandle = FileOpen(filename, FILE_CSV|FILE_WRITE, ',');
      if(logFileHandle != INVALID_HANDLE)
      {
         FileWrite(logFileHandle, "Ticket", "Direction", "OpenTime", "OpenPrice", 
                   "CloseTime", "ClosePrice", "Pips", "Profit", "Comment");
         FileFlush(logFileHandle);
      }
      else Print("Error opening log file: ", GetLastError());
   }
}

void LogTrade(int ticket, string direction, datetime openT, double openP, 
              datetime closeT, double closeP, string comment="")
{
   OpenLogFile();
   if(logFileHandle==INVALID_HANDLE) return;
   double pipVal = MarketInfo(Symbol(), MODE_POINT);
   double pips   = 0, profit = 0;
   if(closeP > 0 && openP > 0)
   {
      pips = (closeP - openP)/pipVal;
      if(direction == "SELL") pips = -pips;
      profit = pips * 0.1;
   }
   string row = IntegerToString(ticket) + "," + direction + "," + 
                TimeToString(openT, TIME_DATE|TIME_SECONDS) + "," + 
                DoubleToString(openP, Digits) + "," + 
                TimeToString(closeT, TIME_DATE|TIME_SECONDS) + "," + 
                DoubleToString(closeP, Digits) + "," +
                DoubleToString(pips, 1) + "," + DoubleToString(profit, 2) + "," + comment;
   FileWriteString(logFileHandle, row + "\r\n");
   FileFlush(logFileHandle);
}

void NotifyTradeEvent(string msg)
{
   // Sends a push notification (ensure notifications are enabled in Tools->Options->Notifications)
   SendNotification(msg);
}

void TrackOpenTrade(int ticket, string symbol, string dir, datetime oTime, double oPrice)
{
   TRADE_DATA td;
   td.ticket = ticket;
   td.symbol = symbol;
   td.direction = dir;
   td.openTime = oTime;
   td.openPrice = oPrice;
   td.riskReward = 0;
   int sz = ArraySize(openTrades);
   ArrayResize(openTrades, sz+1);
   openTrades[sz] = td;
   
   string notiMsg = "New Trade: " + dir + " " + symbol + " at " + 
                    DoubleToString(oPrice, Digits) + ", ticket=" + IntegerToString(ticket);
   NotifyTradeEvent(notiMsg);
}

void CloseOpenTrade(int ticket, datetime cTime, double cPrice, string comment="")
{
   for(int i = 0; i < ArraySize(openTrades); i++)
   {
      if(openTrades[i].ticket == ticket)
      {
         LogTrade(ticket, openTrades[i].direction, openTrades[i].openTime, openTrades[i].openPrice, cTime, cPrice, comment);
         string notiMsg = "Close Trade: ticket=" + IntegerToString(ticket) + " " +
                          openTrades[i].direction + " " + openTrades[i].symbol;
         NotifyTradeEvent(notiMsg);
         for(int j = i; j < ArraySize(openTrades)-1; j++)
            openTrades[j] = openTrades[j+1];
         ArrayResize(openTrades, ArraySize(openTrades)-1);
         break;
      }
   }
}

//--------------------------------------------------------------------
// 2) Multi-Session Logic
//--------------------------------------------------------------------
bool IsWithinAnySession(datetime tm)
{
   int hour = TimeHour(tm);
   if(hour >= Session1Start && hour < Session1End) return true;
   if(hour >= Session2Start && hour < Session2End) return true;
   return false;
}

bool IsTradingSessionActive()
{
   if(!UseMultiSession) return true;
   return IsWithinAnySession(TimeCurrent());
}

//--------------------------------------------------------------------
// 3) Daily Drawdown Limit
//--------------------------------------------------------------------
bool CheckDailyDrawdown()
{
   double eq = AccountEquity();
   double dd = (gDailyStartEquity - eq) / gDailyStartEquity * 100.0;
   if(dd >= DailyDrawdownLimitPct)
   {
      Print("Daily drawdown of ", dd, "% exceeded limit ", DailyDrawdownLimitPct, "% => EA suspended.");
      gEAState = EA_STATE_SUSPENDED;
      NotifyTradeEvent("EA suspended: daily drawdown reached (" + DoubleToString(dd, 1) + "%).");
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
// 4) Dynamic Lot Sizing
//--------------------------------------------------------------------
double CalculateLotSize(string symbol, double pips)
{
   double accBal = AccountBalance();
   double riskAmt = accBal * (RiskPercentPerTrade / 100.0);

   double tickVal = MarketInfo(symbol, MODE_TICKVALUE);
   double tickSize = MarketInfo(symbol, MODE_TICKSIZE);
   if(tickSize <= 0) tickSize = 0.00001;
   double pipVal = (tickVal * (MarketInfo(symbol, MODE_POINT)/tickSize) * 10.0);
   if(pipVal <= 0) pipVal = 10.0;

   double costPerTrade = pips * pipVal;
   if(costPerTrade <= 0) costPerTrade = 1;
   double rawLots = riskAmt / costPerTrade;

   double step = MarketInfo(symbol, MODE_LOTSTEP);
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);

   rawLots = MathFloor(rawLots / step) * step;
   if(rawLots < minLot) rawLots = minLot;
   if(rawLots > maxLot) rawLots = maxLot;
   return NormalizeDouble(rawLots, 2);
}

//--------------------------------------------------------------------
// 5) Robust Order Send/Modify with Retries
//--------------------------------------------------------------------
int RobustOrderSend(string symbol, int cmd, double volume, double price, int slippage, double sl, double tp, string comment)
{
   int ticket = -1;
   for(int attempt = 0; attempt < RetryMax; attempt++)
   {
      ticket = OrderSend(symbol, cmd, volume, price, slippage, sl, tp, comment, MagicNumber, 0, clrBlue);
      if(ticket >= 0)
      {
         Print("OrderSend succeeded on attempt ", attempt+1, ", ticket=", ticket);
         return ticket;
      }
      else
      {
         int err = GetLastError();
         Print("OrderSend error on attempt ", attempt+1, " code=", err);
         Sleep(1000);
         RefreshRates();
      }
   }
   return ticket;
}

bool RobustOrderModify(int ticket, double openPrice, double stoploss, double takeprofit)
{
   for(int attempt = 0; attempt < RetryMax; attempt++)
   {
      if(OrderModify(ticket, openPrice, stoploss, takeprofit, 0, clrYellow))
         return true;
      else
      {
         int err = GetLastError();
         Print("OrderModify error on attempt ", attempt+1, " code=", err);
         Sleep(500);
         RefreshRates();
      }
   }
   return false;
}

//--------------------------------------------------------------------
// 6) Real-time News Parsing using cJSON
//--------------------------------------------------------------------
bool IsMajorNewsTime()
{
   if(!UseNewsFilter) return false;
   
   string hdr = "Content-Type: application/json\r\n";
   char req[], resp[];
   string respHdr;
   int res = WebRequest("GET", NewsAPI_URL, hdr, 5000, req, resp, respHdr);
   if(res < 0)
   {
      Print("News WebRequest error: ", GetLastError());
      return false;
   }
   string json = CharArrayToString(resp, 0, ArraySize(resp));
   return ParseNewsWithCJSON(json);
}

bool ParseNewsWithCJSON(string json)
{
   cJSON *root = cJSON_Parse(json);
   if(root == NULL)
   {
      Print("cJSON_Parse failed: invalid JSON format");
      return false;
   }
   bool majorEvent = false;
   if(root.type == cJSON_Array)
   {
      majorEvent = CheckNewsArray(root);
   }
   else
   {
      cJSON *calendar = cJSON_GetObjectItem(root, "calendar");
      if(calendar != NULL && calendar.type == cJSON_Array)
         majorEvent = CheckNewsArray(*calendar);
      else
      {
         cJSON *data = cJSON_GetObjectItem(root, "data");
         if(data != NULL && data.type == cJSON_Array)
            majorEvent = CheckNewsArray(*data);
      }
   }
   cJSON_Delete(root);
   return majorEvent;
}

bool CheckNewsArray(cJSON &arr)
{
   int arrSize = cJSON_GetArraySize(&arr);
   for(int i = 0; i < arrSize; i++)
   {
      cJSON *ev = cJSON_GetArrayItem(&arr, i);
      if(ev != NULL && ev.type == cJSON_Object)
      {
         datetime eTime = GetEventTime(ev);
         int impact = GetEventImpact(ev);
         if(eTime > 0 && impact >= NewsImpactThreshold)
         {
            if(MathAbs(TimeCurrent() - eTime) <= 1800)
            {
               Print("Major news event detected: Time=", TimeToString(eTime, TIME_DATE|TIME_SECONDS), " Impact=", impact);
               return true;
            }
         }
      }
   }
   return false;
}

datetime GetEventTime(cJSON *ev)
{
   cJSON *dt = cJSON_GetObjectItem(ev, "DateTime");
   if(dt != NULL && dt.type == cJSON_String)
      return StrToTime(dt.valuestring);
   cJSON *dt2 = cJSON_GetObjectItem(ev, "datetime");
   if(dt2 != NULL && dt2.type == cJSON_String)
      return StrToTime(dt2.valuestring);
   return 0;
}

int GetEventImpact(cJSON *ev)
{
   cJSON *im = cJSON_GetObjectItem(ev, "Impact");
   if(im != NULL && im.type == cJSON_Number)
      return (int)im.valuedouble;
   if(im != NULL && im.type == cJSON_String)
      return (int)StringToInteger(im.valuestring);
   cJSON *im2 = cJSON_GetObjectItem(ev, "impact");
   if(im2 != NULL && im2.type == cJSON_Number)
      return (int)im2.valuedouble;
   if(im2 != NULL && im2.type == cJSON_String)
      return (int)StringToInteger(im2.valuestring);
   return 0;
}

//--------------------------------------------------------------------
// 7) Advanced Filters: Volatility, Breakout, MACD
//--------------------------------------------------------------------
bool CheckVolatilityFilter(string symbol)
{
   double atr = iATR(symbol, PERIOD_M5, 14, 0);
   return (atr >= ATR_VolatilityThreshold);
}

bool CheckBreakoutFilter(string symbol, bool isBuy)
{
   double cClose = iClose(symbol, PERIOD_M5, 0);
   double extreme = (isBuy ? -1e10 : 1e10);
   for(int i = 1; i <= BreakoutBars; i++)
   {
      if(isBuy)
      {
         double h = iHigh(symbol, PERIOD_M5, i);
         if(h > extreme) extreme = h;
      }
      else
      {
         double l = iLow(symbol, PERIOD_M5, i);
         if(l < extreme) extreme = l;
      }
   }
   if(isBuy && cClose > extreme) return true;
   if(!isBuy && cClose < extreme) return true;
   return false;
}

bool CheckMACDBuy(string symbol)
{
   double mc = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double mp = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (mc > mp);
}

bool CheckMACDSell(string symbol)
{
   double mc = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double mp = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (mc < mp);
}

//--------------------------------------------------------------------
// 8) Main Buy/Sell Signal Checks with Adaptive Stops
//--------------------------------------------------------------------
bool CheckBuySignal(string symbol, double &slDist, double &tpDist)
{
   double h1c = iClose(symbol, PERIOD_H1, 0);
   double h1ma = iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   if(h1c <= h1ma) return false;
   
   double cM5 = iClose(symbol, PERIOD_M5, 0);
   double pM5 = iClose(symbol, PERIOD_M5, 1);
   double maC = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maP = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5 < maP && cM5 > maC)) return false;
   
   double rsi = iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi <= 50) return false;
   
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol)) return false;
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol, true)) return false;
   if(UseMACDFilter && !CheckMACDBuy(symbol)) return false;
   
   double spreadPts = MarketInfo(symbol, MODE_SPREAD);
   double pip = MarketInfo(symbol, MODE_POINT);
   double spreadPips = spreadPts * pip / pip;
   if(spreadPips > MaxSpreadPips) return false;
   
   if(UseAdaptiveStops)
   {
      double atrVal = iATR(symbol, PERIOD_M5, 14, 0);
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

bool CheckSellSignal(string symbol, double &slDist, double &tpDist)
{
   double h1c = iClose(symbol, PERIOD_H1, 0);
   double h1ma = iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   if(h1c >= h1ma) return false;
   
   double cM5 = iClose(symbol, PERIOD_M5, 0);
   double pM5 = iClose(symbol, PERIOD_M5, 1);
   double maC = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maP = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5 > maP && cM5 < maC)) return false;
   
   double rsi = iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi >= 50) return false;
   
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol)) return false;
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol, false)) return false;
   if(UseMACDFilter && !CheckMACDSell(symbol)) return false;
   
   double spreadPts = MarketInfo(symbol, MODE_SPREAD);
   double pip = MarketInfo(symbol, MODE_POINT);
   double spreadPips = spreadPts * pip / pip;
   if(spreadPips > MaxSpreadPips) return false;
   
   if(UseAdaptiveStops)
   {
      double atrVal = iATR(symbol, PERIOD_M5, 14, 0);
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
// 9) Manage Open Trades: Trailing, Break-even, Partial & Final Close
//--------------------------------------------------------------------
void ManageOpenTrades()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      
      string sym = OrderSymbol();
      double bid = MarketInfo(sym, MODE_BID);
      double ask = MarketInfo(sym, MODE_ASK);
      double pip = MarketInfo(sym, MODE_POINT);
      double sl = OrderStopLoss();
      double newSL;
      double trailingDist = BaseTrailingStopPips;
      
      if(UseAdaptiveStops)
      {
         double atrVal = iATR(sym, PERIOD_M5, 14, 0);
         trailingDist = 1.5 * (atrVal / pip);
      }
      
      double currentPrice = (OrderType() == OP_BUY ? bid : ask);
      
      // Trailing Stop Update
      if(OrderType() == OP_BUY)
      {
         newSL = NormalizeDouble(currentPrice - trailingDist * pip, Digits);
         if(newSL > sl)
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      else if(OrderType() == OP_SELL)
      {
         newSL = NormalizeDouble(currentPrice + trailingDist * pip, Digits);
         if(sl == 0 || newSL < sl)
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      
      // Break-even Adjustment
      double profitPips = (OrderType() == OP_BUY ? (bid - OrderOpenPrice()) : (OrderOpenPrice() - ask)) / pip;
      if(profitPips >= BreakEvenPips)
      {
         double beSL = OrderOpenPrice();
         if(OrderType() == OP_BUY)
         {
            if(beSL > OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
         else
         {
            if(OrderStopLoss() == 0 || beSL < OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
      }
      
      // Partial Close Logic (based on R:R threshold)
      double slpips = (OrderType() == OP_BUY ? (OrderOpenPrice() - OrderStopLoss()) : (OrderStopLoss() - OrderOpenPrice())) / pip;
      if(slpips < 0) slpips = BaseStopLossPips;
      double rr = profitPips / slpips;
      if(rr >= PartialCloseRR && OrderLots() > 0.01)
      {
         double pcVolume = NormalizeDouble(OrderLots() * (PartialClosePct / 100.0), 2);
         if(pcVolume >= 0.01)
         {
            double closePrice = (OrderType() == OP_BUY ? bid : ask);
            if(OrderClose(OrderTicket(), pcVolume, closePrice, 3, clrAqua))
            {
               LogTrade(OrderTicket(), (OrderType() == OP_BUY ? "BUY" : "SELL"),
                        OrderOpenTime(), OrderOpenPrice(), TimeCurrent(), closePrice, "PartialClose");
               double partialPips = (closePrice - OrderOpenPrice()) / pip;
               if(OrderType() == OP_SELL) partialPips = -partialPips;
               NotifyTradeEvent("Partial close: ticket=" + IntegerToString(OrderTicket()) +
                                " pips=" + DoubleToString(partialPips, 1));
            }
         }
      }
      
      // Final Close Detection
      if(OrderCloseTime() > 0)
      {
         double cPrice = OrderClosePrice();
         CloseOpenTrade(OrderTicket(), OrderCloseTime(), cPrice, "FinalClose");
      }
   }
}

//--------------------------------------------------------------------
// 10) UI Dashboard update
//--------------------------------------------------------------------
void UpdateDashboard()
{
   string dashboardText = "Fool007ModeEA\n";
   dashboardText += "State: " + IntegerToString(gEAState) + "\n";
   dashboardText += "Daily Equity Baseline: " + DoubleToString(gDailyStartEquity, 2) + "\n";
   dashboardText += "Current Equity: " + DoubleToString(AccountEquity(), 2) + "\n";
   dashboardText += "Open Orders: " + IntegerToString(OrdersTotal()) + "\n";
   
   if(ObjectFind(0, "Fool007Dashboard") < 0)
   {
      ObjectCreate(0, "Fool007Dashboard", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "Fool007Dashboard", OBJPROP_CORNER, CORNER_RIGHT_TOP);
      ObjectSetInteger(0, "Fool007Dashboard", OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, "Fool007Dashboard", OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, "Fool007Dashboard", OBJPROP_FONTSIZE, 12);
      ObjectSetString(0, "Fool007Dashboard", OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, "Fool007Dashboard", OBJPROP_COLOR, clrWhite);
   }
   ObjectSetString(0, "Fool007Dashboard", OBJPROP_TEXT, dashboardText);
}

//--------------------------------------------------------------------
// 11) OnTick: Main Driver
//--------------------------------------------------------------------
int start()
{
   ResetDailyEquityIfNewDay();
   if(CheckDailyDrawdown()) return(0);
   
   if(gEAState == EA_STATE_SUSPENDED)
   {
      ManageOpenTrades();
      UpdateDashboard();
      return(0);
   }
   else if(gEAState == EA_STATE_SAFE_MODE)
   {
      ManageOpenTrades();
      UpdateDashboard();
      return(0);
   }

   if(!IsTradingSessionActive()) return(0);
   
   if(UseNewsFilter && IsMajorNewsTime())
   {
      Print("High-impact news detected => safe mode");
      gEAState = EA_STATE_SAFE_MODE;
      NotifyTradeEvent("EA switched to safe mode due to major news.");
      UpdateDashboard();
      return(0);
   }

   RefreshRates();

   for(int i=0; i<PairCount; i++)
   {
      string symbol = CurrencyPairs[i];
      if(MarketInfo(symbol, MODE_SPREAD) <= 0) continue;
      
      // Skip if an order is already open for this symbol
      int cc = 0;
      for(int j=0; j<OrdersTotal(); j++)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == symbol && OrderMagicNumber() == MagicNumber)
               cc++;
         }
      }
      if(cc > 0) continue;
      
      double slDist = 0, tpDist = 0;
      if(CheckBuySignal(symbol, slDist, tpDist))
      {
         double lot = CalculateLotSize(symbol, slDist);
         double ask = MarketInfo(symbol, MODE_ASK);
         double pip = MarketInfo(symbol, MODE_POINT);
         double sl = ask - slDist * pip;
         double tp = ask + tpDist * pip;
         int ticket = RobustOrderSend(symbol, OP_BUY, lot, ask, 3, sl, tp, "Fool007 Buy");
         if(ticket >= 0)
         {
            TrackOpenTrade(ticket, symbol, "BUY", TimeCurrent(), ask);
         }
      }
      else if(CheckSellSignal(symbol, slDist, tpDist))
      {
         double lot = CalculateLotSize(symbol, slDist);
         double bid = MarketInfo(symbol, MODE_BID);
         double pip = MarketInfo(symbol, MODE_POINT);
         double sl = bid + slDist * pip;
         double tp = bid - tpDist * pip;
         int ticket = RobustOrderSend(symbol, OP_SELL, lot, bid, 3, sl, tp, "Fool007 Sell");
         if(ticket >= 0)
         {
            TrackOpenTrade(ticket, symbol, "SELL", TimeCurrent(), bid);
         }
      }
   }
   
   ManageOpenTrades();
   UpdateDashboard();
   return 0;
}

//--------------------------------------------------------------------
// OnInit: Initialization function
//--------------------------------------------------------------------
int init()
{
   Print("Fool007ModeEA init: Exness version (compiled without __TIME__ macro)");
   PairCount = StringSplit(Pairs, ',', CurrencyPairs);
   Print("Detected ", PairCount, " pairs: ", Pairs);
   
   gDailyStartTime = TimeCurrent();
   gDailyStartEquity = AccountEquity();
   Print("Daily equity baseline set to ", gDailyStartEquity);
   return 0;
}

//--------------------------------------------------------------------
// OnDeinit: Deinitialization function
//--------------------------------------------------------------------
int deinit()
{
   Print("Fool007ModeEA deinit: Closing log file and removing dashboard.");
   if(logFileHandle != INVALID_HANDLE)
      FileClose(logFileHandle);
   ObjectDelete(0, "Fool007Dashboard");
   return 0;
}
//+------------------------------------------------------------------+
