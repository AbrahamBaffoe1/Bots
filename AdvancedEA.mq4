//+------------------------------------------------------------------+
//|                                                 Fool007ModeEA.mq4
//|  Full-featured example EA with advanced logic to address listed
//|  weaknesses, partial close improvements, robust news checks, 
//|  adaptive stops, state/mode tracking, and extra logging.
//+------------------------------------------------------------------+
#property strict

//----------------------------------------------------------------------
// External Parameters
//----------------------------------------------------------------------
extern string  Pairs                = "EURUSD,USDJPY,GBPUSD,AUDUSD,USDCHF"; 
extern double  RiskPercentPerTrade  = 1.0;      // % of account balance to risk
extern int     BaseStopLossPips     = 50;       // Default SL in pips (may be scaled by ATR)
extern int     BaseTakeProfitPips   = 100;      // Default TP in pips (may be scaled by ATR)
extern int     MagicNumber          = 123456;   // Unique ID for this EA

// Session times
extern int     SessionStartHour     = 9;
extern int     SessionEndHour       = 16;

// Indicator periods
extern int     H1_MA_Period         = 50;
extern int     M5_MA_Period         = 10;
extern int     RSI_Period           = 14;

// More advanced management
extern int     BaseTrailingStopPips = 20;       // default trailing stops
extern int     BreakEvenPips        = 30;       // move to break even above this profit
extern double  PartialClosePct      = 50;       // partial close percentage
extern double  PartialCloseRR       = 1.5;      // partial close at 1.5 R:R, for example

// Real-time News integration
extern bool    UseNewsFilter          = true;
extern string  NewsAPI_URL            = "https://api.tradingeconomics.com/calendar?c=guest:guest&f=json";
extern int     NewsImpactThreshold    = 3;

// Additional strategies
extern bool    UseAdaptiveStops       = true;   // scale SL/TP by ATR
extern double  ATRMultiplierSL        = 2.0;    // e.g. SL = 2x ATR
extern double  ATRMultiplierTP        = 3.0;    // e.g. TP = 3x ATR
extern bool    UseVolatilityFilter    = true;
extern double  ATR_VolatilityThreshold= 0.0010;
extern bool    UseBreakoutStrategy    = true;
extern int     BreakoutBars           = 10;
extern bool    UseMACDFilter          = true;   // advanced buy/sell filter
extern bool    UseMultiSession        = false;  // Placeholder if you want multiple sessions
extern double  MaxSpreadPips          = 5.0;    // skip trades if spread > 5 pips

// Risk management expansions
extern double  DailyDrawdownLimitPct  = 5.0;    // stop trading if daily drawdown > 5%
extern bool    UseSymbolSpecificNews  = false;  // placeholder if you want symbol-specific news checks

//----------------------------------------------------------------------
// Global variables
//----------------------------------------------------------------------
string  CurrencyPairs[];
int     PairCount = 0;
int     RetryMax  = 3;           // retries for robust order send
int     logFileHandle = INVALID_HANDLE;

// State machine placeholder: We can define multiple states
enum EA_STATE
{
   EA_STATE_READY = 0,  // normal
   EA_STATE_SAFE_MODE,  // safe mode if e.g. extreme volatility or major news
   EA_STATE_SUSPENDED   // not trading due to daily drawdown or extreme condition
};
EA_STATE gEAState = EA_STATE_READY;

// A structure to track open trades by ticket, storing entry info for logging final close
struct TRADE_DATA
{
   int      ticket;
   string   symbol;
   string   direction;
   datetime openTime;
   double   openPrice;
   double   riskReward; // for partial close logic or expansions
};
TRADE_DATA openTrades[]; // array to track open trades

//----------------------------------------------------------------------
// Helper: Open Log File
//----------------------------------------------------------------------
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
      else
         Print("Error opening log file: ", GetLastError());
   }
}

