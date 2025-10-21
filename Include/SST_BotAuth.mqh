//+------------------------------------------------------------------+
//|                                               SST_BotAuth.mqh    |
//|      Production-Grade Bot Authentication & Registration         |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

#include <SST_WebAPI.mqh>
#include <SST_JSON.mqh>
#include <SST_APIConfig.mqh>
#include <SST_Logger.mqh>

//--------------------------------------------------------------------
// AUTHENTICATION STATE
//--------------------------------------------------------------------
static bool g_BotAuthInitialized = false;
static bool g_IsLoggedIn = false;
static bool g_IsBotRegistered = false;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool BotAuth_Init() {
   if(g_BotAuthInitialized) {
      return true;
   }

   g_IsLoggedIn = false;
   g_IsBotRegistered = false;

   g_BotAuthInitialized = true;

   Logger_Info(CAT_SYSTEM, "Bot Auth module initialized");
   return true;
}

//--------------------------------------------------------------------
// USER LOGIN
//--------------------------------------------------------------------
bool BotAuth_Login(string email = "", string password = "") {
   if(g_IsLoggedIn && APIConfig_IsAuthenticated()) {
      Logger_Debug(CAT_API, "Already logged in");
      return true;
   }

   // Use config credentials if not provided
   if(email == "") {
      email = APIConfig_GetUserEmail();
   }

   if(password == "") {
      password = APIConfig_GetUserPassword();
   }

   if(email == "" || password == "") {
      Logger_Error(CAT_API, "Login failed: Email or password not provided");
      return false;
   }

   // Build JSON payload
   string jsonBody = JSON_BuildAuthLogin(email, password);

   // Build URL
   string url = APIConfig_GetAuthLoginUrl();

   // Send request (no auth token needed for login)
   Logger_Info(CAT_API, "Attempting user login", "Email: " + email);

   HttpResponse response = WebAPI_POST(url, jsonBody, "");

   // Log API request
   Logger_APIRequest("POST", url, response.statusCode);

   if(response.isSuccess) {
      // Parse response to extract token
      JSONParser parser(response.body);

      string token = parser.GetString("token");
      if(token == "") {
         token = parser.GetString("accessToken");
      }

      if(token == "") {
         Logger_Error(CAT_API, "Login succeeded but no token in response");
         return false;
      }

      // Calculate token expiry (default 7 days)
      datetime expiry = TimeCurrent() + (7 * 24 * 60 * 60);

      // Try to parse expiry from response
      string expiryStr = parser.GetString("expiresIn");
      if(expiryStr != "") {
         long expirySeconds = StringToInteger(expiryStr);
         expiry = TimeCurrent() + (int)expirySeconds;
      }

      // Save token to config
      APIConfig_SetAuthToken(token, expiry);

      g_IsLoggedIn = true;

      Logger_Info(CAT_API, "User logged in successfully", "Token expires: " + TimeToString(expiry, TIME_DATE|TIME_MINUTES));

      return true;
   } else {
      Logger_APIError("Login", StringFormat("Failed | Status: %d | Error: %s", response.statusCode, response.errorMessage));
      return false;
   }
}

//--------------------------------------------------------------------
// BOT REGISTRATION
//--------------------------------------------------------------------
bool BotAuth_RegisterBot() {
   if(g_IsBotRegistered && APIConfig_GetBotInstanceId() != "") {
      Logger_Debug(CAT_API, "Bot already registered");
      return true;
   }

   if(!APIConfig_IsAuthenticated()) {
      Logger_Error(CAT_API, "Must be logged in before registering bot");
      return false;
   }

   // Collect bot information
   string botName = APIConfig_GetBotName();
   long accountNumber = AccountNumber();
   string accountName = AccountName();
   string brokerName = AccountCompany();
   string serverName = AccountServer();
   string version = "1.0";

   // Build JSON payload
   string jsonBody = JSON_BuildBotRegistration(
      botName,
      accountNumber,
      accountName,
      brokerName,
      serverName,
      version
   );

   // Build URL
   string url = APIConfig_GetBotsUrl();

   // Get auth token
   string authToken = APIConfig_GetAuthToken();

   // Send request
   Logger_Info(CAT_API, "Registering bot with backend", "Bot Name: " + botName);

   HttpResponse response = WebAPI_POST(url, jsonBody, authToken);

   // Log API request
   Logger_APIRequest("POST", url, response.statusCode);

   if(response.isSuccess) {
      // Parse response to get bot ID
      JSONParser parser(response.body);

      string botId = parser.GetString("id");
      if(botId == "") {
         botId = parser.GetString("_id"); // MongoDB uses _id
      }

      if(botId == "") {
         Logger_Error(CAT_API, "Bot registration succeeded but no ID in response");
         return false;
      }

      // Save bot ID to config
      APIConfig_SetBotInstanceId(botId);

      g_IsBotRegistered = true;

      Logger_Info(CAT_API, "Bot registered successfully", "Bot ID: " + botId);

      return true;
   } else {
      Logger_APIError("RegisterBot",
                     StringFormat("Failed | Status: %d | Error: %s",
                                 response.statusCode, response.errorMessage));

      return false;
   }
}

