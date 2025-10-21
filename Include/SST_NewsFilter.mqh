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
// PRODUCTION NEWS CALENDAR - Live Data Integration
//--------------------------------------------------------------------
void News_InitializeCalendar() {
   Print("📅 Initializing Economic Calendar...");

   g_EventCount = 0;
   ArrayResize(g_UpcomingEvents, 50);  // Room for 50 events

   // Try to fetch live calendar data
   bool liveDataLoaded = News_FetchLiveCalendar();

   if(!liveDataLoaded) {
      // Fallback: Load hardcoded major recurring events
      Print("⚠ Live calendar unavailable - using fallback recurring events");
      News_LoadRecurringEvents();
   }

   Print("✓ Economic Calendar initialized with ", g_EventCount, " upcoming events");
}

//--------------------------------------------------------------------
// FETCH LIVE CALENDAR DATA (ForexFactory JSON API - FREE)
//--------------------------------------------------------------------
bool News_FetchLiveCalendar() {
   // Use WebRequest to fetch economic calendar from ForexFactory
   // Note: User must add "https://nfs.faireconomy.media" to allowed URLs in MT4
   // Tools → Options → Expert Advisors → Allow WebRequest for listed URL
   // Add this URL: https://nfs.faireconomy.media

   string url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";
   string cookie = NULL;
   string referer = NULL;
   int timeout = 10000;  // 10 seconds

   char postData[];
   char resultData[];
   string resultHeaders;

   Print("📡 Fetching live economic calendar from ForexFactory API...");
   Print("   URL: ", url);

   int res = WebRequest(
      "GET",
      url,
      cookie,
      referer,
      timeout,
      postData,
      0,
      resultData,
      resultHeaders
   );

   if(res == -1) {
      int error = GetLastError();
      if(error == 4060) {
         Print("❌ WebRequest error: URL not allowed.");
         Print("   SOLUTION: Add this URL to allowed list in MT4:");
         Print("   Tools → Options → Expert Advisors → Allow WebRequest for listed URL");
         Print("   Add: https://nfs.faireconomy.media");
      } else {
         Print("❌ WebRequest failed with error: ", error);
      }
      return false;
   }

   if(res == 200) {
      // Parse JSON response
      string json = CharArrayToString(resultData);

      if(StringLen(json) < 10) {
         Print("⚠ Empty response from ForexFactory API");
         return false;
      }

      if(VerboseLogging) Print("✓ Received ", StringLen(json), " bytes of calendar data");

      // Parse JSON for high-impact events
      if(News_ParseForexFactoryJSON(json)) {
         Print("✅ Live calendar loaded successfully from ForexFactory (", g_EventCount, " events)");
         return true;
      }
   } else {
      Print("⚠ HTTP error ", res, " from ForexFactory API");
   }

   Print("⚠ Failed to parse live calendar data - using fallback");
   return false;
}

//--------------------------------------------------------------------
// PARSE FOREXFACTORY JSON (Production-Ready)
//--------------------------------------------------------------------
bool News_ParseForexFactoryJSON(string json) {
   // ForexFactory JSON format:
   // [{"title":"Non-Farm Employment Change","country":"USD","date":"2025-01-10T13:30:00-05:00","impact":"High",...}]

   int eventsFound = 0;
   datetime currentTime = TimeCurrent();

   // Simple JSON parsing (MQL4 doesn't have native JSON parser)
   // Look for event objects in the array

   int startPos = 0;
   while(true) {
      // Find next event object
      int objStart = StringFind(json, "{\"title\":", startPos);
      if(objStart < 0) break;

      int objEnd = StringFind(json, "}", objStart);
      if(objEnd < 0) break;

      // Extract this event object
      string eventObj = StringSubstr(json, objStart, objEnd - objStart + 1);

      // Parse title
      string title = News_ExtractJSONValue(eventObj, "title");

      // Parse country
      string country = News_ExtractJSONValue(eventObj, "country");

      // Parse impact
      string impactStr = News_ExtractJSONValue(eventObj, "impact");

      // Parse date (ISO 8601 format: "2025-01-10T13:30:00-05:00")
      string dateStr = News_ExtractJSONValue(eventObj, "date");

      // Only process USD high-impact events
      if(country == "USD" && impactStr == "High") {
         // Convert ISO date to MT4 datetime
         datetime eventTime = News_ParseISODate(dateStr);

         // Only add future events (within next 7 days)
         if(eventTime > currentTime && eventTime < currentTime + (7 * 86400)) {
            News_AddEvent(eventTime, title, country, 3);  // 3 = High impact
            eventsFound++;

            if(VerboseLogging) {
               Print("   ✓ ", title, " at ", TimeToString(eventTime, TIME_DATE|TIME_MINUTES));
            }
         }
      }

      startPos = objEnd + 1;

      // Safety limit: max 100 events
      if(eventsFound >= 100) break;
   }

   if(VerboseLogging) {
      Print("   Parsed ", eventsFound, " high-impact USD events from ForexFactory");
   }

   return (eventsFound > 0);
}

//--------------------------------------------------------------------
// HELPER: Extract JSON value by key
//--------------------------------------------------------------------
string News_ExtractJSONValue(string json, string key) {
   string searchStr = "\"" + key + "\":\"";
   int startPos = StringFind(json, searchStr);

   if(startPos < 0) return "";

   startPos += StringLen(searchStr);
   int endPos = StringFind(json, "\"", startPos);

   if(endPos < 0) return "";

   return StringSubstr(json, startPos, endPos - startPos);
}

