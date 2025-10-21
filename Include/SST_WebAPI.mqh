//+------------------------------------------------------------------+
//|                                                  SST_WebAPI.mqh  |
//|                     Production-Grade HTTP Client for MT4/MT5     |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

//--------------------------------------------------------------------
// HTTP METHOD ENUMERATION
//--------------------------------------------------------------------
enum HTTP_METHOD {
   HTTP_GET,
   HTTP_POST,
   HTTP_PUT,
   HTTP_PATCH,
   HTTP_DELETE
};

//--------------------------------------------------------------------
// HTTP RESPONSE STRUCTURE
//--------------------------------------------------------------------
struct HttpResponse {
   int statusCode;
   string body;
   string errorMessage;
   bool isSuccess;
   datetime timestamp;
};

//--------------------------------------------------------------------
// HTTP REQUEST CONFIGURATION
//--------------------------------------------------------------------
struct HttpRequestConfig {
   string url;
   HTTP_METHOD method;
   string body;
   string headers[];
   int timeout;

   // Constructor with defaults
   void Init() {
      url = "";
      method = HTTP_GET;
      body = "";
      timeout = 5000; // 5 seconds default
      ArrayResize(headers, 0);
   }
};

//--------------------------------------------------------------------
// GLOBAL CONSTANTS
//--------------------------------------------------------------------
#define WEB_API_TIMEOUT_DEFAULT     5000   // 5 seconds
#define WEB_API_TIMEOUT_LONG        15000  // 15 seconds
#define WEB_API_MAX_RETRIES         3
#define WEB_API_RETRY_DELAY_MS      1000   // 1 second between retries

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
static bool g_WebAPIInitialized = false;
static string g_LastWebAPIError = "";
static int g_WebAPIRequestCount = 0;
static int g_WebAPIFailureCount = 0;
static datetime g_LastWebAPIRequest = 0;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool WebAPI_Init() {
   if(g_WebAPIInitialized) {
      return true;
   }

   // Reset counters
   g_WebAPIRequestCount = 0;
   g_WebAPIFailureCount = 0;
   g_LastWebAPIError = "";
   g_LastWebAPIRequest = 0;

   g_WebAPIInitialized = true;

   Print("✓ WebAPI Module initialized");
   return true;
}

//--------------------------------------------------------------------
// GET METHOD HELPERS
//--------------------------------------------------------------------
string WebAPI_MethodToString(HTTP_METHOD method) {
   switch(method) {
      case HTTP_GET:    return "GET";
      case HTTP_POST:   return "POST";
      case HTTP_PUT:    return "PUT";
      case HTTP_PATCH:  return "PATCH";
      case HTTP_DELETE: return "DELETE";
      default:          return "GET";
   }
}

//--------------------------------------------------------------------
// BUILD HEADERS
//--------------------------------------------------------------------
void WebAPI_BuildHeaders(string &headers[], string contentType = "application/json", string authToken = "") {
   int headerCount = 0;

   // Content-Type header
   if(contentType != "") {
      ArrayResize(headers, headerCount + 1);
      headers[headerCount] = "Content-Type: " + contentType;
      headerCount++;
   }

   // Authorization header
   if(authToken != "") {
      ArrayResize(headers, headerCount + 1);
      headers[headerCount] = "Authorization: Bearer " + authToken;
      headerCount++;
   }

   // User-Agent
   ArrayResize(headers, headerCount + 1);
   headers[headerCount] = "User-Agent: SmartStockTrader-EA/1.0";
   headerCount++;

   // Accept
   ArrayResize(headers, headerCount + 1);
   headers[headerCount] = "Accept: application/json";
   headerCount++;
}

//--------------------------------------------------------------------
// FLATTEN HEADERS ARRAY TO STRING
//--------------------------------------------------------------------
string WebAPI_FlattenHeaders(string &headers[]) {
   string result = "";
   int size = ArraySize(headers);

   for(int i = 0; i < size; i++) {
      result += headers[i];
      if(i < size - 1) {
         result += "\r\n";
      }
   }

   return result;
}

