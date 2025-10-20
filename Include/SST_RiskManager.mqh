//+------------------------------------------------------------------+
//|                                            SST_RiskManager.mqh |
//|                    Smart Stock Trader - Risk Management          |
//|         Position sizing, risk limits, and money management       |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// RISK MANAGER FUNCTIONS
//--------------------------------------------------------------------

// Calculate position size based on risk percentage and stop loss
double Risk_CalculatePositionSize(string symbol, double stopLossPips) {
   double accountBalance = AccountBalance();
   double riskAmount = accountBalance * (RiskPercentPerTrade / 100.0);

   // Apply adaptive position sizing if enabled
   if(UseAdaptivePosition) {
      // Increase size after consecutive wins
      if(g_ConsecutiveWins >= StreakThreshold) {
         riskAmount *= WinStreakMultiplier;
         if(DebugMode) Print("Increasing position size due to ", g_ConsecutiveWins, " consecutive wins");
      }

      // Decrease size after consecutive losses
      if(g_ConsecutiveLosses >= StreakThreshold) {
         riskAmount /= LoseStreakDivisor;
         if(DebugMode) Print("Decreasing position size due to ", g_ConsecutiveLosses, " consecutive losses");
      }
   }

   // Apply recovery mode reduction if active
   if(g_RecoveryModeActive && UseRecoveryMode) {
      riskAmount = accountBalance * (RecoveryRiskPercent / 100.0);
      if(DebugMode) Print("Recovery mode active - using reduced risk: ", RecoveryRiskPercent, "%");
   }

   // Get symbol specifications
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double tickSize = MarketInfo(symbol, MODE_TICKSIZE);
   double point = MarketInfo(symbol, MODE_POINT);

   if(tickSize <= 0) tickSize = point;
   if(tickValue <= 0) tickValue = 1.0;

   // Calculate pip value (for stocks, this is typically point value)
   double pipValue = tickValue * (point / tickSize);
   if(pipValue <= 0) pipValue = 1.0;

   // Calculate lot size
   double riskPerPip = riskAmount / stopLossPips;
   double lotSize = riskPerPip / pipValue;

   // Round to lot step
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);

   if(lotStep > 0) {
      lotSize = MathFloor(lotSize / lotStep) * lotStep;
   }

   // Apply limits
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;

   return NormalizeDouble(lotSize, 2);
}

// Calculate dynamic stop loss based on ATR
double Risk_CalculateStopLoss(string symbol, int timeframe, bool isBuy) {
   double stopDistance = 0;

   if(UseATRStops) {
      double atr = iATR(symbol, timeframe, ATR_Period, 0);
      double point = MarketInfo(symbol, MODE_POINT);
      stopDistance = (atr / point) * ATRMultiplierSL;
   } else {
      stopDistance = FixedStopLossPips;
   }

   double currentPrice = isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   double point = MarketInfo(symbol, MODE_POINT);

   double stopLevel;
   if(isBuy) {
      stopLevel = currentPrice - (stopDistance * point);
   } else {
      stopLevel = currentPrice + (stopDistance * point);
   }

   return NormalizeDouble(stopLevel, _Digits);
}

// Calculate dynamic take profit based on ATR
double Risk_CalculateTakeProfit(string symbol, int timeframe, bool isBuy) {
   double tpDistance = 0;

   if(UseATRStops) {
      double atr = iATR(symbol, timeframe, ATR_Period, 0);
      double point = MarketInfo(symbol, MODE_POINT);
      tpDistance = (atr / point) * ATRMultiplierTP;
   } else {
      tpDistance = FixedTakeProfitPips;
   }

   double currentPrice = isBuy ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
   double point = MarketInfo(symbol, MODE_POINT);

   double tpLevel;
   if(isBuy) {
      tpLevel = currentPrice + (tpDistance * point);
   } else {
      tpLevel = currentPrice - (tpDistance * point);
   }

   return NormalizeDouble(tpLevel, _Digits);
}

