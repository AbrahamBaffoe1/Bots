//+------------------------------------------------------------------+
//|                                                   SST_Logger.mqh |
//|            Production-Grade Logging & Error Handling Module      |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

//--------------------------------------------------------------------
// LOG LEVEL ENUMERATION
//--------------------------------------------------------------------
enum LOG_LEVEL {
   LOG_DEBUG,
   LOG_INFO,
   LOG_WARN,
   LOG_ERROR,
   LOG_CRITICAL
};

//--------------------------------------------------------------------
// LOG CATEGORY ENUMERATION
//--------------------------------------------------------------------
enum LOG_CATEGORY {
   CAT_GENERAL,
   CAT_TRADE,
   CAT_API,
   CAT_PERFORMANCE,
   CAT_RISK,
   CAT_SYSTEM,
   CAT_HEARTBEAT
};

//--------------------------------------------------------------------
// LOG ENTRY STRUCTURE
//--------------------------------------------------------------------
struct LogEntry {
   datetime timestamp;
   LOG_LEVEL level;
   LOG_CATEGORY category;
   string message;
   string metadata;
};

//--------------------------------------------------------------------
// GLOBAL LOGGER STATE
//--------------------------------------------------------------------
static bool g_LoggerInitialized = false;
static LOG_LEVEL g_MinLogLevel = LOG_INFO;
static bool g_EnableConsoleLogging = true;
static bool g_EnableFileLogging = false;
static bool g_EnableRemoteLogging = false;
static int g_LogFileHandle = INVALID_HANDLE;
static string g_LogFilePath = "";
static LogEntry g_LogBuffer[];
static int g_LogBufferSize = 0;
static const int g_LogBufferMaxSize = 100;

//--------------------------------------------------------------------
// INITIALIZATION
//--------------------------------------------------------------------
bool Logger_Init(
   LOG_LEVEL minLevel = LOG_INFO,
   bool enableConsole = true,
   bool enableFile = false,
   bool enableRemote = false
) {
   if(g_LoggerInitialized) {
      return true;
   }

   g_MinLogLevel = minLevel;
   g_EnableConsoleLogging = enableConsole;
   g_EnableFileLogging = enableFile;
   g_EnableRemoteLogging = enableRemote;

   ArrayResize(g_LogBuffer, 0);
   g_LogBufferSize = 0;

   // Initialize file logging if enabled
   if(g_EnableFileLogging) {
      string filename = "SmartStockTrader_" +
                       IntegerToString(AccountNumber()) + "_" +
                       TimeToString(TimeCurrent(), TIME_DATE) + ".log";

      g_LogFilePath = filename;
      g_LogFileHandle = FileOpen(g_LogFilePath, FILE_WRITE|FILE_TXT|FILE_ANSI, '\t');

      if(g_LogFileHandle == INVALID_HANDLE) {
         Print("✗ Failed to create log file: ", g_LogFilePath);
         g_EnableFileLogging = false;
      } else {
         Print("✓ Log file created: ", g_LogFilePath);
      }
   }

   g_LoggerInitialized = true;
   Logger_Info(CAT_SYSTEM, "Logger initialized successfully");

   return true;
}

//--------------------------------------------------------------------
// LEVEL TO STRING
//--------------------------------------------------------------------
string Logger_LevelToString(LOG_LEVEL level) {
   switch(level) {
      case LOG_DEBUG:    return "DEBUG";
      case LOG_INFO:     return "INFO";
      case LOG_WARN:     return "WARN";
      case LOG_ERROR:    return "ERROR";
      case LOG_CRITICAL: return "CRITICAL";
      default:           return "UNKNOWN";
   }
}

//--------------------------------------------------------------------
// CATEGORY TO STRING
//--------------------------------------------------------------------
string Logger_CategoryToString(LOG_CATEGORY category) {
   switch(category) {
      case CAT_GENERAL:     return "GENERAL";
      case CAT_TRADE:       return "TRADE";
      case CAT_API:         return "API";
      case CAT_PERFORMANCE: return "PERFORMANCE";
      case CAT_RISK:        return "RISK";
      case CAT_SYSTEM:      return "SYSTEM";
      case CAT_HEARTBEAT:   return "HEARTBEAT";
      default:              return "UNKNOWN";
   }
}

