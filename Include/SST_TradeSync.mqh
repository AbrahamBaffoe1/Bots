//+------------------------------------------------------------------+
//|                                                SST_TradeSync.mqh |
//|          Production-Grade Trade Synchronization Module          |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

#include <SST_WebAPI.mqh>
#include <SST_JSON.mqh>
#include <SST_APIConfig.mqh>
#include <SST_Logger.mqh>

//--------------------------------------------------------------------
// TRADE SYNC STATE
//--------------------------------------------------------------------
struct TradeSyncState {
   int ticket;
   string backendTradeId;
   bool isSynced;
   int syncAttempts;
   datetime lastSyncAttempt;
};

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
static bool g_TradeSyncInitialized = false;
static TradeSyncState g_SyncedTrades[];
static int g_SyncedTradesCount = 0;
static int g_TotalSyncAttempts = 0;
static int g_SuccessfulSyncs = 0;
static int g_FailedSyncs = 0;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool TradeSync_Init() {
   if(g_TradeSyncInitialized) {
      return true;
   }

   ArrayResize(g_SyncedTrades, 0);
   g_SyncedTradesCount = 0;
   g_TotalSyncAttempts = 0;
   g_SuccessfulSyncs = 0;
   g_FailedSyncs = 0;

   g_TradeSyncInitialized = true;

   Logger_Info(CAT_SYSTEM, "Trade Sync module initialized");
   return true;
}

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------

// Find trade in synced array
int TradeSync_FindTrade(int ticket) {
   for(int i = 0; i < g_SyncedTradesCount; i++) {
      if(g_SyncedTrades[i].ticket == ticket) {
         return i;
      }
   }
   return -1;
}

// Add trade to sync tracking
void TradeSync_AddTrade(int ticket, string backendTradeId) {
   int index = TradeSync_FindTrade(ticket);

   if(index >= 0) {
      // Update existing entry
      g_SyncedTrades[index].backendTradeId = backendTradeId;
      g_SyncedTrades[index].isSynced = true;
   } else {
      // Add new entry
      ArrayResize(g_SyncedTrades, g_SyncedTradesCount + 1);

      g_SyncedTrades[g_SyncedTradesCount].ticket = ticket;
      g_SyncedTrades[g_SyncedTradesCount].backendTradeId = backendTradeId;
      g_SyncedTrades[g_SyncedTradesCount].isSynced = true;
      g_SyncedTrades[g_SyncedTradesCount].syncAttempts = 1;
      g_SyncedTrades[g_SyncedTradesCount].lastSyncAttempt = TimeCurrent();

      g_SyncedTradesCount++;
   }
}

// Mark sync attempt
void TradeSync_MarkAttempt(int ticket) {
   int index = TradeSync_FindTrade(ticket);

   if(index >= 0) {
      g_SyncedTrades[index].syncAttempts++;
      g_SyncedTrades[index].lastSyncAttempt = TimeCurrent();
   }
}

