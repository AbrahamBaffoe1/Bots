//+------------------------------------------------------------------+
//|                                                SST_APIConfig.mqh |
//|              Production-Grade API Configuration Management       |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

//--------------------------------------------------------------------
// API CONFIGURATION STRUCTURE
//--------------------------------------------------------------------
struct APIConfig {
   // Backend API Settings
   string baseUrl;
   string authToken;
   bool isAuthenticated;
   datetime tokenExpiry;

   // Bot Instance Settings
   string botInstanceId;
   string botName;

   // User Credentials
   string userEmail;
   string userPassword;

   // Sync Settings
   bool enableTradeSync;
   bool enableHeartbeat;
   bool enablePerformanceSync;
   bool enableLogSync;

   // Timing Settings
   int heartbeatIntervalSeconds;
   int performanceSyncIntervalSeconds;
   int maxRetries;
   int retryDelayMs;

   // Feature Flags
   bool autoRegisterBot;
   bool autoLogin;
   bool verboseLogging;
   bool offlineMode;

   // Constructor with defaults
   void Init() {
      // API Defaults
      baseUrl = "http://localhost:5000";
      authToken = "";
      isAuthenticated = false;
      tokenExpiry = 0;

      // Bot Defaults
      botInstanceId = "";
      botName = "SmartStockTrader_EA";

      // User Defaults (CHANGE THESE!)
      userEmail = "";
      userPassword = "";

      // Sync Defaults
      enableTradeSync = true;
      enableHeartbeat = true;
      enablePerformanceSync = true;
      enableLogSync = true; // Enabled by default for monitoring

      // Timing Defaults
      heartbeatIntervalSeconds = 60;       // Every 1 minute
      performanceSyncIntervalSeconds = 300; // Every 5 minutes
      maxRetries = 3;
      retryDelayMs = 1000;

      // Feature Defaults
      autoRegisterBot = true;
      autoLogin = true;
      verboseLogging = false;
      offlineMode = false; // Set to true to disable all API calls
   }
};

//--------------------------------------------------------------------
// GLOBAL CONFIGURATION INSTANCE
//--------------------------------------------------------------------
static APIConfig g_APIConfig;
static bool g_ConfigInitialized = false;

//--------------------------------------------------------------------
// CONFIGURATION INITIALIZATION
//--------------------------------------------------------------------
bool APIConfig_Init(
   string baseUrl = "http://localhost:5000",
   string userEmail = "",
   string userPassword = "",
   bool enableTradeSync = true,
   bool enableHeartbeat = true,
   bool enablePerformanceSync = true,
   bool verboseLogging = false
) {
   if(g_ConfigInitialized) {
      Print("⚠ API Config already initialized");
      return true;
   }

   // Initialize with defaults
   g_APIConfig.Init();

   // Override with provided parameters
   if(baseUrl != "") {
      g_APIConfig.baseUrl = baseUrl;
   }

   if(userEmail != "") {
      g_APIConfig.userEmail = userEmail;
   }

   if(userPassword != "") {
      g_APIConfig.userPassword = userPassword;
   }

   g_APIConfig.enableTradeSync = enableTradeSync;
   g_APIConfig.enableHeartbeat = enableHeartbeat;
   g_APIConfig.enablePerformanceSync = enablePerformanceSync;
   g_APIConfig.verboseLogging = verboseLogging;

   // Generate bot name from account info
   g_APIConfig.botName = "SST_" + IntegerToString(AccountNumber()) + "_" + Symbol();

   g_ConfigInitialized = true;

   Print("╔════════════════════════════════════════╗");
   Print("║     API Configuration Initialized      ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Base URL:         ", g_APIConfig.baseUrl);
   Print("║ Bot Name:         ", g_APIConfig.botName);
   Print("║ Trade Sync:       ", g_APIConfig.enableTradeSync ? "ENABLED" : "DISABLED");
   Print("║ Heartbeat:        ", g_APIConfig.enableHeartbeat ? "ENABLED" : "DISABLED");
   Print("║ Performance Sync: ", g_APIConfig.enablePerformanceSync ? "ENABLED" : "DISABLED");
   Print("║ Offline Mode:     ", g_APIConfig.offlineMode ? "YES" : "NO");
   Print("╚════════════════════════════════════════╝");

   return true;
}

