//+------------------------------------------------------------------+
//|                                  SmartStockTrader_Single.mq4     |
//|           Ultra-Intelligent Stock Trading EA - Single File       |
//|              ALL CODE IN ONE FILE FOR EASY MT4 LOADING           |
//+------------------------------------------------------------------+
#property copyright "Smart Stock Trader Pro v1.0"
#property version   "1.00"
#property strict
#property description "Professional stock trading EA - Single file version"

//--------------------------------------------------------------------
// LICENSE PARAMETERS
//--------------------------------------------------------------------
extern string  LicenseKey            = "";                              // Enter your license key
extern datetime ExpirationDate       = D'2026.12.31 23:59:59';         // License expiration date
extern string  AuthorizedAccounts    = "";                             // Comma-separated account numbers
extern bool    RequireLicenseKey     = true;                           // Require valid license key

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------
extern string  Stocks                = "AAPL,MSFT,GOOGL,AMZN,TSLA";
extern int     MagicNumber           = 555777;
extern bool    EnableTrading         = true;
extern double  RiskPercentPerTrade   = 1.0;
extern double  MaxDailyLossPercent   = 5.0;
extern bool    ShowDashboard         = true;
extern bool    SendNotifications     = false;

// Session Settings
extern bool    TradePreMarket        = false;
extern bool    TradeRegularHours     = true;
extern bool    TradeAfterHours       = false;
extern int     BrokerGMTOffset       = -5;

// Risk Management
extern bool    UseATRStops           = true;
extern double  ATRMultiplierSL       = 2.5;
extern double  ATRMultiplierTP       = 4.0;
extern int     FixedStopLossPips     = 100;
extern int     FixedTakeProfitPips   = 200;

// Strategies
extern bool    UseMomentumStrategy   = true;
extern bool    UseTrendFollowing     = true;
extern bool    UseBreakoutStrategy   = true;

// Indicators
extern int     FastMA_Period         = 10;
extern int     SlowMA_Period         = 50;
extern int     RSI_Period            = 14;
extern int     ATR_Period            = 14;

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
string  g_Symbols[];
int     g_SymbolCount = 0;
datetime g_DailyStartTime = 0;
double   g_DailyStartEquity = 0;
int     g_DailyTrades = 0;
int     g_DailyWins = 0;
int     g_DailyLosses = 0;
int     g_TotalTrades = 0;
int     g_TotalWins = 0;
int     g_TotalLosses = 0;
double  g_TotalProfit = 0;
double  g_TotalLoss = 0;
bool    g_IsMarketHours = false;

enum EA_STATE { STATE_READY, STATE_SUSPENDED };
EA_STATE g_EAState = STATE_READY;

//--------------------------------------------------------------------
// VALID LICENSE KEYS DATABASE
//--------------------------------------------------------------------
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345"
};

//--------------------------------------------------------------------
// LICENSE VALIDATION FUNCTIONS
//--------------------------------------------------------------------
string GetHardwareFingerprint() {
   return IntegerToString(AccountNumber()) + "-" + AccountName() + "-" + AccountServer();
}

bool ValidateLicenseKey(string key) {
   if(!RequireLicenseKey) return true;
   if(key == "") return false;

   for(int i = 0; i < ArraySize(g_ValidLicenseKeys); i++) {
      if(key == g_ValidLicenseKeys[i]) return true;
   }
   return false;
}

bool CheckExpiration() {
   if(ExpirationDate == 0) return true;
   if(TimeCurrent() > ExpirationDate) return false;
   return true;
}

bool CheckAccountAuthorization() {
   if(AuthorizedAccounts == "") return true;
   string accountStr = IntegerToString(AccountNumber());
   if(StringFind(AuthorizedAccounts, accountStr) >= 0) return true;
   return false;
}

int GetDaysUntilExpiration() {
   if(ExpirationDate == 0) return 999999;
   datetime current = TimeCurrent();
   if(current > ExpirationDate) return 0;
   int secondsRemaining = (int)(ExpirationDate - current);
   return secondsRemaining / 86400;
}

