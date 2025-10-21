//+------------------------------------------------------------------+
//|                                              SST_Heartbeat.mqh   |
//|         Production-Grade Heartbeat & Monitoring Module          |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

#include <SST_WebAPI.mqh>
#include <SST_JSON.mqh>
#include <SST_APIConfig.mqh>
#include <SST_Logger.mqh>

//--------------------------------------------------------------------
// HEARTBEAT STATE
//--------------------------------------------------------------------
struct HeartbeatState {
   datetime lastHeartbeat;
   int successCount;
   int failureCount;
   bool isOnline;
   int consecutiveFailures;
};

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
static bool g_HeartbeatInitialized = false;
static HeartbeatState g_HeartbeatState;
static datetime g_NextHeartbeat = 0;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool Heartbeat_Init() {
   if(g_HeartbeatInitialized) {
      return true;
   }

   g_HeartbeatState.lastHeartbeat = 0;
   g_HeartbeatState.successCount = 0;
   g_HeartbeatState.failureCount = 0;
   g_HeartbeatState.isOnline = false;
   g_HeartbeatState.consecutiveFailures = 0;

   g_NextHeartbeat = TimeCurrent();

   g_HeartbeatInitialized = true;

   Logger_Info(CAT_SYSTEM, "Heartbeat module initialized");
   return true;
}

//--------------------------------------------------------------------
// SEND HEARTBEAT
//--------------------------------------------------------------------
bool Heartbeat_Send() {
   if(!APIConfig_IsHeartbeatEnabled()) {
      Logger_Debug(CAT_HEARTBEAT, "Heartbeat disabled - skipping");
      return false;
   }

   if(!APIConfig_IsAuthenticated()) {
      Logger_Debug(CAT_HEARTBEAT, "Not authenticated - skipping heartbeat");
      return false;
   }

   string botId = APIConfig_GetBotInstanceId();

   if(botId == "") {
      Logger_Error(CAT_HEARTBEAT, "Bot Instance ID not set - cannot send heartbeat");
      return false;
   }

   // Collect account data
   double balance = AccountBalance();
   double equity = AccountEquity();
   double margin = AccountMargin();
   double freeMargin = AccountFreeMargin();

   // Count open positions
   int openPositions = 0;
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
            openPositions++;
         }
      }
   }

   // Determine status
   string status = "RUNNING";
   if(openPositions == 0) {
      status = "IDLE";
   }

   // Build JSON payload
   string jsonBody = JSON_BuildHeartbeat(balance, equity, margin, freeMargin, openPositions, status);

   // Build URL
   string url = APIConfig_GetBotHeartbeatUrl(botId);

   // Get auth token
   string authToken = APIConfig_GetAuthToken();

   // Send request
   Logger_Debug(CAT_HEARTBEAT, "Sending heartbeat", StringFormat("Balance: $%.2f | Equity: $%.2f | Open: %d", balance, equity, openPositions));

   HttpResponse response = WebAPI_POST(url, jsonBody, authToken);

   // Log API request
   Logger_APIRequest("POST", url, response.statusCode);

   if(response.isSuccess) {
      g_HeartbeatState.lastHeartbeat = TimeCurrent();
      g_HeartbeatState.successCount++;
      g_HeartbeatState.isOnline = true;
      g_HeartbeatState.consecutiveFailures = 0;

      Logger_Heartbeat(balance, equity, openPositions);

      return true;
   } else {
      g_HeartbeatState.failureCount++;
      g_HeartbeatState.consecutiveFailures++;

      Logger_APIError("SendHeartbeat",
                     StringFormat("Failed to send heartbeat | Status: %d | Error: %s",
                                 response.statusCode, response.errorMessage));

      // Mark offline after 3 consecutive failures
      if(g_HeartbeatState.consecutiveFailures >= 3) {
         g_HeartbeatState.isOnline = false;
         Logger_Warn(CAT_HEARTBEAT, "Bot marked as OFFLINE after 3 consecutive heartbeat failures");
      }

      return false;
   }
}

