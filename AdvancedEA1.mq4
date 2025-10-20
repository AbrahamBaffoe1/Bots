//+------------------------------------------------------------------+
//|                                                  Fool007ModeEA.mq4 |
//|  Advanced EA: Multi-symbol trading with robust order management, |
//|  dynamic money management, real-time news integration, and advanced|
//|  strategy filters to approach near–flawless trading              |
//+------------------------------------------------------------------+
#property strict

//----------------------------------------------------------------------
// External Parameters
//----------------------------------------------------------------------
// Symbols and basic trade settings
extern string  Pairs             = "EURUSD,USDJPY,GBPUSD,AUDUSD,USDCHF"; // Symbols to trade (MarketWatch must include these)
extern double  RiskPercentPerTrade = 1.0;    // Percentage of account balance to risk per trade
extern int     StopLossPips      = 50;     // Stop Loss in pips
extern int     TakeProfitPips    = 100;    // Take Profit in pips
extern int     MagicNumber       = 123456; // Unique magic number for this EA

// Trading session (server time)
extern int     SessionStartHour  = 9;      // Start hour (server time)
extern int     SessionEndHour    = 16;     // End hour (server time)

// Multi-timeframe technical indicators
extern int     H1_MA_Period      = 50;     // H1 SMA period (trend filter)
extern int     M5_MA_Period      = 10;     // M5 SMA period (entry signal)
extern int     RSI_Period        = 14;     // M5 RSI period

// Trade Management advanced parameters
extern int     TrailingStopPips  = 20;     // Trailing stop distance in pips
extern int     BreakEvenPips     = 30;     // When trade profit exceeds this, move SL to break even
extern double  PartialClosePct   = 50;     // Percentage of lots to partially close at high profit

// Advanced News Integration settings (Trading Economics free guest endpoint)
extern bool    UseNewsFilter         = true;
extern string  NewsAPI_URL           = "https://api.tradingeconomics.com/calendar?c=guest:guest&f=json";
extern int     NewsImpactThreshold   = 3;   // Impact level (1-5): if an event with impact >= this is active, suspend trading

// Advanced strategy filters
extern bool    UseAdvancedStrategies = true;
extern bool    UseVolatilityFilter   = true;
extern double  ATR_VolatilityThreshold = 0.0010; // Minimum ATR value on M5 required
extern bool    UseBreakoutStrategy   = true;
extern int     BreakoutBars          = 10;   // Lookback for breakout filter

//----------------------------------------------------------------------
// Global Variables
//----------------------------------------------------------------------
string CurrencyPairs[];      // Array of symbols
int    PairCount = 0;
int    RetryMax = 3;         // Number of retries for orders
int    logFileHandle = INVALID_HANDLE;  // Global file handle for logging

//----------------------------------------------------------------------
// Helper Function: Open Log File
void OpenLogFile()
{
   if(logFileHandle == INVALID_HANDLE)
   {
      string filename = "Fool007ModeEA_Log_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
      logFileHandle = FileOpen(filename, FILE_CSV|FILE_WRITE, ',');
      if(logFileHandle != INVALID_HANDLE)
      {
         FileWrite(logFileHandle, "TradeID", "TradeType", "EntryTime", "EntryPrice", "ExitTime", "ExitPrice", "Pips", "Profit");
         FileFlush(logFileHandle);
      }
      else
         Print("Error opening log file. Error code: ", GetLastError());
   }
}