//--------------------------------------------------------------------
// EXECUTE HTTP REQUEST (Core Function)
//--------------------------------------------------------------------
HttpResponse WebAPI_ExecuteRequest(HttpRequestConfig &config, int retryCount = 0) {
   HttpResponse response;
   response.isSuccess = false;
   response.statusCode = 0;
   response.body = "";
   response.errorMessage = "";
   response.timestamp = TimeCurrent();

   if(!g_WebAPIInitialized) {
      response.errorMessage = "WebAPI not initialized";
      g_LastWebAPIError = response.errorMessage;
      return response;
   }

   // Validate URL
   if(config.url == "") {
      response.errorMessage = "Empty URL provided";
      g_LastWebAPIError = response.errorMessage;
      return response;
   }

   // Increment request counter
   g_WebAPIRequestCount++;
   g_LastWebAPIRequest = TimeCurrent();

   // Prepare headers string
   string headersString = WebAPI_FlattenHeaders(config.headers);

   // Prepare request data
   char postData[];
   char resultData[];
   string resultHeaders = "";

   // Convert body to char array if needed
   if(config.body != "") {
      StringToCharArray(config.body, postData, 0, StringLen(config.body));
   }

   // Execute WebRequest
   ResetLastError();

   int httpCode = WebRequest(
      WebAPI_MethodToString(config.method),
      config.url,
      headersString,
      config.timeout,
      postData,
      resultData,
      resultHeaders
   );

   int lastError = GetLastError();

   // Handle WebRequest errors
   if(httpCode == -1) {
      response.statusCode = -1;
      response.errorMessage = WebAPI_GetWebRequestErrorDescription(lastError);
      g_LastWebAPIError = response.errorMessage;
      g_WebAPIFailureCount++;

      // Retry logic
      if(retryCount < WEB_API_MAX_RETRIES) {
         Print("⚠ WebRequest failed (attempt ", retryCount + 1, "/", WEB_API_MAX_RETRIES, "): ", response.errorMessage);
         Print("   Retrying in ", WEB_API_RETRY_DELAY_MS, "ms...");

         Sleep(WEB_API_RETRY_DELAY_MS);
         return WebAPI_ExecuteRequest(config, retryCount + 1);
      }

      Print("✗ WebRequest failed after ", WEB_API_MAX_RETRIES, " retries: ", response.errorMessage);
      return response;
   }

   // Success - convert response
   response.statusCode = httpCode;
   response.body = CharArrayToString(resultData, 0, ArraySize(resultData));

   // Determine success based on HTTP status code
   if(httpCode >= 200 && httpCode < 300) {
      response.isSuccess = true;
      response.errorMessage = "";
   } else {
      response.isSuccess = false;
      response.errorMessage = "HTTP Error " + IntegerToString(httpCode);
      g_LastWebAPIError = response.errorMessage + ": " + response.body;
      g_WebAPIFailureCount++;
   }

   return response;
}

//--------------------------------------------------------------------
// CONVENIENCE METHODS
//--------------------------------------------------------------------

// GET Request
HttpResponse WebAPI_GET(string url, string authToken = "", int timeout = WEB_API_TIMEOUT_DEFAULT) {
   HttpRequestConfig config;
   config.Init();
   config.url = url;
   config.method = HTTP_GET;
   config.timeout = timeout;

   WebAPI_BuildHeaders(config.headers, "application/json", authToken);

   return WebAPI_ExecuteRequest(config);
}

// POST Request
HttpResponse WebAPI_POST(string url, string jsonBody, string authToken = "", int timeout = WEB_API_TIMEOUT_DEFAULT) {
   HttpRequestConfig config;
   config.Init();
   config.url = url;
   config.method = HTTP_POST;
   config.body = jsonBody;
   config.timeout = timeout;

   WebAPI_BuildHeaders(config.headers, "application/json", authToken);

   return WebAPI_ExecuteRequest(config);
}

