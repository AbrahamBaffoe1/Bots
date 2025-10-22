//+------------------------------------------------------------------+
//|                                          SmartStockTrader.mq4 |
//|                       Ultra-Intelligent Stock Trading EA         |
//|  Multi-Strategy | ML Patterns | Advanced Risk | Real-time Analytics |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0"
#property link      "https://github.com/yourusername/smart-stock-trader"
#property version   "1.00"
#property strict
#property description "Professional-grade stock trading EA with 8 strategies"
#property description "Momentum, Mean Reversion, Breakout, Trend, Volume, Gap Trading"
#property description "Advanced Risk Management & Performance Analytics"

//--------------------------------------------------------------------
// BACKEND API CONFIGURATION
//--------------------------------------------------------------------
input string API_BaseURL = "http://localhost:5000";     // Backend API URL
input string API_UserEmail = "";                         // Your account email
input string API_UserPassword = "";                      // Your account password
input bool API_EnableSync = true;                        // Enable backend sync

//--------------------------------------------------------------------
// INCLUDE ALL MODULES
//--------------------------------------------------------------------
#include <SST_LicenseManager.mqh>
#include <SST_Config.mqh>
#include <SST_Logger.mqh>
#include <SST_APIConfig.mqh>
#include <SST_WebAPI.mqh>
#include <SST_BotAuth.mqh>
#include <SST_Heartbeat.mqh>
#include <SST_PerformanceSync.mqh>
#include <SST_SessionManager.mqh>
#include <SST_Indicators.mqh>
#include <SST_PatternRecognition.mqh>
#include <SST_MarketStructure.mqh>
#include <SST_RiskManager.mqh>
#include <SST_Strategies.mqh>
#include <SST_Analytics.mqh>
#include <SST_Dashboard.mqh>
#include <SST_HTMLDashboard.mqh>

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════════════════╗");
   Print("║     SMART STOCK TRADER PRO v1.0 - STARTING...     ║");
   Print("╚════════════════════════════════════════════════════╝");

   // VALIDATE LICENSE FIRST
   if(!License_Validate()) {
      Print("╔════════════════════════════════════════════════════╗");
      Print("║         LICENSE VALIDATION FAILED!                ║");
      Print("║         EA WILL NOT TRADE                         ║");
      Print("╚════════════════════════════════════════════════════╝");
      return(INIT_FAILED);
   }

   Print("\n✓ License validated successfully\n");

   // Initialize all modules
   Config_Init();
   Logger_Init(LOG_INFO, true, false, true); // Enable console + remote logging
   Logger_Info(CAT_SYSTEM, "SmartStockTrader EA v1.0 starting");

   // Initialize API modules (if enabled)
   if(API_EnableSync && API_UserEmail != "" && API_UserPassword != "") {
      Logger_Info(CAT_SYSTEM, "Initializing backend API connection...");

      // Initialize API Config
      APIConfig_Init(API_BaseURL, API_UserEmail, API_UserPassword, true, true, true, false);

      // Initialize WebAPI
      WebAPI_Init();

      // Authenticate with backend (login + register bot)
      if(BotAuth_Authenticate()) {
         Logger_Info(CAT_SYSTEM, "✓ Backend authentication successful");

         // Initialize Heartbeat module
         Heartbeat_Init();

         // Initialize Performance Sync module
         PerformanceSync_Init();

         Logger_Info(CAT_SYSTEM, "✓ All API modules initialized");
      } else {
         Logger_Warn(CAT_SYSTEM, "✗ Backend authentication failed - EA will run in offline mode");
      }
   } else {
      if(API_EnableSync) {
         Logger_Warn(CAT_SYSTEM, "Backend sync enabled but no credentials provided");
         Logger_Warn(CAT_SYSTEM, "Please set API_UserEmail and API_UserPassword in EA inputs");
      }
      Logger_Info(CAT_SYSTEM, "Running in offline mode (no backend sync)");
   }

   Session_Init();
   Risk_Init();
   Structure_Init();
   Analytics_Init();
   Dashboard_Init();

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
      SendNotification("Smart Stock Trader: EA started successfully");
   }

   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("\n=== SMART STOCK TRADER SHUTTING DOWN ===");
   Print("Reason: ", reason);

   // Show final summary if BacktestMode or VerboseLogging
   if(BacktestMode || VerboseLogging) {
      double finalEquity = AccountEquity();
      double totalPL = finalEquity - g_DailyStartEquity;
      int totalTrades = g_DailyTrades;  // This is actually all-time if analytics module tracks it

      Print("\n╔════════════════════════════════════════╗");
      Print("║     PERFORMANCE SUMMARY               ║");
      Print("╠════════════════════════════════════════╣");
      Print("║ Starting Equity:  $", DoubleToString(g_DailyStartEquity, 2));
      Print("║ Final Equity:     $", DoubleToString(finalEquity, 2));
      Print("║ Total P/L:        $", DoubleToString(totalPL, 2), " (", DoubleToString((totalPL/g_DailyStartEquity)*100, 2), "%)");
      Print("║ Total Trades:     ", totalTrades);
      if(totalTrades > 0) {
         double winRate = Analytics_GetWinRate();
         Print("║ Win Rate:         ", DoubleToString(winRate * 100, 1), "%");
         Print("║ Profit Factor:    ", DoubleToString(Analytics_GetProfitFactor(), 2));
      }
      Print("╚════════════════════════════════════════╝\n");
   }

   // Close all open positions if requested
   if(CloseBeforeMarketClose) {
      Print("Closing all open positions...");
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderMagicNumber() == MagicNumber) {
               bool closed = OrderClose(OrderTicket(), OrderLots(),
                                       OrderType() == OP_BUY ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK),
                                       5, clrRed);
               if(closed) {
                  Print("Closed position: ", OrderTicket());
               }
            }
         }
      }
   }

   // Cleanup
   Analytics_Deinit();
   Dashboard_Remove();

   // Shutdown API modules (if enabled)
   if(API_EnableSync) {
      Heartbeat_Shutdown();
      PerformanceSync_Shutdown();
      BotAuth_Shutdown();
      WebAPI_Shutdown();
      APIConfig_Shutdown();
   }

   Logger_Shutdown();

   if(SendNotifications) {
      SendNotification("Smart Stock Trader: EA stopped");
   }

   Print("=== SHUTDOWN COMPLETE ===\n");
}

