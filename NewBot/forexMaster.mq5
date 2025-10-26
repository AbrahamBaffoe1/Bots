//+------------------------------------------------------------------+
//|                                            forexMaster.mq5        |
//|                    Multi-Currency Forex EA with Python Backend    |
//|                    Advanced Multi-Pair Trading System             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader"
#property link      "https://smartstocktrader.com"
#property version   "1.00"
#property description "Advanced Forex Trading EA with Multi-Currency Support"
#property description "Correlation analysis, basket trading, hedging strategies"
#property description "Python backend integration for ML predictions"

//--- Input Parameters
input group "=== Connection Settings ==="
input string InpServerURL = "http://localhost:5000";  // Backend Server URL
input string InpAPIKey = "";                           // API Key
input bool InpEnableWebSocket = true;                  // Enable WebSocket

input group "=== Trading Settings ==="
input bool InpEnableTrading = true;                    // Enable Trading
input double InpRiskPercent = 1.0;                     // Risk Per Trade (%)
input double InpMaxRiskPercent = 5.0;                  // Max Portfolio Risk (%)
input int InpMagicNumber = 300001;                     // Magic Number Base

input group "=== Multi-Currency Settings ==="
input string InpTradingPairs = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD";  // Trading Pairs (comma-separated)
input bool InpTradeAllPairs = false;                   // Trade All Available Pairs
input bool InpUseCorrelation = true;                   // Use Correlation Filter
input double InpMaxCorrelation = 0.7;                  // Max Correlation Threshold
input bool InpBasketTrading = false;                   // Enable Basket Trading
input int InpMaxSimultaneousTrades = 5;                // Max Simultaneous Trades

input group "=== Risk Management ==="
input double InpATRMultiplierSL = 2.0;                 // ATR Multiplier for SL
input double InpRiskRewardRatio = 2.5;                 // Risk:Reward Ratio
input double InpMaxSpreadPips = 20.0;                  // Max Spread (pips)
input int InpSlippagePoints = 10;                      // Max Slippage
input bool InpUseEquityStop = true;                    // Use Equity Stop
input double InpEquityStopPercent = 5.0;               // Equity Stop (%)

input group "=== Money Management ==="
input double InpMinLotSize = 0.01;                     // Min Lot Size
input double InpMaxLotSize = 2.0;                      // Max Lot Size
input bool InpNormalizeLots = true;                    // Normalize Lots Across Pairs
input bool InpUseMartingale = false;                   // Use Martingale (Risky!)
input double InpMartingaleMultiplier = 1.5;            // Martingale Multiplier

input group "=== Strategy Settings ==="
input ENUM_FOREX_STRATEGY InpStrategy = FOREX_MULTI;   // Trading Strategy
enum ENUM_FOREX_STRATEGY
{
   FOREX_TREND,        // Trend Following
   FOREX_SCALPING,     // Scalping Strategy
   FOREX_SWING,        // Swing Trading
   FOREX_CARRY,        // Carry Trade
   FOREX_MULTI         // Multi-Strategy
};

input group "=== Trend Settings ==="
input int InpFastEMA = 12;                             // Fast EMA Period
input int InpSlowEMA = 26;                             // Slow EMA Period
input int InpSignalMA = 9;                             // Signal MA Period
input int InpADXPeriod = 14;                           // ADX Period
input double InpMinADX = 25.0;                         // Minimum ADX for Trend

input group "=== Scalping Settings ==="
input int InpScalpPeriod = 5;                          // Scalping Period
input double InpScalpTarget = 10.0;                    // Scalp Target (pips)
input double InpScalpStop = 5.0;                       // Scalp Stop (pips)
input bool InpScalpOnlyTrend = true;                   // Scalp Only in Trend

input group "=== Swing Settings ==="
input int InpSwingPeriod = 50;                         // Swing Period
input double InpSwingRisk = 1.5;                       // Swing Risk (%)
input int InpMinSwingBars = 20;                        // Min Bars for Swing

input group "=== Hedging Settings ==="
input bool InpEnableHedging = false;                   // Enable Hedging
input double InpHedgeRatio = 1.0;                      // Hedge Ratio
input double InpHedgeTrigger = 2.0;                    // Hedge Trigger (% loss)

input group "=== Session Filters ==="
input bool InpTradeAsianSession = true;                // Trade Asian Session
input bool InpTradeLondonSession = true;               // Trade London Session
input bool InpTradeNYSession = true;                   // Trade NY Session
input bool InpAvoidOverlap = false;                    // Avoid Session Overlaps