//--------------------------------------------------------------------
// GET OR CREATE BOT (Smart Registration)
//--------------------------------------------------------------------
bool BotAuth_GetOrCreateBot() {
   if(!APIConfig_IsAuthenticated()) {
      Logger_Error(CAT_API, "Must be logged in before getting/creating bot");
      return false;
   }

   // Try to get existing bot by account number
   string url = APIConfig_GetBotsUrl() + "?account_number=" + IntegerToString(AccountNumber());
   string authToken = APIConfig_GetAuthToken();

   Logger_Debug(CAT_API, "Checking for existing bot registration");

   HttpResponse response = WebAPI_GET(url, authToken);

   if(response.isSuccess && response.body != "") {
      // Parse response
      JSONParser parser(response.body);

      // Check if we got a bot list or single bot
      string botId = parser.GetString("id");
      if(botId == "") {
         botId = parser.GetString("_id");
      }

      if(botId != "") {
         // Found existing bot
         APIConfig_SetBotInstanceId(botId);
         g_IsBotRegistered = true;

         Logger_Info(CAT_API, "Found existing bot registration", "Bot ID: " + botId);
         return true;
      }
   }

   // Bot not found, register new one
   Logger_Info(CAT_API, "No existing bot found, registering new bot");
   return BotAuth_RegisterBot();
}

//--------------------------------------------------------------------
// FULL AUTHENTICATION FLOW
//--------------------------------------------------------------------
bool BotAuth_Authenticate() {
   if(!g_BotAuthInitialized) {
      BotAuth_Init();
   }

   Logger_Info(CAT_SYSTEM, "═══ Starting Authentication Flow ═══");

   // Step 1: Login
   if(!APIConfig_IsAutoLogin()) {
      Logger_Warn(CAT_API, "Auto-login disabled in config");
      return false;
   }

   if(!BotAuth_Login()) {
      Logger_Error(CAT_API, "✗ Login failed");
      return false;
   }

   Logger_Info(CAT_API, "✓ Login successful");

   // Step 2: Register/Get Bot
   if(!APIConfig_IsAutoRegisterBot()) {
      Logger_Warn(CAT_API, "Auto-register bot disabled in config");
      return true; // Login succeeded, just skip bot registration
   }

   if(!BotAuth_GetOrCreateBot()) {
      Logger_Error(CAT_API, "✗ Bot registration failed");
      return false;
   }

   Logger_Info(CAT_API, "✓ Bot registered");

   Logger_Info(CAT_SYSTEM, "═══ Authentication Complete ═══");

   return true;
}

//--------------------------------------------------------------------
// VALIDATE AUTHENTICATION (Check & Refresh if Needed)
//--------------------------------------------------------------------
bool BotAuth_ValidateAndRefresh() {
   if(!g_BotAuthInitialized) {
      BotAuth_Init();
   }

   // Check if authenticated
   if(!APIConfig_IsAuthenticated()) {
      Logger_Warn(CAT_API, "Auth token expired or invalid, re-authenticating...");
      return BotAuth_Authenticate();
   }

   // Check if bot is registered
   if(APIConfig_GetBotInstanceId() == "") {
      Logger_Warn(CAT_API, "Bot not registered, registering now...");
      return BotAuth_GetOrCreateBot();
   }

   return true;
}

//--------------------------------------------------------------------
// LOGOUT (Clear Credentials)
//--------------------------------------------------------------------
void BotAuth_Logout() {
   APIConfig_SetAuthToken("", 0);
   g_IsLoggedIn = false;

   Logger_Info(CAT_API, "User logged out");
}

//--------------------------------------------------------------------
// STATUS GETTERS
//--------------------------------------------------------------------
bool BotAuth_IsLoggedIn() {
   return g_IsLoggedIn && APIConfig_IsAuthenticated();
}

bool BotAuth_IsBotRegistered() {
   return g_IsBotRegistered && (APIConfig_GetBotInstanceId() != "");
}

bool BotAuth_IsFullyAuthenticated() {
   return BotAuth_IsLoggedIn() && BotAuth_IsBotRegistered();
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
void BotAuth_PrintStatus() {
   Print("╔════════════════════════════════════════╗");
   Print("║       Authentication Status            ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Logged In:        ", g_IsLoggedIn ? "YES" : "NO");
   Print("║ Bot Registered:   ", g_IsBotRegistered ? "YES" : "NO");
   Print("║ Authenticated:    ", APIConfig_IsAuthenticated() ? "YES" : "NO");
   Print("║ Bot Instance ID:  ", APIConfig_GetBotInstanceId() != "" ? APIConfig_GetBotInstanceId() : "(not set)");
   Print("║ Token Expiry:     ", APIConfig_IsAuthenticated() ? "Valid" : "Expired/Invalid");
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void BotAuth_Shutdown() {
   if(g_BotAuthInitialized) {
      BotAuth_PrintStatus();
      g_BotAuthInitialized = false;
      Logger_Info(CAT_SYSTEM, "Bot Auth module shut down");
   }
}

//+------------------------------------------------------------------+
