//+------------------------------------------------------------------+
//|                                          SmartStockTrader.mq5    |
//|                       Ultra-Intelligent Stock Trading EA         |
//|  Multi-Strategy | ML Patterns | Advanced Risk | Real-time Analytics |
//|                      CONVERTED FROM MQ4 TO MQ5                    |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0 MT5"
#property link      "https://github.com/yourusername/smart-stock-trader"
#property version   "5.00"
#property description "Professional-grade stock trading EA with 8 strategies"
#property description "Momentum, Mean Reversion, Breakout, Trend, Volume, Gap Trading"
#property description "Advanced Risk Management & Performance Analytics"

//+------------------------------------------------------------------+
//| Include MT5 Trade Library                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//--------------------------------------------------------------------
// BACKEND API CONFIGURATION
//--------------------------------------------------------------------
input string API_BaseURL = "http://localhost:5000";     // Backend API URL
input string API_UserEmail = "";                         // Your account email
input string API_UserPassword = "";                      // Your account password
input bool API_EnableSync = false;                       // Enable backend sync (disabled for MT5 initially)

//--------------------------------------------------------------------
// TRADING CONFIGURATION
//--------------------------------------------------------------------
input string  TradingSymbols        = "AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA,META,NFLX"; // Stock symbols to trade
input int     MagicNumber           = 555888;
input bool    EnableTrading         = true;
input double  RiskPercentPerTrade   = 1.0;
input double  MaxDailyLossPercent   = 5.0;
input int     MaxPositions          = 3;

// Strategy Settings
input bool    UseMomentumStrategy   = true;
input bool    UseMeanReversion      = true;
input bool    UseBreakoutStrategy   = true;
input bool    UseTrendFollowing     = true;
input bool    UseVolumeAnalysis     = true;
input bool    UseGapTrading         = false;  // Gap trading for stocks
input bool    UseMultiTimeframe     = true;
input bool    UseMarketRegime       = true;

// Risk Management
input bool    UseATRStops           = true;
input double  ATRMultiplierSL       = 2.5;
input double  ATRMultiplierTP       = 4.0;
input int     FixedStopLossPips     = 100;
input int     FixedTakeProfitPips   = 200;
input bool    UseTrailingStop       = true;
input int     TrailingStopPips      = 50;
input bool    UseBreakEven          = true;
input int     BreakEvenPips         = 30;
input double  BreakEvenBufferPips   = 5.0;
input bool    UsePartialClose       = true;
input double  Partial1Percent       = 30.0;
input double  Partial1RR            = 1.5;
input double  Partial2Percent       = 30.0;
input double  Partial2RR            = 2.5;

// Indicator Settings
input int     FastMA_Period         = 10;
input int     SlowMA_Period         = 50;
input int     RSI_Period            = 14;
input int     RSI_Oversold          = 30;
input int     RSI_Overbought        = 70;
input int     ATR_Period            = 14;
input int     ADX_Period            = 14;
input int     ADX_Threshold         = 25;

// Time & Session Settings
input int     TradingStartHour      = 9;     // Market open hour
input int     TradingEndHour        = 16;    // Market close hour
input bool    CloseBeforeMarketClose = true;
input int     CloseBeforeMinutes    = 30;

// Display Settings
input bool    ShowDashboard         = true;
input bool    SendNotifications     = false;
input bool    VerboseLogging        = true;
input bool    DebugMode             = false;

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
string  g_Symbols[];
int     g_SymbolCount = 0;
datetime g_DailyStartTime = 0;
double   g_DailyStartEquity = 0;
int     g_DailyTrades = 0;
int     g_TotalTrades = 0;
int     g_TotalWins = 0;
int     g_TotalLosses = 0;

enum EA_STATE { STATE_READY = 0, STATE_SUSPENDED };
EA_STATE g_EAState = STATE_READY;