//--------------------------------------------------------------------
// CONFIGURATION GETTERS
//--------------------------------------------------------------------
string APIConfig_GetBaseUrl() {
   return g_APIConfig.baseUrl;
}

string APIConfig_GetAuthToken() {
   return g_APIConfig.authToken;
}

bool APIConfig_IsAuthenticated() {
   // Check if authenticated and token not expired
   if(!g_APIConfig.isAuthenticated) return false;
   if(g_APIConfig.tokenExpiry > 0 && TimeCurrent() >= g_APIConfig.tokenExpiry) {
      Print("⚠ Auth token expired");
      g_APIConfig.isAuthenticated = false;
      return false;
   }
   return true;
}

string APIConfig_GetBotInstanceId() {
   return g_APIConfig.botInstanceId;
}

string APIConfig_GetBotName() {
   return g_APIConfig.botName;
}

string APIConfig_GetUserEmail() {
   return g_APIConfig.userEmail;
}

string APIConfig_GetUserPassword() {
   return g_APIConfig.userPassword;
}

bool APIConfig_IsTradeSyncEnabled() {
   return g_APIConfig.enableTradeSync && !g_APIConfig.offlineMode;
}

bool APIConfig_IsHeartbeatEnabled() {
   return g_APIConfig.enableHeartbeat && !g_APIConfig.offlineMode;
}

bool APIConfig_IsPerformanceSyncEnabled() {
   return g_APIConfig.enablePerformanceSync && !g_APIConfig.offlineMode;
}

bool APIConfig_IsLogSyncEnabled() {
   return g_APIConfig.enableLogSync && !g_APIConfig.offlineMode;
}

int APIConfig_GetHeartbeatInterval() {
   return g_APIConfig.heartbeatIntervalSeconds;
}

int APIConfig_GetPerformanceSyncInterval() {
   return g_APIConfig.performanceSyncIntervalSeconds;
}

bool APIConfig_IsVerboseLogging() {
   return g_APIConfig.verboseLogging;
}

bool APIConfig_IsOfflineMode() {
   return g_APIConfig.offlineMode;
}

bool APIConfig_IsAutoRegisterBot() {
   return g_APIConfig.autoRegisterBot;
}

bool APIConfig_IsAutoLogin() {
   return g_APIConfig.autoLogin;
}

//--------------------------------------------------------------------
// CONFIGURATION SETTERS
//--------------------------------------------------------------------
void APIConfig_SetBaseUrl(string url) {
   g_APIConfig.baseUrl = url;
   Print("✓ Base URL updated: ", url);
}

void APIConfig_SetAuthToken(string token, datetime expiry = 0) {
   g_APIConfig.authToken = token;
   g_APIConfig.isAuthenticated = (token != "");
   g_APIConfig.tokenExpiry = expiry;

   if(g_APIConfig.isAuthenticated) {
      Print("✓ Auth token set (expires: ", TimeToString(expiry, TIME_DATE|TIME_MINUTES), ")");
   } else {
      Print("⚠ Auth token cleared");
   }
}

void APIConfig_SetBotInstanceId(string instanceId) {
   g_APIConfig.botInstanceId = instanceId;
   Print("✓ Bot Instance ID set: ", instanceId);
}

void APIConfig_SetBotName(string name) {
   g_APIConfig.botName = name;
   Print("✓ Bot Name set: ", name);
}

void APIConfig_SetUserCredentials(string email, string password) {
   g_APIConfig.userEmail = email;
   g_APIConfig.userPassword = password;
   Print("✓ User credentials updated");
}

void APIConfig_SetTradeSyncEnabled(bool enabled) {
   g_APIConfig.enableTradeSync = enabled;
   Print("✓ Trade Sync: ", enabled ? "ENABLED" : "DISABLED");
}

