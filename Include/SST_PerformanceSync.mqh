//+------------------------------------------------------------------+
//|                                         SST_PerformanceSync.mqh  |
//|       Production-Grade Performance Metrics Synchronization       |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

#include <SST_WebAPI.mqh>
#include <SST_JSON.mqh>
#include <SST_APIConfig.mqh>
#include <SST_Logger.mqh>

//--------------------------------------------------------------------
// PERFORMANCE METRICS STRUCTURE
//--------------------------------------------------------------------
struct PerformanceMetrics {
   // Trade Statistics
   int totalTrades;
   int winningTrades;
   int losingTrades;
   double winRate;

   // Financial Metrics
   double grossProfit;
   double grossLoss;
   double netProfit;
   double profitFactor;

   // Risk Metrics
   double maxDrawdown;
   double maxDrawdownPercent;
   double sharpeRatio;

   // Timing
   datetime calculatedAt;
   datetime periodStart;
   datetime periodEnd;
};

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
static bool g_PerformanceSyncInitialized = false;
static PerformanceMetrics g_CurrentMetrics;
static datetime g_LastPerformanceSync = 0;
static datetime g_NextPerformanceSync = 0;
static int g_PerformanceSyncCount = 0;
static int g_PerformanceSyncFailures = 0;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool PerformanceSync_Init() {
   if(g_PerformanceSyncInitialized) {
      return true;
   }

   // Initialize metrics
   PerformanceSync_ResetMetrics();

   g_LastPerformanceSync = 0;
   g_NextPerformanceSync = TimeCurrent();
   g_PerformanceSyncCount = 0;
   g_PerformanceSyncFailures = 0;

   g_PerformanceSyncInitialized = true;

   Logger_Info(CAT_SYSTEM, "Performance Sync module initialized");
   return true;
}

//--------------------------------------------------------------------
// RESET METRICS
//--------------------------------------------------------------------
void PerformanceSync_ResetMetrics() {
   g_CurrentMetrics.totalTrades = 0;
   g_CurrentMetrics.winningTrades = 0;
   g_CurrentMetrics.losingTrades = 0;
   g_CurrentMetrics.winRate = 0.0;
   g_CurrentMetrics.grossProfit = 0.0;
   g_CurrentMetrics.grossLoss = 0.0;
   g_CurrentMetrics.netProfit = 0.0;
   g_CurrentMetrics.profitFactor = 0.0;
   g_CurrentMetrics.maxDrawdown = 0.0;
   g_CurrentMetrics.maxDrawdownPercent = 0.0;
   g_CurrentMetrics.sharpeRatio = 0.0;
   g_CurrentMetrics.calculatedAt = 0;
   g_CurrentMetrics.periodStart = 0;
   g_CurrentMetrics.periodEnd = 0;
}

//--------------------------------------------------------------------
// CALCULATE METRICS FROM ACCOUNT HISTORY
//--------------------------------------------------------------------
bool PerformanceSync_CalculateMetrics() {
   PerformanceSync_ResetMetrics();

   g_CurrentMetrics.periodStart = iTime(Symbol(), PERIOD_D1, 365); // Last year
   g_CurrentMetrics.periodEnd = TimeCurrent();

   int historyTotal = OrdersHistoryTotal();

   if(historyTotal == 0) {
      Logger_Debug(CAT_PERFORMANCE, "No trade history available");
      return false;
   }

   // Temporary variables
   double runningProfit = 0.0;
   double peakEquity = AccountBalance();
   double maxDD = 0.0;

   // Loop through history
   for(int i = 0; i < historyTotal; i++) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         continue;
      }

      // Only count closed trades within period
      if(OrderCloseTime() < g_CurrentMetrics.periodStart || OrderCloseTime() > g_CurrentMetrics.periodEnd) {
         continue;
      }

      // Only count buy/sell orders (not pending)
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) {
         continue;
      }

      double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();

      g_CurrentMetrics.totalTrades++;

      if(orderProfit > 0) {
         g_CurrentMetrics.winningTrades++;
         g_CurrentMetrics.grossProfit += orderProfit;
      } else {
         g_CurrentMetrics.losingTrades++;
         g_CurrentMetrics.grossLoss += MathAbs(orderProfit);
      }

      // Calculate drawdown
      runningProfit += orderProfit;
      double currentEquity = AccountBalance() + runningProfit;

      if(currentEquity > peakEquity) {
         peakEquity = currentEquity;
      }

      double currentDD = peakEquity - currentEquity;
      if(currentDD > maxDD) {
         maxDD = currentDD;
      }
   }

   // Calculate derived metrics
   if(g_CurrentMetrics.totalTrades > 0) {
      g_CurrentMetrics.winRate = (g_CurrentMetrics.winningTrades / (double)g_CurrentMetrics.totalTrades) * 100.0;
   }

   g_CurrentMetrics.netProfit = g_CurrentMetrics.grossProfit - g_CurrentMetrics.grossLoss;

   if(g_CurrentMetrics.grossLoss > 0) {
      g_CurrentMetrics.profitFactor = g_CurrentMetrics.grossProfit / g_CurrentMetrics.grossLoss;
   } else if(g_CurrentMetrics.grossProfit > 0) {
      g_CurrentMetrics.profitFactor = 999.99; // Infinite profit factor (no losses)
   }

   g_CurrentMetrics.maxDrawdown = maxDD;

   if(AccountBalance() > 0) {
      g_CurrentMetrics.maxDrawdownPercent = (maxDD / AccountBalance()) * 100.0;
   }

   // Sharpe ratio calculation (simplified - would need daily returns for accurate calculation)
   // For now, use a simple approximation
   if(g_CurrentMetrics.totalTrades >= 30) {
      double avgReturn = g_CurrentMetrics.netProfit / g_CurrentMetrics.totalTrades;
      double stdDev = PerformanceSync_CalculateStdDev();

      if(stdDev > 0) {
         g_CurrentMetrics.sharpeRatio = (avgReturn / stdDev) * MathSqrt(252); // Annualized
      }
   }

   g_CurrentMetrics.calculatedAt = TimeCurrent();

   Logger_Performance(
      g_CurrentMetrics.totalTrades,
      g_CurrentMetrics.winRate,
      g_CurrentMetrics.profitFactor,
      g_CurrentMetrics.netProfit
   );

   return true;
}