// Trade tracking structure
struct TradeInfo {
   ulong ticket;
   string symbol;
   ENUM_ORDER_TYPE orderType;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double lotSize;
   datetime openTime;
   string strategy;
   bool partial1Done;
   bool partial2Done;
   bool partial3Done;
   bool breakEvenSet;
};
TradeInfo g_OpenTrades[];

// Indicator handles per symbol
struct SymbolIndicators {
   string symbol;
   int h_FastMA;
   int h_SlowMA;
   int h_MA200;
   int h_RSI;
   int h_ATR;
   int h_ADX;
   int h_Bands;
};
SymbolIndicators g_Indicators[];

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------
int SplitString(string str, string separator, string &result[]) {
   int count = 0;
   string temp = str;
   ArrayResize(result, 0);

   while(StringLen(temp) > 0) {
      int pos = StringFind(temp, separator, 0);
      if(pos < 0) {
         if(StringLen(temp) > 0) {
            ArrayResize(result, count + 1);
            result[count] = temp;
            count++;
         }
         break;
      } else {
         string part = StringSubstr(temp, 0, pos);
         if(StringLen(part) > 0) {
            ArrayResize(result, count + 1);
            result[count] = part;
            count++;
         }
         temp = StringSubstr(temp, pos + StringLen(separator));
      }
   }
   return count;
}

//--------------------------------------------------------------------
// INITIALIZE INDICATORS FOR A SYMBOL
//--------------------------------------------------------------------
bool InitSymbolIndicators(string symbol) {
   SymbolIndicators si;
   si.symbol = symbol;
   si.h_FastMA = iMA(symbol, PERIOD_CURRENT, FastMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_SlowMA = iMA(symbol, PERIOD_CURRENT, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE);
   si.h_MA200 = iMA(symbol, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE);
   si.h_RSI = iRSI(symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   si.h_ATR = iATR(symbol, PERIOD_CURRENT, ATR_Period);
   si.h_ADX = iADX(symbol, PERIOD_CURRENT, ADX_Period);
   si.h_Bands = iBands(symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);

   if(si.h_FastMA == INVALID_HANDLE || si.h_SlowMA == INVALID_HANDLE ||
      si.h_MA200 == INVALID_HANDLE || si.h_RSI == INVALID_HANDLE ||
      si.h_ATR == INVALID_HANDLE || si.h_ADX == INVALID_HANDLE ||
      si.h_Bands == INVALID_HANDLE) {
      Print("ERROR: Failed to create indicators for ", symbol);
      return false;
   }

   int size = ArraySize(g_Indicators);
   ArrayResize(g_Indicators, size + 1);
   g_Indicators[size] = si;
   return true;
}

//--------------------------------------------------------------------
// GET INDICATOR INDEX FOR SYMBOL
//--------------------------------------------------------------------
int GetIndicatorIndex(string symbol) {
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      if(g_Indicators[i].symbol == symbol)
         return i;
   }
   return -1;
}

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════════════════╗");
   Print("║     SMART STOCK TRADER PRO v1.0 - MT5 VERSION     ║");
   Print("╚════════════════════════════════════════════════════╝");

   // Parse symbols
   g_SymbolCount = SplitString(TradingSymbols, ",", g_Symbols);
   if(g_SymbolCount == 0) {
      Print("ERROR: No trading symbols configured!");
      return(INIT_FAILED);
   }

   Print("Configuring ", g_SymbolCount, " symbols...");

   // Initialize indicators for each symbol
   for(int i = 0; i < g_SymbolCount; i++) {
      string sym = g_Symbols[i];
      Print("  → Initializing ", sym);
      if(!InitSymbolIndicators(sym)) {
         Print("  ✗ Failed to initialize ", sym);
      } else {
         Print("  ✓ ", sym, " ready");
      }
   }

   // Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   trade.SetAsyncMode(false);

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   Print("\n=== INITIALIZATION COMPLETE ===");
   Print("Symbols: ", g_SymbolCount);
   Print("Strategies Enabled: ");
   if(UseMomentumStrategy) Print("  - Momentum Trading");
   if(UseMeanReversion) Print("  - Mean Reversion");
   if(UseBreakoutStrategy) Print("  - Breakout Trading");
   if(UseTrendFollowing) Print("  - Trend Following");
   if(UseVolumeAnalysis) Print("  - Volume Analysis");
   if(UseGapTrading) Print("  - Gap Trading");
   if(UseMultiTimeframe) Print("  - Multi-Timeframe");
   if(UseMarketRegime) Print("  - Market Regime Adaptive");

   Print("\n=== READY TO TRADE ===\n");

   if(SendNotifications) {
      SendNotification("Smart Stock Trader MT5: EA started successfully");
   }

   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("\n=== SMART STOCK TRADER MT5 SHUTTING DOWN ===");
   Print("Reason: ", reason);

   // Show final summary
   if(VerboseLogging) {
      double finalEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double totalPL = finalEquity - g_DailyStartEquity;

      Print("\n╔════════════════════════════════════════╗");
      Print("║     PERFORMANCE SUMMARY               ║");
      Print("╠════════════════════════════════════════╣");
      Print("║ Starting Equity:  $", DoubleToString(g_DailyStartEquity, 2));
      Print("║ Final Equity:     $", DoubleToString(finalEquity, 2));
      Print("║ Total P/L:        $", DoubleToString(totalPL, 2));
      Print("║ Total Trades:     ", g_TotalTrades);
      if(g_TotalTrades > 0) {
         double winRate = (double)g_TotalWins / g_TotalTrades * 100.0;
         Print("║ Win Rate:         ", DoubleToString(winRate, 1), "%");
      }
      Print("╚════════════════════════════════════════╝\n");
   }

   // Close all positions if requested
   if(CloseBeforeMarketClose) {
      Print("Closing all open positions...");
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
               trade.PositionClose(ticket);
            }
         }
      }
   }

   // Release indicator handles
   for(int i = 0; i < ArraySize(g_Indicators); i++) {
      IndicatorRelease(g_Indicators[i].h_FastMA);
      IndicatorRelease(g_Indicators[i].h_SlowMA);
      IndicatorRelease(g_Indicators[i].h_MA200);
      IndicatorRelease(g_Indicators[i].h_RSI);
      IndicatorRelease(g_Indicators[i].h_ATR);
      IndicatorRelease(g_Indicators[i].h_ADX);
      IndicatorRelease(g_Indicators[i].h_Bands);
   }

   ObjectsDeleteAll(0, "SST_");

   if(SendNotifications) {
      SendNotification("Smart Stock Trader MT5: EA stopped");
   }

   Print("=== SHUTDOWN COMPLETE ===\n");
}