//----------------------------------------------------------------------
// Helper Function: Log Trade
// For simplicity, we assume each trade gets a unique ID (here simply the OrderTicket).
void LogTrade(int tradeID, string tradeType, datetime entryTime, double entryPrice,
              datetime exitTime, double exitPrice)
{
   OpenLogFile();
   if(logFileHandle != INVALID_HANDLE)
   {
      double pips = (exitPrice - entryPrice) / MarketInfo(Symbol(), MODE_POINT);
      if(tradeType == "SELL")  pips = -pips;
      double profit = (exitPrice - entryPrice) * LotSize;
      if(tradeType == "SELL")  profit = -profit;
      FileWrite(logFileHandle, tradeID, tradeType,
                TimeToString(entryTime, TIME_DATE|TIME_SECONDS), entryPrice,
                TimeToString(exitTime, TIME_DATE|TIME_SECONDS), exitPrice, pips, profit);
      FileFlush(logFileHandle);
   }
}

//----------------------------------------------------------------------
// Dynamic Lot Sizing: Calculate lot size based on RiskPercentPerTrade and stop loss in pips.
double CalculateLotSize(string symbol, int stopLossPips)
{
   double balance = AccountBalance();
   double riskAmount = balance * (RiskPercentPerTrade/100.0);
   // pip value estimation (this is simplified; proper calculation depends on symbol/currency)
   double pipValue = MarketInfo(symbol, MODE_TICKVALUE) * 10;
   double lot = riskAmount / (stopLossPips * pipValue);
   lot = NormalizeDouble(lot, 2);
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
   if(lot < minLot)
      lot = minLot;
   if(lot > maxLot)
      lot = maxLot;
   // Adjust to the nearest step:
   lot = MathFloor(lot/lotStep)*lotStep;
   return(lot);
}

//----------------------------------------------------------------------
// Robust OrderSend: Try to send order with retry logic
int RobustOrderSend(string symbol, int cmd, double volume, double price,
                    int slippage, double stoploss, double takeprofit, string comment)
{
   int ticket = -1;
   for(int attempt=0; attempt < RetryMax; attempt++)
   {
      ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, MagicNumber, 0, clrBlue);
      if(ticket >= 0)
      {
         Print("OrderSend succeeded on attempt ", attempt+1, " ticket: ", ticket);
         return(ticket);
      }
      else
      {
         int err = GetLastError();
         Print("OrderSend failed on attempt ", attempt+1, " Error code: ", err);
         Sleep(1000); // wait 1 second before retrying
      }
   }
   return(ticket);
}

//----------------------------------------------------------------------
// Check if order modification (OrderModify) succeeds with retry.
bool RobustOrderModify(int ticket, double newStopLoss, double newTakeProfit)
{
   bool modified = false;
   for(int attempt = 0; attempt < RetryMax; attempt++)
   {
      if(OrderModify(ticket, OrderOpenPrice(), newStopLoss, newTakeProfit, 0, clrYellow))
      {
         modified = true;
         break;
      }
      else
      {
         int err = GetLastError();
         Print("OrderModify failed on attempt ", attempt+1, " ticket: ", ticket, " Error code: ", err);
         Sleep(500);
      }
   }
   return(modified);
}

//----------------------------------------------------------------------
// Partial Close: Close part of an order to secure profit
bool PartialCloseOrder(int ticket, double closeLots)
{
   // OrderClosePartial is not a native function in MT4.
   // Instead, you close a part of the order by opening an opposite order for part of the volume,
   // if your broker supports partial close by OrderSend with OP_CLOSEBY or using expert advisor logic.
   // Here, we mimic a partial close by closing the entire order if volume is small.
   // For demonstration, we assume that if the order's volume is more than closeLots, we close that portion.
   if(OrderSelect(ticket, SELECT_BY_TICKET))
   {
      double currentVolume = OrderLots();
      if(currentVolume > closeLots)
      {
         // Execute a market order in opposite direction of closeLots.
         int type = (OrderType() == OP_BUY ? OP_SELL : OP_BUY);
         double price = (type == OP_BUY ? MarketInfo(OrderSymbol(), MODE_ASK) : MarketInfo(OrderSymbol(), MODE_BID));
         int partialTicket = OrderSend(OrderSymbol(), type, closeLots, price, 3, 0, 0, "PartialClose", MagicNumber, 0, clrAqua);
         if(partialTicket >= 0)
         {
            Print("Partial close executed for order ", ticket, ", volume: ", closeLots);
            return(true);
         }
         else
         {
            Print("Partial close failed for order ", ticket, " Error: ", GetLastError());
            return(false);
         }
      }
      else
         return(false); // Not enough volume to partial close.
   }
   return(false);
}

