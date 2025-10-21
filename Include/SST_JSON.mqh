//+------------------------------------------------------------------+
//|                                                    SST_JSON.mqh  |
//|                Production-Grade JSON Parser/Builder for MT4/MT5  |
//|                          Smart Stock Trader Pro v1.0             |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro"
#property strict

//--------------------------------------------------------------------
// JSON BUILDER CLASS (Production-Ready)
//--------------------------------------------------------------------
class JSONBuilder {
private:
   string m_json;
   bool m_firstElement;
   int m_depth;

public:
   // Constructor
   JSONBuilder() {
      Reset();
   }

   // Reset builder
   void Reset() {
      m_json = "";
      m_firstElement = true;
      m_depth = 0;
   }

   // Start object
   void StartObject() {
      if(!m_firstElement) m_json += ",";
      m_json += "{";
      m_firstElement = true;
      m_depth++;
   }

   // End object
   void EndObject() {
      m_json += "}";
      m_firstElement = false;
      m_depth--;
   }

   // Start array
   void StartArray(string key) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":[";
      m_firstElement = true;
      m_depth++;
   }

   // End array
   void EndArray() {
      m_json += "]";
      m_firstElement = false;
      m_depth--;
   }

   // Add string property
   void AddString(string key, string value) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":\"" + EscapeString(value) + "\"";
      m_firstElement = false;
   }

   // Add integer property
   void AddInt(string key, long value) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":" + IntegerToString(value);
      m_firstElement = false;
   }

   // Add double property
   void AddDouble(string key, double value, int digits = 5) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":" + DoubleToString(value, digits);
      m_firstElement = false;
   }

   // Add boolean property
   void AddBool(string key, bool value) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":" + (value ? "true" : "false");
      m_firstElement = false;
   }

   // Add datetime property (ISO 8601 format)
   void AddDateTime(string key, datetime value) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":\"" + TimeToISO8601(value) + "\"";
      m_firstElement = false;
   }

   // Add null property
   void AddNull(string key) {
      if(!m_firstElement) m_json += ",";
      m_json += "\"" + key + "\":null";
      m_firstElement = false;
   }

   // Get final JSON string
   string GetJSON() {
      return m_json;
   }

   // Escape special characters in strings
   string EscapeString(string input) {
      string output = input;

      // Escape backslash first
      StringReplace(output, "\\", "\\\\");

      // Escape quotes
      StringReplace(output, "\"", "\\\"");

      // Escape control characters
      StringReplace(output, "\n", "\\n");
      StringReplace(output, "\r", "\\r");
      StringReplace(output, "\t", "\\t");

      return output;
   }

   // Convert datetime to ISO 8601 format
   string TimeToISO8601(datetime dt) {
      MqlDateTime mdt;
      TimeToStruct(dt, mdt);

      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                         mdt.year, mdt.mon, mdt.day,
                         mdt.hour, mdt.min, mdt.sec);
   }
};

//--------------------------------------------------------------------
// JSON PARSER (Simple key-value extraction)
//--------------------------------------------------------------------
class JSONParser {
private:
   string m_json;

public:
   // Constructor
   JSONParser(string json) {
      m_json = json;
   }

   // Set JSON string
   void SetJSON(string json) {
      m_json = json;
   }

   // Extract string value by key
   string GetString(string key) {
      int startPos = StringFind(m_json, "\"" + key + "\"");
      if(startPos < 0) return "";

      startPos = StringFind(m_json, ":", startPos);
      if(startPos < 0) return "";

      startPos = StringFind(m_json, "\"", startPos);
      if(startPos < 0) return "";

      int endPos = StringFind(m_json, "\"", startPos + 1);
      if(endPos < 0) return "";

      return StringSubstr(m_json, startPos + 1, endPos - startPos - 1);
   }

   // Extract integer value by key
   long GetInt(string key) {
      string value = GetNumericString(key);
      if(value == "") return 0;
      return StringToInteger(value);
   }

   // Extract double value by key
   double GetDouble(string key) {
      string value = GetNumericString(key);
      if(value == "") return 0.0;
      return StringToDouble(value);
   }

   // Extract boolean value by key
   bool GetBool(string key) {
      int startPos = StringFind(m_json, "\"" + key + "\"");
      if(startPos < 0) return false;

      startPos = StringFind(m_json, ":", startPos);
      if(startPos < 0) return false;

      string remainder = StringSubstr(m_json, startPos + 1);
      StringTrimLeft(remainder);
      StringTrimRight(remainder);

      if(StringFind(remainder, "true") == 0) return true;
      return false;
   }

   // Check if key exists
   bool HasKey(string key) {
      return StringFind(m_json, "\"" + key + "\"") >= 0;
   }

private:
   // Helper: Get numeric string value
   string GetNumericString(string key) {
      int startPos = StringFind(m_json, "\"" + key + "\"");
      if(startPos < 0) return "";

      startPos = StringFind(m_json, ":", startPos);
      if(startPos < 0) return "";

      // Move past ':'
      startPos++;

      // Skip whitespace
      while(startPos < StringLen(m_json)) {
         ushort ch = StringGetCharacter(m_json, startPos);
         if(ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') break;
         startPos++;
      }

      // Extract number
      string result = "";
      while(startPos < StringLen(m_json)) {
         ushort ch = StringGetCharacter(m_json, startPos);
         if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == 'e' || ch == 'E' || ch == '+') {
            result += CharToString((char)ch);
            startPos++;
         } else {
            break;
         }
      }

      return result;
   }
};