//--------------------------------------------------------------------
// SEND TRADE OPEN TO BACKEND
//--------------------------------------------------------------------
bool TradeSync_SendTradeOpen(
   int ticket,
   string symbol,
   bool isBuy,
   double lotSize,
   double openPrice,
   double stopLoss,
   double takeProfit,
   string strategy = "",
   datetime openTime = 0,
   string comment = ""
) {
   if(!APIConfig_IsTradeSyncEnabled()) {
      Logger_Debug(CAT_API, "Trade sync disabled - skipping");
      return false;
   }

   if(!APIConfig_IsAuthenticated()) {
      Logger_Error(CAT_API, "Not authenticated - cannot sync trade");
      return false;
   }

   g_TotalSyncAttempts++;

   // Prepare trade data
   if(openTime == 0) {
      openTime = TimeCurrent();
   }

   string tradeType = isBuy ? "BUY" : "SELL";

   // Build JSON payload
   string jsonBody = JSON_BuildTradeOpen(
      ticket,
      symbol,
      tradeType,
      lotSize,
      openPrice,
      stopLoss,
      takeProfit,
      strategy,
      openTime,
      comment
   );

   // Get bot instance ID
   string botId = APIConfig_GetBotInstanceId();

   if(botId == "") {
      Logger_Error(CAT_API, "Bot Instance ID not set - cannot sync trade");
      g_FailedSyncs++;
      return false;
   }

   // Build URL
   string url = APIConfig_GetBotTradesUrl(botId);

   // Get auth token
   string authToken = APIConfig_GetAuthToken();

   // Send request
   Logger_Debug(CAT_API, "Sending trade open to backend", "Ticket: " + IntegerToString(ticket));

   HttpResponse response = WebAPI_POST(url, jsonBody, authToken);

   // Log API request
   Logger_APIRequest("POST", url, response.statusCode);

   if(response.isSuccess) {
      // Parse response to get backend trade ID
      JSONParser parser(response.body);
      string backendTradeId = parser.GetString("id");

      if(backendTradeId == "") {
         backendTradeId = parser.GetString("_id"); // MongoDB uses _id
      }

      if(backendTradeId == "") {
         backendTradeId = IntegerToString(ticket); // Fallback to ticket number
      }

      // Track synced trade
      TradeSync_AddTrade(ticket, backendTradeId);

      g_SuccessfulSyncs++;

      Logger_Info(CAT_TRADE, "Trade synced to backend",
                  StringFormat("Ticket: %d | Backend ID: %s", ticket, backendTradeId));

      Logger_TradeOpened(ticket, symbol, tradeType, lotSize, openPrice, stopLoss, takeProfit);

      return true;
   } else {
      g_FailedSyncs++;

      Logger_APIError("SendTradeOpen",
                     StringFormat("Failed to sync ticket %d | Status: %d | Error: %s",
                                 ticket, response.statusCode, response.errorMessage));

      TradeSync_MarkAttempt(ticket);

      return false;
   }
}

//--------------------------------------------------------------------
// SEND TRADE CLOSE TO BACKEND
//--------------------------------------------------------------------
bool TradeSync_SendTradeClose(
   int ticket,
   double closePrice,
   double profit,
   double commission,
   double swap,
   datetime closeTime = 0
) {
   if(!APIConfig_IsTradeSyncEnabled()) {
      return false;
   }

   if(!APIConfig_IsAuthenticated()) {
      Logger_Error(CAT_API, "Not authenticated - cannot sync trade close");
      return false;
   }

   // Find trade in synced array
   int index = TradeSync_FindTrade(ticket);

   if(index < 0) {
      Logger_Warn(CAT_API, "Trade not found in sync tracking",
                  "Ticket: " + IntegerToString(ticket) + " - attempting to sync anyway");

      // Try to sync anyway using ticket as ID
      return TradeSync_SendTradeCloseById(IntegerToString(ticket), closePrice, profit, commission, swap, closeTime);
   }

   string backendTradeId = g_SyncedTrades[index].backendTradeId;

   return TradeSync_SendTradeCloseById(backendTradeId, closePrice, profit, commission, swap, closeTime);
}

// Send trade close by backend ID
bool TradeSync_SendTradeCloseById(
   string backendTradeId,
   double closePrice,
   double profit,
   double commission,
   double swap,
   datetime closeTime = 0
) {
   if(closeTime == 0) {
      closeTime = TimeCurrent();
   }

   g_TotalSyncAttempts++;

   // Build JSON payload
   string jsonBody = JSON_BuildTradeClose(closePrice, profit, commission, swap, closeTime);

   // Build URL
   string url = APIConfig_GetTradeByIdUrl(backendTradeId);

   // Get auth token
   string authToken = APIConfig_GetAuthToken();

   // Send request
   Logger_Debug(CAT_API, "Sending trade close to backend", "Backend ID: " + backendTradeId);

   HttpResponse response = WebAPI_PUT(url, jsonBody, authToken);

   // Log API request
   Logger_APIRequest("PUT", url, response.statusCode);

   if(response.isSuccess) {
      g_SuccessfulSyncs++;

      Logger_Info(CAT_TRADE, "Trade close synced to backend",
                  StringFormat("Backend ID: %s | P/L: $%.2f", backendTradeId, profit));

      return true;
   } else {
      g_FailedSyncs++;

      Logger_APIError("SendTradeClose",
                     StringFormat("Failed to sync close for %s | Status: %d | Error: %s",
                                 backendTradeId, response.statusCode, response.errorMessage));

      return false;
   }
}