// Check if daily loss limit has been breached
bool Risk_CheckDailyLossLimit() {
   double currentEquity = AccountEquity();
   double dailyPL = currentEquity - g_DailyStartEquity;
   double dailyLossPct = (dailyPL / g_DailyStartEquity) * 100.0;

   if(dailyLossPct <= -MaxDailyLossPercent) {
      g_EAState = STATE_SUSPENDED;
      Print("DAILY LOSS LIMIT BREACHED: ", DoubleToString(dailyLossPct, 2), "% loss");

      if(SendNotifications) {
         SendNotification("Smart Stock Trader: Daily loss limit reached (" +
                         DoubleToString(dailyLossPct, 2) + "%). Trading suspended.");
      }

      return true;
   }

   return false;
}

// Check if maximum positions limit reached
bool Risk_CheckMaxPositions(string symbol = "") {
   int totalPositions = 0;
   int symbolPositions = 0;

   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            totalPositions++;
            if(symbol != "" && OrderSymbol() == symbol) {
               symbolPositions++;
            }
         }
      }
   }

   // Check total positions
   if(totalPositions >= MaxTotalPositions) {
      if(DebugMode) Print("Max total positions reached: ", totalPositions);
      return true;
   }

   // Check per-symbol positions
   if(symbol != "" && symbolPositions >= MaxPositionsPerStock) {
      if(DebugMode) Print("Max positions for ", symbol, " reached: ", symbolPositions);
      return true;
   }

   return false;
}

// Calculate correlation between two symbols
double Risk_CalculateCorrelation(string sym1, string sym2, int period = 100) {
   double prices1[], prices2[];
   ArrayResize(prices1, period);
   ArrayResize(prices2, period);

   // Get price data
   for(int i = 0; i < period; i++) {
      prices1[i] = iClose(sym1, PERIOD_H1, i);
      prices2[i] = iClose(sym2, PERIOD_H1, i);

      if(prices1[i] == 0 || prices2[i] == 0) return 0;
   }

   // Calculate returns
   double returns1[], returns2[];
   ArrayResize(returns1, period - 1);
   ArrayResize(returns2, period - 1);

   double mean1 = 0, mean2 = 0;
   for(int i = 0; i < period - 1; i++) {
      returns1[i] = (prices1[i] - prices1[i + 1]) / prices1[i + 1];
      returns2[i] = (prices2[i] - prices2[i + 1]) / prices2[i + 1];
      mean1 += returns1[i];
      mean2 += returns2[i];
   }
   mean1 /= (period - 1);
   mean2 /= (period - 1);

   // Calculate correlation
   double numerator = 0, denom1 = 0, denom2 = 0;
   for(int i = 0; i < period - 1; i++) {
      double diff1 = returns1[i] - mean1;
      double diff2 = returns2[i] - mean2;
      numerator += diff1 * diff2;
      denom1 += diff1 * diff1;
      denom2 += diff2 * diff2;
   }

   if(denom1 > 0 && denom2 > 0) {
      return numerator / MathSqrt(denom1 * denom2);
   }

   return 0;
}

