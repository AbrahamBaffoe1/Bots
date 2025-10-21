//+------------------------------------------------------------------+
//|                                            SST_SessionManager.mqh |
//|                         Smart Stock Trader - Session Management  |
//|              Handles US stock market trading hours (EST/EDT)     |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// SESSION CONSTANTS (EST/EDT)
//--------------------------------------------------------------------
#define PRE_MARKET_START_HOUR    4
#define PRE_MARKET_START_MINUTE  0
#define PRE_MARKET_END_HOUR      9
#define PRE_MARKET_END_MINUTE    30

#define REGULAR_START_HOUR       9
#define REGULAR_START_MINUTE     30
#define REGULAR_END_HOUR         16
#define REGULAR_END_MINUTE       0

#define AFTER_HOURS_START_HOUR   16
#define AFTER_HOURS_START_MINUTE 0
#define AFTER_HOURS_END_HOUR     20
#define AFTER_HOURS_END_MINUTE   0

//--------------------------------------------------------------------
// SESSION ENUMERATION
//--------------------------------------------------------------------
enum SESSION_TYPE {
   SESSION_CLOSED,
   SESSION_PRE_MARKET,
   SESSION_REGULAR,
   SESSION_AFTER_HOURS
};

//--------------------------------------------------------------------
// SESSION MANAGER CLASS
//--------------------------------------------------------------------

// Convert broker time to EST
datetime Session_BrokerToEST(datetime brokerTime) {
   // Apply GMT offset to get EST time
   // Note: This is a simplified approach. For production, consider daylight saving time
   return brokerTime + (BrokerGMTOffset * 3600);
}

// Get current session type
SESSION_TYPE Session_GetCurrent() {
   datetime estTime = Session_BrokerToEST(TimeCurrent());
   int hour = TimeHour(estTime);
   int minute = TimeMinute(estTime);
   int dayOfWeek = TimeDayOfWeek(estTime);

   // Market closed on weekends
   if(dayOfWeek == 0 || dayOfWeek == 6) {
      return SESSION_CLOSED;
   }

   // Check pre-market (4:00 AM - 9:30 AM EST)
   if(hour > PRE_MARKET_START_HOUR || (hour == PRE_MARKET_START_HOUR && minute >= PRE_MARKET_START_MINUTE)) {
      if(hour < PRE_MARKET_END_HOUR || (hour == PRE_MARKET_END_HOUR && minute < PRE_MARKET_END_MINUTE)) {
         return SESSION_PRE_MARKET;
      }
   }

   // Check regular hours (9:30 AM - 4:00 PM EST)
   if(hour > REGULAR_START_HOUR || (hour == REGULAR_START_HOUR && minute >= REGULAR_START_MINUTE)) {
      if(hour < REGULAR_END_HOUR || (hour == REGULAR_END_HOUR && minute < REGULAR_END_MINUTE)) {
         return SESSION_REGULAR;
      }
   }

   // Check after hours (4:00 PM - 8:00 PM EST)
   if(hour >= AFTER_HOURS_START_HOUR && hour < AFTER_HOURS_END_HOUR) {
      return SESSION_AFTER_HOURS;
   }

   return SESSION_CLOSED;
}

// Check if currently in trading session
bool Session_IsTradingTime() {
   // In backtest mode, trade 24/7
   if(BacktestMode) {
      return true;
   }

   SESSION_TYPE session = Session_GetCurrent();

   if(session == SESSION_CLOSED) {
      return false;
   }

   if(session == SESSION_PRE_MARKET && !TradePreMarket) {
      return false;
   }

   if(session == SESSION_REGULAR && !TradeRegularHours) {
      return false;
   }

   if(session == SESSION_AFTER_HOURS && !TradeAfterHours) {
      return false;
   }

   // Check if we're in the avoid periods
   if(session == SESSION_REGULAR) {
      datetime estTime = Session_BrokerToEST(TimeCurrent());
      int hour = TimeHour(estTime);
      int minute = TimeMinute(estTime);

      // Avoid first 15 minutes (9:30 - 9:45)
      if(AvoidFirstMinutes) {
         if(hour == REGULAR_START_HOUR && minute < (REGULAR_START_MINUTE + 15)) {
            return false;
         }
      }

      // Avoid last 15 minutes (3:45 - 4:00)
      if(AvoidLastMinutes) {
         if(hour == (REGULAR_END_HOUR - 1) && minute >= 45) {
            return false;
         }
      }
   }

   return true;
}

// Check if market is about to close
bool Session_IsNearClose() {
   if(!CloseBeforeMarketClose) {
      return false;
   }

   SESSION_TYPE session = Session_GetCurrent();
   if(session != SESSION_REGULAR && session != SESSION_AFTER_HOURS) {
      return false;
   }

   datetime estTime = Session_BrokerToEST(TimeCurrent());
   int hour = TimeHour(estTime);
   int minute = TimeMinute(estTime);

   int closeHour = (session == SESSION_REGULAR) ? REGULAR_END_HOUR : AFTER_HOURS_END_HOUR;
   int closeMinute = (session == SESSION_REGULAR) ? REGULAR_END_MINUTE : AFTER_HOURS_END_MINUTE;

   // Calculate minutes until close
   int currentTotalMinutes = hour * 60 + minute;
   int closeTotalMinutes = closeHour * 60 + closeMinute;
   int minutesUntilClose = closeTotalMinutes - currentTotalMinutes;

   return (minutesUntilClose <= MinutesBeforeClose && minutesUntilClose >= 0);
}