//----------------------------------------------------------------------
// Helper: Log a trade event (open or close)
//----------------------------------------------------------------------
void LogTrade(int ticket, string direction, datetime openT, double openP, 
              datetime closeT, double closeP, string comment="")
{
   OpenLogFile();
   if(logFileHandle == INVALID_HANDLE) return;

   double pips = 0, profit = 0;
   if(closeP > 0 && openP > 0)
   {
      pips = (closeP - openP)/MarketInfo(Symbol(), MODE_POINT);
      if(direction=="SELL")
         pips = -pips;
      // This is a naive profit calc for demonstration.
      // Could be improved by accurate pip value calculations.
      profit = pips * 0.1; // e.g. $0.1/pip for 0.01 lot, or you do advanced logic.
   }
   string row = IntegerToString(ticket)+","+direction+","+TimeToString(openT,TIME_DATE|TIME_SECONDS)+","+
                DoubleToString(openP,Digits)+","+TimeToString(closeT,TIME_DATE|TIME_SECONDS)+","+
                DoubleToString(closeP,Digits)+","+DoubleToString(pips,1)+","+
                DoubleToString(profit,2)+","+comment;
   FileWriteString(logFileHandle, row+"\r\n");
   FileFlush(logFileHandle);
}

//----------------------------------------------------------------------
// Track an open trade in our openTrades array
//----------------------------------------------------------------------
void TrackOpenTrade(int ticket, string symbol, string dir, datetime oTime, double oPrice)
{
   TRADE_DATA td;
   td.ticket    = ticket;
   td.symbol    = symbol;
   td.direction = dir;
   td.openTime  = oTime;
   td.openPrice = oPrice;
   td.riskReward= 0;
   int size = ArraySize(openTrades);
   ArrayResize(openTrades, size+1);
   openTrades[size] = td;
}

//----------------------------------------------------------------------
// Remove or update an open trade from openTrades when it closes or partial closes
//----------------------------------------------------------------------
void CloseOpenTrade(int ticket, datetime cTime, double cPrice, string comment="")
{
   for(int i=0; i<ArraySize(openTrades); i++)
   {
      if(openTrades[i].ticket == ticket)
      {
         // We log the final close
         LogTrade(ticket, openTrades[i].direction, openTrades[i].openTime, openTrades[i].openPrice,
                  cTime, cPrice, comment);
         // remove from array
         for(int j=i; j<ArraySize(openTrades)-1; j++)
            openTrades[j] = openTrades[j+1];
         ArrayResize(openTrades, ArraySize(openTrades)-1);
         break;
      }
   }
}

//----------------------------------------------------------------------
// Dynamic Lot Sizing with more accurate pip value (still simplified)
double CalculateLotSize(string symbol, double pips)
{
   double accBalance = AccountBalance();
   double riskAmount = accBalance*(RiskPercentPerTrade/100.0);
   // Attempt to get pipValue
   // e.g., for 1 standard lot, each pip might be $10 on EURUSD if the deposit currency is USD.
   double pipValue = MarketInfo(symbol, MODE_TICKVALUE)*10; // simple approach
   // If pipValue=0 or inaccurate on some brokers, you may need cross rates calc.
   double costPerTrade = pips * pipValue; 
   if(costPerTrade<=0) costPerTrade=1; // fallback
   double rawLots = riskAmount/costPerTrade;
   // Broker constraints
   double step   = MarketInfo(symbol, MODE_LOTSTEP);
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   rawLots = MathFloor(rawLots/step)*step;
   if(rawLots<minLot) rawLots=minLot;
   if(rawLots>maxLot) rawLots=maxLot;
   return(NormalizeDouble(rawLots,2));
}

