//+------------------------------------------------------------------+
//|                                              GoldTrader.mq5       |
//|                        Gold/XAU Trading EA with Python Backend    |
//|                        Specialized for Precious Metals Trading    |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader"
#property link      "https://smartstocktrader.com"
#property version   "1.00"
#property description "Gold Trading EA with Python Backend Integration"
#property description "Optimized for XAU/USD with volatility-based strategies"
#property description "Advanced breakout and mean reversion techniques"

//--- Input Parameters
input group "=== Connection Settings ==="
input string InpServerURL = "http://localhost:5000";  // Backend Server URL
input string InpAPIKey = "";                           // API Key
input bool InpEnableWebSocket = true;                  // Enable WebSocket

input group "=== Trading Settings ==="
input bool InpEnableTrading = true;                    // Enable Trading
input double InpRiskPercent = 0.5;                     // Risk Per Trade (%) - Conservative for Gold
input double InpMaxRiskPercent = 2.0;                  // Max Total Risk (%)
input int InpMagicNumber = 200001;                     // Magic Number
input string InpSymbol = "XAUUSD";                     // Gold Symbol

input group "=== Strategy Selection ==="
input ENUM_STRATEGY InpStrategy = STRATEGY_HYBRID;     // Trading Strategy
enum ENUM_STRATEGY
{
   STRATEGY_BREAKOUT,      // Breakout Strategy
   STRATEGY_MEANREVERSION, // Mean Reversion Strategy
   STRATEGY_TREND,         // Trend Following
   STRATEGY_HYBRID         // Hybrid (All Strategies)
};

input group "=== Risk Management ==="
input double InpATRMultiplierSL = 1.5;                 // ATR Multiplier for SL
input double InpATRMultiplierTP = 3.0;                 // ATR Multiplier for TP
input double InpMaxSpreadPips = 30.0;                  // Max Spread (points)
input int InpSlippagePoints = 30;                      // Max Slippage
input double InpDynamicLeverage = 1.0;                 // Dynamic Leverage Factor

input group "=== Money Management ==="
input double InpMinLotSize = 0.01;                     // Min Lot Size
input double InpMaxLotSize = 5.0;                      // Max Lot Size
input bool InpCompoundProfit = true;                   // Compound Profits
input double InpProfitCompoundPercent = 50.0;          // Compound % of Profit

input group "=== Breakout Settings ==="
input int InpBreakoutPeriod = 20;                      // Breakout Period
input double InpBreakoutThreshold = 1.5;               // Breakout Threshold (ATR multiplier)
input bool InpUseVolumeFilter = true;                  // Use Volume Filter
input double InpVolumeMultiplier = 1.5;                // Volume Multiplier

input group "=== Mean Reversion Settings ==="
input int InpBollingerPeriod = 20;                     // Bollinger Period
input double InpBollingerDeviation = 2.0;              // Bollinger Deviation
input int InpOverboughtLevel = 80;                     // Overbought Level
input int InpOversoldLevel = 20;                       // Oversold Level

input group "=== Trend Settings ==="
input int InpFastMA = 20;                              // Fast MA Period
input int InpSlowMA = 50;                              // Slow MA Period
input int InpTrendMA = 200;                            // Trend MA Period

input group "=== Session Settings ==="
input bool InpTradeAsianSession = false;               // Trade Asian Session
input bool InpTradeLondonSession = true;               // Trade London Session
input bool InpTradeNYSession = true;                   // Trade NY Session
input bool InpAvoidNews = true;                        // Avoid High Impact News

input group "=== Advanced Features ==="
input bool InpUseTrailingStop = true;                  // Use Trailing Stop
input double InpTrailingStart = 100.0;                 // Trailing Start (points)
input double InpTrailingStep = 50.0;                   // Trailing Step (points)
input bool InpUseBreakEven = true;                     // Move to Break Even
input double InpBreakEvenTrigger = 50.0;               // BE Trigger (points)
input bool InpScaleOut = true;                         // Scale Out Profits
input int InpMaxDailyTrades = 5;                       // Max Daily Trades
input double InpMaxDailyDrawdown = 2.0;                // Max Daily Drawdown (%)

input group "=== Technical Indicators ==="
input int InpATRPeriod = 14;                           // ATR Period
input int InpRSIPeriod = 14;                           // RSI Period
input int InpCCIPeriod = 20;                           // CCI Period
input int InpStochPeriod = 14;                         // Stochastic Period

