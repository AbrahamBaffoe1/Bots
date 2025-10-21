//+------------------------------------------------------------------+
//|                                   SST_DrawdownProtection.mqh     |
//|        Smart Stock Trader - Drawdown Protection & Recovery       |
//|   Adaptive position sizing, recovery mode, equity curve health   |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// DRAWDOWN PROTECTION PARAMETERS
//--------------------------------------------------------------------
extern bool    UseDrawdownProtection = true;         // Enable drawdown protection
extern double  DrawdownLevel1        = 5.0;          // First drawdown threshold (%)
extern double  DrawdownLevel2        = 10.0;         // Second drawdown threshold (%)
extern double  DrawdownLevel3        = 15.0;         // Critical drawdown threshold (%)
extern double  SizeReductionLevel1   = 0.75;         // Reduce to 75% at Level 1
extern double  SizeReductionLevel2   = 0.50;         // Reduce to 50% at Level 2
extern double  SizeReductionLevel3   = 0.25;         // Reduce to 25% at Level 3
extern double  StopTradingDrawdown   = 20.0;         // Stop all trading at this drawdown (%)
extern bool    UseRecoveryMode       = true;         // Enable recovery mode after losses
extern int     ConsecutiveLossLimit  = 3;            // Enter recovery after X losses
extern double  RecoveryMultiplier    = 0.50;         // Trade half size in recovery
extern int     RecoveryWinsRequired  = 2;            // Wins needed to exit recovery

//--------------------------------------------------------------------
// EQUITY CURVE HEALTH PARAMETERS
//--------------------------------------------------------------------
extern bool    UseEquityCurveFilter  = true;         // Filter trades based on equity health
extern int     EquityCurvePeriod     = 20;           // Lookback period for equity analysis
extern double  MinEquityCurveSlope   = 0.0;          // Min slope to allow trading

//--------------------------------------------------------------------
// GLOBAL VARIABLES
//--------------------------------------------------------------------
double   g_HighWaterMark = 0;                        // Peak equity
double   g_CurrentDrawdown = 0;                      // Current drawdown %
double   g_MaxDrawdown = 0;                          // Max drawdown ever
int      g_ConsecutiveLosses = 0;                    // Current loss streak
int      g_ConsecutiveWins = 0;                      // Current win streak
bool     g_InRecoveryMode = false;                   // Recovery mode flag
datetime g_RecoveryStartTime = 0;                    // When recovery started
double   g_RecoveryStartEquity = 0;                  // Equity at recovery start
double   g_EquitySMA[];                              // Equity curve moving average
int      g_EquityDataPoints = 0;                     // Number of equity snapshots

//--------------------------------------------------------------------
// INITIALIZE DRAWDOWN PROTECTION
//--------------------------------------------------------------------
void Drawdown_Init() {
   g_HighWaterMark = AccountEquity();
   g_CurrentDrawdown = 0;
   g_MaxDrawdown = 0;
   g_ConsecutiveLosses = 0;
   g_ConsecutiveWins = 0;
   g_InRecoveryMode = false;

   ArrayResize(g_EquitySMA, EquityCurvePeriod);
   ArrayInitialize(g_EquitySMA, AccountEquity());
   g_EquityDataPoints = 1;

   Print("🛡️ Drawdown Protection initialized");
   Print("   High Water Mark: $", DoubleToString(g_HighWaterMark, 2));
}

//--------------------------------------------------------------------
// UPDATE DRAWDOWN STATS (Call every tick)
//--------------------------------------------------------------------
void Drawdown_Update() {
   double currentEquity = AccountEquity();

   // Update high water mark
   if(currentEquity > g_HighWaterMark) {
      g_HighWaterMark = currentEquity;

      // Exit recovery mode if we hit new high
      if(g_InRecoveryMode) {
         g_InRecoveryMode = false;
         Print("✅ RECOVERY COMPLETE - New equity high: $", DoubleToString(currentEquity, 2));
      }
   }

   // Calculate current drawdown
   if(g_HighWaterMark > 0) {
      g_CurrentDrawdown = ((g_HighWaterMark - currentEquity) / g_HighWaterMark) * 100.0;
   }

   // Update max drawdown
   if(g_CurrentDrawdown > g_MaxDrawdown) {
      g_MaxDrawdown = g_CurrentDrawdown;
      Print("⚠️ New max drawdown: ", DoubleToString(g_MaxDrawdown, 2), "%");
   }

   // Update equity curve data
   Drawdown_UpdateEquityCurve(currentEquity);
}

//--------------------------------------------------------------------
// UPDATE EQUITY CURVE TRACKING
//--------------------------------------------------------------------
void Drawdown_UpdateEquityCurve(double currentEquity) {
   // Add new equity point
   if(g_EquityDataPoints < EquityCurvePeriod) {
      g_EquitySMA[g_EquityDataPoints] = currentEquity;
      g_EquityDataPoints++;
   } else {
      // Shift array and add new point
      for(int i = 0; i < EquityCurvePeriod - 1; i++) {
         g_EquitySMA[i] = g_EquitySMA[i + 1];
      }
      g_EquitySMA[EquityCurvePeriod - 1] = currentEquity;
   }
}