// Get session name as string
string Session_GetName(SESSION_TYPE session) {
   switch(session) {
      case SESSION_PRE_MARKET:
         return "Pre-Market";
      case SESSION_REGULAR:
         return "Regular Hours";
      case SESSION_AFTER_HOURS:
         return "After Hours";
      case SESSION_CLOSED:
         return "Market Closed";
      default:
         return "Unknown";
   }
}

// Get current session name
string Session_GetCurrentName() {
   return Session_GetName(Session_GetCurrent());
}

// Check if it's a new trading day
bool Session_IsNewDay() {
   static datetime lastCheckDay = 0;
   datetime estTime = Session_BrokerToEST(TimeCurrent());
   datetime currentDay = iTime(_Symbol, PERIOD_D1, 0);

   if(lastCheckDay == 0) {
      lastCheckDay = currentDay;
      return false;
   }

   if(currentDay != lastCheckDay) {
      lastCheckDay = currentDay;
      return true;
   }

   return false;
}

// Get minutes until market open
int Session_MinutesUntilOpen() {
   SESSION_TYPE session = Session_GetCurrent();
   if(session != SESSION_CLOSED) {
      return 0;  // Market is already open
   }

   datetime estTime = Session_BrokerToEST(TimeCurrent());
   int hour = TimeHour(estTime);
   int minute = TimeMinute(estTime);
   int dayOfWeek = TimeDayOfWeek(estTime);

   // If weekend, calculate to Monday pre-market
   if(dayOfWeek == 0) {  // Sunday
      return ((24 - hour) + (24 + PRE_MARKET_START_HOUR)) * 60 - minute;
   }
   if(dayOfWeek == 6) {  // Saturday
      return ((24 - hour) + (48 + PRE_MARKET_START_HOUR)) * 60 - minute;
   }

   // Calculate to next session start
   int currentTotalMinutes = hour * 60 + minute;

   // Determine next session
   int nextSessionHour = PRE_MARKET_START_HOUR;
   int nextSessionMinute = PRE_MARKET_START_MINUTE;

   // If we're past after-hours, next open is tomorrow's pre-market
   if(hour >= AFTER_HOURS_END_HOUR) {
      return ((24 - hour) + PRE_MARKET_START_HOUR) * 60 - minute;
   }

   // Otherwise, find the next enabled session
   if(TradePreMarket && hour < PRE_MARKET_START_HOUR) {
      nextSessionHour = PRE_MARKET_START_HOUR;
      nextSessionMinute = PRE_MARKET_START_MINUTE;
   } else if(TradeRegularHours && (hour < REGULAR_START_HOUR || (hour == REGULAR_START_HOUR && minute < REGULAR_START_MINUTE))) {
      nextSessionHour = REGULAR_START_HOUR;
      nextSessionMinute = REGULAR_START_MINUTE;
   } else if(TradeAfterHours && hour < AFTER_HOURS_START_HOUR) {
      nextSessionHour = AFTER_HOURS_START_HOUR;
      nextSessionMinute = AFTER_HOURS_START_MINUTE;
   } else {
      // Next day's pre-market
      return ((24 - hour) + PRE_MARKET_START_HOUR) * 60 - minute;
   }

   int nextTotalMinutes = nextSessionHour * 60 + nextSessionMinute;
   return nextTotalMinutes - currentTotalMinutes;
}

// Get market close time for today
datetime Session_GetTodayCloseTime() {
   datetime estTime = Session_BrokerToEST(TimeCurrent());
   datetime dayStart = estTime - (estTime % 86400);  // Start of day

   int closeHour = TradeAfterHours ? AFTER_HOURS_END_HOUR : REGULAR_END_HOUR;
   int closeMinute = TradeAfterHours ? AFTER_HOURS_END_MINUTE : REGULAR_END_MINUTE;

   return dayStart + (closeHour * 3600) + (closeMinute * 60);
}

// Initialize session manager
void Session_Init() {
   Print("=== Session Manager Initialized ===");
   Print("Pre-Market: ", TradePreMarket ? "Enabled" : "Disabled");
   Print("Regular Hours: ", TradeRegularHours ? "Enabled" : "Disabled");
   Print("After Hours: ", TradeAfterHours ? "Enabled" : "Disabled");
   Print("Current Session: ", Session_GetCurrentName());
   Print("Is Trading Time: ", Session_IsTradingTime() ? "YES" : "NO");

   if(!Session_IsTradingTime()) {
      int minutesUntilOpen = Session_MinutesUntilOpen();
      Print("Minutes until next session: ", minutesUntilOpen, " (", minutesUntilOpen / 60, "h ", minutesUntilOpen % 60, "m)");
   }
}

// Update session state (call on every tick)
void Session_Update() {
   static SESSION_TYPE lastSession = SESSION_CLOSED;
   SESSION_TYPE currentSession = Session_GetCurrent();

   // Detect session changes
   if(currentSession != lastSession) {
      Print("Session changed: ", Session_GetName(lastSession), " -> ", Session_GetName(currentSession));
      lastSession = currentSession;
   }

   // Update global market hours flag
   g_IsMarketHours = Session_IsTradingTime();
}

//+------------------------------------------------------------------+
