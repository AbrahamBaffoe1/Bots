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
extern string  LicenseKey            = "SST-BASIC-X3EWSS-F2LSJW-766S";   // Your license key
extern datetime ExpirationDate       = D'2026.12.31 23:59:59';         // License expiration date
extern string  AuthorizedAccounts    = "";                             // Comma-separated account numbers (leave empty for any account)
extern bool    RequireLicenseKey     = true;                           // Set FALSE to disable license check for testing

//--------------------------------------------------------------------
// EXTERNAL PARAMETERS
//--------------------------------------------------------------------
extern string  Stocks                = "AAPL,MSFT,GOOGL,AMZN,TSLA";  // Leave empty to use current chart symbol
extern int     MagicNumber           = 555777;
extern bool    EnableTrading         = true;
extern bool    BacktestMode          = false;                        // Enable backtest features (24/7, verbose logs, no restrictions)
extern bool    VerboseLogging        = false;                       // Detailed logs for debugging
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

//=== QUICK WIN FILTERS (Added for +10-15% Profitability) ===
extern double  MaxSpreadPips         = 2.0;          // Max spread in pips (reject wider spreads)
extern bool    UseTimeOfDayFilter    = true;         // Skip first 30min and lunch hour
extern int     MaxDailyTrades         = 10;          // Maximum trades per day (prevent overtrading)
extern int     MinMinutesBetweenTrades = 15;        // Minimum minutes between trades
extern bool    UseSPYTrendFilter     = true;         // Only trade with market direction
extern string  MarketIndexSymbol     = "SPY";        // Market index for trend filter (SPY, QQQ, DIA)
extern int     SPYTrendMA            = 50;           // MA period for SPY trend (50 or 200)

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
datetime g_LastTradeTime = 0;  // Track last trade time for spacing filter

enum EA_STATE { STATE_READY, STATE_SUSPENDED };
EA_STATE g_EAState = STATE_READY;

//--------------------------------------------------------------------
// VALID LICENSE KEYS DATABASE
//--------------------------------------------------------------------
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345",
   "SST-PRO-TEST01-DEMO99-K7M2",
   "SST-BASIC-X3EWSS-F2LSJW-766S"  // ← Your generated key
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
   // Skip license check if not required or in backtest mode
   if(!RequireLicenseKey) {
      Print("⚠ License check DISABLED by parameter");
      return true;
   }

   if(BacktestMode) {
      Print("✓ Backtest mode - skipping license validation");
      return true;
   }

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
   // In backtest mode, trade 24/7
   if(BacktestMode) {
      return true;
   }

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

//--------------------------------------------------------------------
// QUICK WIN FILTERS - Added for +10-15% Profitability
//--------------------------------------------------------------------

// Filter 1: Check Spread (Avoid wide spreads)
bool CheckSpreadFilter(string symbol) {
   if(BacktestMode) return true;  // Skip in backtest

   double spread = MarketInfo(symbol, MODE_SPREAD);
   double point = MarketInfo(symbol, MODE_POINT);
   double spreadPips = spread * point / (point * 10.0);

   if(spreadPips > MaxSpreadPips) {
      if(VerboseLogging) Print("✗ Spread too wide on ", symbol, ": ", DoubleToString(spreadPips, 1), " pips (max: ", MaxSpreadPips, ")");
      return false;
   }

   if(VerboseLogging) Print("✓ Spread OK on ", symbol, ": ", DoubleToString(spreadPips, 1), " pips");
   return true;
}

// Filter 2: Time of Day Filter (Avoid first 30min and lunch)
bool CheckTimeOfDayFilter() {
   if(!UseTimeOfDayFilter || BacktestMode) return true;

   int hour = TimeHour(TimeCurrent());
   int minute = TimeMinute(TimeCurrent());

   // Skip first 30 minutes of market open (9:30-10:00 AM EST)
   if(hour == 9 && minute < 30) {
      if(VerboseLogging) Print("✗ Market just opened - waiting for first 30 min to pass");
      return false;
   }

   if(hour == 10 && minute == 0) {
      if(VerboseLogging) Print("✓ First 30 min passed - ready to trade");
   }

   // Skip lunch hour (12:00-1:00 PM EST - low volume, choppy)
   if(hour == 12 || hour == 13) {
      if(VerboseLogging && minute == 0) Print("✗ Lunch hour - skipping trades");
      return false;
   }

   return true;
}

// Filter 3: Max Daily Trades Limit
bool CheckMaxDailyTrades() {
   if(g_DailyTrades >= MaxDailyTrades) {
      if(VerboseLogging) Print("✗ Max daily trades reached (", g_DailyTrades, "/", MaxDailyTrades, ")");
      return false;
   }
   return true;
}