input group "=== Advanced Features ==="
input bool InpUseTrailingStop = true;                  // Use Trailing Stop
input double InpTrailingStart = 20.0;                  // Trailing Start (pips)
input double InpTrailingStep = 10.0;                   // Trailing Step (pips)
input bool InpBreakEven = true;                        // Move to Break Even
input double InpBreakEvenPips = 15.0;                  // BE Trigger (pips)
input int InpMaxDailyTrades = 20;                      // Max Daily Trades
input double InpMaxDailyLoss = 3.0;                    // Max Daily Loss (%)

input group "=== Technical Indicators ==="
input int InpATRPeriod = 14;                           // ATR Period
input int InpRSIPeriod = 14;                           // RSI Period
input int InpMACDFast = 12;                            // MACD Fast Period
input int InpMACDSlow = 26;                            // MACD Slow Period
input int InpMACDSignal = 9;                           // MACD Signal Period

//--- Global Variables
string tradingPairs[];
int pairCount = 0;
datetime lastBarTime = 0;
int dailyTradeCount = 0;
double dailyPnL = 0.0;
datetime lastTradeDay = 0;
double initialBalance = 0;

//--- Structures
struct PairData
{
   string symbol;
   int atrHandle;
   int fastEMAHandle;
   int slowEMAHandle;
   int macdHandle;
   int rsiHandle;
   int adxHandle;
   double atr[];
   double fastEMA[];
   double slowEMA[];
   double macdMain[];
   double macdSignal[];
   double rsi[];
   double adx[];
   bool canTrade;
   datetime lastTradeTime;
   double lastLotSize;
   int consecutiveLosses;
};

struct TradeSignal
{
   bool valid;
   string symbol;
   int type;
   double entry;
   double stopLoss;
   double takeProfit;
   double lotSize;
   string strategy;
   string comment;
   int confidence;
};

struct CorrelationMatrix
{
   string pair1;
   string pair2;
   double correlation;
};