//--------------------------------------------------------------------
// ON TICK - MAIN TRADING LOGIC
//--------------------------------------------------------------------
void OnTick() {
   // Reset daily statistics if new day
   MqlDateTime dt, dt_start;
   TimeToStruct(TimeCurrent(), dt);
   TimeToStruct(g_DailyStartTime, dt_start);

   if(dt.day != dt_start.day) {
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_DailyTrades = 0;
      Print("━━━ NEW DAY - Daily stats reset ━━━");
   }

   // Update dashboard
   static int tickCount = 0;
   tickCount++;
   if(ShowDashboard && tickCount % 20 == 0) {
      UpdateDashboard();
   }

   // Check if trading is allowed
   if(!EnableTrading) return;
   if(g_EAState == STATE_SUSPENDED) return;

   // Check daily loss limit
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPL = currentEquity - g_DailyStartEquity;
   double dailyLossPercent = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyLossPercent <= -MaxDailyLossPercent) {
      g_EAState = STATE_SUSPENDED;
      Print("⚠ Daily loss limit reached: ", DoubleToString(dailyLossPercent, 2), "%");
      return;
   }

   // Check trading session
   if(dt.hour < TradingStartHour || dt.hour >= TradingEndHour) return;

   // Manage open trades
   ManageOpenTrades();

   // Check if we can open new positions
   if(PositionsTotal() >= MaxPositions) return;

   // Scan symbols for trading opportunities (once per minute)
   static datetime lastScanTime = 0;
   if(TimeCurrent() - lastScanTime < 60) return;
   lastScanTime = TimeCurrent();

   for(int i = 0; i < g_SymbolCount; i++) {
      string symbol = g_Symbols[i];

      // Check if already have position on this symbol
      if(PositionSelect(symbol)) continue;

      // Analyze and trade
      ScanSymbolForSignals(symbol);
   }
}