//--------------------------------------------------------------------
// CALCULATE STANDARD DEVIATION OF RETURNS
//--------------------------------------------------------------------
double PerformanceSync_CalculateStdDev() {
   if(g_CurrentMetrics.totalTrades < 2) {
      return 0.0;
   }

   double returns[];
   ArrayResize(returns, 0);

   int historyTotal = OrdersHistoryTotal();

   for(int i = 0; i < historyTotal; i++) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         continue;
      }

      if(OrderCloseTime() < g_CurrentMetrics.periodStart || OrderCloseTime() > g_CurrentMetrics.periodEnd) {
         continue;
      }

      if(OrderType() != OP_BUY && OrderType() != OP_SELL) {
         continue;
      }

      double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();

      int size = ArraySize(returns);
      ArrayResize(returns, size + 1);
      returns[size] = orderProfit;
   }

   int count = ArraySize(returns);
   if(count < 2) {
      return 0.0;
   }

   // Calculate mean
   double sum = 0.0;
   for(int i = 0; i < count; i++) {
      sum += returns[i];
   }
   double mean = sum / count;

   // Calculate variance
   double variance = 0.0;
   for(int i = 0; i < count; i++) {
      double diff = returns[i] - mean;
      variance += diff * diff;
   }
   variance /= (count - 1);

   return MathSqrt(variance);
}

//--------------------------------------------------------------------
// SEND METRICS TO BACKEND
//--------------------------------------------------------------------
bool PerformanceSync_SendMetrics() {
   if(!APIConfig_IsPerformanceSyncEnabled()) {
      Logger_Debug(CAT_PERFORMANCE, "Performance sync disabled - skipping");
      return false;
   }

   if(!APIConfig_IsAuthenticated()) {
      Logger_Error(CAT_PERFORMANCE, "Not authenticated - cannot sync performance");
      return false;
   }

   string botId = APIConfig_GetBotInstanceId();

   if(botId == "") {
      Logger_Error(CAT_PERFORMANCE, "Bot Instance ID not set - cannot sync performance");
      return false;
   }

   // Calculate latest metrics
   if(!PerformanceSync_CalculateMetrics()) {
      Logger_Warn(CAT_PERFORMANCE, "No metrics to sync");
      return false;
   }

   // Build JSON payload
   string jsonBody = JSON_BuildPerformanceMetrics(
      g_CurrentMetrics.totalTrades,
      g_CurrentMetrics.winningTrades,
      g_CurrentMetrics.losingTrades,
      g_CurrentMetrics.winRate,
      g_CurrentMetrics.profitFactor,
      g_CurrentMetrics.grossProfit,
      g_CurrentMetrics.grossLoss,
      g_CurrentMetrics.netProfit,
      g_CurrentMetrics.maxDrawdown,
      g_CurrentMetrics.sharpeRatio
   );

   // Build URL
   string url = APIConfig_GetBotPerformanceUrl(botId);

   // Get auth token
   string authToken = APIConfig_GetAuthToken();

   // Send request
   Logger_Debug(CAT_PERFORMANCE, "Sending performance metrics to backend");

   HttpResponse response = WebAPI_POST(url, jsonBody, authToken);

   // Log API request
   Logger_APIRequest("POST", url, response.statusCode);

   if(response.isSuccess) {
      g_LastPerformanceSync = TimeCurrent();
      g_PerformanceSyncCount++;

      Logger_Info(CAT_PERFORMANCE, "Performance metrics synced",
                  StringFormat("Trades: %d | Win Rate: %.1f%% | PF: %.2f",
                              g_CurrentMetrics.totalTrades,
                              g_CurrentMetrics.winRate,
                              g_CurrentMetrics.profitFactor));

      return true;
   } else {
      g_PerformanceSyncFailures++;

      Logger_APIError("SendPerformanceMetrics",
                     StringFormat("Failed to sync | Status: %d | Error: %s",
                                 response.statusCode, response.errorMessage));

      return false;
   }
}