//--------------------------------------------------------------------
// CONVENIENCE FUNCTIONS FOR TRADE DATA
//--------------------------------------------------------------------

// Build Trade Open JSON
string JSON_BuildTradeOpen(
   int ticketNumber,
   string symbol,
   string tradeType,
   double lotSize,
   double openPrice,
   double stopLoss,
   double takeProfit,
   string strategyUsed,
   datetime openTime,
   string comment = ""
) {
   JSONBuilder json;
   json.StartObject();

   json.AddInt("ticket_number", ticketNumber);
   json.AddString("symbol", symbol);
   json.AddString("trade_type", tradeType);
   json.AddDouble("lot_size", lotSize, 2);
   json.AddDouble("open_price", openPrice, 5);
   json.AddDouble("stop_loss", stopLoss, 5);
   json.AddDouble("take_profit", takeProfit, 5);
   json.AddString("strategy_used", strategyUsed);
   json.AddDateTime("open_time", openTime);

   if(comment != "") {
      json.AddString("comment", comment);
   }

   json.EndObject();

   return json.GetJSON();
}

// Build Trade Close JSON
string JSON_BuildTradeClose(
   double closePrice,
   double profit,
   double commission,
   double swap,
   datetime closeTime
) {
   JSONBuilder json;
   json.StartObject();

   json.AddDouble("close_price", closePrice, 5);
   json.AddDouble("profit", profit, 2);
   json.AddDouble("commission", commission, 2);
   json.AddDouble("swap", swap, 2);
   json.AddDateTime("close_time", closeTime);
   json.AddString("status", "CLOSED");

   json.EndObject();

   return json.GetJSON();
}

// Build Performance Metrics JSON
string JSON_BuildPerformanceMetrics(
   int totalTrades,
   int winningTrades,
   int losingTrades,
   double winRate,
   double profitFactor,
   double grossProfit,
   double grossLoss,
   double netProfit,
   double maxDrawdown,
   double sharpeRatio = 0.0
) {
   JSONBuilder json;
   json.StartObject();

   json.AddInt("total_trades", totalTrades);
   json.AddInt("winning_trades", winningTrades);
   json.AddInt("losing_trades", losingTrades);
   json.AddDouble("win_rate", winRate, 2);
   json.AddDouble("profit_factor", profitFactor, 2);
   json.AddDouble("gross_profit", grossProfit, 2);
   json.AddDouble("gross_loss", grossLoss, 2);
   json.AddDouble("net_profit", netProfit, 2);
   json.AddDouble("max_drawdown", maxDrawdown, 2);

   if(sharpeRatio != 0.0) {
      json.AddDouble("sharpe_ratio", sharpeRatio, 2);
   }

   json.AddDateTime("timestamp", TimeCurrent());

   json.EndObject();

   return json.GetJSON();
}

// Build Heartbeat JSON
string JSON_BuildHeartbeat(
   double balance,
   double equity,
   double margin,
   double freeMargin,
   int openPositions,
   string status = "RUNNING"
) {
   JSONBuilder json;
   json.StartObject();

   json.AddDouble("balance", balance, 2);
   json.AddDouble("equity", equity, 2);
   json.AddDouble("margin", margin, 2);
   json.AddDouble("free_margin", freeMargin, 2);
   json.AddInt("open_positions", openPositions);
   json.AddString("status", status);
   json.AddDateTime("timestamp", TimeCurrent());

   json.EndObject();

   return json.GetJSON();
}

// Build Bot Registration JSON
string JSON_BuildBotRegistration(
   string botName,
   long accountNumber,
   string accountName,
   string brokerName,
   string serverName,
   string version = "1.0"
) {
   JSONBuilder json;
   json.StartObject();

   json.AddString("bot_name", botName);
   json.AddInt("account_number", accountNumber);
   json.AddString("account_name", accountName);
   json.AddString("broker_name", brokerName);
   json.AddString("server_name", serverName);
   json.AddString("version", version);
   json.AddDateTime("started_at", TimeCurrent());

   json.EndObject();

   return json.GetJSON();
}

// Build Auth Login JSON
string JSON_BuildAuthLogin(string email, string password) {
   JSONBuilder json;
   json.StartObject();

   json.AddString("email", email);
   json.AddString("password", password);

   json.EndObject();

   return json.GetJSON();
}

// Build Log Entry JSON
string JSON_BuildLogEntry(
   string level,
   string category,
   string message,
   string metadata = ""
) {
   JSONBuilder json;
   json.StartObject();

   json.AddString("level", level);
   json.AddString("category", category);
   json.AddString("message", message);

   if(metadata != "") {
      json.AddString("metadata", metadata);
   }

   json.AddDateTime("timestamp", TimeCurrent());

   json.EndObject();

   return json.GetJSON();
}

//+------------------------------------------------------------------+