//--------------------------------------------------------------------
// HEARTBEAT TIMER (Call from OnTick or OnTimer)
//--------------------------------------------------------------------
void Heartbeat_Update() {
   if(!g_HeartbeatInitialized) {
      Heartbeat_Init();
   }

   if(!APIConfig_IsHeartbeatEnabled()) {
      return;
   }

   // Check if it's time for next heartbeat
   if(TimeCurrent() < g_NextHeartbeat) {
      return;
   }

   // Send heartbeat
   Heartbeat_Send();

   // Schedule next heartbeat
   int intervalSeconds = APIConfig_GetHeartbeatInterval();
   g_NextHeartbeat = TimeCurrent() + intervalSeconds;
}

//--------------------------------------------------------------------
// FORCE HEARTBEAT (Immediate)
//--------------------------------------------------------------------
bool Heartbeat_SendNow() {
   bool success = Heartbeat_Send();

   if(success) {
      // Reset next heartbeat timer
      int intervalSeconds = APIConfig_GetHeartbeatInterval();
      g_NextHeartbeat = TimeCurrent() + intervalSeconds;
   }

   return success;
}

//--------------------------------------------------------------------
// STATUS GETTERS
//--------------------------------------------------------------------
bool Heartbeat_IsOnline() {
   return g_HeartbeatState.isOnline;
}

datetime Heartbeat_GetLastHeartbeat() {
   return g_HeartbeatState.lastHeartbeat;
}

int Heartbeat_GetSuccessCount() {
   return g_HeartbeatState.successCount;
}

int Heartbeat_GetFailureCount() {
   return g_HeartbeatState.failureCount;
}

double Heartbeat_GetSuccessRate() {
   int total = g_HeartbeatState.successCount + g_HeartbeatState.failureCount;
   if(total == 0) return 100.0;
   return (g_HeartbeatState.successCount / (double)total) * 100.0;
}

int Heartbeat_GetConsecutiveFailures() {
   return g_HeartbeatState.consecutiveFailures;
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
void Heartbeat_PrintStats() {
   Print("╔════════════════════════════════════════╗");
   Print("║       Heartbeat Statistics             ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Status:           ", g_HeartbeatState.isOnline ? "ONLINE" : "OFFLINE");
   Print("║ Last Heartbeat:   ", g_HeartbeatState.lastHeartbeat > 0 ? TimeToString(g_HeartbeatState.lastHeartbeat, TIME_DATE|TIME_MINUTES) : "N/A");
   Print("║ Success Count:    ", g_HeartbeatState.successCount);
   Print("║ Failure Count:    ", g_HeartbeatState.failureCount);
   Print("║ Success Rate:     ", DoubleToString(Heartbeat_GetSuccessRate(), 1), "%");
   Print("║ Consecutive Fails:", g_HeartbeatState.consecutiveFailures);
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void Heartbeat_Shutdown() {
   if(g_HeartbeatInitialized) {
      // Send final heartbeat with STOPPED status
      if(APIConfig_IsHeartbeatEnabled() && APIConfig_IsAuthenticated()) {
         string botId = APIConfig_GetBotInstanceId();

         if(botId != "") {
            // Build shutdown heartbeat
            JSONBuilder json;
            json.StartObject();
            json.AddDouble("balance", AccountBalance(), 2);
            json.AddDouble("equity", AccountEquity(), 2);
            json.AddDouble("margin", AccountMargin(), 2);
            json.AddDouble("free_margin", AccountFreeMargin(), 2);
            json.AddInt("open_positions", 0);
            json.AddString("status", "STOPPED");
            json.AddDateTime("timestamp", TimeCurrent());
            json.EndObject();

            string url = APIConfig_GetBotHeartbeatUrl(botId);
            string authToken = APIConfig_GetAuthToken();

            WebAPI_POST(url, json.GetJSON(), authToken);

            Logger_Info(CAT_SYSTEM, "Sent shutdown heartbeat");
         }
      }

      Heartbeat_PrintStats();
      g_HeartbeatInitialized = false;
      Logger_Info(CAT_SYSTEM, "Heartbeat module shut down");
   }
}

//+------------------------------------------------------------------+