//--------------------------------------------------------------------
// GET POSITION SIZE MULTIPLIER BASED ON DRAWDOWN
//--------------------------------------------------------------------
double Drawdown_GetSizeMultiplier() {
   if(!UseDrawdownProtection) return 1.0;

   // Recovery mode override
   if(g_InRecoveryMode && UseRecoveryMode) {
      if(VerboseLogging) Print("🔧 Recovery mode active - size reduced to ",
                               DoubleToString(RecoveryMultiplier * 100, 0), "%");
      return RecoveryMultiplier;
   }

   // Drawdown-based reduction
   if(g_CurrentDrawdown >= DrawdownLevel3) {
      if(VerboseLogging) Print("🔴 Drawdown Level 3 (", DoubleToString(g_CurrentDrawdown, 1),
                               "%) - size reduced to ", DoubleToString(SizeReductionLevel3 * 100, 0), "%");
      return SizeReductionLevel3;
   } else if(g_CurrentDrawdown >= DrawdownLevel2) {
      if(VerboseLogging) Print("🟡 Drawdown Level 2 (", DoubleToString(g_CurrentDrawdown, 1),
                               "%) - size reduced to ", DoubleToString(SizeReductionLevel2 * 100, 0), "%");
      return SizeReductionLevel2;
   } else if(g_CurrentDrawdown >= DrawdownLevel1) {
      if(VerboseLogging) Print("🟠 Drawdown Level 1 (", DoubleToString(g_CurrentDrawdown, 1),
                               "%) - size reduced to ", DoubleToString(SizeReductionLevel1 * 100, 0), "%");
      return SizeReductionLevel1;
   }

   return 1.0; // Normal size
}