//----------------------------------------------------------------------
// Break-Even: Move stop loss to break even if profit exceeds threshold.
void CheckBreakEven(int ticket)
{
   if(OrderSelect(ticket, SELECT_BY_TICKET))
   {
      double entryPrice = OrderOpenPrice();
      double currentPrice = (OrderType() == OP_BUY ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK));
      double diffPips = MathAbs(currentPrice - entryPrice) / MarketInfo(OrderSymbol(), MODE_POINT);
      if(diffPips >= BreakEvenPips)
      {
         double newSL = entryPrice;
         // Only modify if new SL is better than current SL:
         if(OrderType() == OP_BUY && newSL > OrderStopLoss() ||
            OrderType() == OP_SELL && (OrderStopLoss() == 0 || newSL < OrderStopLoss()))
         {
            if(RobustOrderModify(ticket, newSL, OrderTakeProfit()))
               Print("Break-even stop loss applied for order ", ticket);
         }
      }
   }
}

//----------------------------------------------------------------------
// Real-Time News Integration: JSON Parser
// This routine looks for news events in the JSON response with a DateTime and Impact.
// Returns true if an event with impact >= NewsImpactThreshold is active within ±30 minutes.
bool CheckForActiveNewsEvent(string json)
{
   int pos = 0;
   while(true)
   {
      pos = StringFind(json, "\"DateTime\":\"", pos);
      if(pos == -1)
         break;
      pos += StringLen("\"DateTime\":\"");
      int endPos = StringFind(json, "\"", pos);
      if(endPos == -1) break;
      string eventTimeStr = StringSubstr(json, pos, endPos - pos);
      datetime eventTime = StrToTime(eventTimeStr);
      datetime currentTime = TimeCurrent();
      if(MathAbs(currentTime - eventTime) <= 30 * 60)
      {
         int impactPos = StringFind(json, "\"Impact\":\"", endPos);
         if(impactPos == -1) break;
         impactPos += StringLen("\"Impact\":\"");
         int impactEndPos = StringFind(json, "\"", impactPos);
         if(impactEndPos == -1) break;
         string impactStr = StringSubstr(json, impactPos, impactEndPos - impactPos);
         int impact = StringToInteger(impactStr);
         if(impact >= NewsImpactThreshold)
         {
            Print("Active news event detected: Time=", eventTimeStr, " Impact=", impact);
            return(true);
         }
      }
      pos = endPos;
   }
   return(false);
}

//----------------------------------------------------------------------
// News Integration: Fetch and parse news data via WebRequest.
// Returns true if a major news event is active.
bool IsMajorNewsTime()
{
   if(!UseNewsFilter)
      return(false);
      
   string url = NewsAPI_URL;
   string headers = "Content-Type: application/json\r\n";
   char request[];
   char result[];
   string result_headers;
   int timeout = 5000;
   int res = WebRequest("GET", url, headers, timeout, request, result, result_headers);
   if(res == -1)
   {
      Print("WebRequest failed. Error: ", GetLastError());
      return(false);
   }
   string newsResponse = CharArrayToStr(result);
   Print("News API response: ", newsResponse);
   if(CheckForActiveNewsEvent(newsResponse))
      return(true);
   return(false);
}

//----------------------------------------------------------------------
// Advanced Technical Filters: Volatility, Breakout, and MACD filters
bool CheckVolatilityFilter(string symbol)
{
   double atr = iATR(symbol, PERIOD_M5, 14, 0);
   return (atr >= ATR_VolatilityThreshold);
}

