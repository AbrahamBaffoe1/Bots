//+------------------------------------------------------------------+
//|                                                  AdvancedEA.mq5  |
//|  Advanced Multi-Symbol EA with Sessions, Multi-Timeframe Analysis, |
//|  Dynamic Lot Sizing, News Filter and Trailing Stop Management      |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//---- Input parameters
input string   Pairs                     = "EURUSD,USDJPY,GBPUSD,AUDUSD,USDCHF"; // Comma-separated symbol list
input double   FixedLotSize              = 0.1;      // Fixed lot size (used if dynamic sizing is off)
input bool     DynamicLotSizingEnabled   = true;     // Enable dynamic lot sizing
input double   RiskPercent               = 2.0;      // % risk per trade (used when dynamic sizing is enabled)
input int      StopLoss                  = 50;       // Stop loss in pips
input int      TakeProfit                = 100;      // Take profit in pips
input long     MagicNumber               = 123456;   // Unique identifier for EA orders

// Trading session (server time hours)
input int      SessionStartHour          = 9;        // Start trading session at 9:00
input int      SessionEndHour            = 16;       // End trading session at 16:00

// News filter parameters
input bool     NewsFilterEnabled         = true;     // Enable news filter
input int      NewsStartHour             = 13;       // Start of news window (e.g., 13:00)
input int      NewsDurationMinutes       = 30;       // Duration of news window in minutes

// Multi-timeframe indicator parameters
input int      H1_MA_Period              = 50;       // H1: 50-period SMA for trend filter
input int      M5_MA_Period              = 10;       // M5: 10-period SMA for crossover signal
input int      RSI_Period                = 14;       // M5: RSI period

// Trailing stop parameter (in pips)
input int      TrailingStopPips          = 20;

//---- Global variables
string CurrencyPairs[];
int    PairCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Split the comma-separated symbol list into an array.
   PairCount = StringSplit(Pairs, ',', CurrencyPairs);
   Print("Advanced EA Initialized for ", PairCount, " symbols.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Advanced EA removed.");
}

//+------------------------------------------------------------------+
//| Check if current server time is within the trading session       |
//+------------------------------------------------------------------+
bool IsTradingSessionActive()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour >= SessionStartHour && dt.hour < SessionEndHour)
      return(true);
   return(false);
}

//+------------------------------------------------------------------+
//| News Filter: Check if current time falls in the news window      |
//+------------------------------------------------------------------+
bool IsNewsTimeActive()
{
   if(!NewsFilterEnabled)
      return(false);
      
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   // Simple check: if the hour equals the news start and minutes are less than window duration.
   if(dt.hour == NewsStartHour && dt.min < NewsDurationMinutes)
      return(true);
   return(false);
}

//+------------------------------------------------------------------+
//| Helper function: Get the latest close price from a timeframe      |
//+------------------------------------------------------------------+
double GetLastClose(string symbol, ENUM_TIMEFRAMES timeframe)
{
   MqlRates rates[];
   if(CopyRates(symbol, timeframe, 0, 1, rates) <= 0)
   {
      Print("Error copying rates for ", symbol, " (", EnumToString(timeframe), ")");
      return(0);
   }
   return(rates[0].close);
}

//+------------------------------------------------------------------+
//| Helper function: Retrieve current SMA value                      |
//+------------------------------------------------------------------+
double GetSMA(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   int handle = iMA(symbol, timeframe, period, 0, MODE_SMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
   {
      Print("Error creating SMA handle for ", symbol);
      return(0);
   }
   
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
   {
      Print("Error copying SMA buffer for ", symbol);
      IndicatorRelease(handle);
      return(0);
   }
   IndicatorRelease(handle);
   return(buffer[0]);
}

//+------------------------------------------------------------------+
//| Helper function: Retrieve current RSI value                      |
//+------------------------------------------------------------------+
double GetRSI(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   int handle = iRSI(symbol, timeframe, period, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
   {
      Print("Error creating RSI handle for ", symbol);
      return(0);
   }
   
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
   {
      Print("Error copying RSI buffer for ", symbol);
      IndicatorRelease(handle);
      return(0);
   }
   IndicatorRelease(handle);
   return(buffer[0]);
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size based on risk and stop-loss distance    |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, int stopLossPips)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = equity * (RiskPercent / 100.0);
   // Approximate value per pip per standard lot (this is a simplified estimation).
   double lotValuePerPip = 10.0;
   double lots = riskAmount / (stopLossPips * lotValuePerPip);
   
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   lots = MathFloor(lots / lotStep) * lotStep;
   return(lots);
}

//+------------------------------------------------------------------+
//| Count positions for a given symbol with our MagicNumber          |
//+------------------------------------------------------------------+
int CountPositions(string symbol)
{
   int count = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            count++;
      }
   }
   return(count);
}

//+------------------------------------------------------------------+
//| Check for bullish signal based on multi-timeframe analysis       |
//| (H1 trend filter, M5 SMA crossover, and RSI filter)               |
//+------------------------------------------------------------------+
bool CheckBuySignal(string symbol)
{
   // H1 Trend: H1 close must be above its SMA.
   double h1SMA    = GetSMA(symbol, PERIOD_H1, H1_MA_Period, 0);
   double h1Close  = GetLastClose(symbol, PERIOD_H1);
   if(h1Close <= h1SMA)
      return(false);
      
   // M5 Crossover: previous M5 bar below the SMA and current M5 bar above.
   double m5SMA_current  = GetSMA(symbol, PERIOD_M5, M5_MA_Period, 0);
   double m5SMA_previous = GetSMA(symbol, PERIOD_M5, M5_MA_Period, 1);
   double m5Close_current = GetLastClose(symbol, PERIOD_M5);
   double m5Close_previous;
   {
      MqlRates rates[];
      if(CopyRates(symbol, PERIOD_M5, 1, 1, rates) <= 0)
      {
         Print("Error copying previous M5 rates for ", symbol);
         return(false);
      }
      m5Close_previous = rates[0].close;
   }
   
   bool bullishCrossover = (m5Close_previous < m5SMA_previous && m5Close_current > m5SMA_current);
   if(!bullishCrossover)
      return(false);
      
   // M5 RSI Filter: require RSI > 50.
   double rsi = GetRSI(symbol, PERIOD_M5, RSI_Period, 0);
   if(rsi <= 50)
      return(false);
      
   return(true);
}