// PUT Request
HttpResponse WebAPI_PUT(string url, string jsonBody, string authToken = "", int timeout = WEB_API_TIMEOUT_DEFAULT) {
   HttpRequestConfig config;
   config.Init();
   config.url = url;
   config.method = HTTP_PUT;
   config.body = jsonBody;
   config.timeout = timeout;

   WebAPI_BuildHeaders(config.headers, "application/json", authToken);

   return WebAPI_ExecuteRequest(config);
}

// PATCH Request
HttpResponse WebAPI_PATCH(string url, string jsonBody, string authToken = "", int timeout = WEB_API_TIMEOUT_DEFAULT) {
   HttpRequestConfig config;
   config.Init();
   config.url = url;
   config.method = HTTP_PATCH;
   config.body = jsonBody;
   config.timeout = timeout;

   WebAPI_BuildHeaders(config.headers, "application/json", authToken);

   return WebAPI_ExecuteRequest(config);
}

// DELETE Request
HttpResponse WebAPI_DELETE(string url, string authToken = "", int timeout = WEB_API_TIMEOUT_DEFAULT) {
   HttpRequestConfig config;
   config.Init();
   config.url = url;
   config.method = HTTP_DELETE;
   config.timeout = timeout;

   WebAPI_BuildHeaders(config.headers, "application/json", authToken);

   return WebAPI_ExecuteRequest(config);
}

//--------------------------------------------------------------------
// ERROR HANDLING
//--------------------------------------------------------------------
string WebAPI_GetWebRequestErrorDescription(int errorCode) {
   switch(errorCode) {
      case 4014: return "WebRequest not allowed. Add URL to MT4 Tools->Options->Expert Advisors->Allow WebRequest";
      case 4060: return "Function not allowed";
      case 5203: return "Invalid URL";
      case 5200: return "HTTP request failed";
      default:   return "Unknown error (" + IntegerToString(errorCode) + ")";
   }
}

string WebAPI_GetLastError() {
   return g_LastWebAPIError;
}

void WebAPI_ClearLastError() {
   g_LastWebAPIError = "";
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
int WebAPI_GetRequestCount() {
   return g_WebAPIRequestCount;
}

int WebAPI_GetFailureCount() {
   return g_WebAPIFailureCount;
}

double WebAPI_GetSuccessRate() {
   if(g_WebAPIRequestCount == 0) return 100.0;
   return ((g_WebAPIRequestCount - g_WebAPIFailureCount) / (double)g_WebAPIRequestCount) * 100.0;
}

datetime WebAPI_GetLastRequestTime() {
   return g_LastWebAPIRequest;
}

void WebAPI_PrintStats() {
   Print("╔════════════════════════════════════════╗");
   Print("║       WebAPI Statistics                ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Total Requests:  ", g_WebAPIRequestCount);
   Print("║ Failures:        ", g_WebAPIFailureCount);
   Print("║ Success Rate:    ", DoubleToString(WebAPI_GetSuccessRate(), 1), "%");
   Print("║ Last Request:    ", TimeToString(g_LastWebAPIRequest, TIME_DATE|TIME_MINUTES));
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// HEALTH CHECK
//--------------------------------------------------------------------
bool WebAPI_HealthCheck(string baseUrl) {
   string healthUrl = baseUrl;
   if(StringFind(healthUrl, "health") < 0) {
      // Add /health endpoint if not present
      if(StringGetCharacter(healthUrl, StringLen(healthUrl) - 1) != '/') {
         healthUrl += "/";
      }
      healthUrl += "health";
   }

   HttpResponse response = WebAPI_GET(healthUrl, "", WEB_API_TIMEOUT_DEFAULT);

   if(response.isSuccess) {
      Print("✓ WebAPI Health Check: Backend is reachable");
      return true;
   } else {
      Print("✗ WebAPI Health Check Failed: ", response.errorMessage);
      return false;
   }
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void WebAPI_Shutdown() {
   if(g_WebAPIInitialized) {
      WebAPI_PrintStats();
      g_WebAPIInitialized = false;
      Print("✓ WebAPI Module shut down");
   }
}

//+------------------------------------------------------------------+