bool CheckBreakoutFilter(string symbol, bool isBuy)
{
   double currentClose = iClose(symbol, PERIOD_M5, 0);
   double extreme = isBuy ? -1e10 : 1e10;
   for(int shift = 1; shift <= BreakoutBars; shift++)
   {
      if(isBuy)
      {
         double highVal = iHigh(symbol, PERIOD_M5, shift);
         if(highVal > extreme)
            extreme = highVal;
      }
      else
      {
         double lowVal = iLow(symbol, PERIOD_M5, shift);
         if(lowVal < extreme)
            extreme = lowVal;
      }
   }
   if(isBuy && currentClose > extreme) return(true);
   if(!isBuy && currentClose < extreme) return(true);
   return(false);
}

bool CheckAdvancedBuyFilter(string symbol)
{
   double macdCurrent = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double macdPrevious = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (macdCurrent > macdPrevious);
}

bool CheckAdvancedSellFilter(string symbol)
{
   double macdCurrent = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double macdPrevious = iMACD(symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   return (macdCurrent < macdPrevious);
}

//----------------------------------------------------------------------
// Basic Technical Filters: H1 and M5 analysis for entry signals
bool CheckBuySignal(string symbol)
{
   double ma_h1 = iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double h1_close = iClose(symbol, PERIOD_H1, 0);
   if(h1_close <= ma_h1)
      return(false);
      
   double ma_m5_current = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma_m5_previous = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double m5_close_current = iClose(symbol, PERIOD_M5, 0);
   double m5_close_previous = iClose(symbol, PERIOD_M5, 1);
   bool bullishCrossover = (m5_close_previous < ma_m5_previous && m5_close_current > ma_m5_current);
   if(!bullishCrossover)
      return(false);
      
   double rsi_m5 = iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi_m5 <= 50)
      return(false);
      
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol))
      return(false);
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol, true))
      return(false);
   if(UseAdvancedStrategies && !CheckAdvancedBuyFilter(symbol))
      return(false);
      
   return(true);
}

bool CheckSellSignal(string symbol)
{
   double ma_h1 = iMA(symbol, PERIOD_H1, H1_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double h1_close = iClose(symbol, PERIOD_H1, 0);
   if(h1_close >= ma_h1)
      return(false);
      
   double ma_m5_current = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma_m5_previous = iMA(symbol, PERIOD_M5, M5_MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double m5_close_current = iClose(symbol, PERIOD_M5, 0);
   double m5_close_previous = iClose(symbol, PERIOD_M5, 1);
   bool bearishCrossover = (m5_close_previous > ma_m5_previous && m5_close_current < ma_m5_current);
   if(!bearishCrossover)
      return(false);
      
   double rsi_m5 = iRSI(symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);
   if(rsi_m5 >= 50)
      return(false);
      
   if(UseVolatilityFilter && !CheckVolatilityFilter(symbol))
      return(false);
   if(UseBreakoutStrategy && !CheckBreakoutFilter(symbol, false))
      return(false);
   if(UseAdvancedStrategies && !CheckAdvancedSellFilter(symbol))
      return(false);
      
   return(true);
}

//----------------------------------------------------------------------
// Order Management: Manage trailing stops, break-even, and partial close.
void ManageOpenTrades()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() != MagicNumber)
            continue;
         string symbol = OrderSymbol();
         double pointValue = MarketInfo(symbol, MODE_POINT);
         // Update trailing stops:
         double currentPrice = (OrderType() == OP_BUY ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK));
         double currentSL = OrderStopLoss();
         double newSL;
         if(OrderType() == OP_BUY)
         {
            newSL = NormalizeDouble(currentPrice - TrailingStopPips * pointValue, Digits);
            if(newSL > currentSL)
            {
               if(RobustOrderModify(OrderTicket(), newSL, OrderTakeProfit()))
                  Print("Trailing stop updated for Buy order ", OrderTicket());
            }
         }
         else if(OrderType() == OP_SELL)
         {
            newSL = NormalizeDouble(currentPrice + TrailingStopPips * pointValue, Digits);
            if(currentSL == 0 || newSL < currentSL)
            {
               if(RobustOrderModify(OrderTicket(), newSL, OrderTakeProfit()))
                  Print("Trailing stop updated for Sell order ", OrderTicket());
            }
         }
         // Break-even logic:
         CheckBreakEven(OrderTicket());
         
         // Partial close logic (example): if profit exceeds twice the stop loss in pips, 
         // attempt to partially close 50% of the order.
         double profitPips = MathAbs((currentPrice - OrderOpenPrice())/ pointValue);
         if(profitPips >= StopLossPips * 2 && OrderLots() > 0.01)
         {
            double closeVolume = NormalizeDouble(OrderLots() * (PartialClosePct / 100.0), 2);
            if(PartialCloseOrder(OrderTicket(), closeVolume))
               Print("Partial close executed for order ", OrderTicket());
         }
      }
   }
}