//--------------------------------------------------------------------
// CHECK IF TRADING SHOULD STOP (Critical drawdown)
//--------------------------------------------------------------------
bool Drawdown_ShouldStopTrading() {
   if(!UseDrawdownProtection) return false;

   if(g_CurrentDrawdown >= StopTradingDrawdown) {
      if(VerboseLogging) Print("🛑 CRITICAL DRAWDOWN (", DoubleToString(g_CurrentDrawdown, 1),
                               "%) - ALL TRADING STOPPED");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// RECORD TRADE RESULT (Update win/loss streaks)
//--------------------------------------------------------------------
void Drawdown_RecordTrade(bool isWin, double profit) {
   if(isWin) {
      g_ConsecutiveWins++;
      g_ConsecutiveLosses = 0;

      // Check if exiting recovery mode
      if(g_InRecoveryMode && g_ConsecutiveWins >= RecoveryWinsRequired) {
         double recoveryProfit = AccountEquity() - g_RecoveryStartEquity;
         Print("✅ Exiting Recovery Mode after ", g_ConsecutiveWins, " wins");
         Print("   Recovery P/L: $", DoubleToString(recoveryProfit, 2));
         g_InRecoveryMode = false;
      }
   } else {
      g_ConsecutiveLosses++;
      g_ConsecutiveWins = 0;

      // Check if entering recovery mode
      if(UseRecoveryMode && !g_InRecoveryMode && g_ConsecutiveLosses >= ConsecutiveLossLimit) {
         g_InRecoveryMode = true;
         g_RecoveryStartTime = TimeCurrent();
         g_RecoveryStartEquity = AccountEquity();

         Print("⚠️ ENTERING RECOVERY MODE after ", g_ConsecutiveLosses, " consecutive losses");
         Print("   Position size reduced to ", DoubleToString(RecoveryMultiplier * 100, 0), "%");
         Print("   Need ", RecoveryWinsRequired, " consecutive wins to exit recovery");
      }
   }

   if(VerboseLogging) {
      Print("📊 Trade streak: ", g_ConsecutiveWins, " wins, ", g_ConsecutiveLosses, " losses");
   }
}

//--------------------------------------------------------------------
// GET EQUITY CURVE SLOPE (Positive = uptrend, Negative = downtrend)
//--------------------------------------------------------------------
double Drawdown_GetEquityCurveSlope() {
   if(g_EquityDataPoints < 2) return 0;

   // Simple linear regression
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   int n = MathMin(g_EquityDataPoints, EquityCurvePeriod);

   for(int i = 0; i < n; i++) {
      double x = i;
      double y = g_EquitySMA[i];

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
   }

   double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

   return slope;
}

//--------------------------------------------------------------------
// CHECK EQUITY CURVE HEALTH
//--------------------------------------------------------------------
bool Drawdown_IsEquityCurveHealthy() {
   if(!UseEquityCurveFilter) return true;

   if(g_EquityDataPoints < EquityCurvePeriod / 2) {
      return true; // Not enough data yet
   }

   double slope = Drawdown_GetEquityCurveSlope();

   // If equity curve is declining, reduce/stop trading
   if(slope < MinEquityCurveSlope) {
      if(VerboseLogging) Print("📉 Equity curve declining (slope: ", DoubleToString(slope, 2),
                               ") - trading filtered");
      return false;
   }

   return true;
}

//--------------------------------------------------------------------
// GET RECOVERY MODE STATUS STRING
//--------------------------------------------------------------------
string Drawdown_GetRecoveryStatus() {
   if(!g_InRecoveryMode) return "Normal Trading";

   int daysInRecovery = (int)((TimeCurrent() - g_RecoveryStartTime) / 86400);
   double recoveryPL = AccountEquity() - g_RecoveryStartEquity;

   string status = "🔧 RECOVERY MODE\n";
   status += "Duration: " + IntegerToString(daysInRecovery) + " days\n";
   status += "Recovery P/L: $" + DoubleToString(recoveryPL, 2) + "\n";
   status += "Wins needed: " + IntegerToString(RecoveryWinsRequired - g_ConsecutiveWins);

   return status;
}

//--------------------------------------------------------------------
// GET DRAWDOWN STATUS STRING (for dashboard)
//--------------------------------------------------------------------
string Drawdown_GetStatusString() {
   string status = "💧 Drawdown: " + DoubleToString(g_CurrentDrawdown, 2) + "%\n";
   status += "Max DD: " + DoubleToString(g_MaxDrawdown, 2) + "%\n";
   status += "High Water: $" + DoubleToString(g_HighWaterMark, 2) + "\n";

   if(g_CurrentDrawdown >= DrawdownLevel3) {
      status += "🔴 Level 3 Protection (25% size)";
   } else if(g_CurrentDrawdown >= DrawdownLevel2) {
      status += "🟡 Level 2 Protection (50% size)";
   } else if(g_CurrentDrawdown >= DrawdownLevel1) {
      status += "🟠 Level 1 Protection (75% size)";
   } else {
      status += "🟢 Normal (100% size)";
   }

   if(g_InRecoveryMode) {
      status += "\n" + Drawdown_GetRecoveryStatus();
   }

   return status;
}

//--------------------------------------------------------------------
// GET RISK HEALTH SCORE (0-100)
//--------------------------------------------------------------------
double Drawdown_GetHealthScore() {
   double score = 100.0;

   // Deduct for drawdown
   score -= g_CurrentDrawdown * 2.0; // Each 1% DD = -2 points

   // Deduct for consecutive losses
   score -= g_ConsecutiveLosses * 5.0; // Each loss = -5 points

   // Deduct for recovery mode
   if(g_InRecoveryMode) score -= 20.0;

   // Deduct for negative equity curve
   double slope = Drawdown_GetEquityCurveSlope();
   if(slope < 0) score -= 10.0;

   // Cap between 0-100
   if(score < 0) score = 0;
   if(score > 100) score = 100;

   return score;
}

//--------------------------------------------------------------------
// CALCULATE OPTIMAL POSITION SIZE (Kelly Criterion)
//--------------------------------------------------------------------
double Drawdown_CalculateKellySize(double winRate, double avgWin, double avgLoss) {
   if(avgLoss <= 0 || winRate <= 0 || winRate >= 1) return 0;

   // Kelly Formula: f = (p * b - q) / b
   // where: p = win rate, q = loss rate, b = win/loss ratio

   double p = winRate;
   double q = 1.0 - winRate;
   double b = avgWin / avgLoss;

   double kellyFraction = (p * b - q) / b;

   // Use fractional Kelly (1/2 or 1/4) for safety
   kellyFraction *= 0.5; // Half Kelly

   // Cap at reasonable limits
   if(kellyFraction > 0.20) kellyFraction = 0.20; // Max 20% of capital
   if(kellyFraction < 0) kellyFraction = 0;

   return kellyFraction;
}

//--------------------------------------------------------------------
// GET RECOMMENDED POSITION SIZE (Combines all factors)
//--------------------------------------------------------------------
double Drawdown_GetRecommendedSize(double baseSize) {
   double multiplier = 1.0;

   // Apply drawdown reduction
   multiplier *= Drawdown_GetSizeMultiplier();

   // Apply equity curve filter
   if(!Drawdown_IsEquityCurveHealthy()) {
      multiplier *= 0.5; // Half size if equity declining
   }

   // Apply health score factor
   double healthScore = Drawdown_GetHealthScore();
   if(healthScore < 50) {
      multiplier *= 0.75; // Reduce if unhealthy
   }

   return baseSize * multiplier;
}

//--------------------------------------------------------------------
// EMERGENCY STOP CHECK (Multiple risk factors)
//--------------------------------------------------------------------
bool Drawdown_EmergencyStop() {
   // Stop if multiple risk factors present
   int riskFactors = 0;

   if(g_CurrentDrawdown >= 15.0) riskFactors++;
   if(g_ConsecutiveLosses >= 5) riskFactors++;
   if(!Drawdown_IsEquityCurveHealthy()) riskFactors++;
   if(Drawdown_GetHealthScore() < 30) riskFactors++;

   if(riskFactors >= 3) {
      Print("🚨 EMERGENCY STOP - Multiple risk factors detected (", riskFactors, "/4)");
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