//--------------------------------------------------------------------
// ON TICK - MAIN TRADING LOGIC
//--------------------------------------------------------------------
void OnTick() {
   // Update logger (flush remote logs periodically)
   Logger_Update();

   // Update heartbeat (send to backend periodically)
   if(API_EnableSync) {
      Heartbeat_Update();
      PerformanceSync_Update();
   }

   // Update session status
   Session_Update();

   // Reset daily statistics if new day
   Config_ResetDaily();

   // Check daily loss limit
   if(Risk_CheckDailyLossLimit()) {
      Dashboard_Update();
      return;
   }

   // Update market structure periodically
   Structure_Update();

   // Clean old patterns
   static datetime lastPatternClean = 0;
   if(TimeCurrent() - lastPatternClean > 3600) {
      Pattern_CleanOld();
      lastPatternClean = TimeCurrent();
   }

   // Manage open trades
   ManageOpenTrades();

   // Update dashboard
   static int tickCount = 0;
   tickCount++;
   if(tickCount % 10 == 0) { // Update dashboard every 10 ticks
      Dashboard_Update();
      Dashboard_DrawSRLevels();
   }

   // Update HTML dashboard every 60 seconds
   static datetime lastHTMLUpdate = 0;
   if(TimeCurrent() - lastHTMLUpdate > 60) {
      HTMLDashboard_Generate();
      lastHTMLUpdate = TimeCurrent();
   }

   // Check if we can trade
   if(!EnableTrading) return;
   if(!Session_IsTradingTime()) return;
   if(g_EAState == STATE_SUSPENDED) return;

   // Check if near market close
   if(Session_IsNearClose()) {
      CloseAllPositions("Market closing soon");
      return;
   }

   // Scan for trading opportunities on each symbol
   static datetime lastScanTime = 0;
   if(TimeCurrent() - lastScanTime < 60) return; // Scan once per minute

   for(int i = 0; i < g_SymbolCount; i++) {
      string symbol = g_Symbols[i];

      // Pre-trade checks
      if(Risk_CheckMaxPositions(symbol)) continue;
      if(!Risk_CheckSpread(symbol)) continue;
      if(!Risk_CheckVolatility(symbol, MTF_Timeframe1)) continue;
      if(Risk_IsCorrelatedPosition(symbol)) continue;

      // Scan for candlestick patterns
      if(DetectCandlePatterns) {
         Pattern_ScanCandlestick(symbol, MTF_Timeframe1, 1);
      }

      // Get best trading signal
      StrategySignal signal = Strategy_GetBestSignal(symbol, MTF_Timeframe1);

      // Execute trade if signal is strong enough
      if(signal.direction != 0 && signal.confidence >= 0.65) {
         ExecuteTrade(symbol, signal);
      }
   }

   lastScanTime = TimeCurrent();
}