//--------------------------------------------------------------------
// HELPER: Parse ISO 8601 date to MT4 datetime
//--------------------------------------------------------------------
datetime News_ParseISODate(string isoDate) {
   // Format: "2025-01-10T13:30:00-05:00"
   // Convert to MT4 format: "2025.01.10 13:30"

   if(StringLen(isoDate) < 19) return 0;

   // Extract components
   string year = StringSubstr(isoDate, 0, 4);
   string month = StringSubstr(isoDate, 5, 2);
   string day = StringSubstr(isoDate, 8, 2);
   string hour = StringSubstr(isoDate, 11, 2);
   string minute = StringSubstr(isoDate, 14, 2);

   // Build MT4 datetime string
   string mt4DateStr = year + "." + month + "." + day + " " + hour + ":" + minute;

   datetime result = StrToTime(mt4DateStr);

   if(VerboseLogging && result > 0) {
      Print("   Parsed date: ", isoDate, " → ", TimeToString(result, TIME_DATE|TIME_MINUTES));
   }

   return result;
}

//--------------------------------------------------------------------
// LOAD RECURRING EVENTS (Fallback when live data unavailable)
//--------------------------------------------------------------------
void News_LoadRecurringEvents() {
   datetime currentTime = TimeCurrent();

   // Get current month/year
   int currentMonth = TimeMonth(currentTime);
   int currentYear = TimeYear(currentTime);
   int currentDay = TimeDay(currentTime);

   //=== MONTHLY RECURRING EVENTS ===

   // Non-Farm Payrolls (NFP) - First Friday of each month, 8:30 AM EST
   datetime nfpDate = News_GetFirstFridayOfMonth(currentYear, currentMonth);
   if(nfpDate > currentTime) {
      News_AddEvent(nfpDate + 30600, "Non-Farm Payrolls", "USD", 3);  // 8:30 AM = 30600 seconds
   }

   // CPI (Consumer Price Index) - Usually 2nd week, varies
   datetime cpiDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, 2, 3);  // 2nd Wednesday
   if(cpiDate > currentTime) {
      News_AddEvent(cpiDate + 30600, "CPI m/m", "USD", 3);
      News_AddEvent(cpiDate + 30600, "Core CPI m/m", "USD", 3);
   }

   // Retail Sales - Usually mid-month
   datetime retailDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, 2, 4);  // 2nd Thursday
   if(retailDate > currentTime) {
      News_AddEvent(retailDate + 30600, "Retail Sales m/m", "USD", 3);
   }

   // PPI (Producer Price Index)
   datetime ppiDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, 2, 2);  // 2nd Tuesday
   if(ppiDate > currentTime) {
      News_AddEvent(ppiDate + 30600, "PPI m/m", "USD", 3);
   }

   //=== WEEKLY RECURRING EVENTS ===

   // Unemployment Claims - Every Thursday, 8:30 AM EST
   for(int week = 1; week <= 4; week++) {
      datetime thursDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, week, 4);
      if(thursDate > currentTime) {
         News_AddEvent(thursDate + 30600, "Unemployment Claims", "USD", 2);
      }
   }

   //=== QUARTERLY EVENTS ===

   // FOMC Meetings (8 times per year, specific dates)
   // Simplified: Add if we're in FOMC month
   int fomcMonths[] = {1, 3, 5, 6, 7, 9, 11, 12};  // FOMC meeting months
   for(int i = 0; i < ArraySize(fomcMonths); i++) {
      if(fomcMonths[i] == currentMonth) {
         // FOMC usually 3rd week Wednesday, 2:00 PM EST
         datetime fomcDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, 3, 3);
         if(fomcDate > currentTime) {
            News_AddEvent(fomcDate + 50400, "FOMC Statement", "USD", 3);  // 2:00 PM = 50400 seconds
            News_AddEvent(fomcDate + 52200, "FOMC Press Conference", "USD", 3);  // 2:30 PM
         }
         break;
      }
   }

   // GDP (Quarterly - end of Jan, Apr, Jul, Oct)
   int gdpMonths[] = {1, 4, 7, 10};
   for(int i = 0; i < ArraySize(gdpMonths); i++) {
      if(gdpMonths[i] == currentMonth) {
         datetime gdpDate = News_GetNthWeekdayOfMonth(currentYear, currentMonth, 4, 4);  // 4th Thursday
         if(gdpDate > currentTime) {
            News_AddEvent(gdpDate + 30600, "GDP q/q", "USD", 3);
         }
         break;
      }
   }

   Print("   Loaded ", g_EventCount, " recurring events for ", TimeToString(currentTime, TIME_DATE));
}

//--------------------------------------------------------------------
// HELPER: Get First Friday of Month
//--------------------------------------------------------------------
datetime News_GetFirstFridayOfMonth(int year, int month) {
   datetime firstDay = StrToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int dayOfWeek = TimeDayOfWeek(firstDay);

   // Friday = 5, calculate days until first Friday
   int daysUntilFriday = (dayOfWeek <= 5) ? (5 - dayOfWeek) : (12 - dayOfWeek);

   return firstDay + (daysUntilFriday * 86400);
}

//--------------------------------------------------------------------
// HELPER: Get Nth Weekday of Month (e.g., 2nd Wednesday)
//--------------------------------------------------------------------
datetime News_GetNthWeekdayOfMonth(int year, int month, int nthWeek, int targetDayOfWeek) {
   datetime firstDay = StrToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int firstDayOfWeek = TimeDayOfWeek(firstDay);

   // Calculate days until first occurrence of target weekday
   int daysUntilTarget = (targetDayOfWeek >= firstDayOfWeek) ?
                         (targetDayOfWeek - firstDayOfWeek) :
                         (7 - firstDayOfWeek + targetDayOfWeek);

   // Add weeks to get nth occurrence
   int totalDays = daysUntilTarget + ((nthWeek - 1) * 7);

   return firstDay + (totalDays * 86400);
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
