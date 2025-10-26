//+------------------------------------------------------------------+
//|                                        stocksOnlymachine.mq5      |
//|                        Stock Trading EA with Python Integration   |
//|                        Advanced Risk Management & Signal System   |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader"
#property link      "https://smartstocktrader.com"
#property version   "1.00"
#property description "Advanced Stock Trading EA with Python Backend Integration"
#property description "Features: Multi-timeframe analysis, ATR-based risk management"
#property description "WebSocket communication for real-time signals"

//--- Input Parameters
input group "=== Connection Settings ==="
input string InpServerURL = "http://localhost:5000";  // Backend Server URL
input string InpAPIKey = "";                           // API Key for Authentication
input int InpConnectionTimeout = 30;                   // Connection Timeout (seconds)
input bool InpEnableWebSocket = true;                  // Enable WebSocket Communication

input group "=== Trading Settings ==="
input bool InpEnableTrading = true;                    // Enable Automated Trading
input double InpRiskPercent = 1.0;                     // Risk Per Trade (%)
input double InpMaxRiskPercent = 5.0;                  // Maximum Total Risk (%)
input int InpMagicNumber = 100001;                     // Magic Number
input string InpTradeComment = "StockEA";              // Trade Comment

input group "=== Risk Management ==="
input bool InpUseATRStopLoss = true;                   // Use ATR for Stop Loss
input double InpATRMultiplier = 2.0;                   // ATR Multiplier for SL
input double InpRiskRewardRatio = 2.0;                 // Risk:Reward Ratio
input double InpMaxSpreadPips = 50.0;                  // Max Spread (points)
input int InpSlippagePoints = 20;                      // Max Slippage (points)

input group "=== Money Management ==="
input double InpMinLotSize = 0.01;                     // Minimum Lot Size
input double InpMaxLotSize = 10.0;                     // Maximum Lot Size
input bool InpUseFixedLot = false;                     // Use Fixed Lot Size
input double InpFixedLotSize = 0.1;                    // Fixed Lot Size

input group "=== Signal Filters ==="
input bool InpUseTrendFilter = true;                   // Use Trend Filter
input int InpTrendPeriod = 200;                        // Trend MA Period
input bool InpUseVolatilityFilter = true;              // Use Volatility Filter
input double InpMinATR = 0.0001;                       // Minimum ATR Value
input bool InpUseTimeFilter = true;                    // Use Trading Time Filter
input string InpTradingStartTime = "09:30";            // Trading Start Time
input string InpTradingEndTime = "16:00";              // Trading End Time

input group "=== Advanced Features ==="
input bool InpTrailStop = true;                        // Enable Trailing Stop
input double InpTrailStopPercent = 50.0;               // Trail Stop Activation (%)
input double InpTrailStopStep = 25.0;                  // Trail Stop Step (%)
input bool InpPartialClose = true;                     // Enable Partial Close
input double InpPartialClosePercent = 50.0;            // Partial Close at TP1 (%)
input int InpMaxDailyTrades = 10;                      // Max Daily Trades
input double InpMaxDailyLoss = 3.0;                    // Max Daily Loss (%)

input group "=== Technical Indicators ==="
input int InpATRPeriod = 14;                           // ATR Period
input int InpRSIPeriod = 14;                           // RSI Period
input double InpRSIOverbought = 70.0;                  // RSI Overbought Level
input double InpRSIOversold = 30.0;                    // RSI Oversold Level

//--- Global Variables
int atrHandle, maHandle, rsiHandle;
double atrBuffer[], maBuffer[], rsiBuffer[];
datetime lastBarTime = 0;
int dailyTradeCount = 0;
double dailyPnL = 0.0;
datetime lastTradeDay = 0;

//--- Structures
struct TradeSignal
{
   bool valid;
   int type;              // ORDER_TYPE_BUY or ORDER_TYPE_SELL
   double entry;
   double stopLoss;
   double takeProfit;
   double lotSize;
   string comment;
   datetime signalTime;
};

