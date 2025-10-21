//+------------------------------------------------------------------+
//|                                              SST_NewsFilter.mqh  |
//|                Smart Stock Trader - News & Economic Calendar     |
//|          Real-time news detection and economic event filtering   |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// NEWS FILTER PARAMETERS
//--------------------------------------------------------------------
extern bool    UseNewsFilter         = true;         // Enable news filtering
extern int     MinutesBeforeNews     = 30;           // Stop trading X min before news
extern int     MinutesAfterNews      = 30;           // Resume trading X min after news
extern bool    TradeHighImpactNews   = false;        // Trade during high-impact news (risky!)
extern bool    TradeMediumImpactNews = false;        // Trade during medium-impact news
extern bool    AutoDetectNewsSpike   = true;         // Detect news by volatility spike
extern double  VolatilitySpikeThreshold = 3.0;       // ATR spike multiplier for news detection

//--------------------------------------------------------------------
// ECONOMIC CALENDAR STRUCTURE
//--------------------------------------------------------------------
struct EconomicEvent {
   datetime eventTime;       // When event occurs
   string   eventName;       // Event name (NFP, FOMC, CPI, etc.)
   string   currency;        // Affected currency/country
   int      impact;          // 1=Low, 2=Medium, 3=High
   string   forecast;        // Forecasted value
   string   previous;        // Previous value
};

// High-Impact Economic Events (Pre-defined)
// In real production, this would be loaded from ForexFactory API or similar
EconomicEvent g_UpcomingEvents[];
int g_EventCount = 0;

//--------------------------------------------------------------------
// MAJOR US ECONOMIC EVENTS (Hardcoded for stocks)
//--------------------------------------------------------------------
void News_InitializeCalendar() {
   // This is a simplified version. In production, you'd:
   // 1. Fetch from ForexFactory API
   // 2. Parse XML/JSON from economic calendar
   // 3. Update daily

   Print("📅 Initializing Economic Calendar...");

   // For now, we'll define standard recurring events
   // Real implementation would fetch live data

   g_EventCount = 0;
   ArrayResize(g_UpcomingEvents, 20);

   // Add major recurring events (times in EST)
   // These are examples - in real use, fetch from API

   Print("✓ Economic Calendar initialized with ", g_EventCount, " upcoming events");
}

//--------------------------------------------------------------------
// CHECK IF NEWS IS HAPPENING NOW
//--------------------------------------------------------------------
bool News_IsNewsTime() {
   if(!UseNewsFilter) return false;

   datetime currentTime = TimeCurrent();

   // Check against calendar events
   for(int i = 0; i < g_EventCount; i++) {
      datetime eventTime = g_UpcomingEvents[i].eventTime;
      int impact = g_UpcomingEvents[i].impact;

      // Calculate time difference in minutes
      int minutesDiff = (int)((eventTime - currentTime) / 60);

      // If within news window
      if(minutesDiff >= -MinutesAfterNews && minutesDiff <= MinutesBeforeNews) {
         // Check impact level
         if(impact == 3 && !TradeHighImpactNews) {
            if(VerboseLogging) Print("🚨 HIGH IMPACT NEWS: ", g_UpcomingEvents[i].eventName, " in ", minutesDiff, " minutes - TRADING BLOCKED");
            return true;
         }
         if(impact == 2 && !TradeMediumImpactNews) {
            if(VerboseLogging) Print("⚠ MEDIUM IMPACT NEWS: ", g_UpcomingEvents[i].eventName, " in ", minutesDiff, " minutes - TRADING BLOCKED");
            return true;
         }
      }
   }

   // Auto-detect news by volatility spike
   if(AutoDetectNewsSpike) {
      if(News_DetectVolatilitySpike()) {
         if(VerboseLogging) Print("🔥 VOLATILITY SPIKE DETECTED - Possible news event - TRADING BLOCKED");
         return true;
      }
   }

   return false;
}