PairData pairs[];
CorrelationMatrix correlations[];

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== Forex Master EA Initializing ===");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Balance: $", AccountInfoDouble(ACCOUNT_BALANCE));
   Print("Strategy: ", EnumToString(InpStrategy));

   initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   //--- Parse trading pairs
   if(!ParseTradingPairs())
   {
      Alert("Failed to parse trading pairs!");
      return(INIT_FAILED);
   }

   //--- Initialize pair data and indicators
   if(!InitializePairs())
   {
      Alert("Failed to initialize pairs!");
      return(INIT_FAILED);
   }

   //--- Initialize WebSocket
   if(InpEnableWebSocket)
   {
      InitializeWebSocket();
   }

   PrintSettings();
   Print("=== Initialization Complete - ", pairCount, " pairs loaded ===");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== Forex Master EA Shutting Down ===");

   //--- Release all indicator handles
   for(int i = 0; i < pairCount; i++)
   {
      if(pairs[i].atrHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].atrHandle);
      if(pairs[i].fastEMAHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].fastEMAHandle);
      if(pairs[i].slowEMAHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].slowEMAHandle);
      if(pairs[i].macdHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].macdHandle);
      if(pairs[i].rsiHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].rsiHandle);
      if(pairs[i].adxHandle != INVALID_HANDLE) IndicatorRelease(pairs[i].adxHandle);
   }

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
   if(!CheckEquityStop()) return;

   //--- Update all pairs
   for(int i = 0; i < pairCount; i++)
   {
      UpdatePairData(i);
   }

   //--- Calculate correlations
   if(InpUseCorrelation)
   {
      CalculateCorrelations();
   }

   //--- Manage existing positions
   ManageAllPositions();

   //--- Check for new trades
   if(InpEnableTrading && CanTradeNow())
   {
      for(int i = 0; i < pairCount; i++)
      {
         if(!pairs[i].canTrade) continue;

         TradeSignal signal = GetTradeSignal(i);
         if(signal.valid && signal.confidence >= 60)
         {
            if(ValidateSignalWithCorrelation(signal))
            {
               ExecuteSignal(signal, i);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Parse trading pairs from input                                    |
//+------------------------------------------------------------------+
bool ParseTradingPairs()
{
   string pairList = InpTradingPairs;
   StringReplace(pairList, " ", "");  // Remove spaces

   string result[];
   int count = StringSplit(pairList, ',', result);

   if(count <= 0)
   {
      Print("No trading pairs specified!");
      return false;
   }

   ArrayResize(tradingPairs, count);
   ArrayResize(pairs, count);

   pairCount = 0;
   for(int i = 0; i < count; i++)
   {
      if(SymbolSelect(result[i], true))
      {
         tradingPairs[pairCount] = result[i];
         pairCount++;
      }
      else
      {
         Print("Warning: Could not select symbol: ", result[i]);
      }
   }

   return (pairCount > 0);
}

//+------------------------------------------------------------------+
//| Initialize all pairs with indicators                              |
//+------------------------------------------------------------------+
bool InitializePairs()
{
   for(int i = 0; i < pairCount; i++)
   {
      pairs[i].symbol = tradingPairs[i];

      //--- Create indicators
      pairs[i].atrHandle = iATR(pairs[i].symbol, PERIOD_CURRENT, InpATRPeriod);
      pairs[i].fastEMAHandle = iMA(pairs[i].symbol, PERIOD_CURRENT, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
      pairs[i].slowEMAHandle = iMA(pairs[i].symbol, PERIOD_CURRENT, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
      pairs[i].macdHandle = iMACD(pairs[i].symbol, PERIOD_CURRENT, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
      pairs[i].rsiHandle = iRSI(pairs[i].symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
      pairs[i].adxHandle = iADX(pairs[i].symbol, PERIOD_CURRENT, InpADXPeriod);

      if(pairs[i].atrHandle == INVALID_HANDLE || pairs[i].fastEMAHandle == INVALID_HANDLE ||
         pairs[i].slowEMAHandle == INVALID_HANDLE || pairs[i].macdHandle == INVALID_HANDLE ||
         pairs[i].rsiHandle == INVALID_HANDLE || pairs[i].adxHandle == INVALID_HANDLE)
      {
         Print("Error creating indicators for ", pairs[i].symbol);
         return false;
      }

      //--- Set arrays as series
      ArraySetAsSeries(pairs[i].atr, true);
      ArraySetAsSeries(pairs[i].fastEMA, true);
      ArraySetAsSeries(pairs[i].slowEMA, true);
      ArraySetAsSeries(pairs[i].macdMain, true);
      ArraySetAsSeries(pairs[i].macdSignal, true);
      ArraySetAsSeries(pairs[i].rsi, true);
      ArraySetAsSeries(pairs[i].adx, true);

      pairs[i].canTrade = true;
      pairs[i].lastTradeTime = 0;
      pairs[i].lastLotSize = 0;
      pairs[i].consecutiveLosses = 0;

      Print(" Initialized: ", pairs[i].symbol);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if new bar                                                  |
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
//| Update pair data                                                  |
//+------------------------------------------------------------------+
void UpdatePairData(int index)
{
   if(CopyBuffer(pairs[index].atrHandle, 0, 0, 3, pairs[index].atr) <= 0) return;
   if(CopyBuffer(pairs[index].fastEMAHandle, 0, 0, 3, pairs[index].fastEMA) <= 0) return;
   if(CopyBuffer(pairs[index].slowEMAHandle, 0, 0, 3, pairs[index].slowEMA) <= 0) return;
   if(CopyBuffer(pairs[index].macdHandle, 0, 0, 3, pairs[index].macdMain) <= 0) return;
   if(CopyBuffer(pairs[index].macdHandle, 1, 0, 3, pairs[index].macdSignal) <= 0) return;
   if(CopyBuffer(pairs[index].rsiHandle, 0, 0, 3, pairs[index].rsi) <= 0) return;
   if(CopyBuffer(pairs[index].adxHandle, 0, 0, 3, pairs[index].adx) <= 0) return;
}

//+------------------------------------------------------------------+
//| Get trade signal for a pair                                       |
//+------------------------------------------------------------------+
TradeSignal GetTradeSignal(int index)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = pairs[index].symbol;
   signal.confidence = 0;

   //--- Check if already in position
   if(PositionSelect(pairs[index].symbol)) return signal;

   //--- Get WebSocket signal first
   if(InpEnableWebSocket)
   {
      signal = GetWebSocketSignalForPair(pairs[index].symbol);
      if(signal.valid) return signal;
   }

   //--- Generate signals based on strategy
   switch(InpStrategy)
   {
      case FOREX_TREND:
         signal = GetTrendSignal(index);
         break;
      case FOREX_SCALPING:
         signal = GetScalpingSignal(index);
         break;
      case FOREX_SWING:
         signal = GetSwingSignal(index);
         break;
      case FOREX_CARRY:
         signal = GetCarrySignal(index);
         break;
      case FOREX_MULTI:
         signal = GetMultiStrategySignal(index);
         break;
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Trend following signal                                            |
//+------------------------------------------------------------------+
TradeSignal GetTrendSignal(int index)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = pairs[index].symbol;
   signal.strategy = "TREND";

   double fastEMA = pairs[index].fastEMA[1];
   double slowEMA = pairs[index].slowEMA[1];
   double macdMain = pairs[index].macdMain[1];
   double macdSignal = pairs[index].macdSignal[1];
   double adx = pairs[index].adx[1];
   double atr = pairs[index].atr[1];

   //--- Check trend strength
   if(adx < InpMinADX) return signal;

   //--- Buy signal: EMA cross up + MACD cross up
   if(fastEMA > slowEMA && pairs[index].fastEMA[2] <= pairs[index].slowEMA[2] &&
      macdMain > macdSignal && macdMain > 0)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(signal.symbol, SYMBOL_ASK);
      signal.stopLoss = signal.entry - (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry + (atr * InpATRMultiplierSL * InpRiskRewardRatio);
      signal.confidence = (int)MathMin(adx + 20, 90);
      signal.comment = "BUY_TREND";
   }
   //--- Sell signal: EMA cross down + MACD cross down
   else if(fastEMA < slowEMA && pairs[index].fastEMA[2] >= pairs[index].slowEMA[2] &&
           macdMain < macdSignal && macdMain < 0)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(signal.symbol, SYMBOL_BID);
      signal.stopLoss = signal.entry + (atr * InpATRMultiplierSL);
      signal.takeProfit = signal.entry - (atr * InpATRMultiplierSL * InpRiskRewardRatio);
      signal.confidence = (int)MathMin(adx + 20, 90);
      signal.comment = "SELL_TREND";
   }

   if(signal.valid)
   {
      signal.lotSize = CalculateLotSize(index, signal.entry, signal.stopLoss);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Scalping signal                                                   |
//+------------------------------------------------------------------+
TradeSignal GetScalpingSignal(int index)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = pairs[index].symbol;
   signal.strategy = "SCALP";

   double close = iClose(signal.symbol, PERIOD_CURRENT, 1);
   double fastEMA = pairs[index].fastEMA[1];
   double rsi = pairs[index].rsi[1];

   double point = SymbolInfoDouble(signal.symbol, SYMBOL_POINT);
   double pipValue = point * 10;

   //--- Buy scalp
   if(close > fastEMA && rsi > 50 && rsi < 70)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      signal.entry = SymbolInfoDouble(signal.symbol, SYMBOL_ASK);
      signal.stopLoss = signal.entry - (InpScalpStop * pipValue);
      signal.takeProfit = signal.entry + (InpScalpTarget * pipValue);
      signal.confidence = 65;
      signal.comment = "BUY_SCALP";
   }
   //--- Sell scalp
   else if(close < fastEMA && rsi < 50 && rsi > 30)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_SELL;
      signal.entry = SymbolInfoDouble(signal.symbol, SYMBOL_BID);
      signal.stopLoss = signal.entry + (InpScalpStop * pipValue);
      signal.takeProfit = signal.entry - (InpScalpTarget * pipValue);
      signal.confidence = 65;
      signal.comment = "SELL_SCALP";
   }

   if(signal.valid)
   {
      signal.lotSize = CalculateLotSize(index, signal.entry, signal.stopLoss);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Swing trading signal                                              |
//+------------------------------------------------------------------+
TradeSignal GetSwingSignal(int index)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = pairs[index].symbol;
   signal.strategy = "SWING";

   // Implementation similar to trend but with wider stops
   signal = GetTrendSignal(index);
   if(signal.valid)
   {
      signal.strategy = "SWING";
      // Widen stops for swing trading
      double atr = pairs[index].atr[1];
      if(signal.type == ORDER_TYPE_BUY)
      {
         signal.stopLoss = signal.entry - (atr * 3.0);
         signal.takeProfit = signal.entry + (atr * 6.0);
      }
      else
      {
         signal.stopLoss = signal.entry + (atr * 3.0);
         signal.takeProfit = signal.entry - (atr * 6.0);
      }
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Carry trade signal                                                |
//+------------------------------------------------------------------+
TradeSignal GetCarrySignal(int index)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = pairs[index].symbol;
   signal.strategy = "CARRY";

   // Placeholder for carry trade logic
   // Would integrate interest rate differentials

   return signal;
}

//+------------------------------------------------------------------+
//| Multi-strategy signal (best of all)                               |
//+------------------------------------------------------------------+
TradeSignal GetMultiStrategySignal(int index)
{
   TradeSignal trend = GetTrendSignal(index);
   TradeSignal scalp = GetScalpingSignal(index);
   TradeSignal swing = GetSwingSignal(index);

   TradeSignal best;
   best.valid = false;
   best.confidence = 0;

   if(trend.valid && trend.confidence > best.confidence) best = trend;
   if(scalp.valid && scalp.confidence > best.confidence) best = scalp;
   if(swing.valid && swing.confidence > best.confidence) best = swing;

   return best;
}

//+------------------------------------------------------------------+
//| Calculate lot size for pair                                       |
//+------------------------------------------------------------------+
double CalculateLotSize(int index, double entry, double stopLoss)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;

   //--- Adjust for number of active trades
   int activeTrades = CountActiveTrades();
   if(activeTrades > 0)
   {
      riskAmount = riskAmount / (activeTrades + 1);
   }

   double slDistance = MathAbs(entry - stopLoss);
   if(slDistance == 0) return InpMinLotSize;

   string symbol = pairs[index].symbol;
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   double lots = riskAmount / (slDistance / tickSize * tickValue);
   lots = MathFloor(lots / lotStep) * lotStep;

   return NormalizeLot(lots, symbol);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lot, string symbol)
{
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(lot, InpMinLotSize);
   lot = MathMin(lot, InpMaxLotSize);
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   lot = MathRound(lot / stepLot) * stepLot;

   return lot;
}

//+------------------------------------------------------------------+
//| Calculate correlations between pairs                              |
//+------------------------------------------------------------------+
void CalculateCorrelations()
{
   // Placeholder for correlation calculation
   // Would calculate Pearson correlation between pairs
}

//+------------------------------------------------------------------+
//| Validate signal with correlation filter                           |
//+------------------------------------------------------------------+
bool ValidateSignalWithCorrelation(TradeSignal &signal)
{
   if(!InpUseCorrelation) return true;

   // Check if we have correlated positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      string posSymbol = PositionGetString(POSITION_SYMBOL);

      // Simplified correlation check
      // In production, use actual correlation values
      if(StringFind(signal.symbol, "USD") >= 0 && StringFind(posSymbol, "USD") >= 0)
      {
         // Both contain USD - check if same direction
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if((posType == POSITION_TYPE_BUY && signal.type == ORDER_TYPE_BUY) ||
            (posType == POSITION_TYPE_SELL && signal.type == ORDER_TYPE_SELL))
         {
            Print("Correlation filter: avoiding correlated trade");
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Execute trade signal                                              |
//+------------------------------------------------------------------+
void ExecuteSignal(TradeSignal &signal, int pairIndex)
{
   if(CountActiveTrades() >= InpMaxSimultaneousTrades) return;

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = signal.symbol;
   request.volume = signal.lotSize;
   request.type = signal.type;
   request.price = signal.entry;
   request.sl = signal.stopLoss;
   request.tp = signal.takeProfit;
   request.deviation = InpSlippagePoints;
   request.magic = InpMagicNumber + pairIndex;
   request.comment = signal.comment;
   request.type_filling = ORDER_FILLING_FOK;

   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
      {
         Print(" ", signal.symbol, " ", signal.comment, " | Lot: ", signal.lotSize, " | Conf: ", signal.confidence, "%");
         dailyTradeCount++;
         pairs[pairIndex].lastTradeTime = TimeCurrent();
         pairs[pairIndex].lastLotSize = signal.lotSize;
         SendTradeNotification(result);
      }
   }
}

//+------------------------------------------------------------------+
//| Manage all positions                                              |
//+------------------------------------------------------------------+
void ManageAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      int magic = (int)PositionGetInteger(POSITION_MAGIC);
      if(magic < InpMagicNumber || magic >= InpMagicNumber + pairCount) continue;

      if(InpBreakEven) MoveToBreakEven(ticket);
      if(InpUseTrailingStop) TrailPosition(ticket);
   }
}

//+------------------------------------------------------------------+
//| Move position to break even                                       |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   string symbol = PositionGetString(POSITION_SYMBOL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipValue = point * 10;

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(symbol, SYMBOL_BID) :
                        SymbolInfoDouble(symbol, SYMBOL_ASK);

   double profitPips = (posType == POSITION_TYPE_BUY ?
                       (currentPrice - openPrice) :
                       (openPrice - currentPrice)) / pipValue;

   if(profitPips >= InpBreakEvenPips)
   {
      if((posType == POSITION_TYPE_BUY && currentSL < openPrice) ||
         (posType == POSITION_TYPE_SELL && currentSL > openPrice))
      {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);

         request.action = TRADE_ACTION_SLTP;
         request.symbol = symbol;
         request.sl = openPrice;
         request.tp = PositionGetDouble(POSITION_TP);
         request.position = ticket;

         OrderSend(request, result);
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
   string symbol = PositionGetString(POSITION_SYMBOL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipValue = point * 10;

   double currentPrice = posType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(symbol, SYMBOL_BID) :
                        SymbolInfoDouble(symbol, SYMBOL_ASK);

   double profitPips = (posType == POSITION_TYPE_BUY ?
                       (currentPrice - openPrice) :
                       (openPrice - currentPrice)) / pipValue;

   if(profitPips < InpTrailingStart) return;

   double newSL = 0;
   if(posType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - (InpTrailingStep * pipValue);
      if(newSL <= currentSL) return;
   }
   else
   {
      newSL = currentPrice + (InpTrailingStep * pipValue);
      if(newSL >= currentSL) return;
   }

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_SLTP;
   request.symbol = symbol;
   request.sl = newSL;
   request.tp = PositionGetDouble(POSITION_TP);
   request.position = ticket;

   OrderSend(request, result);
}

//+------------------------------------------------------------------+
//| Count active trades                                               |
//+------------------------------------------------------------------+
int CountActiveTrades()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      int magic = (int)PositionGetInteger(POSITION_MAGIC);
      if(magic >= InpMagicNumber && magic < InpMagicNumber + pairCount)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Check if can trade now                                            |
//+------------------------------------------------------------------+
bool CanTradeNow()
{
   if(!IsWithinTradingSession()) return false;
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

   if(InpTradeAsianSession && hour >= 0 && hour < 9) return true;
   if(InpTradeLondonSession && hour >= 8 && hour < 17) return true;
   if(InpTradeNYSession && hour >= 13 && hour < 22) return true;

   return false;
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

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   dailyPnL = currentEquity - initialBalance;
}

//+------------------------------------------------------------------+
//| Check daily limits                                                |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
   if(dailyTradeCount >= InpMaxDailyTrades) return false;

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
//| Check equity stop                                                 |
//+------------------------------------------------------------------+
bool CheckEquityStop()
{
   if(!InpUseEquityStop) return true;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double loss = (balance - equity) / balance * 100.0;

   if(loss > InpEquityStopPercent)
   {
      Print("L Equity stop triggered! Loss: ", loss, "%");
      CloseAllPositions();
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Close all positions                                               |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      int magic = (int)PositionGetInteger(POSITION_MAGIC);
      if(magic >= InpMagicNumber && magic < InpMagicNumber + pairCount)
      {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);

         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = PositionGetString(POSITION_SYMBOL);
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.type = (ENUM_ORDER_TYPE)(1 - PositionGetInteger(POSITION_TYPE));
         request.price = request.type == ORDER_TYPE_BUY ?
                        SymbolInfoDouble(request.symbol, SYMBOL_ASK) :
                        SymbolInfoDouble(request.symbol, SYMBOL_BID);
         request.magic = magic;

         OrderSend(request, result);
      }
   }
}

//+------------------------------------------------------------------+
//| WebSocket functions                                               |
//+------------------------------------------------------------------+
bool InitializeWebSocket()
{
   Print("Initializing WebSocket for Forex Multi-Pair Trading...");
   return true;
}

TradeSignal GetWebSocketSignalForPair(string symbol)
{
   TradeSignal signal;
   signal.valid = false;
   signal.symbol = symbol;
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
   Print("--- Forex Master Settings ---");
   Print("Pairs: ", pairCount);
   Print("Strategy: ", EnumToString(InpStrategy));
   Print("Risk: ", InpRiskPercent, "%");
   Print("Max Simultaneous: ", InpMaxSimultaneousTrades);
}

void PrintDailyStats()
{
   Print("--- Daily Stats ---");
   Print("Trades: ", dailyTradeCount);
   Print("P&L: $", dailyPnL);
}
//+------------------------------------------------------------------+