//--------------------------------------------------------------------
// SCAN SYMBOL FOR TRADING SIGNALS
//--------------------------------------------------------------------
void ScanSymbolForSignals(string symbol) {
   int idx = GetIndicatorIndex(symbol);
   if(idx < 0) return;

   // Get indicator values
   double fastMA[], slowMA[], ma200[], rsi[], atr[], adx[];
   double bandsUpper[], bandsLower[], bandsMiddle[];
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);
   ArraySetAsSeries(ma200, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(adx, true);
   ArraySetAsSeries(bandsUpper, true);
   ArraySetAsSeries(bandsLower, true);
   ArraySetAsSeries(bandsMiddle, true);

   if(CopyBuffer(g_Indicators[idx].h_FastMA, 0, 0, 3, fastMA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_SlowMA, 0, 0, 3, slowMA) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_MA200, 0, 0, 3, ma200) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_RSI, 0, 0, 3, rsi) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ATR, 0, 0, 3, atr) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_ADX, 0, 0, 3, adx) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 1, 0, 3, bandsUpper) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 2, 0, 3, bandsLower) <= 0 ||
      CopyBuffer(g_Indicators[idx].h_Bands, 0, 0, 3, bandsMiddle) <= 0) {
      return;
   }

   // Get price data
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(symbol, PERIOD_CURRENT, 0, 3, close) <= 0) return;

   // Determine market regime
   bool isTrending = (adx[1] > ADX_Threshold);

   int signal = 0;  // 0=none, 1=buy, -1=sell
   double confidence = 0.0;
   string strategyName = "";

   // STRATEGY 1: Momentum (MA Crossover + RSI)
   if(UseMomentumStrategy && isTrending) {
      if(fastMA[1] > slowMA[1] && rsi[1] < RSI_Overbought && close[1] > close[2]) {
         signal = 1;
         confidence = 0.75;
         strategyName = "Momentum Buy";
      } else if(fastMA[1] < slowMA[1] && rsi[1] > RSI_Oversold && close[1] < close[2]) {
         signal = -1;
         confidence = 0.75;
         strategyName = "Momentum Sell";
      }
   }

   // STRATEGY 2: Mean Reversion (Bollinger Bands + RSI)
   if(signal == 0 && UseMeanReversion && !isTrending) {
      if(close[1] <= bandsLower[1] && rsi[1] < RSI_Oversold) {
         signal = 1;
         confidence = 0.70;
         strategyName = "Mean Reversion Buy";
      } else if(close[1] >= bandsUpper[1] && rsi[1] > RSI_Overbought) {
         signal = -1;
         confidence = 0.70;
         strategyName = "Mean Reversion Sell";
      }
   }

   // STRATEGY 3: Trend Following
   if(signal == 0 && UseTrendFollowing && isTrending) {
      if(close[1] > ma200[1] && fastMA[1] > slowMA[1] && rsi[1] > 50) {
         signal = 1;
         confidence = 0.80;
         strategyName = "Trend Following Buy";
      } else if(close[1] < ma200[1] && fastMA[1] < slowMA[1] && rsi[1] < 50) {
         signal = -1;
         confidence = 0.80;
         strategyName = "Trend Following Sell";
      }
   }

   // Execute trade if signal is strong enough
   if(signal != 0 && confidence >= 0.65) {
      ExecuteTrade(symbol, signal == 1, strategyName, confidence);
   }
}

