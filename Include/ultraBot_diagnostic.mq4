//+------------------------------------------------------------------+
//|                          UltraBot_Diagnostic.mq4                 |
//|  Diagnostic version - shows WHY no trades are being taken        |
//+------------------------------------------------------------------+
#property strict

extern string  Pairs                = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCHF";
extern double  RiskPercentPerTrade  = 1.0;
extern int     MagicNumber          = 987654;
extern bool    UseNewsFilter        = false;  // DISABLED for testing
extern bool    UseCorrelationFilter = false;  // DISABLED for testing

string  CurrencyPairs[];
int     PairCount = 0;
datetime lastDiagnosticUpdate = 0;

int SplitPairs(string str, string separator, string &result[])
{
   int count = 0;
   string temp = str;
   ArrayResize(result, 0);

   while(StringLen(temp) > 0)
   {
      int sepPos = StringFind(temp, separator, 0);
      if(sepPos < 0)
      {
         if(StringLen(temp) > 0)
         {
            ArrayResize(result, count + 1);
            result[count] = temp;
            count++;
         }
         break;
      }
      else
      {
         string part = StringSubstr(temp, 0, sepPos);
         if(StringLen(part) > 0)
         {
            ArrayResize(result, count + 1);
            result[count] = part;
            count++;
         }
         temp = StringSubstr(temp, sepPos + StringLen(separator));
      }
   }
   return count;
}

string GetDiagnosticInfo()
{
   string info = "=== ULTRABOT DIAGNOSTIC ===\n";
   info += "EA IS ACTIVE!\n";
   info += "Current Symbol: " + Symbol() + "\n";
   info += "Account Equity: $" + DoubleToString(AccountEquity(), 2) + "\n";
   info += "Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\n";
   info += "Open Trades: " + IntegerToString(OrdersTotal()) + "\n\n";

   info += "MONITORED PAIRS:\n";
   for(int i = 0; i < PairCount; i++)
   {
      string sym = CurrencyPairs[i];
      double spread = MarketInfo(sym, MODE_SPREAD);
      info += sym;
      if(spread > 0)
         info += " ✓ ";
      else
         info += " ✗ ";
      info += "\n";
   }

   info += "\nFILTERS STATUS:\n";
   info += "News Filter: " + (UseNewsFilter ? "ON" : "OFF") + "\n";
   info += "Correlation: " + (UseCorrelationFilter ? "ON" : "OFF") + "\n";

   info += "\nLAST UPDATE: " + TimeToString(TimeCurrent(), TIME_SECONDS);

   return info;
}

void UpdateDiagnosticDashboard()
{
   string objName = "UltraBotDiagnostic";

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, objName, OBJPROP_FONT, "Courier New");
   }

   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrLime);
   ObjectSetString(0, objName, OBJPROP_TEXT, GetDiagnosticInfo());
}

int OnInit()
{
   Print("=== ULTRABOT DIAGNOSTIC MODE STARTED ===");
   PairCount = SplitPairs(Pairs, ",", CurrencyPairs);
   Print("Monitoring ", PairCount, " pairs: ", Pairs);

   for(int i = 0; i < PairCount; i++)
   {
      string sym = CurrencyPairs[i];
      double spread = MarketInfo(sym, MODE_SPREAD);
      if(spread > 0)
         Print("✓ ", sym, " is available (spread: ", spread, ")");
      else
         Print("✗ ", sym, " is NOT available or no data");
   }

   UpdateDiagnosticDashboard();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete(0, "UltraBotDiagnostic");
   Print("=== ULTRABOT DIAGNOSTIC STOPPED ===");
}

void OnTick()
{
   // Update dashboard every 5 seconds
   if(TimeCurrent() - lastDiagnosticUpdate >= 5)
   {
      UpdateDiagnosticDashboard();
      lastDiagnosticUpdate = TimeCurrent();
   }
}