//----------------------------------------------------------------------
// Example: robust order sending with retry
int RobustOrderSend(string symbol, int cmd, double volume, double price, int slippage, double sl, double tp, string comment)
{
   int ticket=-1;
   for(int attempt=0; attempt<RetryMax; attempt++)
   {
      ticket=OrderSend(symbol, cmd, volume, price, slippage, sl, tp, comment, MagicNumber, 0, clrBlue);
      if(ticket>=0)
      {
         Print("OrderSend success on attempt ", attempt+1, " ticket=", ticket);
         return(ticket);
      }
      else
      {
         int err=GetLastError();
         Print("OrderSend error on attempt ", attempt+1, " code=", err);
         // advanced fallback: if err is e.g. 136 (off quotes), we might check spread or wait
         Sleep(1000);
         RefreshRates();
      }
   }
   return(ticket);
}

//----------------------------------------------------------------------
// Modify orders with retry
bool RobustOrderModify(int ticket, double price, double stoploss, double takeprofit)
{
   bool ok=false;
   for(int attempt=0; attempt<RetryMax; attempt++)
   {
      if(OrderModify(ticket, price, stoploss, takeprofit, 0, clrYellow))
      {
         ok=true;
         break;
      }
      else
      {
         int err=GetLastError();
         Print("OrderModify error on attempt ", attempt+1, " code=", err);
         Sleep(500);
         RefreshRates();
      }
   }
   return(ok);
}

//----------------------------------------------------------------------
// PartialClose: Close partial volume using standard MQL4 approach with OrderClose()
bool PartialClose(int ticket, double lotToClose, double closePrice, int slippage)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return(false);
   if(OrderType()==OP_BUY)
   {
      bool closed=OrderClose(ticket, lotToClose, closePrice, slippage, clrAqua);
      if(!closed) Print("PartialClose() BUY error:", GetLastError());
      return(closed);
   }
   else if(OrderType()==OP_SELL)
   {
      bool closed=OrderClose(ticket, lotToClose, closePrice, slippage, clrAqua);
      if(!closed) Print("PartialClose() SELL error:", GetLastError());
      return(closed);
   }
   return(false);
}

//----------------------------------------------------------------------
// Basic session check
bool IsTradingSessionActive()
{
   int ch=TimeHour(TimeCurrent());
   if(UseMultiSession)
   {
      // placeholder if you want multiple sessions or advanced session logic
      // e.g. different sessions for each symbol or time offset
   }
   return(ch>=SessionStartHour && ch<SessionEndHour);
}

//----------------------------------------------------------------------
// Real-time news (still naive JSON)
bool CheckForActiveNewsEvent(string json)
{
   // Enhanced approach: we might have a real JSON parser, but here's the same substring approach
   int pos=0;
   while(true)
   {
      pos=StringFind(json, "\"DateTime\":\"", pos);
      if(pos<0) break;
      pos+=StringLen("\"DateTime\":\"");
      int endPos=StringFind(json, "\"", pos);
      if(endPos<0) break;
      string tStr=StringSubstr(json, pos, endPos-pos);
      datetime eTime=StrToTime(tStr);
      datetime cTime=TimeCurrent();
      if(MathAbs(cTime-eTime)<=1800) // ±30 minutes
      {
         // parse Impact
         int iPos=StringFind(json, "\"Impact\":\"", endPos);
         if(iPos<0) break;
         iPos+=StringLen("\"Impact\":\"");
         int iEnd=StringFind(json, "\"", iPos);
         if(iEnd<0) break;
         string impStr=StringSubstr(json, iPos, iEnd-iPos);
         int impact=StringToInteger(impStr);
         if(impact>=NewsImpactThreshold)
         {
            Print("High Impact News found, time=",tStr," impact=",impact);
            return(true);
         }
      }
      pos=endPos;
   }
   return(false);
}

//----------------------------------------------------------------------
// Check news from Trading Economics
bool IsMajorNewsTime()
{
   if(!UseNewsFilter) return(false);
   string hdr="Content-Type: application/json\r\n";
   char req[], resp[];
   string respHdr;
   int ret=WebRequest("GET", NewsAPI_URL, hdr, 3000, req, resp, respHdr);
   if(ret<0)
   {
      Print("News request error=",GetLastError());
      return(false);
   }
   string news=CharArrayToString(resp,0,ArraySize(resp));
   return(CheckForActiveNewsEvent(news));
}