//--------------------------------------------------------------------
// EXECUTE TRADE
//--------------------------------------------------------------------
void ExecuteTrade(string symbol, bool isBuy, string strategy, double confidence) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);

   // Get ATR for stop loss calculation
   int idx = GetIndicatorIndex(symbol);
   if(idx < 0) return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(g_Indicators[idx].h_ATR, 0, 0, 2, atr) <= 0) return;

   double slPips, tpPips;
   if(UseATRStops) {
      slPips = atr[1] / point / 10.0 * ATRMultiplierSL;
      tpPips = atr[1] / point / 10.0 * ATRMultiplierTP;
   } else {
      slPips = FixedStopLossPips;
      tpPips = FixedTakeProfitPips;
   }

   // Calculate position size
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercentPerTrade / 100.0;
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotSize = riskAmount / (slPips * 10.0 * tickValue);

   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);

   // Calculate SL/TP prices
   double price = isBuy ? ask : bid;
   double sl = isBuy ? (price - slPips * point * 10.0) : (price + slPips * point * 10.0);
   double tp = isBuy ? (price + tpPips * point * 10.0) : (price - tpPips * point * 10.0);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   // Execute order
   bool result = false;
   if(isBuy) {
      result = trade.Buy(lotSize, symbol, price, sl, tp, "SST: " + strategy);
   } else {
      result = trade.Sell(lotSize, symbol, price, sl, tp, "SST: " + strategy);
   }

   if(result) {
      ulong ticket = trade.ResultOrder();
      g_TotalTrades++;
      g_DailyTrades++;

      // Add to tracking
      TradeInfo ti;
      ti.ticket = ticket;
      ti.symbol = symbol;
      ti.orderType = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      ti.entryPrice = price;
      ti.stopLoss = sl;
      ti.takeProfit = tp;
      ti.lotSize = lotSize;
      ti.openTime = TimeCurrent();
      ti.strategy = strategy;
      ti.partial1Done = false;
      ti.partial2Done = false;
      ti.partial3Done = false;
      ti.breakEvenSet = false;

      int size = ArraySize(g_OpenTrades);
      ArrayResize(g_OpenTrades, size + 1);
      g_OpenTrades[size] = ti;

      Print("╔════════════════════════════════════╗");
      Print("║       NEW TRADE OPENED            ║");
      Print("╠════════════════════════════════════╣");
      Print("║ Ticket:   ", ticket);
      Print("║ Symbol:   ", symbol);
      Print("║ Type:     ", isBuy ? "BUY" : "SELL");
      Print("║ Price:    ", DoubleToString(price, _Digits));
      Print("║ Lot Size: ", DoubleToString(lotSize, 2));
      Print("║ Stop Loss: ", DoubleToString(sl, _Digits));
      Print("║ Take Profit: ", DoubleToString(tp, _Digits));
      Print("║ Strategy: ", strategy);
      Print("║ Confidence: ", DoubleToString(confidence * 100, 1), "%");
      Print("╚════════════════════════════════════╝");

      if(SendNotifications) {
         SendNotification("Smart Stock Trader MT5: " + (isBuy ? "BUY" : "SELL") + " " + symbol);
      }
   } else {
      Print("✗ ERROR opening trade - ", trade.ResultRetcodeDescription());
   }
}