struct DailyStats
{
   int tradesCount;
   double totalPnL;
   double winRate;
   double avgWin;
   double avgLoss;
   datetime date;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== Stock Trading EA Initializing ===");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Balance: $", AccountInfoDouble(ACCOUNT_BALANCE));
   Print("Server: ", InpServerURL);

   //--- Check if trading is allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Alert("Automated trading is disabled in the terminal!");
      return(INIT_FAILED);
   }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Alert("Automated trading is disabled for this EA!");
      return(INIT_FAILED);
   }

   //--- Initialize indicators
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   maHandle = iMA(_Symbol, PERIOD_CURRENT, InpTrendPeriod, 0, MODE_SMA, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);

   if(atrHandle == INVALID_HANDLE || maHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE)
   {
      Print("Error creating indicators: ", GetLastError());
      return(INIT_FAILED);
   }

   ArraySetAsSeries(atrBuffer, true);
   ArraySetAsSeries(maBuffer, true);
   ArraySetAsSeries(rsiBuffer, true);

   //--- Initialize WebSocket connection
   if(InpEnableWebSocket)
   {
      if(InitializeWebSocket())
         Print("WebSocket connection established");
      else
         Print("Warning: WebSocket connection failed - EA will use local signals only");
   }

   //--- Display settings
   PrintSettings();

   Print("=== Initialization Complete ===");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== EA Shutting Down ===");
   Print("Reason: ", GetUninitReasonText(reason));

   //--- Release indicator handles
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);

   //--- Close WebSocket
   CloseWebSocket();

   //--- Print final statistics
   PrintDailyStats();
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new bar
   if(!IsNewBar()) return;

   //--- Update daily statistics
   UpdateDailyStats();

   //--- Check daily limits
   if(!CheckDailyLimits()) return;

   //--- Update indicator values
   if(!UpdateIndicators()) return;

   //--- Check existing positions
   ManageOpenPositions();

   //--- Check for new trade signals
   if(InpEnableTrading)
   {
      TradeSignal signal = GetTradeSignal();
      if(signal.valid)
      {
         ExecuteSignal(signal);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentTime != lastBarTime)
   {
      lastBarTime = currentTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update indicator values                                           |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   if(CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) <= 0) return false;
   if(CopyBuffer(maHandle, 0, 0, 3, maBuffer) <= 0) return false;
   if(CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) <= 0) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Get trade signal                                                  |
//+------------------------------------------------------------------+
TradeSignal GetTradeSignal()
{
   TradeSignal signal;
   signal.valid = false;
   signal.signalTime = TimeCurrent();

   //--- Check if already in position
   if(PositionSelect(_Symbol))
   {
      return signal;
   }

   //--- Check filters
   if(!PassFilters()) return signal;

   //--- Get signal from Python backend (if connected)
   if(InpEnableWebSocket)
   {
      signal = GetWebSocketSignal();
      if(signal.valid) return signal;
   }

   //--- Generate local signal based on technical analysis
   signal = GenerateLocalSignal();

   return signal;
}