//--------------------------------------------------------------------
// EXECUTE TRADE
//--------------------------------------------------------------------
void ExecuteTrade(string symbol, StrategySignal &signal) {
   bool isBuy = (signal.direction == 1);

   // Calculate stop loss and take profit
   double stopLoss = Risk_CalculateStopLoss(symbol, MTF_Timeframe1, isBuy);
   double takeProfit = Risk_CalculateTakeProfit(symbol, MTF_Timeframe1, isBuy);

   // Calculate position size
   double point = MarketInfo(symbol, MODE_POINT);
   double slPips = MathAbs((isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID)) - stopLoss) / point / 10.0;
   double lotSize = Risk_CalculatePositionSize(symbol, slPips);

   // Execute order
   double price = isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   int cmd = isBuy ? OP_BUY : OP_SELL;

   int ticket = OrderSend(symbol, cmd, lotSize, price, 5, stopLoss, takeProfit,
                         "SST: " + signal.strategyName, MagicNumber, 0,
                         isBuy ? clrBlue : clrRed);

   if(ticket > 0) {
      // Add to tracking
      TradeInfo trade;
      trade.ticket = ticket;
      trade.symbol = symbol;
      trade.orderType = cmd;
      trade.entryPrice = price;
      trade.stopLoss = stopLoss;
      trade.takeProfit = takeProfit;
      trade.lotSize = lotSize;
      trade.openTime = TimeCurrent();
      trade.strategy = signal.strategyName;
      trade.partial1Done = false;
      trade.partial2Done = false;
      trade.partial3Done = false;
      trade.breakEvenSet = false;

      int size = ArraySize(g_OpenTrades);
      ArrayResize(g_OpenTrades, size + 1);
      g_OpenTrades[size] = trade;

      Print("╔════════════════════════════════════╗");
      Print("║         NEW TRADE OPENED          ║");
      Print("╠════════════════════════════════════╣");
      Print("║ Ticket:   ", ticket);
      Print("║ Symbol:   ", symbol);
      Print("║ Type:     ", isBuy ? "BUY" : "SELL");
      Print("║ Price:    ", DoubleToString(price, _Digits));
      Print("║ Lot Size: ", DoubleToString(lotSize, 2));
      Print("║ Stop Loss: ", DoubleToString(stopLoss, _Digits));
      Print("║ Take Profit: ", DoubleToString(takeProfit, _Digits));
      Print("║ Strategy: ", signal.strategyName);
      Print("║ Confidence: ", DoubleToString(signal.confidence * 100, 1), "%");
      Print("╚════════════════════════════════════╝");

      if(SendNotifications) {
         SendNotification("Smart Stock Trader: " + (isBuy ? "BUY" : "SELL") + " " + symbol +
                         "\nPrice: " + DoubleToString(price, _Digits) +
                         "\nStrategy: " + signal.strategyName +
                         "\nConfidence: " + DoubleToString(signal.confidence * 100, 1) + "%");
      }
   } else {
      int error = GetLastError();
      Print("ERROR: Failed to open trade on ", symbol, " - Error code: ", error);
   }
}