//--- Global Variables
int atrHandle, fastMAHandle, slowMAHandle, trendMAHandle;
int rsiHandle, cciHandle, stochHandle, bbHandle;
double atrBuffer[], fastMABuffer[], slowMABuffer[], trendMABuffer[];
double rsiBuffer[], cciBuffer[], stochMainBuffer[], stochSignalBuffer[];
double bbUpperBuffer[], bbMiddleBuffer[], bbLowerBuffer[];
datetime lastBarTime = 0;
int dailyTradeCount = 0;
double dailyPnL = 0.0;
double dailyMaxEquity = 0.0;
datetime lastTradeDay = 0;
bool beMovedToday = false;

//--- Structures
struct TradeSignal
{
   bool valid;
   int type;
   double entry;
   double stopLoss;
   double takeProfit;
   double lotSize;
   string strategy;
   string comment;
   int confidence;        // 0-100
};

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== Gold Trading EA Initializing ===");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Balance: $", AccountInfoDouble(ACCOUNT_BALANCE));
   Print("Symbol: ", InpSymbol);
   Print("Strategy: ", EnumToString(InpStrategy));

   //--- Validate symbol
   if(!SymbolSelect(InpSymbol, true))
   {
      Alert("Failed to select symbol: ", InpSymbol);
      return(INIT_FAILED);
   }

   //--- Initialize indicators
   atrHandle = iATR(InpSymbol, PERIOD_CURRENT, InpATRPeriod);
   fastMAHandle = iMA(InpSymbol, PERIOD_CURRENT, InpFastMA, 0, MODE_EMA, PRICE_CLOSE);
   slowMAHandle = iMA(InpSymbol, PERIOD_CURRENT, InpSlowMA, 0, MODE_EMA, PRICE_CLOSE);
   trendMAHandle = iMA(InpSymbol, PERIOD_CURRENT, InpTrendMA, 0, MODE_SMA, PRICE_CLOSE);
   rsiHandle = iRSI(InpSymbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   cciHandle = iCCI(InpSymbol, PERIOD_CURRENT, InpCCIPeriod, PRICE_TYPICAL);
   stochHandle = iStochastic(InpSymbol, PERIOD_CURRENT, InpStochPeriod, 3, 3, MODE_SMA, STO_LOWHIGH);
   bbHandle = iBands(InpSymbol, PERIOD_CURRENT, InpBollingerPeriod, 0, InpBollingerDeviation, PRICE_CLOSE);

   if(atrHandle == INVALID_HANDLE || fastMAHandle == INVALID_HANDLE ||
      slowMAHandle == INVALID_HANDLE || trendMAHandle == INVALID_HANDLE ||
      rsiHandle == INVALID_HANDLE || cciHandle == INVALID_HANDLE ||
      stochHandle == INVALID_HANDLE || bbHandle == INVALID_HANDLE)
   {
      Print("Error creating indicators: ", GetLastError());
      return(INIT_FAILED);
   }

   //--- Set arrays as series
   ArraySetAsSeries(atrBuffer, true);
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);
   ArraySetAsSeries(trendMABuffer, true);
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(cciBuffer, true);
   ArraySetAsSeries(stochMainBuffer, true);
   ArraySetAsSeries(stochSignalBuffer, true);
   ArraySetAsSeries(bbUpperBuffer, true);
   ArraySetAsSeries(bbMiddleBuffer, true);
   ArraySetAsSeries(bbLowerBuffer, true);

   //--- Initialize WebSocket
   if(InpEnableWebSocket)
   {
      InitializeWebSocket();
   }

   PrintSettings();
   Print("=== Initialization Complete ===");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== Gold EA Shutting Down ===");

   //--- Release indicators
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(fastMAHandle != INVALID_HANDLE) IndicatorRelease(fastMAHandle);
   if(slowMAHandle != INVALID_HANDLE) IndicatorRelease(slowMAHandle);
   if(trendMAHandle != INVALID_HANDLE) IndicatorRelease(trendMAHandle);
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(cciHandle != INVALID_HANDLE) IndicatorRelease(cciHandle);
   if(stochHandle != INVALID_HANDLE) IndicatorRelease(stochHandle);
   if(bbHandle != INVALID_HANDLE) IndicatorRelease(bbHandle);

   CloseWebSocket();
   PrintDailyStats();
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBar()) return;

   UpdateDailyStats();
   if(!CheckDailyLimits()) return;
   if(!UpdateIndicators()) return;

   ManageOpenPositions();

   if(InpEnableTrading && CanTrade())
   {
      TradeSignal signal = GetTradeSignal();
      if(signal.valid && signal.confidence >= 60)
      {
         ExecuteSignal(signal);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if new bar                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentTime = iTime(InpSymbol, PERIOD_CURRENT, 0);
   if(currentTime != lastBarTime)
   {
      lastBarTime = currentTime;
      beMovedToday = false;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update indicators                                                 |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   if(CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) <= 0) return false;
   if(CopyBuffer(fastMAHandle, 0, 0, 3, fastMABuffer) <= 0) return false;
   if(CopyBuffer(slowMAHandle, 0, 0, 3, slowMABuffer) <= 0) return false;
   if(CopyBuffer(trendMAHandle, 0, 0, 3, trendMABuffer) <= 0) return false;
   if(CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) <= 0) return false;
   if(CopyBuffer(cciHandle, 0, 0, 3, cciBuffer) <= 0) return false;
   if(CopyBuffer(stochHandle, 0, 0, 3, stochMainBuffer) <= 0) return false;
   if(CopyBuffer(stochHandle, 1, 0, 3, stochSignalBuffer) <= 0) return false;
   if(CopyBuffer(bbHandle, 1, 0, 3, bbUpperBuffer) <= 0) return false;
   if(CopyBuffer(bbHandle, 0, 0, 3, bbMiddleBuffer) <= 0) return false;
   if(CopyBuffer(bbHandle, 2, 0, 3, bbLowerBuffer) <= 0) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Get trade signal                                                  |
//+------------------------------------------------------------------+
TradeSignal GetTradeSignal()
{
   TradeSignal signal;
   signal.valid = false;
   signal.confidence = 0;

   if(PositionSelect(InpSymbol)) return signal;

   //--- Get WebSocket signal first
   if(InpEnableWebSocket)
   {
      signal = GetWebSocketSignal();
      if(signal.valid) return signal;
   }

   //--- Generate signals based on strategy
   switch(InpStrategy)
   {
      case STRATEGY_BREAKOUT:
         signal = GetBreakoutSignal();
         break;
      case STRATEGY_MEANREVERSION:
         signal = GetMeanReversionSignal();
         break;
      case STRATEGY_TREND:
         signal = GetTrendSignal();
         break;
      case STRATEGY_HYBRID:
         signal = GetHybridSignal();
         break;
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Breakout strategy signal                                          |
//+------------------------------------------------------------------+
TradeSignal GetBreakoutSignal()
{
   TradeSignal signal;
   signal.valid = false;
   signal.strategy = "BREAKOUT";

   double high = iHigh(InpSymbol, PERIOD_CURRENT, 1);
   double low = iLow(InpSymbol, PERIOD_CURRENT, 1);
   double close = iClose(InpSymbol, PERIOD_CURRENT, 1);
   double atr = atrBuffer[1];

   //--- Find highest high and lowest low
   double highestHigh = high;
   double lowestLow = low;
   for(int i = 2; i <= InpBreakoutPeriod; i++)
   {
      highestHigh = MathMax(highestHigh, iHigh(InpSymbol, PERIOD_CURRENT, i));
      lowestLow = MathMin(lowestLow, iLow(InpSymbol, PERIOD_CURRENT, i));
   }

   //--- Buy breakout
   if(close > highestHigh && close > trendMABuffer[1])
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
      signal.stopLoss = signal.entry - (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry + (atr * InpATRMultiplierTP);
      signal.confidence = 75;
      signal.comment = "BUY_BREAKOUT";
   }
   //--- Sell breakout
   else if(close < lowestLow && close < trendMABuffer[1])
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
      signal.stopLoss = signal.entry + (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry - (atr * InpATRMultiplierTP);
      signal.confidence = 75;
      signal.comment = "SELL_BREAKOUT";
   }

   if(signal.valid)
   {
      signal.lotSize = CalculateLotSize(signal.entry, signal.stopLoss, signal.confidence);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Mean reversion strategy signal                                    |
//+------------------------------------------------------------------+
TradeSignal GetMeanReversionSignal()
{
   TradeSignal signal;
   signal.valid = false;
   signal.strategy = "MEANREV";

   double close = iClose(InpSymbol, PERIOD_CURRENT, 1);
   double atr = atrBuffer[1];
   double rsi = rsiBuffer[1];
   double stoch = stochMainBuffer[1];

   //--- Buy at lower band with oversold conditions
   if(close < bbLowerBuffer[1] && rsi < InpOversoldLevel && stoch < InpOversoldLevel)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
      signal.stopLoss = signal.entry - (atr * InpATRMultiplierSL);
      signal.takeProfit = bbMiddleBuffer[1];  // Target middle band
      signal.confidence = 70;
      signal.comment = "BUY_MEANREV";
   }
   //--- Sell at upper band with overbought conditions
   else if(close > bbUpperBuffer[1] && rsi > InpOverboughtLevel && stoch > InpOverboughtLevel)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
      signal.stopLoss = signal.entry + (atr * InpATRMultiplierSL);
      signal.takeProfit = bbMiddleBuffer[1];  // Target middle band
      signal.confidence = 70;
      signal.comment = "SELL_MEANREV";
   }

   if(signal.valid)
   {
      signal.lotSize = CalculateLotSize(signal.entry, signal.stopLoss, signal.confidence);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Trend following signal                                            |
//+------------------------------------------------------------------+
TradeSignal GetTrendSignal()
{
   TradeSignal signal;
   signal.valid = false;
   signal.strategy = "TREND";

   double close = iClose(InpSymbol, PERIOD_CURRENT, 1);
   double prevClose = iClose(InpSymbol, PERIOD_CURRENT, 2);
   double atr = atrBuffer[1];
   double fastMA = fastMABuffer[1];
   double slowMA = slowMABuffer[1];
   double trendMA = trendMABuffer[1];

   //--- Buy signal: Fast MA crosses above Slow MA in uptrend
   if(fastMA > slowMA && fastMABuffer[2] <= slowMABuffer[2] && close > trendMA)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
      signal.stopLoss = signal.entry - (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry + (atr * InpATRMultiplierTP);
      signal.confidence = 80;
      signal.comment = "BUY_TREND";
   }
   //--- Sell signal: Fast MA crosses below Slow MA in downtrend
   else if(fastMA < slowMA && fastMABuffer[2] >= slowMABuffer[2] && close < trendMA)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
      signal.stopLoss = signal.entry + (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry - (atr * InpATRMultiplierTP);
      signal.confidence = 80;
      signal.comment = "SELL_TREND";
   }

   if(signal.valid)
   {
      signal.lotSize = CalculateLotSize(signal.entry, signal.stopLoss, signal.confidence);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Hybrid signal combining all strategies                            |
//+------------------------------------------------------------------+
TradeSignal GetHybridSignal()
{
   TradeSignal breakout = GetBreakoutSignal();
   TradeSignal meanRev = GetMeanReversionSignal();
   TradeSignal trend = GetTrendSignal();

   //--- Return signal with highest confidence
   TradeSignal best;
   best.valid = false;
   best.confidence = 0;

   if(breakout.valid && breakout.confidence > best.confidence) best = breakout;
   if(meanRev.valid && meanRev.confidence > best.confidence) best = meanRev;
   if(trend.valid && trend.confidence > best.confidence) best = trend;

   return best;
}

//+------------------------------------------------------------------+
//| Calculate lot size with confidence weighting                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry, double stopLoss, int confidence)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;

   //--- Adjust risk based on confidence
   riskAmount *= (confidence / 100.0);

   double slDistance = MathAbs(entry - stopLoss);
   if(slDistance == 0) return InpMinLotSize;

   double tickValue = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);

   double lots = riskAmount / (slDistance / tickSize * tickValue);
   lots = MathFloor(lots / lotStep) * lotStep;

   return NormalizeLot(lots);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(lot, InpMinLotSize);
   lot = MathMin(lot, InpMaxLotSize);
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   lot = MathRound(lot / stepLot) * stepLot;

   return lot;
}

//+------------------------------------------------------------------+
//| Execute trade signal                                              |
//+------------------------------------------------------------------+
void ExecuteSignal(TradeSignal &signal)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = InpSymbol;
   request.volume = signal.lotSize;
   request.type = signal.type;
   request.price = signal.entry;
   request.sl = signal.stopLoss;
   request.tp = signal.takeProfit;
   request.deviation = InpSlippagePoints;
   request.magic = InpMagicNumber;
   request.comment = signal.comment;
   request.type_filling = ORDER_FILLING_FOK;

   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
      {
         Print(" Trade executed: ", signal.comment, " | Lot: ", signal.lotSize, " | Confidence: ", signal.confidence, "%");
         dailyTradeCount++;
         SendTradeNotification(result);
      }
   }
}

//+------------------------------------------------------------------+
//| Manage open positions                                             |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != InpSymbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      if(InpUseBreakEven) MoveToBreakEven(ticket);
      if(InpUseTrailingStop) TrailPosition(ticket);
      if(InpScaleOut) ScaleOutPosition(ticket);
   }
}

//+------------------------------------------------------------------+
//| Move position to break even                                       |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket)
{
   if(beMovedToday) return;
   if(!PositionSelectByTicket(ticket)) return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(InpSymbol, SYMBOL_BID) :
                        SymbolInfoDouble(InpSymbol, SYMBOL_ASK);

   double profitPoints = posType == POSITION_TYPE_BUY ?
                        (currentPrice - openPrice) :
                        (openPrice - currentPrice);

   if(profitPoints >= InpBreakEvenTrigger * _Point)
   {
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);

      request.action = TRADE_ACTION_SLTP;
      request.symbol = InpSymbol;
      request.sl = openPrice;
      request.tp = PositionGetDouble(POSITION_TP);
      request.position = ticket;

      if(OrderSend(request, result))
      {
         Print(" Position moved to break even");
         beMovedToday = true;
      }
   }
}