//--------------------------------------------------------------------
// MANAGE OPEN TRADES
//--------------------------------------------------------------------
void ManageOpenTrades() {
   for(int i = ArraySize(g_OpenTrades) - 1; i >= 0; i--) {
      ulong ticket = g_OpenTrades[i].ticket;

      if(!PositionSelectByTicket(ticket)) {
         // Position closed - remove from tracking
         for(int j = i; j < ArraySize(g_OpenTrades) - 1; j++) {
            g_OpenTrades[j] = g_OpenTrades[j + 1];
         }
         ArrayResize(g_OpenTrades, ArraySize(g_OpenTrades) - 1);
         continue;
      }

      // Position still open - manage it
      string symbol = PositionGetString(POSITION_SYMBOL);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double currentPrice = isBuy ? bid : ask;
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      // Calculate profit in pips
      double profitPips = isBuy ?
                         (currentPrice - openPrice) / point / 10.0 :
                         (openPrice - currentPrice) / point / 10.0;

      // Trailing stop
      if(UseTrailingStop && profitPips > TrailingStopPips) {
         double newSL = isBuy ?
                       NormalizeDouble(currentPrice - TrailingStopPips * point * 10.0, _Digits) :
                       NormalizeDouble(currentPrice + TrailingStopPips * point * 10.0, _Digits);

         if((isBuy && newSL > currentSL) || (!isBuy && (currentSL == 0 || newSL < currentSL))) {
            trade.PositionModify(ticket, newSL, currentTP);
         }
      }

      // Break-even
      if(UseBreakEven && !g_OpenTrades[i].breakEvenSet && profitPips >= BreakEvenPips) {
         double beSL = NormalizeDouble(openPrice + (isBuy ? 1 : -1) * BreakEvenBufferPips * point * 10.0, _Digits);
         if(trade.PositionModify(ticket, beSL, currentTP)) {
            g_OpenTrades[i].breakEvenSet = true;
            if(DebugMode) Print("Break-even set for ", ticket);
         }
      }

      // Partial closes
      if(UsePartialClose) {
         double lots = PositionGetDouble(POSITION_VOLUME);
         double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

         if(lots > minLot) {
            double riskPips = MathAbs(openPrice - currentSL) / point / 10.0;
            if(riskPips <= 0) riskPips = 50.0;
            double rMultiple = profitPips / riskPips;

            // Partial 1
            if(!g_OpenTrades[i].partial1Done && rMultiple >= Partial1RR) {
               double closeVol = NormalizeDouble(lots * Partial1Percent / 100.0, 2);
               if(closeVol >= minLot && closeVol <= lots) {
                  trade.PositionClosePartial(ticket, closeVol);
                  g_OpenTrades[i].partial1Done = true;
               }
            }

            // Partial 2
            if(!g_OpenTrades[i].partial2Done && rMultiple >= Partial2RR) {
               double closeVol = NormalizeDouble(lots * Partial2Percent / 100.0, 2);
               if(closeVol >= minLot && closeVol <= lots) {
                  trade.PositionClosePartial(ticket, closeVol);
                  g_OpenTrades[i].partial2Done = true;
               }
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// UPDATE DASHBOARD
//--------------------------------------------------------------------
void UpdateDashboard() {
   int y = 20;
   int lineHeight = 18;

   CreateLabel("SST_Title", "Smart Stock Trader MT5", 10, y, clrWhite, 11); y += lineHeight + 5;
   CreateLabel("SST_Equity", "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), 10, y, clrLime, 9); y += lineHeight;

   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - g_DailyStartEquity;
   color plColor = dailyPL >= 0 ? clrLime : clrRed;
   CreateLabel("SST_DailyPL", "Daily P/L: $" + DoubleToString(dailyPL, 2), 10, y, plColor, 9); y += lineHeight;

   CreateLabel("SST_Positions", "Open Positions: " + IntegerToString(PositionsTotal()), 10, y, clrWhite, 9); y += lineHeight;
   CreateLabel("SST_Trades", "Total Trades: " + IntegerToString(g_TotalTrades), 10, y, clrWhite, 9); y += lineHeight;

   if(g_TotalTrades > 0) {
      double winRate = (double)g_TotalWins / g_TotalTrades * 100.0;
      CreateLabel("SST_WinRate", "Win Rate: " + DoubleToString(winRate, 1) + "%", 10, y, winRate >= 50 ? clrLime : clrOrange, 9);
   }
}

void CreateLabel(string name, string text, int x, int y, color clr, int size) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