void APIConfig_SetHeartbeatEnabled(bool enabled) {
   g_APIConfig.enableHeartbeat = enabled;
   Print("✓ Heartbeat: ", enabled ? "ENABLED" : "DISABLED");
}

void APIConfig_SetPerformanceSyncEnabled(bool enabled) {
   g_APIConfig.enablePerformanceSync = enabled;
   Print("✓ Performance Sync: ", enabled ? "ENABLED" : "DISABLED");
}

void APIConfig_SetVerboseLogging(bool enabled) {
   g_APIConfig.verboseLogging = enabled;
   Print("✓ Verbose Logging: ", enabled ? "ENABLED" : "DISABLED");
}

void APIConfig_SetOfflineMode(bool offline) {
   g_APIConfig.offlineMode = offline;
   Print("✓ Offline Mode: ", offline ? "ENABLED" : "DISABLED");
}

void APIConfig_SetHeartbeatInterval(int seconds) {
   g_APIConfig.heartbeatIntervalSeconds = seconds;
   Print("✓ Heartbeat Interval: ", seconds, " seconds");
}

void APIConfig_SetPerformanceSyncInterval(int seconds) {
   g_APIConfig.performanceSyncIntervalSeconds = seconds;
   Print("✓ Performance Sync Interval: ", seconds, " seconds");
}

//--------------------------------------------------------------------
// URL BUILDERS (DRY Principle)
//--------------------------------------------------------------------
string APIConfig_BuildUrl(string endpoint) {
   string url = g_APIConfig.baseUrl;

   // Remove trailing slash from base URL
   if(StringGetCharacter(url, StringLen(url) - 1) == '/') {
      url = StringSubstr(url, 0, StringLen(url) - 1);
   }

   // Add leading slash to endpoint if missing
   if(StringGetCharacter(endpoint, 0) != '/') {
      endpoint = "/" + endpoint;
   }

   return url + endpoint;
}

// Auth Endpoints
string APIConfig_GetAuthLoginUrl() {
   return APIConfig_BuildUrl("/api/auth/login");
}

string APIConfig_GetAuthRegisterUrl() {
   return APIConfig_BuildUrl("/api/auth/register");
}

string APIConfig_GetAuthProfileUrl() {
   return APIConfig_BuildUrl("/api/auth/profile");
}

// Bot Endpoints
string APIConfig_GetBotsUrl() {
   return APIConfig_BuildUrl("/api/bots");
}

string APIConfig_GetBotByIdUrl(string botId) {
   return APIConfig_BuildUrl("/api/bots/" + botId);
}

string APIConfig_GetBotHeartbeatUrl(string botId) {
   return APIConfig_BuildUrl("/api/bots/" + botId + "/heartbeat");
}

string APIConfig_GetBotStatsUrl(string botId) {
   return APIConfig_BuildUrl("/api/bots/" + botId + "/stats");
}

string APIConfig_GetBotStartUrl(string botId) {
   return APIConfig_BuildUrl("/api/bots/" + botId + "/start");
}

string APIConfig_GetBotStopUrl(string botId) {
   return APIConfig_BuildUrl("/api/bots/" + botId + "/stop");
}

// Trade Endpoints
string APIConfig_GetTradesUrl() {
   return APIConfig_BuildUrl("/api/trades");
}

string APIConfig_GetBotTradesUrl(string botId) {
   return APIConfig_BuildUrl("/api/trades/bot/" + botId);
}

string APIConfig_GetTradeByIdUrl(string tradeId) {
   return APIConfig_BuildUrl("/api/trades/" + tradeId);
}

// Performance Endpoints
string APIConfig_GetPerformanceUrl() {
   return APIConfig_BuildUrl("/api/performance");
}

string APIConfig_GetBotPerformanceUrl(string botId) {
   return APIConfig_BuildUrl("/api/performance/bot/" + botId);
}

// Log Endpoints
string APIConfig_GetLogsUrl() {
   return APIConfig_BuildUrl("/api/logs");
}