bool ValidateLicense() {
   Print("=== LICENSE VALIDATION ===");
   Print("Hardware Fingerprint: ", GetHardwareFingerprint());
   Print("Account: ", AccountNumber());
   Print("Broker: ", AccountCompany());

   if(!CheckExpiration()) {
      Alert("LICENSE EXPIRED!\n\nYour license expired on " + TimeToString(ExpirationDate, TIME_DATE) +
            "\n\nContact: support@smartstocktrader.com");
      Print("ERROR: License expired");
      return false;
   }

   if(!ValidateLicenseKey(LicenseKey)) {
      Alert("INVALID LICENSE KEY!\n\nPlease check your license key.\n\nContact: support@smartstocktrader.com");
      Print("ERROR: Invalid license key");
      return false;
   }

   if(!CheckAccountAuthorization()) {
      Alert("ACCOUNT NOT AUTHORIZED!\n\nAccount #" + IntegerToString(AccountNumber()) +
            " is not authorized.\n\nContact: support@smartstocktrader.com");
      Print("ERROR: Account not authorized");
      return false;
   }

   int daysLeft = GetDaysUntilExpiration();
   Print("LICENSE VALID - ", daysLeft, " days remaining");

   if(daysLeft <= 30 && daysLeft > 0) {
      Alert("LICENSE WARNING\n\nExpires in " + IntegerToString(daysLeft) +
            " days\n\nRenew at: www.smartstocktrader.com");
   }

   Print("========================");
   return true;
}

//--------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------
int ParseSymbols(string symbolList, string &output[]) {
   int count = 0;
   string temp = symbolList;
   ArrayResize(output, 0);

   while(StringLen(temp) > 0) {
      int pos = StringFind(temp, ",", 0);
      if(pos < 0) {
         if(StringLen(temp) > 0) {
            ArrayResize(output, count + 1);
            output[count] = temp;
            count++;
         }
         break;
      } else {
         string part = StringSubstr(temp, 0, pos);
         StringTrimLeft(part);
         StringTrimRight(part);
         if(StringLen(part) > 0) {
            ArrayResize(output, count + 1);
            output[count] = part;
            count++;
         }
         temp = StringSubstr(temp, pos + 1);
      }
   }
   return count;
}

//--------------------------------------------------------------------
// SESSION MANAGEMENT
//--------------------------------------------------------------------
bool IsTradingTime() {
   // Simplified: Just check if regular hours are enabled
   if(!TradeRegularHours && !TradePreMarket && !TradeAfterHours) return false;

   int hour = TimeHour(TimeCurrent());
   int dayOfWeek = TimeDayOfWeek(TimeCurrent());

   // No trading on weekends
   if(dayOfWeek == 0 || dayOfWeek == 6) return false;

   // For now, allow trading between 9-16 EST (adjust for your broker)
   if(TradeRegularHours && hour >= 9 && hour < 16) return true;

   return false;
}

//--------------------------------------------------------------------
// RISK MANAGEMENT
//--------------------------------------------------------------------
bool CheckDailyLossLimit() {
   double dailyPL = AccountEquity() - g_DailyStartEquity;
   double dailyPct = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyPct <= -MaxDailyLossPercent) {
      g_EAState = STATE_SUSPENDED;
      Print("Daily loss limit reached: ", DoubleToString(dailyPct, 2), "%");
      return true;
   }
   return false;
}

double CalculateLotSize(string symbol, double slPips) {
   double riskAmount = AccountBalance() * (RiskPercentPerTrade / 100.0);
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double point = MarketInfo(symbol, MODE_POINT);

   if(tickValue <= 0) tickValue = 1.0;
   if(point <= 0) point = 0.00001;

   double pipValue = tickValue * 10.0;
   double lotSize = riskAmount / (slPips * pipValue);

   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);

   if(lotStep > 0) lotSize = MathFloor(lotSize / lotStep) * lotStep;
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;

   return NormalizeDouble(lotSize, 2);
}