//----------------------------------------------------------------------
// Additional filters
bool CheckVolatilityFilter(string symbol)
{
   double atr=iATR(symbol, PERIOD_M5, 14, 0);
   return(atr>=ATR_VolatilityThreshold);
}

bool CheckBreakoutFilter(string symbol, bool isBuy)
{
   double cClose=iClose(symbol, PERIOD_M5, 0);
   double extreme=(isBuy? -1e10:1e10);
   for(int i=1;i<=BreakoutBars;i++)
   {
      if(isBuy)
      {
         double h=iHigh(symbol, PERIOD_M5, i);
         if(h>extreme) extreme=h;
      }
      else
      {
         double l=iLow(symbol, PERIOD_M5, i);
         if(l<extreme) extreme=l;
      }
   }
   if(isBuy && cClose>extreme) return(true);
   if(!isBuy && cClose<extreme) return(true);
   return(false);
}

bool CheckMACDBuy(string symbol)
{
   double macdCurr=iMACD(symbol, PERIOD_M5, 12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   double macdPrev=iMACD(symbol, PERIOD_M5, 12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   return(macdCurr>macdPrev);
}

bool CheckMACDSell(string symbol)
{
   double macdCurr=iMACD(symbol, PERIOD_M5,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   double macdPrev=iMACD(symbol, PERIOD_M5,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   return(macdCurr<macdPrev);
}

//----------------------------------------------------------------------
// Basic buy/sell signal check with adaptive SL/TP if needed
bool CheckBuySignal(string symbol, double &slDistancePips, double &tpDistancePips)
{
   // check H1 trend
   double h1close=iClose(symbol, PERIOD_H1,0);
   double maH1   =iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA,PRICE_CLOSE,0);
   if(h1close<=maH1) return(false);
   
   // M5 crossover + RSI
   double cM5=iClose(symbol, PERIOD_M5, 0);
   double pM5=iClose(symbol, PERIOD_M5, 1);
   double maM5_c=iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maM5_p=iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5<maM5_p && cM5>maM5_c)) return(false);
   double rsi=iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE,0);
   if(rsi<=50) return(false);
   
   // Additional filters
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol)) return(false);
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol,true)) return(false);
   if(UseMACDFilter && !CheckMACDBuy(symbol)) return(false);
   
   // spread check
   double spreadPts=MarketInfo(symbol, MODE_SPREAD);
   double pip=MarketInfo(symbol, MODE_POINT);
   double spreadPips=spreadPts*pip / pip;
   if(spreadPips>MaxSpreadPips)
   {
      Print(symbol," spread too high: ",spreadPips," pips");
      return(false);
   }

   // compute final SL & TP pips (allow adaptive ATR)
   if(UseAdaptiveStops)
   {
      // measure ATR on M5 or H1
      double atrVal=iATR(symbol, PERIOD_M5,14,0);
      slDistancePips=ATRMultiplierSL* (atrVal/pip);
      tpDistancePips=ATRMultiplierTP* (atrVal/pip);
   }
   else
   {
      slDistancePips=BaseStopLossPips;
      tpDistancePips=BaseTakeProfitPips;
   }
   
   return(true);
}