string APIConfig_GetBotLogsUrl(string botId) {
   return APIConfig_BuildUrl("/api/logs/bot/" + botId);
}

// Health Check
string APIConfig_GetHealthCheckUrl() {
   return APIConfig_BuildUrl("/health");
}

//--------------------------------------------------------------------
// CONFIGURATION VALIDATION
//--------------------------------------------------------------------
bool APIConfig_Validate() {
   bool isValid = true;

   if(g_APIConfig.baseUrl == "") {
      Print("✗ Config Error: Base URL is empty");
      isValid = false;
   }

   if(g_APIConfig.autoLogin) {
      if(g_APIConfig.userEmail == "") {
         Print("✗ Config Error: User email is empty (required for auto-login)");
         isValid = false;
      }

      if(g_APIConfig.userPassword == "") {
         Print("✗ Config Error: User password is empty (required for auto-login)");
         isValid = false;
      }
   }

   if(g_APIConfig.heartbeatIntervalSeconds < 30) {
      Print("⚠ Config Warning: Heartbeat interval too low (", g_APIConfig.heartbeatIntervalSeconds, "s). Recommended: 60s+");
   }

   if(!isValid) {
      Print("╔════════════════════════════════════════╗");
      Print("║     CONFIGURATION VALIDATION FAILED    ║");
      Print("╚════════════════════════════════════════╝");
   }

   return isValid;
}

//--------------------------------------------------------------------
// CONFIGURATION DUMP (Debug)
//--------------------------------------------------------------------
void APIConfig_Print() {
   Print("╔════════════════════════════════════════════════════════╗");
   Print("║              API CONFIGURATION DETAILS                 ║");
   Print("╠════════════════════════════════════════════════════════╣");
   Print("║ Base URL:              ", g_APIConfig.baseUrl);
   Print("║ Bot Name:              ", g_APIConfig.botName);
   Print("║ Bot Instance ID:       ", g_APIConfig.botInstanceId != "" ? g_APIConfig.botInstanceId : "(not set)");
   Print("║ User Email:            ", g_APIConfig.userEmail != "" ? g_APIConfig.userEmail : "(not set)");
   Print("║ Authenticated:         ", g_APIConfig.isAuthenticated ? "YES" : "NO");
   Print("║ Token Expiry:          ", g_APIConfig.tokenExpiry > 0 ? TimeToString(g_APIConfig.tokenExpiry, TIME_DATE|TIME_MINUTES) : "N/A");
   Print("╠════════════════════════════════════════════════════════╣");
   Print("║ Trade Sync:            ", g_APIConfig.enableTradeSync ? "ENABLED" : "DISABLED");
   Print("║ Heartbeat:             ", g_APIConfig.enableHeartbeat ? "ENABLED" : "DISABLED");
   Print("║ Performance Sync:      ", g_APIConfig.enablePerformanceSync ? "ENABLED" : "DISABLED");
   Print("║ Log Sync:              ", g_APIConfig.enableLogSync ? "ENABLED" : "DISABLED");
   Print("╠════════════════════════════════════════════════════════╣");
   Print("║ Heartbeat Interval:    ", g_APIConfig.heartbeatIntervalSeconds, " seconds");
   Print("║ Performance Interval:  ", g_APIConfig.performanceSyncIntervalSeconds, " seconds");
   Print("║ Auto Register Bot:     ", g_APIConfig.autoRegisterBot ? "YES" : "NO");
   Print("║ Auto Login:            ", g_APIConfig.autoLogin ? "YES" : "NO");
   Print("║ Verbose Logging:       ", g_APIConfig.verboseLogging ? "YES" : "NO");
   Print("║ Offline Mode:          ", g_APIConfig.offlineMode ? "YES" : "NO");
   Print("╚════════════════════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void APIConfig_Shutdown() {
   if(g_ConfigInitialized) {
      Print("✓ API Configuration module shut down");
      g_ConfigInitialized = false;
   }
}

//+------------------------------------------------------------------+