//--------------------------------------------------------------------
// MANAGE OPEN TRADES
//--------------------------------------------------------------------
void ManageOpenTrades() {
   for(int i = ArraySize(g_OpenTrades) - 1; i >= 0; i--) {
      int ticket = g_OpenTrades[i].ticket;

      if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
         // Order closed - log it
         if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
            Analytics_LogTrade(ticket, g_OpenTrades[i].strategy, g_OpenTrades[i].openTime, OrderCloseTime());
         }

         // Remove from tracking
         for(int j = i; j < ArraySize(g_OpenTrades) - 1; j++) {
            g_OpenTrades[j] = g_OpenTrades[j + 1];
         }
         ArrayResize(g_OpenTrades, ArraySize(g_OpenTrades) - 1);
         continue;
      }

      // Trade still open - manage it
      string symbol = OrderSymbol();
      double bid = MarketInfo(symbol, MODE_BID);
      double ask = MarketInfo(symbol, MODE_ASK);
      double point = MarketInfo(symbol, MODE_POINT);
      bool isBuy = (OrderType() == OP_BUY);
      double currentPrice = isBuy ? bid : ask;

      // Calculate profit in pips
      double profitPips = isBuy ?
                         (currentPrice - OrderOpenPrice()) / point / 10.0 :
                         (OrderOpenPrice() - currentPrice) / point / 10.0;

      // Trailing stop
      if(UseTrailingStop && profitPips > 0) {
         double trailDistance = UseATRStops ?
                                iATR(symbol, MTF_Timeframe1, ATR_Period, 0) * TrailingATRMultiplier / point / 10.0 :
                                TrailingStopPips;

         double newSL = isBuy ?
                       NormalizeDouble(currentPrice - trailDistance * point * 10.0, _Digits) :
                       NormalizeDouble(currentPrice + trailDistance * point * 10.0, _Digits);

         if((isBuy && newSL > OrderStopLoss()) || (!isBuy && (OrderStopLoss() == 0 || newSL < OrderStopLoss()))) {
            if(OrderModify(ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrYellow)) {
               if(DebugMode) Print("Trailing stop updated for ", ticket, ": ", newSL);
            }
         }
      }

      // Break-even
      if(UseBreakEven && !g_OpenTrades[i].breakEvenSet && profitPips >= BreakEvenPips) {
         double beSL = NormalizeDouble(OrderOpenPrice() + (isBuy ? 1 : -1) * BreakEvenBufferPips * point * 10.0, _Digits);

         if(OrderModify(ticket, OrderOpenPrice(), beSL, OrderTakeProfit(), 0, clrGreen)) {
            g_OpenTrades[i].breakEvenSet = true;
            if(DebugMode) Print("Break-even set for ", ticket);
         }
      }

      // Partial closes
      if(UsePartialClose && OrderLots() > MarketInfo(symbol, MODE_MINLOT)) {
         double riskPips = MathAbs(OrderOpenPrice() - OrderStopLoss()) / point / 10.0;
         if(riskPips <= 0) riskPips = 50.0; // Fallback default
         double rMultiple = profitPips / riskPips;

         // Partial 1
         if(!g_OpenTrades[i].partial1Done && rMultiple >= Partial1RR) {
            double closeVolume = NormalizeDouble(OrderLots() * Partial1Percent / 100.0, 2);
            if(closeVolume >= MarketInfo(symbol, MODE_MINLOT) && closeVolume <= OrderLots()) {
               if(OrderClose(ticket, closeVolume, currentPrice, 5, clrOrange)) {
                  g_OpenTrades[i].partial1Done = true;
                  if(DebugMode) Print("Partial close 1 executed for ", ticket);
               }
            }
         }

         // Partial 2
         if(!g_OpenTrades[i].partial2Done && rMultiple >= Partial2RR) {
            double closeVolume = NormalizeDouble(OrderLots() * Partial2Percent / 100.0, 2);
            if(closeVolume >= MarketInfo(symbol, MODE_MINLOT) && closeVolume <= OrderLots()) {
               if(OrderClose(ticket, closeVolume, currentPrice, 5, clrOrange)) {
                  g_OpenTrades[i].partial2Done = true;
                  if(DebugMode) Print("Partial close 2 executed for ", ticket);
               }
            }
         }

         // Partial 3
         if(!g_OpenTrades[i].partial3Done && rMultiple >= Partial3RR) {
            double closeVolume = NormalizeDouble(OrderLots() * Partial3Percent / 100.0, 2);
            if(closeVolume >= MarketInfo(symbol, MODE_MINLOT) && closeVolume <= OrderLots()) {
               if(OrderClose(ticket, closeVolume, currentPrice, 5, clrOrange)) {
                  g_OpenTrades[i].partial3Done = true;
                  if(DebugMode) Print("Partial close 3 executed for ", ticket);
               }
            }
         }
      }
   }
}

//--------------------------------------------------------------------
// CLOSE ALL POSITIONS
//--------------------------------------------------------------------
void CloseAllPositions(string reason) {
   Print("Closing all positions - Reason: ", reason);

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            bool closed = OrderClose(OrderTicket(), OrderLots(),
                                   OrderType() == OP_BUY ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK),
                                   10, clrRed);
            if(closed) {
               Print("Closed position: ", OrderTicket());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