//--------------------------------------------------------------------
// SIMPLE STRATEGY
//--------------------------------------------------------------------
bool GetBuySignal(string symbol) {
   // Simple MA crossover + RSI
   double fastMA = iMA(symbol, PERIOD_H1, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(symbol, PERIOD_H1, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double rsi = iRSI(symbol, PERIOD_H1, RSI_Period, PRICE_CLOSE, 0);
   double close = iClose(symbol, PERIOD_H1, 0);

   // Buy signal: Price above both MAs, RSI between 50-70
   if(close > fastMA && close > slowMA && fastMA > slowMA && rsi > 50 && rsi < 70) {
      return true;
   }
   return false;
}

bool GetSellSignal(string symbol) {
   double fastMA = iMA(symbol, PERIOD_H1, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(symbol, PERIOD_H1, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double rsi = iRSI(symbol, PERIOD_H1, RSI_Period, PRICE_CLOSE, 0);
   double close = iClose(symbol, PERIOD_H1, 0);

   // Sell signal: Price below both MAs, RSI between 30-50
   if(close < fastMA && close < slowMA && fastMA < slowMA && rsi < 50 && rsi > 30) {
      return true;
   }
   return false;
}

//--------------------------------------------------------------------
// DASHBOARD
//--------------------------------------------------------------------
void UpdateDashboard() {
   if(!ShowDashboard) return;

   int y = 20;
   int lineHeight = 18;

   // Header
   CreateLabel("SST_Header", 15, y, "=== SMART STOCK TRADER ===", clrAqua, 11);
   y += lineHeight + 5;

   // State
   color stateColor = (g_EAState == STATE_READY) ? clrLime : clrRed;
   string stateName = (g_EAState == STATE_READY) ? "READY" : "SUSPENDED";
   CreateLabel("SST_State", 15, y, "State: " + stateName, stateColor, 10);
   y += lineHeight;

   // Account
   CreateLabel("SST_Balance", 15, y, "Balance: $" + DoubleToString(AccountBalance(), 2), clrWhite);
   y += lineHeight;
   CreateLabel("SST_Equity", 15, y, "Equity:  $" + DoubleToString(AccountEquity(), 2), clrWhite);
   y += lineHeight;

   // Daily P/L
   double dailyPL = AccountEquity() - g_DailyStartEquity;
   color plColor = (dailyPL >= 0) ? clrLime : clrRed;
   string plSign = (dailyPL >= 0) ? "+" : "";
   CreateLabel("SST_DailyPL", 15, y, "Daily P/L: " + plSign + "$" + DoubleToString(dailyPL, 2), plColor);
   y += lineHeight + 3;

   // Today's stats
   CreateLabel("SST_TodayHeader", 15, y, "--- Today's Stats ---", clrSilver);
   y += lineHeight;
   CreateLabel("SST_Trades", 15, y, "Trades: " + IntegerToString(g_DailyTrades), clrWhite);
   y += lineHeight;
   CreateLabel("SST_WL", 15, y, "W/L: " + IntegerToString(g_DailyWins) + "/" + IntegerToString(g_DailyLosses), clrWhite);
   y += lineHeight;

   double winRate = (g_DailyTrades > 0) ? (g_DailyWins / (double)g_DailyTrades * 100.0) : 0;
   CreateLabel("SST_WinRate", 15, y, "Win Rate: " + DoubleToString(winRate, 1) + "%", winRate >= 50 ? clrLime : clrOrange);
}

void CreateLabel(string name, int x, int y, string text, color clr = clrWhite, int fontSize = 9) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//--------------------------------------------------------------------
// ON INIT
//--------------------------------------------------------------------
int OnInit() {
   Print("╔════════════════════════════════════════╗");
   Print("║  SMART STOCK TRADER - STARTING...     ║");
   Print("╚════════════════════════════════════════╝");

   // VALIDATE LICENSE FIRST
   if(!ValidateLicense()) {
      Print("╔════════════════════════════════════════╗");
      Print("║    LICENSE VALIDATION FAILED!         ║");
      Print("║         EA WILL NOT TRADE             ║");
      Print("╚════════════════════════════════════════╝");
      return(INIT_FAILED);
   }

   Print("\n✓ License validated successfully\n");

   g_SymbolCount = ParseSymbols(Stocks, g_Symbols);
   Print("Trading ", g_SymbolCount, " symbols: ", Stocks);

   g_DailyStartTime = TimeCurrent();
   g_DailyStartEquity = AccountEquity();

   UpdateDashboard();

   Print("=== INITIALIZATION COMPLETE ===");
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------
// ON DEINIT
//--------------------------------------------------------------------
void OnDeinit(const int reason) {
   Print("Smart Stock Trader shutting down...");
   ObjectsDeleteAll(0, "SST_", 0, OBJ_LABEL);
}

//--------------------------------------------------------------------
// ON TICK
//--------------------------------------------------------------------
void OnTick() {
   // Reset daily stats if new day
   if(TimeDay(TimeCurrent()) != TimeDay(g_DailyStartTime)) {
      g_DailyStartTime = TimeCurrent();
      g_DailyStartEquity = AccountEquity();
      g_DailyTrades = 0;
      g_DailyWins = 0;
      g_DailyLosses = 0;
      Print("New day - daily stats reset");
   }

   // Update dashboard every 10 ticks
   static int tickCount = 0;
   tickCount++;
   if(tickCount % 10 == 0) {
      UpdateDashboard();
   }

   // Check if trading is allowed
   if(!EnableTrading) return;
   if(g_EAState == STATE_SUSPENDED) return;
   if(!IsTradingTime()) return;
   if(CheckDailyLossLimit()) return;

   // Scan for trades once per minute
   static datetime lastScan = 0;
   if(TimeCurrent() - lastScan < 60) return;
   lastScan = TimeCurrent();

   // Loop through symbols
   for(int i = 0; i < g_SymbolCount; i++) {
      string symbol = g_Symbols[i];

      // Check if already have position
      bool hasPosition = false;
      for(int j = 0; j < OrdersTotal(); j++) {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == symbol && OrderMagicNumber() == MagicNumber) {
               hasPosition = true;
               break;
            }
         }
      }

      if(hasPosition) continue;

      // Check for signals
      bool buySignal = GetBuySignal(symbol);
      bool sellSignal = GetSellSignal(symbol);

      if(buySignal || sellSignal) {
         ExecuteTrade(symbol, buySignal);
      }
   }
}

//--------------------------------------------------------------------
// EXECUTE TRADE
//--------------------------------------------------------------------
void ExecuteTrade(string symbol, bool isBuy) {
   double atr = iATR(symbol, PERIOD_H1, ATR_Period, 0);
   double point = MarketInfo(symbol, MODE_POINT);

   // Calculate SL/TP
   double slPips = UseATRStops ? (atr / point / 10.0 * ATRMultiplierSL) : FixedStopLossPips;
   double tpPips = UseATRStops ? (atr / point / 10.0 * ATRMultiplierTP) : FixedTakeProfitPips;

   double price = isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   double slDistance = slPips * point * 10.0;
   double tpDistance = tpPips * point * 10.0;
   double sl = isBuy ? (price - slDistance) : (price + slDistance);
   double tp = isBuy ? (price + tpDistance) : (price - tpDistance);

   double lotSize = CalculateLotSize(symbol, slPips);

   int ticket = OrderSend(symbol,
                         isBuy ? OP_BUY : OP_SELL,
                         lotSize,
                         price,
                         5,
                         NormalizeDouble(sl, _Digits),
                         NormalizeDouble(tp, _Digits),
                         "SmartStockTrader",
                         MagicNumber,
                         0,
                         isBuy ? clrBlue : clrRed);

   if(ticket > 0) {
      Print("╔════════════════════════╗");
      Print("║  NEW TRADE OPENED     ║");
      Print("╠════════════════════════╣");
      Print("║ Symbol: ", symbol);
      Print("║ Type: ", isBuy ? "BUY" : "SELL");
      Print("║ Price: ", DoubleToString(price, _Digits));
      Print("║ Lot: ", DoubleToString(lotSize, 2));
      Print("║ SL: ", DoubleToString(sl, _Digits));
      Print("║ TP: ", DoubleToString(tp, _Digits));
      Print("╚════════════════════════╝");

      g_DailyTrades++;

      if(SendNotifications) {
         SendNotification("SmartStockTrader: " + (isBuy ? "BUY" : "SELL") + " " + symbol + " @ " + DoubleToString(price, _Digits));
      }
   } else {
      Print("ERROR: Failed to open trade on ", symbol, " - Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