//--------------------------------------------------------------------
// CORE LOGGING FUNCTION
//--------------------------------------------------------------------
void Logger_Log(LOG_LEVEL level, LOG_CATEGORY category, string message, string metadata = "") {
   if(!g_LoggerInitialized) {
      Logger_Init(); // Auto-initialize if not done
   }

   // Check if log level meets minimum threshold
   if(level < g_MinLogLevel) {
      return;
   }

   // Create log entry
   LogEntry entry;
   entry.timestamp = TimeCurrent();
   entry.level = level;
   entry.category = category;
   entry.message = message;
   entry.metadata = metadata;

   // Format log message
   string logLine = StringFormat("[%s] [%s] [%s] %s",
                                TimeToString(entry.timestamp, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                                Logger_LevelToString(level),
                                Logger_CategoryToString(category),
                                message);

   if(metadata != "") {
      logLine += " | " + metadata;
   }

   // Console logging
   if(g_EnableConsoleLogging) {
      Print(logLine);
   }

   // File logging
   if(g_EnableFileLogging && g_LogFileHandle != INVALID_HANDLE) {
      FileWrite(g_LogFileHandle, logLine);
      FileFlush(g_LogFileHandle);
   }

   // Remote logging (buffer for batch sending)
   if(g_EnableRemoteLogging) {
      Logger_AddToBuffer(entry);
   }
}

//--------------------------------------------------------------------
// CONVENIENCE LOGGING FUNCTIONS
//--------------------------------------------------------------------
void Logger_Debug(LOG_CATEGORY category, string message, string metadata = "") {
   Logger_Log(LOG_DEBUG, category, message, metadata);
}

void Logger_Info(LOG_CATEGORY category, string message, string metadata = "") {
   Logger_Log(LOG_INFO, category, message, metadata);
}

void Logger_Warn(LOG_CATEGORY category, string message, string metadata = "") {
   Logger_Log(LOG_WARN, category, message, metadata);
}

void Logger_Error(LOG_CATEGORY category, string message, string metadata = "") {
   Logger_Log(LOG_ERROR, category, message, metadata);
}

void Logger_Critical(LOG_CATEGORY category, string message, string metadata = "") {
   Logger_Log(LOG_CRITICAL, category, message, metadata);
}

//--------------------------------------------------------------------
// SPECIALIZED LOGGING FUNCTIONS
//--------------------------------------------------------------------

// Log trade opened
void Logger_TradeOpened(int ticket, string symbol, string type, double lots, double price, double sl, double tp) {
   string message = StringFormat("TRADE OPENED: #%d %s %s %.2f lots @ %.5f (SL: %.5f, TP: %.5f)",
                                ticket, symbol, type, lots, price, sl, tp);
   Logger_Info(CAT_TRADE, message);
}

// Log trade closed
void Logger_TradeClosed(int ticket, string symbol, double closePrice, double profit) {
   string message = StringFormat("TRADE CLOSED: #%d %s @ %.5f | P/L: $%.2f",
                                ticket, symbol, closePrice, profit);

   LOG_LEVEL level = (profit >= 0) ? LOG_INFO : LOG_WARN;
   Logger_Log(level, CAT_TRADE, message);
}

// Log API request
void Logger_APIRequest(string method, string url, int statusCode) {
   string message = StringFormat("API %s %s -> %d", method, url, statusCode);

   LOG_LEVEL level = LOG_INFO;
   if(statusCode >= 400) {
      level = LOG_ERROR;
   } else if(statusCode >= 300) {
      level = LOG_WARN;
   }

   Logger_Log(level, CAT_API, message);
}

// Log API error
void Logger_APIError(string operation, string errorMessage) {
   string message = StringFormat("API ERROR [%s]: %s", operation, errorMessage);
   Logger_Error(CAT_API, message);
}

// Log heartbeat
void Logger_Heartbeat(double balance, double equity, int openPositions) {
   string message = StringFormat("HEARTBEAT: Balance: $%.2f | Equity: $%.2f | Open: %d",
                                balance, equity, openPositions);
   Logger_Debug(CAT_HEARTBEAT, message);
}

// Log performance metrics
void Logger_Performance(int totalTrades, double winRate, double profitFactor, double netProfit) {
   string message = StringFormat("PERFORMANCE: Trades: %d | Win Rate: %.1f%% | PF: %.2f | Net: $%.2f",
                                totalTrades, winRate, profitFactor, netProfit);
   Logger_Info(CAT_PERFORMANCE, message);
}

// Log risk event
void Logger_RiskEvent(string eventType, string details) {
   string message = StringFormat("RISK EVENT [%s]: %s", eventType, details);
   Logger_Warn(CAT_RISK, message);
}

// Log system event
void Logger_SystemEvent(string event, string details = "") {
   string message = event;
   if(details != "") {
      message += ": " + details;
   }
   Logger_Info(CAT_SYSTEM, message);
}

//--------------------------------------------------------------------
// BUFFER MANAGEMENT (For Remote Logging)
//--------------------------------------------------------------------
void Logger_AddToBuffer(LogEntry &entry) {
   if(g_LogBufferSize >= g_LogBufferMaxSize) {
      Logger_FlushBuffer(); // Auto-flush when buffer is full
   }

   ArrayResize(g_LogBuffer, g_LogBufferSize + 1);
   g_LogBuffer[g_LogBufferSize] = entry;
   g_LogBufferSize++;
}

// Get buffered log count (for remote sending)
int Logger_GetBufferedLogCount() {
   return g_LogBufferSize;
}

// Clear buffer after successful send
void Logger_ClearBuffer() {
   ArrayResize(g_LogBuffer, 0);
   g_LogBufferSize = 0;
}

// Flush buffer (placeholder for remote send)
void Logger_FlushBuffer() {
   if(g_LogBufferSize == 0) {
      return;
   }

   // TODO: Implement remote log sending via SST_TradeSync module
   Logger_Debug(CAT_SYSTEM, "Flushing log buffer", "Entries: " + IntegerToString(g_LogBufferSize));

   // For now, just clear the buffer
   Logger_ClearBuffer();
}

//--------------------------------------------------------------------
// CONFIGURATION
//--------------------------------------------------------------------
void Logger_SetMinLevel(LOG_LEVEL level) {
   g_MinLogLevel = level;
   Logger_Info(CAT_SYSTEM, "Log level changed", "New level: " + Logger_LevelToString(level));
}

void Logger_EnableConsole(bool enable) {
   g_EnableConsoleLogging = enable;
}

void Logger_EnableFile(bool enable) {
   g_EnableFileLogging = enable;

   if(enable && g_LogFileHandle == INVALID_HANDLE) {
      // Re-initialize file logging
      string filename = "SmartStockTrader_" +
                       IntegerToString(AccountNumber()) + "_" +
                       TimeToString(TimeCurrent(), TIME_DATE) + ".log";

      g_LogFilePath = filename;
      g_LogFileHandle = FileOpen(g_LogFilePath, FILE_WRITE|FILE_TXT|FILE_ANSI, '\t');

      if(g_LogFileHandle != INVALID_HANDLE) {
         Logger_Info(CAT_SYSTEM, "File logging enabled", "File: " + g_LogFilePath);
      }
   }
}

void Logger_EnableRemote(bool enable) {
   g_EnableRemoteLogging = enable;
   Logger_Info(CAT_SYSTEM, "Remote logging " + (enable ? "enabled" : "disabled"));
}

//--------------------------------------------------------------------
// STATISTICS
//--------------------------------------------------------------------
void Logger_PrintStats() {
   Print("╔════════════════════════════════════════╗");
   Print("║          Logger Statistics             ║");
   Print("╠════════════════════════════════════════╣");
   Print("║ Min Level:       ", Logger_LevelToString(g_MinLogLevel));
   Print("║ Console Logging: ", g_EnableConsoleLogging ? "ENABLED" : "DISABLED");
   Print("║ File Logging:    ", g_EnableFileLogging ? "ENABLED" : "DISABLED");
   Print("║ Remote Logging:  ", g_EnableRemoteLogging ? "ENABLED" : "DISABLED");
   Print("║ Buffer Size:     ", g_LogBufferSize, "/", g_LogBufferMaxSize);
   if(g_EnableFileLogging) {
      Print("║ Log File:        ", g_LogFilePath);
   }
   Print("╚════════════════════════════════════════╝");
}

//--------------------------------------------------------------------
// CLEANUP
//--------------------------------------------------------------------
void Logger_Shutdown() {
   if(!g_LoggerInitialized) {
      return;
   }

   Logger_Info(CAT_SYSTEM, "Logger shutting down");

   // Flush remaining logs
   if(g_EnableRemoteLogging && g_LogBufferSize > 0) {
      Logger_FlushBuffer();
   }

   // Close log file
   if(g_EnableFileLogging && g_LogFileHandle != INVALID_HANDLE) {
      FileClose(g_LogFileHandle);
      g_LogFileHandle = INVALID_HANDLE;
      Print("✓ Log file closed: ", g_LogFilePath);
   }

   g_LoggerInitialized = false;
   Print("✓ Logger shut down");
}

//+------------------------------------------------------------------+