//--------------------------------------------------------------------
// DETECT NEWS BY VOLATILITY SPIKE (Auto-detection)
//--------------------------------------------------------------------
bool News_DetectVolatilitySpike() {
   // Check current ATR vs recent ATR
   // If current ATR is significantly higher = news/volatility spike

   string symbol = Symbol();

   // Current ATR (last 5 periods)
   double atr_current = iATR(symbol, PERIOD_M5, 14, 0);

   // Average ATR over last hour (12 x 5-min periods)
   double atr_sum = 0;
   for(int i = 1; i <= 12; i++) {
      atr_sum += iATR(symbol, PERIOD_M5, 14, i);
   }
   double atr_average = atr_sum / 12.0;

   if(atr_average == 0) return false;

   // Calculate spike ratio
   double spike_ratio = atr_current / atr_average;

   if(spike_ratio >= VolatilitySpikeThreshold) {
      if(VerboseLogging) Print("⚡ ATR Spike Detected: ", DoubleToString(spike_ratio, 2), "x normal (",
                               DoubleToString(atr_current, 5), " vs ", DoubleToString(atr_average, 5), ")");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// GET UPCOMING NEWS (for dashboard display)
//--------------------------------------------------------------------
string News_GetUpcomingEvents(int maxEvents = 3) {
   string output = "";
   datetime currentTime = TimeCurrent();
   int count = 0;

   for(int i = 0; i < g_EventCount && count < maxEvents; i++) {
      datetime eventTime = g_UpcomingEvents[i].eventTime;

      if(eventTime > currentTime) {
         int hoursUntil = (int)((eventTime - currentTime) / 3600);
         int minutesUntil = (int)(((eventTime - currentTime) % 3600) / 60);

         string impactStr = "";
         if(g_UpcomingEvents[i].impact == 3) impactStr = "🔴HIGH";
         else if(g_UpcomingEvents[i].impact == 2) impactStr = "🟡MED";
         else impactStr = "🟢LOW";

         output += impactStr + " " + g_UpcomingEvents[i].eventName + " in " +
                   IntegerToString(hoursUntil) + "h " + IntegerToString(minutesUntil) + "m\n";
         count++;
      }
   }

   if(count == 0) output = "No major events in next 24h";

   return output;
}

//--------------------------------------------------------------------
// ADD REAL-TIME NEWS EVENT (for manual/API additions)
//--------------------------------------------------------------------
void News_AddEvent(datetime eventTime, string eventName, string currency, int impact) {
   ArrayResize(g_UpcomingEvents, g_EventCount + 1);

   g_UpcomingEvents[g_EventCount].eventTime = eventTime;
   g_UpcomingEvents[g_EventCount].eventName = eventName;
   g_UpcomingEvents[g_EventCount].currency = currency;
   g_UpcomingEvents[g_EventCount].impact = impact;
   g_UpcomingEvents[g_EventCount].forecast = "";
   g_UpcomingEvents[g_EventCount].previous = "";

   g_EventCount++;

   Print("📅 Added news event: ", eventName, " at ", TimeToString(eventTime, TIME_DATE|TIME_MINUTES), " (Impact: ", impact, ")");
}

//--------------------------------------------------------------------
// LOAD WEEK'S MAJOR EVENTS (Called weekly)
//--------------------------------------------------------------------
void News_LoadWeeklyEvents() {
   // Clear existing events
   g_EventCount = 0;
   ArrayResize(g_UpcomingEvents, 0);

   datetime currentTime = TimeCurrent();

   // Add this week's major US economic events
   // In production, fetch from API (ForexFactory, Investing.com, etc.)

   // Example: Non-Farm Payrolls (First Friday of month at 8:30 AM EST)
   // Example: FOMC Rate Decision (8 times per year at 2:00 PM EST)
   // Example: CPI Data (Monthly, usually 2nd week at 8:30 AM EST)
   // Example: GDP Data (Quarterly)
   // Example: Retail Sales (Monthly, mid-month at 8:30 AM EST)
   // Example: Unemployment Claims (Every Thursday at 8:30 AM EST)

   // For demo purposes, add some placeholder events
   // REPLACE THIS with real API data in production

   if(VerboseLogging) Print("📰 Weekly calendar loaded - ", g_EventCount, " high-impact events");
}

//--------------------------------------------------------------------
// CHECK IF MARKET IS IN NEWS-DRIVEN MODE
//--------------------------------------------------------------------
bool News_IsNewsSession() {
   // Check if we're in a period of high news activity
   // (Multiple events in short timespan)

   datetime currentTime = TimeCurrent();
   int eventsInNextHour = 0;

   for(int i = 0; i < g_EventCount; i++) {
      int minutesDiff = (int)((g_UpcomingEvents[i].eventTime - currentTime) / 60);
      if(minutesDiff >= 0 && minutesDiff <= 60 && g_UpcomingEvents[i].impact >= 2) {
         eventsInNextHour++;
      }
   }

   return (eventsInNextHour >= 2); // Multiple high-impact events in next hour
}

//--------------------------------------------------------------------
// GET NEWS RISK LEVEL (0-10 scale)
//--------------------------------------------------------------------
int News_GetRiskLevel() {
   if(!UseNewsFilter) return 0;

   datetime currentTime = TimeCurrent();
   int riskScore = 0;

   // Check proximity to news events
   for(int i = 0; i < g_EventCount; i++) {
      int minutesDiff = MathAbs((int)((g_UpcomingEvents[i].eventTime - currentTime) / 60));

      if(minutesDiff <= 15) {
         if(g_UpcomingEvents[i].impact == 3) riskScore += 10;
         else if(g_UpcomingEvents[i].impact == 2) riskScore += 5;
      } else if(minutesDiff <= 30) {
         if(g_UpcomingEvents[i].impact == 3) riskScore += 5;
         else if(g_UpcomingEvents[i].impact == 2) riskScore += 3;
      } else if(minutesDiff <= 60) {
         if(g_UpcomingEvents[i].impact == 3) riskScore += 2;
      }
   }

   // Add volatility spike score
   if(News_DetectVolatilitySpike()) {
      riskScore += 10;
   }

   // Cap at 10
   if(riskScore > 10) riskScore = 10;

   return riskScore;
}

//+------------------------------------------------------------------+