//----------------------------------------------------------------------
// Check if current server time is within our trading session.
bool IsTradingSessionActive()
{
   int currentHour = TimeHour(TimeCurrent());
   return(currentHour >= SessionStartHour && currentHour < SessionEndHour);
}

//----------------------------------------------------------------------
// Count open orders for a given symbol (using our MagicNumber).
int CountOrders(string symbol)
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol() == symbol && OrderMagicNumber() == MagicNumber)
            count++;
   }
   return(count);
}

//----------------------------------------------------------------------
// Main Tick Function
int start()
{
   // Only operate during defined trading session.
   if(!IsTradingSessionActive())
      return(0);
      
   // Check news events; if a major event is active, suspend trading.
   if(UseNewsFilter && IsMajorNewsTime())
   {
      Print("Major news event detected. Trading suspended.");
      return(0);
   }
      
   RefreshRates();
   
   // Process each symbol from our list.
   for(int i = 0; i < PairCount; i++)
   {
      string symbol = CurrencyPairs[i];
      if(MarketInfo(symbol, MODE_SPREAD) == 0)
         continue;
         
      // Only create new orders if none exist for this symbol.
      if(CountOrders(symbol) == 0)
      {
         double volume = CalculateLotSize(symbol, StopLossPips);
         // For Buy signal:
         if(CheckBuySignal(symbol))
         {
            double price = MarketInfo(symbol, MODE_ASK);
            double point = MarketInfo(symbol, MODE_POINT);
            double sl = price - StopLossPips * point;
            double tp = price + TakeProfitPips * point;
            int ticket = RobustOrderSend(symbol, OP_BUY, volume, price, 3, sl, tp, "Fool007ModeEA Buy");
            if(ticket >= 0)
            {
               Print("Buy order opened for ", symbol, ". Ticket: ", ticket);
               // Log entry
               LogTrade(ticket, "BUY", TimeCurrent(), price, 0, 0);
            }
            else
               Print("Buy order failed for ", symbol);
         }
         else if(CheckSellSignal(symbol))
         {
            double price = MarketInfo(symbol, MODE_BID);
            double point = MarketInfo(symbol, MODE_POINT);
            double sl = price + StopLossPips * point;
            double tp = price - TakeProfitPips * point;
            int ticket = RobustOrderSend(symbol, OP_SELL, volume, price, 3, sl, tp, "Fool007ModeEA Sell");
            if(ticket >= 0)
            {
               Print("Sell order opened for ", symbol, ". Ticket: ", ticket);
               LogTrade(ticket, "SELL", TimeCurrent(), price, 0, 0);
            }
            else
               Print("Sell order failed for ", symbol);
         }
      }
   }
   
   // Manage open trades: trailing, break-even, partial closes.
   ManageOpenTrades();
   
   return(0);
}

//+------------------------------------------------------------------+