//--------------------------------------------------------------------
// AUTO-SYNC EXISTING TRADES (On Startup)
//--------------------------------------------------------------------
int TradeSync_SyncExistingTrades() {
   if(!APIConfig_IsTradeSyncEnabled() || !APIConfig_IsAuthenticated()) {
      return 0;
   }

   Logger_Info(CAT_SYSTEM, "Auto-syncing existing open trades...");

   int syncedCount = 0;
   int totalOrders = OrdersTotal();

   for(int i = 0; i < totalOrders; i++) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         continue;
      }

      int ticket = OrderTicket();
      string symbol = OrderSymbol();
      int orderType = OrderType();
      double lots = OrderLots();
      double openPrice = OrderOpenPrice();
      double sl = OrderStopLoss();
      double tp = OrderTakeProfit();
      datetime openTime = OrderOpenTime();
      string comment = OrderComment();

      // Check if already synced
      if(TradeSync_FindTrade(ticket) >= 0) {
         continue; // Already synced
      }

      // Only sync buy/sell orders (not pending orders)
      if(orderType != OP_BUY && orderType != OP_SELL) {
         continue;
      }

      bool isBuy = (orderType == OP_BUY);

      // Sync to backend
      if(TradeSync_SendTradeOpen(ticket, symbol, isBuy, lots, openPrice, sl, tp, "Existing", openTime, comment)) {
         syncedCount++;
      }

      // Don't overwhelm the API
      Sleep(100);
   }

   Logger_Info(CAT_SYSTEM, "Auto-sync complete", IntegerToString(syncedCount) + " trades synced");

   return syncedCount;
}

//--------------------------------------------------------------------
// RETRY FAILED SYNCS
//--------------------------------------------------------------------
int TradeSync_RetryFailedSyncs(int maxRetries = 3) {
   if(!APIConfig_IsTradeSyncEnabled() || !APIConfig_IsAuthenticated()) {
      return 0;
   }

   int retriedCount = 0;

   for(int i = 0; i < g_SyncedTradesCount; i++) {
      // Skip already synced trades
      if(g_SyncedTrades[i].isSynced) {
         continue;
      }

      // Skip trades that exceeded max retries
      if(g_SyncedTrades[i].syncAttempts >= maxRetries) {
         continue;
      }

      // Skip if retried recently (within last 5 minutes)
      if(TimeCurrent() - g_SyncedTrades[i].lastSyncAttempt < 300) {
         continue;
      }

      int ticket = g_SyncedTrades[i].ticket;

      // Try to sync again
      if(OrderSelect(ticket, SELECT_BY_TICKET)) {
         bool isBuy = (OrderType() == OP_BUY);

         if(TradeSync_SendTradeOpen(
            ticket,
            OrderSymbol(),
            isBuy,
            OrderLots(),
            OrderOpenPrice(),
            OrderStopLoss(),
            OrderTakeProfit(),
            "Retry",
            OrderOpenTime(),
            OrderComment()
         )) {
            retriedCount++;
         }
      }

      // Rate limit
      Sleep(100);
   }

   if(retriedCount > 0) {
      Logger_Info(CAT_SYSTEM, "Retried failed syncs", IntegerToString(retriedCount) + " trades");
   }

   return retriedCount;
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
double TradeSync_GetSuccessRate() {
   if(g_TotalSyncAttempts == 0) return 100.0;
   return (g_SuccessfulSyncs / (double)g_TotalSyncAttempts) * 100.0;
}

void TradeSync_PrintStats() {
   Print("╔════════════════════════════════════════╗");
   Print("║       Trade Sync Statistics            ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Total Synced:     ", g_SyncedTradesCount);
   Print("║ Total Attempts:   ", g_TotalSyncAttempts);
   Print("║ Successful:       ", g_SuccessfulSyncs);
   Print("║ Failed:           ", g_FailedSyncs);
   Print("║ Success Rate:     ", DoubleToString(TradeSync_GetSuccessRate(), 1), "%");
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void TradeSync_Shutdown() {
   if(g_TradeSyncInitialized) {
      TradeSync_PrintStats();
      g_TradeSyncInitialized = false;
      Logger_Info(CAT_SYSTEM, "Trade Sync module shut down");
   }
}

//+------------------------------------------------------------------+