// Check if symbol is correlated with existing positions
bool Risk_IsCorrelatedPosition(string symbol) {
   if(!UseCorrelationFilter) return false;

   // Check cache first
   for(int i = 0; i < ArraySize(g_CorrelationCache); i++) {
      if((g_CorrelationCache[i].sym1 == symbol || g_CorrelationCache[i].sym2 == symbol) &&
         (TimeCurrent() - g_CorrelationCache[i].calculated) < g_CorrelationCacheExpiry) {

         // Check if there's an open position in the correlated symbol
         string correlatedSym = (g_CorrelationCache[i].sym1 == symbol) ?
                                g_CorrelationCache[i].sym2 : g_CorrelationCache[i].sym1;

         for(int j = 0; j < OrdersTotal(); j++) {
            if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
               if(OrderMagicNumber() == MagicNumber && OrderSymbol() == correlatedSym) {
                  if(MathAbs(g_CorrelationCache[i].correlation) > MaxCorrelation) {
                     if(DebugMode) Print("Skipping ", symbol, " - correlated with ", correlatedSym,
                                       " (correlation: ", DoubleToString(g_CorrelationCache[i].correlation, 2), ")");
                     return true;
                  }
               }
            }
         }
      }
   }

   // Calculate new correlations
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            string openSymbol = OrderSymbol();
            if(openSymbol != symbol) {
               double corr = Risk_CalculateCorrelation(symbol, openSymbol, 100);

               // Cache the result
               CorrelationData cd;
               cd.sym1 = symbol;
               cd.sym2 = openSymbol;
               cd.correlation = corr;
               cd.calculated = TimeCurrent();

               int size = ArraySize(g_CorrelationCache);
               ArrayResize(g_CorrelationCache, size + 1);
               g_CorrelationCache[size] = cd;

               // Check if correlated
               if(MathAbs(corr) > MaxCorrelation) {
                  if(DebugMode) Print("Skipping ", symbol, " - correlated with ", openSymbol,
                                    " (correlation: ", DoubleToString(corr, 2), ")");
                  return true;
               }
            }
         }
      }
   }

   return false;
}

// Check spread filter
bool Risk_CheckSpread(string symbol) {
   if(!UseSpreadFilter) return true;

   double spread = MarketInfo(symbol, MODE_SPREAD);
   double point = MarketInfo(symbol, MODE_POINT);
   double spreadPips = spread * point * 10.0; // Convert to pips

   if(spreadPips > MaxSpreadPips) {
      if(DebugMode) Print("Spread too high for ", symbol, ": ", DoubleToString(spreadPips, 1), " pips");
      return false;
   }

   return true;
}

// Check volatility filter
bool Risk_CheckVolatility(string symbol, int timeframe) {
   if(!UseVolatilityFilter) return true;

   double atr = iATR(symbol, timeframe, ATR_Period, 0);

   if(atr < MinATRValue) {
      if(DebugMode) Print("ATR too low for ", symbol, ": ", DoubleToString(atr, 4));
      return false;
   }

   return true;
}

// Update recovery mode status
void Risk_UpdateRecoveryMode() {
   if(!UseRecoveryMode) {
      g_RecoveryModeActive = false;
      return;
   }

   if(g_ConsecutiveLosses >= RecoveryAfterLosses) {
      if(!g_RecoveryModeActive) {
         g_RecoveryModeActive = true;
         g_EAState = STATE_RECOVERY;
         Print("RECOVERY MODE ACTIVATED after ", g_ConsecutiveLosses, " consecutive losses");

         if(SendNotifications) {
            SendNotification("Smart Stock Trader: Recovery mode activated. Risk reduced to " +
                           DoubleToString(RecoveryRiskPercent, 1) + "%");
         }
      }
   } else {
      if(g_RecoveryModeActive && g_ConsecutiveWins >= 2) {
         g_RecoveryModeActive = false;
         g_EAState = STATE_READY;
         Print("RECOVERY MODE DEACTIVATED after ", g_ConsecutiveWins, " consecutive wins");

         if(SendNotifications) {
            SendNotification("Smart Stock Trader: Recovery mode deactivated. Normal risk resumed.");
         }
      }
   }
}

// Initialize risk manager
void Risk_Init() {
   Print("=== Risk Manager Initialized ===");
   Print("Risk per trade: ", RiskPercentPerTrade, "%");
   Print("Max daily loss: ", MaxDailyLossPercent, "%");
   Print("Max positions: ", MaxTotalPositions);
   Print("Adaptive position sizing: ", UseAdaptivePosition ? "Enabled" : "Disabled");
   Print("Recovery mode: ", UseRecoveryMode ? "Enabled" : "Disabled");
}

//+------------------------------------------------------------------+