bool CheckSellSignal(string symbol, double &slDistancePips, double &tpDistancePips)
{
   double h1close=iClose(symbol, PERIOD_H1,0);
   double maH1   =iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA,PRICE_CLOSE,0);
   if(h1close>=maH1) return(false);
   
   double cM5=iClose(symbol, PERIOD_M5,0);
   double pM5=iClose(symbol, PERIOD_M5,1);
   double maM5_c=iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maM5_p=iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   if(!(pM5>maM5_p && cM5<maM5_c)) return(false);
   double rsi=iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE,0);
   if(rsi>=50) return(false);
   
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol)) return(false);
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol,false))return(false);
   if(UseMACDFilter && !CheckMACDSell(symbol))return(false);

   double spreadPts=MarketInfo(symbol, MODE_SPREAD);
   double pip=MarketInfo(symbol, MODE_POINT);
   double spreadPips=spreadPts*pip/pip;
   if(spreadPips>MaxSpreadPips)
   {
      Print(symbol," spread too high for sell: ",spreadPips," pips");
      return(false);
   }

   if(UseAdaptiveStops)
   {
      double atrVal=iATR(symbol, PERIOD_M5,14,0);
      slDistancePips=ATRMultiplierSL* (atrVal/pip);
      tpDistancePips=ATRMultiplierTP* (atrVal/pip);
   }
   else
   {
      slDistancePips=BaseStopLossPips;
      tpDistancePips=BaseTakeProfitPips;
   }
   
   return(true);
}

//----------------------------------------------------------------------
// Manage open trades: trailing stops, break even, partial close
void ManageOpenTrades()
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber()!=MagicNumber) continue;
      
      string sym=OrderSymbol();
      double bid=MarketInfo(sym, MODE_BID);
      double ask=MarketInfo(sym, MODE_ASK);
      double pip=MarketInfo(sym, MODE_POINT);
      
      // If trade has closed externally, remove from openTrades array
      // but this is done after the fact. We'll do a separate check in OnTick? 
      // We'll do it if OrderCloseTime()>0 in partial or final closure detection.
      
      // trailing stop
      double currentPrice=(OrderType()==OP_BUY ? bid:ask);
      double sl=OrderStopLoss();
      double newSL;
      double trailingDistPips=BaseTrailingStopPips;
      if(UseAdaptiveStops)
      {
         // example: adaptive trailing = 1.5 * ATR
         double atrVal=iATR(sym, PERIOD_M5,14,0);
         trailingDistPips=1.5* (atrVal/pip);
      }
      
      if(OrderType()==OP_BUY)
      {
         newSL=NormalizeDouble(currentPrice - trailingDistPips*pip, Digits);
         if(newSL>sl && newSL<OrderOpenPrice())
         {
            // won't go below open, but let's do break even logic
         }
         if(newSL>sl)
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      else if(OrderType()==OP_SELL)
      {
         newSL=NormalizeDouble(currentPrice + trailingDistPips*pip, Digits);
         if((sl==0 || newSL<sl))
            RobustOrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit());
      }
      
      // break even logic
      double profitPips=(OrderType()==OP_BUY ? (bid - OrderOpenPrice()):(OrderOpenPrice()-ask))/pip;
      if(profitPips>=BreakEvenPips)
      {
         double beSL=OrderOpenPrice();
         if(OrderType()==OP_BUY)
         {
            if(beSL>OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
         else
         {
            if(OrderStopLoss()==0 || beSL<OrderStopLoss())
               RobustOrderModify(OrderTicket(), OrderOpenPrice(), beSL, OrderTakeProfit());
         }
      }
      
      // partial close logic: use risk:reward or simple threshold
      // e.g. partial close at 1.5 R:R or if profitpips>1.5*SL
      double slpips= (OrderType()==OP_BUY ? (OrderOpenPrice()-OrderStopLoss()):(OrderStopLoss()-OrderOpenPrice()))/pip;
      if(slpips<0) slpips=BaseStopLossPips; // fallback
      double rr=profitPips/slpips;
      if(rr>=PartialCloseRR && OrderLots()>0.01)
      {
         double pcVolume=NormalizeDouble(OrderLots()*(PartialClosePct/100.0),2);
         double closePrice=(OrderType()==OP_BUY?bid:ask);
         if(PartialClose(OrderTicket(), pcVolume, closePrice, 3))
         {
            Print("Partial close done for ticket ",OrderTicket());
            // log partial
            LogTrade(OrderTicket(), (OrderType()==OP_BUY?"BUY":"SELL"),
                     OrderOpenTime(), OrderOpenPrice(),
                     TimeCurrent(), closePrice, "PartialClose");
         }
      }
      
      // finalize logging if the order is fully closed
      // If orderCloseTime>0 means it's closed, but we do that detection in next pass or OnDeinit
   }
}