//+------------------------------------------------------------------+
//| Trail position                                                    |
//+------------------------------------------------------------------+
void TrailPosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(InpSymbol, SYMBOL_BID) :
                        SymbolInfoDouble(InpSymbol, SYMBOL_ASK);

   double profitPoints = posType == POSITION_TYPE_BUY ?
                        (currentPrice - openPrice) :
                        (openPrice - currentPrice);

   if(profitPoints < InpTrailingStart * _Point) return;

   double newSL = 0;
   if(posType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - (InpTrailingStep * _Point);
      if(newSL <= currentSL) return;
   }
   else
   {
      newSL = currentPrice + (InpTrailingStep * _Point);
      if(newSL >= currentSL) return;
   }

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_SLTP;
   request.symbol = InpSymbol;
   request.sl = newSL;
   request.tp = PositionGetDouble(POSITION_TP);
   request.position = ticket;

   if(OrderSend(request, result))
   {
      Print(" Trailing stop updated");
   }
}

//+------------------------------------------------------------------+
//| Scale out position                                                |
//+------------------------------------------------------------------+
void ScaleOutPosition(ulong ticket)
{
   // Placeholder for scale out functionality
}

//+------------------------------------------------------------------+
//| Check if can trade                                                |
//+------------------------------------------------------------------+
bool CanTrade()
{
   if(!IsWithinTradingSession()) return false;
   if(InpAvoidNews && IsNewsTime()) return false;

   double spread = SymbolInfoInteger(InpSymbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPips) return false;

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

   // Asian: 00:00-09:00, London: 08:00-17:00, NY: 13:00-22:00
   if(InpTradeAsianSession && hour >= 0 && hour < 9) return true;
   if(InpTradeLondonSession && hour >= 8 && hour < 17) return true;
   if(InpTradeNYSession && hour >= 13 && hour < 22) return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check if news time                                                |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   // Placeholder - integrate with news calendar
   return false;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                           |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   datetime currentDay = iTime(InpSymbol, PERIOD_D1, 0);

   if(currentDay != lastTradeDay)
   {
      dailyTradeCount = 0;
      dailyPnL = 0.0;
      dailyMaxEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      lastTradeDay = currentDay;
   }

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   dailyMaxEquity = MathMax(dailyMaxEquity, currentEquity);
   dailyPnL = currentEquity - AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Check daily limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
   if(dailyTradeCount >= InpMaxDailyTrades) return false;

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double drawdown = (dailyMaxEquity - currentEquity) / dailyMaxEquity * 100.0;

   if(drawdown > InpMaxDailyDrawdown)
   {
      Print("Daily drawdown limit reached: ", drawdown, "%");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| WebSocket functions                                               |
//+------------------------------------------------------------------+
bool InitializeWebSocket()
{
   Print("Initializing WebSocket for Gold Trading...");
   return true;
}

TradeSignal GetWebSocketSignal()
{
   TradeSignal signal;
   signal.valid = false;
   return signal;
}

void SendTradeNotification(MqlTradeResult &result)
{
   Print("Sending trade notification to backend...");
}

void CloseWebSocket()
{
   Print("Closing WebSocket connection...");
}

//+------------------------------------------------------------------+
//| Print functions                                                   |
//+------------------------------------------------------------------+
void PrintSettings()
{
   Print("--- Gold EA Settings ---");
   Print("Strategy: ", EnumToString(InpStrategy));
   Print("Risk: ", InpRiskPercent, "%");
   Print("Max Daily Trades: ", InpMaxDailyTrades);
}

void PrintDailyStats()
{
   Print("--- Daily Stats ---");
   Print("Trades: ", dailyTradeCount);
   Print("P&L: $", dailyPnL);
}
//+------------------------------------------------------------------+