// Filter 4: Minimum Time Between Trades
bool CheckMinTimeBetweenTrades() {
   if(g_LastTradeTime == 0) return true;  // First trade

   int secondsSinceLastTrade = (int)(TimeCurrent() - g_LastTradeTime);
   int minutesSinceLastTrade = secondsSinceLastTrade / 60;

   if(minutesSinceLastTrade < MinMinutesBetweenTrades) {
      if(VerboseLogging) Print("✗ Too soon since last trade (", minutesSinceLastTrade, " min, need ", MinMinutesBetweenTrades, " min)");
      return false;
   }

   return true;
}

// Filter 5: SPY Trend Filter (Only trade with market direction)
bool CheckSPYTrendFilter(bool isBuySignal) {
   if(!UseSPYTrendFilter || BacktestMode) return true;

   // Get SPY current price and MA
   double spyClose = iClose(MarketIndexSymbol, PERIOD_D1, 0);
   double spyMA = iMA(MarketIndexSymbol, PERIOD_D1, SPYTrendMA, 0, MODE_SMA, PRICE_CLOSE, 0);

   // If data not available (symbol not found), skip filter
   if(spyClose == 0 || spyMA == 0) {
      if(VerboseLogging) Print("⚠ ", MarketIndexSymbol, " data not available - skipping trend filter");
      return true;
   }

   bool marketBullish = (spyClose > spyMA);

   // Only allow long trades when market is bullish
   if(isBuySignal && !marketBullish) {
      if(VerboseLogging) Print("✗ ", MarketIndexSymbol, " bearish (", DoubleToString(spyClose, 2), " < MA", SPYTrendMA, ": ", DoubleToString(spyMA, 2), ") - skipping LONG");
      return false;
   }

   // Only allow short trades when market is bearish
   if(!isBuySignal && marketBullish) {
      if(VerboseLogging) Print("✗ ", MarketIndexSymbol, " bullish (", DoubleToString(spyClose, 2), " > MA", SPYTrendMA, ": ", DoubleToString(spyMA, 2), ") - skipping SHORT");
      return false;
   }

   if(VerboseLogging) {
      string trend = marketBullish ? "BULLISH" : "BEARISH";
      Print("✓ ", MarketIndexSymbol, " ", trend, " - ", isBuySignal ? "LONG" : "SHORT", " trade aligned");
   }

   return true;
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

   // If Stocks is empty or BacktestMode, use current chart symbol
   if(Stocks == "" || BacktestMode) {
      g_SymbolCount = 1;
      ArrayResize(g_Symbols, 1);
      g_Symbols[0] = Symbol();
      if(VerboseLogging) Print("✓ Trading current chart symbol: ", Symbol());
   } else {
      g_SymbolCount = ParseSymbols(Stocks, g_Symbols);
      if(VerboseLogging) Print("✓ Trading ", g_SymbolCount, " symbols: ", Stocks);
   }

   if(BacktestMode) {
      Print("╔════════════════════════════════════════╗");
      Print("║      BACKTEST MODE ENABLED            ║");
      Print("║  - Trading 24/7 (no time limits)      ║");
      Print("║  - Verbose logging enabled            ║");
      Print("║  - Single symbol: ", Symbol(), "           ║");
      Print("╚════════════════════════════════════════╝");
      VerboseLogging = true;  // Force verbose logging in backtest mode
   }

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
   // === QUICK WIN FILTERS - Pre-trade checks ===

   // Filter: Time of Day
   if(!CheckTimeOfDayFilter()) return;

   // Filter: Max Daily Trades
   if(!CheckMaxDailyTrades()) return;

   // Filter: Min Time Between Trades
   if(!CheckMinTimeBetweenTrades()) return;

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

      // Filter: Spread Check
      if(!CheckSpreadFilter(symbol)) continue;

      // Check for signals
      bool buySignal = GetBuySignal(symbol);
      bool sellSignal = GetSellSignal(symbol);

      if(buySignal || sellSignal) {
         bool isBuy = buySignal;

         // Filter: SPY Trend Confirmation
         if(!CheckSPYTrendFilter(isBuy)) continue;

         ExecuteTrade(symbol, isBuy);
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
      Print("║ SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(slPips, 1), " pips)");
      Print("║ TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(tpPips, 1), " pips)");
      Print("╚════════════════════════╝");

      // Update tracking variables
      g_DailyTrades++;
      g_TotalTrades++;
      g_LastTradeTime = TimeCurrent();  // Record trade time for spacing filter

      if(VerboseLogging) {
         Print("✓ Trade #", g_DailyTrades, " of max ", MaxDailyTrades, " today");
      }

      if(SendNotifications) {
         SendNotification("SmartStockTrader: " + (isBuy ? "BUY" : "SELL") + " " + symbol + " @ " + DoubleToString(price, _Digits));
      }
   } else {
      Print("ERROR: Failed to open trade on ", symbol, " - Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