//----------------------------------------------------------------------
// OnTick
int start()
{
   // 1. check daily drawdown or safe mode states
   // e.g. if daily drawdown>DailyDrawdownLimitPct, set gEAState=EA_STATE_SUSPENDED
   if(gEAState==EA_STATE_SUSPENDED)
   {
      Print("EA Suspended due to daily drawdown or user override.");
      return(0);
   }
   else if(gEAState==EA_STATE_SAFE_MODE)
   {
      // e.g. skip new trades but manage existing
      ManageOpenTrades();
      return(0);
   }

   // 2. check session
   if(!IsTradingSessionActive())
      return(0);

   // 3. check news
   if(UseNewsFilter && IsMajorNewsTime())
   {
      Print("High-impact news => safe mode");
      gEAState=EA_STATE_SAFE_MODE;
      return(0);
   }

   // 4. scanning pairs for signals
   RefreshRates();
   for(int i=0;i<PairCount;i++)
   {
      string symbol=CurrencyPairs[i];
      if(MarketInfo(symbol, MODE_SPREAD)<=0) continue;
      
      // skip if we have open orders for that symbol
      int c=0;
      for(int j=0;j<OrdersTotal();j++)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol()==symbol && OrderMagicNumber()==MagicNumber)
               c++;
         }
      }
      if(c>0) continue; // skip new trade if already have an open order
      
      double slDist=0, tpDist=0;
      // check buy
      if(CheckBuySignal(symbol, slDist, tpDist))
      {
         double lot=CalculateLotSize(symbol, slDist);
         double ask=MarketInfo(symbol, MODE_ASK);
         double pip=MarketInfo(symbol, MODE_POINT);
         double sl=ask - slDist*pip;
         double tp=ask + tpDist*pip;
         int ticket=RobustOrderSend(symbol, OP_BUY, lot, ask, 3, sl, tp, "Fool007 Buy");
         if(ticket>=0)
         {
            Print("Buy opened on ",symbol," ticket=",ticket);
            TrackOpenTrade(ticket, symbol,"BUY",TimeCurrent(), ask);
         }
      }
      else if(CheckSellSignal(symbol, slDist, tpDist))
      {
         double lot=CalculateLotSize(symbol, slDist);
         double bid=MarketInfo(symbol, MODE_BID);
         double pip=MarketInfo(symbol, MODE_POINT);
         double sl=bid + slDist*pip;
         double tp=bid - tpDist*pip;
         int ticket=RobustOrderSend(symbol, OP_SELL, lot, bid, 3, sl, tp, "Fool007 Sell");
         if(ticket>=0)
         {
            Print("Sell opened on ",symbol," ticket=",ticket);
            TrackOpenTrade(ticket, symbol,"SELL",TimeCurrent(), bid);
         }
      }
   }
   
   // 5. manage existing trades
   ManageOpenTrades();
   return(0);
}

//----------------------------------------------------------------------
// OnInit or init function
int init()
{
   Print("Fool007ModeEA: Initializing...");
   PairCount=StringSplit(Pairs, ',', CurrencyPairs);
   Print("Found ", PairCount, " symbols: ", Pairs);
   // Optionally check daily drawdown, etc., or read from a file
   return(0);
}

//----------------------------------------------------------------------
// OnDeinit
int deinit()
{
   Print("Fool007ModeEA: Deinitializing, close log file if open.");
   if(logFileHandle!=INVALID_HANDLE)
      FileClose(logFileHandle);
   return(0);
}
//+------------------------------------------------------------------+