//+------------------------------------------------------------------+
//| Check for bearish signal based on multi-timeframe analysis       |
//| (H1 trend filter, M5 SMA crossover, and RSI filter)               |
//+------------------------------------------------------------------+
bool CheckSellSignal(string symbol)
{
   // H1 Trend: H1 close must be below its SMA.
   double h1SMA   = GetSMA(symbol, PERIOD_H1, H1_MA_Period, 0);
   double h1Close = GetLastClose(symbol, PERIOD_H1);
   if(h1Close >= h1SMA)
      return(false);
      
   // M5 Crossover: previous M5 bar above the SMA and current M5 bar below.
   double m5SMA_current  = GetSMA(symbol, PERIOD_M5, M5_MA_Period, 0);
   double m5SMA_previous = GetSMA(symbol, PERIOD_M5, M5_MA_Period, 1);
   double m5Close_current = GetLastClose(symbol, PERIOD_M5);
   double m5Close_previous;
   {
      MqlRates rates[];
      if(CopyRates(symbol, PERIOD_M5, 1, 1, rates) <= 0)
      {
         Print("Error copying previous M5 rates for ", symbol);
         return(false);
      }
      m5Close_previous = rates[0].close;
   }
   
   bool bearishCrossover = (m5Close_previous > m5SMA_previous && m5Close_current < m5SMA_current);
   if(!bearishCrossover)
      return(false);
      
   // M5 RSI Filter: require RSI < 50.
   double rsi = GetRSI(symbol, PERIOD_M5, RSI_Period, 0);
   if(rsi >= 50)
      return(false);
      
   return(true);
}

//+------------------------------------------------------------------+
//| Trailing stop management: adjust stop losses for open positions    |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
         string symbol = PositionGetString(POSITION_SYMBOL);
         long positionType = PositionGetInteger(POSITION_TYPE);
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);
         double newSL;
         double price;
         // Use the symbol's digits for normalization.
         int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         
         if(positionType == POSITION_TYPE_BUY)
         {
            price = SymbolInfoDouble(symbol, SYMBOL_BID);
            newSL = NormalizeDouble(price - TrailingStopPips * point, digits);
            if(newSL > currentSL)  // Only update if stop loss moves up
            {
               if(!trade.PositionModify(ticket, newSL, currentTP))
                  Print("Failed to update trailing stop for Buy position ", ticket, " on ", symbol);
               else
                  Print("Trailing stop updated for Buy position ", ticket, " on ", symbol);
            }
         }
         else if(positionType == POSITION_TYPE_SELL)
         {
            price = SymbolInfoDouble(symbol, SYMBOL_ASK);
            newSL = NormalizeDouble(price + TrailingStopPips * point, digits);
            if(currentSL == 0 || newSL < currentSL)
            {
               if(!trade.PositionModify(ticket, newSL, currentTP))
                  Print("Failed to update trailing stop for Sell position ", ticket, " on ", symbol);
               else
                  Print("Trailing stop updated for Sell position ", ticket, " on ", symbol);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check session and news filters.
   if(!IsTradingSessionActive())
      return;
      
   if(IsNewsTimeActive())
   {
      Print("News event active. Skipping new trade entries.");
      return;
   }
   
   // Process each symbol.
   for(int i = 0; i < PairCount; i++)
   {
      string symbol = CurrencyPairs[i];
      
      // Ensure the symbol is available in MarketWatch.
      double dummy;
      if(!SymbolInfoDouble(symbol, SYMBOL_ASK, dummy))
         continue;
         
      // Only open a new trade if no position exists for this symbol.
      if(CountPositions(symbol) == 0)
      {
         double lotSize = (DynamicLotSizingEnabled ? CalculateLotSize(symbol, StopLoss) : FixedLotSize);
         
         // Check for a bullish signal.
         if(CheckBuySignal(symbol))
         {
            double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double sl = NormalizeDouble(price - StopLoss * point, digits);
            double tp = NormalizeDouble(price + TakeProfit * point, digits);
            
            if(!trade.Buy(lotSize, symbol, price, sl, tp, "Buy Order"))
               Print("Error opening Buy order for ", symbol, " Error: ", GetLastError());
            else
               Print("Buy order opened for ", symbol);
         }
         // Check for a bearish signal.
         else if(CheckSellSignal(symbol))
         {
            double price = SymbolInfoDouble(symbol, SYMBOL_BID);
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double sl = NormalizeDouble(price + StopLoss * point, digits);
            double tp = NormalizeDouble(price - TakeProfit * point, digits);
            
            if(!trade.Sell(lotSize, symbol, price, sl, tp, "Sell Order"))
               Print("Error opening Sell order for ", symbol, " Error: ", GetLastError());
            else
               Print("Sell order opened for ", symbol);
         }
      }
   }
   
   // Update trailing stops for open positions.
   ManageTrailingStop();
}