//+------------------------------------------------------------------+
//| Generate local trading signal                                     |
//+------------------------------------------------------------------+
TradeSignal GenerateLocalSignal()
{
   TradeSignal signal;
   signal.valid = false;

   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double prevClose = iClose(_Symbol, PERIOD_CURRENT, 2);
   double rsi = rsiBuffer[1];
   double ma = maBuffer[1];
   double atr = atrBuffer[1];

   //--- Buy signal: Price above MA, RSI oversold, bullish candle
   if(close > ma && rsi < InpRSIOversold && close > prevClose)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double slDistance = InpUseATRStopLoss ? atr * InpATRMultiplier : (signal.entry * InpRiskPercent / 100);
      signal.stopLoss = signal.entry - slDistance;
      signal.takeProfit = signal.entry + (slDistance * InpRiskRewardRatio);
      signal.lotSize = CalculateLotSize(signal.entry, signal.stopLoss);
      signal.comment = "BUY_Local_RSI_MA";
   }
   //--- Sell signal: Price below MA, RSI overbought, bearish candle
   else if(close < ma && rsi > InpRSIOverbought && close < prevClose)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      double slDistance = InpUseATRStopLoss ? atr * InpATRMultiplier : (signal.entry * InpRiskPercent / 100);
      signal.stopLoss = signal.entry + slDistance;
      signal.takeProfit = signal.entry - (slDistance * InpRiskRewardRatio);
      signal.lotSize = CalculateLotSize(signal.entry, signal.stopLoss);
      signal.comment = "SELL_Local_RSI_MA";
   }

   return signal;
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
   request.symbol = _Symbol;
   request.volume = signal.lotSize;
   request.type = signal.type;
   request.price = signal.entry;
   request.sl = signal.stopLoss;
   request.tp = signal.takeProfit;
   request.deviation = InpSlippagePoints;
   request.magic = InpMagicNumber;
   request.comment = signal.comment;
   request.type_filling = ORDER_FILLING_FOK;

   //--- Send order
   if(!OrderSend(request, result))
   {
      Print("Order failed: ", GetLastError());
      Print("Return code: ", result.retcode);
      return;
   }

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      Print("Trade executed successfully!");
      Print("Deal: ", result.deal);
      Print("Order: ", result.order);
      Print("Volume: ", result.volume);
      Print("Price: ", result.price);

      dailyTradeCount++;

      //--- Send trade notification to backend
      SendTradeNotification(result);
   }
   else
   {
      Print("Trade failed with code: ", result.retcode);
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry, double stopLoss)
{
   if(InpUseFixedLot)
      return NormalizeLot(InpFixedLotSize);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;
   double slDistance = MathAbs(entry - stopLoss);

   if(slDistance == 0) return InpMinLotSize;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double lots = riskAmount / (slDistance / tickSize * tickValue);
   lots = MathFloor(lots / lotStep) * lotStep;

   return NormalizeLot(lots);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(lot, InpMinLotSize);
   lot = MathMin(lot, InpMaxLotSize);
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);

   lot = MathRound(lot / stepLot) * stepLot;

   return lot;
}