//--------------------------------------------------------------------
// PERFORMANCE SYNC TIMER (Call from OnTick or OnTimer)
//--------------------------------------------------------------------
void PerformanceSync_Update() {
   if(!g_PerformanceSyncInitialized) {
      PerformanceSync_Init();
   }

   if(!APIConfig_IsPerformanceSyncEnabled()) {
      return;
   }

   // Check if it's time for next sync
   if(TimeCurrent() < g_NextPerformanceSync) {
      return;
   }

   // Send metrics
   PerformanceSync_SendMetrics();

   // Schedule next sync
   int intervalSeconds = APIConfig_GetPerformanceSyncInterval();
   g_NextPerformanceSync = TimeCurrent() + intervalSeconds;
}

//--------------------------------------------------------------------
// FORCE SYNC (Immediate)
//--------------------------------------------------------------------
bool PerformanceSync_SendNow() {
   bool success = PerformanceSync_SendMetrics();

   if(success) {
      // Reset next sync timer
      int intervalSeconds = APIConfig_GetPerformanceSyncInterval();
      g_NextPerformanceSync = TimeCurrent() + intervalSeconds;
   }

   return success;
}

//--------------------------------------------------------------------
// GETTERS
//--------------------------------------------------------------------
PerformanceMetrics PerformanceSync_GetCurrentMetrics() {
   return g_CurrentMetrics;
}

datetime PerformanceSync_GetLastSync() {
   return g_LastPerformanceSync;
}

int PerformanceSync_GetSyncCount() {
   return g_PerformanceSyncCount;
}

int PerformanceSync_GetSyncFailures() {
   return g_PerformanceSyncFailures;
}

double PerformanceSync_GetSyncSuccessRate() {
   int total = g_PerformanceSyncCount + g_PerformanceSyncFailures;
   if(total == 0) return 100.0;
   return (g_PerformanceSyncCount / (double)total) * 100.0;
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
void PerformanceSync_PrintStats() {
   Print("╔════════════════════════════════════════╗");
   Print("║    Performance Sync Statistics         ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Last Sync:        ", g_LastPerformanceSync > 0 ? TimeToString(g_LastPerformanceSync, TIME_DATE|TIME_MINUTES) : "N/A");
   Print("║ Sync Count:       ", g_PerformanceSyncCount);
   Print("║ Failures:         ", g_PerformanceSyncFailures);
   Print("║ Success Rate:     ", DoubleToString(PerformanceSync_GetSyncSuccessRate(), 1), "%");
   Print("╠════════════════════════════════════════╣");
   Print("║ Current Metrics:");
   Print("║ Total Trades:     ", g_CurrentMetrics.totalTrades);
   Print("║ Win Rate:         ", DoubleToString(g_CurrentMetrics.winRate, 1), "%");
   Print("║ Profit Factor:    ", DoubleToString(g_CurrentMetrics.profitFactor, 2));
   Print("║ Net Profit:       $", DoubleToString(g_CurrentMetrics.netProfit, 2));
   Print("║ Max DD:           $", DoubleToString(g_CurrentMetrics.maxDrawdown, 2), " (", DoubleToString(g_CurrentMetrics.maxDrawdownPercent, 1), "%)");
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void PerformanceSync_Shutdown() {
   if(g_PerformanceSyncInitialized) {
      // Send final performance snapshot
      PerformanceSync_SendMetrics();

      PerformanceSync_PrintStats();
      g_PerformanceSyncInitialized = false;
      Logger_Info(CAT_SYSTEM, "Performance Sync module shut down");
   }
}

//+------------------------------------------------------------------+