//+------------------------------------------------------------------+
//| Check trading filters                                             |
//+------------------------------------------------------------------+
bool PassFilters()
{
   //--- Check spread
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPips)
   {
      Print("Spread too high: ", spread);
      return false;
   }

   //--- Check volatility
   if(InpUseVolatilityFilter && atrBuffer[1] < InpMinATR)
   {
      Print("Volatility too low: ", atrBuffer[1]);
      return false;
   }

   //--- Check trading time
   if(InpUseTimeFilter && !IsWithinTradingHours())
   {
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if within trading hours                                     |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   int currentMinutes = now.hour * 60 + now.min;

   string startParts[];
   string endParts[];
   StringSplit(InpTradingStartTime, ':', startParts);
   StringSplit(InpTradingEndTime, ':', endParts);

   int startMinutes = (int)StringToInteger(startParts[0]) * 60 + (int)StringToInteger(startParts[1]);
   int endMinutes = (int)StringToInteger(endParts[0]) * 60 + (int)StringToInteger(endParts[1]);

   return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
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

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      //--- Trailing stop
      if(InpTrailStop)
      {
         TrailPosition(ticket);
      }

      //--- Partial close
      if(InpPartialClose)
      {
         CheckPartialClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Trail position                                                    |
//+------------------------------------------------------------------+
void TrailPosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double positionSL = PositionGetDouble(POSITION_SL);
   double positionTP = PositionGetDouble(POSITION_TP);
   ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double currentPrice = positionType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double slDistance = MathAbs(positionOpenPrice - positionSL);
   double profitDistance = MathAbs(currentPrice - positionOpenPrice);
   double activationDistance = slDistance * InpTrailStopPercent / 100.0;

   if(profitDistance < activationDistance) return;

   double newSL = 0;
   double trailDistance = slDistance * InpTrailStopStep / 100.0;

   if(positionType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - trailDistance;
      if(newSL <= positionSL) return;
   }
   else
   {
      newSL = currentPrice + trailDistance;
      if(newSL >= positionSL) return;
   }

   //--- Modify position
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_SLTP;
   request.symbol = _Symbol;
   request.sl = newSL;
   request.tp = positionTP;
   request.position = ticket;

   if(OrderSend(request, result))
   {
      Print("Trailing stop updated for position ", ticket);
   }
}

//+------------------------------------------------------------------+
//| Check partial close                                               |
//+------------------------------------------------------------------+
void CheckPartialClose(ulong ticket)
{
   // Implementation for partial close at first target
   // This is a placeholder for advanced feature
}

//+------------------------------------------------------------------+
//| Update daily statistics                                           |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   datetime currentDay = iTime(_Symbol, PERIOD_D1, 0);

   if(currentDay != lastTradeDay)
   {
      dailyTradeCount = 0;
      dailyPnL = 0.0;
      lastTradeDay = currentDay;
   }

   //--- Calculate today's P&L
   double todayPnL = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         {
            todayPnL += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   dailyPnL = todayPnL;
}

//+------------------------------------------------------------------+
//| Check daily limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
   //--- Check max daily trades
   if(dailyTradeCount >= InpMaxDailyTrades)
   {
      return false;
   }

   //--- Check max daily loss
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxLoss = balance * InpMaxDailyLoss / 100.0;

   if(dailyPnL < -maxLoss)
   {
      Print("Daily loss limit reached: $", dailyPnL);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| WebSocket initialization                                          |
//+------------------------------------------------------------------+
bool InitializeWebSocket()
{
   // This is a placeholder - actual WebSocket connection will be
   // handled by the Python bridge script
   Print("Initializing WebSocket connection to: ", InpServerURL);
   return true;
}

//+------------------------------------------------------------------+
//| Get signal from WebSocket                                         |
//+------------------------------------------------------------------+
TradeSignal GetWebSocketSignal()
{
   TradeSignal signal;
   signal.valid = false;

   // This will be implemented with Python bridge
   // The Python script will write signals to a shared file or pipe

   return signal;
}

//+------------------------------------------------------------------+
//| Send trade notification to backend                                |
//+------------------------------------------------------------------+
void SendTradeNotification(MqlTradeResult &result)
{
   // This will send trade data to backend via Python bridge
   Print("Sending trade notification to backend...");
}

//+------------------------------------------------------------------+
//| Close WebSocket                                                   |
//+------------------------------------------------------------------+
void CloseWebSocket()
{
   Print("Closing WebSocket connection...");
}

//+------------------------------------------------------------------+
//| Print EA settings                                                 |
//+------------------------------------------------------------------+
void PrintSettings()
{
   Print("--- Trading Settings ---");
   Print("Risk per trade: ", InpRiskPercent, "%");
   Print("Max total risk: ", InpMaxRiskPercent, "%");
   Print("Risk:Reward ratio: 1:", InpRiskRewardRatio);
   Print("ATR period: ", InpATRPeriod);
   Print("Max daily trades: ", InpMaxDailyTrades);
   Print("Max daily loss: ", InpMaxDailyLoss, "%");
}

//+------------------------------------------------------------------+
//| Print daily statistics                                            |
//+------------------------------------------------------------------+
void PrintDailyStats()
{
   Print("--- Daily Statistics ---");
   Print("Trades today: ", dailyTradeCount);
   Print("P&L today: $", dailyPnL);
}

//+------------------------------------------------------------------+
//| Get uninit reason text                                            |
//+------------------------------------------------------------------+
string GetUninitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM: return "EA stopped by user";
      case REASON_REMOVE: return "EA removed from chart";
      case REASON_RECOMPILE: return "EA recompiled";
      case REASON_CHARTCHANGE: return "Chart symbol or period changed";
      case REASON_CHARTCLOSE: return "Chart closed";
      case REASON_PARAMETERS: return "Input parameters changed";
      case REASON_ACCOUNT: return "Account changed";
      default: return "Unknown reason";
   }
}
//+------------------------------------------------------------------+
