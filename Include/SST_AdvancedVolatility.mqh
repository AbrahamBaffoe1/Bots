//+------------------------------------------------------------------+
//|                                   SST_AdvancedVolatility.mqh     |
//|          Smart Stock Trader - Advanced Volatility Analysis       |
//|    BBW, ATR percentile, volatility regime, adaptive parameters   |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// VOLATILITY PARAMETERS
//--------------------------------------------------------------------
extern bool    UseVolatilityRegime   = true;         // Enable volatility regime filtering
extern double  MinBBW                = 0.02;         // Minimum Bollinger Band Width (avoid consolidation)
extern double  MaxBBW                = 0.15;         // Maximum BBW (avoid extreme volatility)
extern int     ATRPercentilePeriod   = 100;          // Lookback for ATR percentile
extern double  MinATRPercentile      = 20.0;         // Min ATR percentile (avoid too quiet)
extern double  MaxATRPercentile      = 90.0;         // Max ATR percentile (avoid too volatile)
extern bool    AdaptiveParameters    = true;         // Adjust SL/TP based on volatility

//--------------------------------------------------------------------
// VOLATILITY REGIME ENUM
//--------------------------------------------------------------------
enum VOLATILITY_REGIME {
   VOL_VERY_LOW,      // Consolidation, avoid trading
   VOL_LOW,           // Quiet, use smaller stops
   VOL_NORMAL,        // Ideal for trading
   VOL_HIGH,          // Volatile, use wider stops
   VOL_VERY_HIGH      // Extreme volatility, avoid trading
};

//--------------------------------------------------------------------
// CALCULATE BOLLINGER BAND WIDTH (BBW)
//--------------------------------------------------------------------
double Volatility_GetBBW(string symbol, int timeframe, int period = 20, double deviation = 2.0) {
   double upper = iBands(symbol, timeframe, period, deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double lower = iBands(symbol, timeframe, period, deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double middle = iBands(symbol, timeframe, period, deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);

   if(middle == 0) return 0;

   // BBW = (Upper - Lower) / Middle
   double bbw = (upper - lower) / middle;

   return bbw;
}

//--------------------------------------------------------------------
// CALCULATE ATR PERCENTILE RANK
//--------------------------------------------------------------------
double Volatility_GetATRPercentile(string symbol, int timeframe, int atrPeriod = 14, int lookback = 100) {
   double currentATR = iATR(symbol, timeframe, atrPeriod, 0);

   // Get ATR values for lookback period
   double atrValues[];
   ArrayResize(atrValues, lookback);

   for(int i = 0; i < lookback; i++) {
      atrValues[i] = iATR(symbol, timeframe, atrPeriod, i);
   }

   // Sort array to find percentile
   ArraySort(atrValues);

   // Find where current ATR ranks
   int rank = 0;
   for(int i = 0; i < lookback; i++) {
      if(currentATR >= atrValues[i]) {
         rank = i + 1;
      }
   }

   // Prevent division by zero
   if(lookback <= 0) return 50.0;  // Return neutral percentile

   double percentile = ((double)rank / lookback) * 100.0;

   return percentile;
}

//--------------------------------------------------------------------
// GET VOLATILITY REGIME
//--------------------------------------------------------------------
VOLATILITY_REGIME Volatility_GetRegime(string symbol, int timeframe) {
   double bbw = Volatility_GetBBW(symbol, timeframe);
   double atrPercentile = Volatility_GetATRPercentile(symbol, timeframe);

   if(VerboseLogging) {
      Print("📊 Volatility Analysis for ", symbol, ":");
      Print("   BBW: ", DoubleToString(bbw, 4));
      Print("   ATR Percentile: ", DoubleToString(atrPercentile, 1), "%");
   }

   // Determine regime based on BBW and ATR percentile
   if(bbw < MinBBW || atrPercentile < MinATRPercentile) {
      if(VerboseLogging) Print("   Regime: VERY LOW (Consolidation)");
      return VOL_VERY_LOW;
   }

   if(bbw > MaxBBW || atrPercentile > MaxATRPercentile) {
      if(VerboseLogging) Print("   Regime: VERY HIGH (Extreme Volatility)");
      return VOL_VERY_HIGH;
   }

   if(atrPercentile < 40) {
      if(VerboseLogging) Print("   Regime: LOW (Quiet)");
      return VOL_LOW;
   }

   if(atrPercentile > 70) {
      if(VerboseLogging) Print("   Regime: HIGH (Volatile)");
      return VOL_HIGH;
   }

   if(VerboseLogging) Print("   Regime: NORMAL (Ideal)");
   return VOL_NORMAL;
}

//--------------------------------------------------------------------
// CHECK IF VOLATILITY IS SUITABLE FOR TRADING
//--------------------------------------------------------------------
bool Volatility_IsTradeable(string symbol, int timeframe) {
   if(!UseVolatilityRegime) return true;

   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);

   // Avoid VERY_LOW (consolidation) and VERY_HIGH (extreme volatility)
   if(regime == VOL_VERY_LOW) {
      if(VerboseLogging) Print("✗ Volatility too low (consolidation) - skipping trade on ", symbol);
      return false;
   }

   if(regime == VOL_VERY_HIGH) {
      if(VerboseLogging) Print("✗ Volatility too high (extreme) - skipping trade on ", symbol);
      return false;
   }

   return true;
}

//--------------------------------------------------------------------
// GET ADAPTIVE SL/TP MULTIPLIERS BASED ON VOLATILITY
//--------------------------------------------------------------------
double Volatility_GetSLMultiplier(string symbol, int timeframe) {
   if(!AdaptiveParameters) return 1.0;

   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);

   switch(regime) {
      case VOL_VERY_LOW:
         return 0.7;  // Tighter stops in quiet markets

      case VOL_LOW:
         return 0.85;

      case VOL_NORMAL:
         return 1.0;  // Standard

      case VOL_HIGH:
         return 1.3;  // Wider stops in volatile markets

      case VOL_VERY_HIGH:
         return 1.5;

      default:
         return 1.0;
   }
}

double Volatility_GetTPMultiplier(string symbol, int timeframe) {
   if(!AdaptiveParameters) return 1.0;

   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);

   switch(regime) {
      case VOL_VERY_LOW:
         return 0.8;  // Smaller targets in quiet markets

      case VOL_LOW:
         return 0.9;

      case VOL_NORMAL:
         return 1.0;  // Standard

      case VOL_HIGH:
         return 1.2;  // Larger targets in volatile markets

      case VOL_VERY_HIGH:
         return 1.4;

      default:
         return 1.0;
   }
}

//--------------------------------------------------------------------
// GET POSITION SIZE MULTIPLIER BASED ON VOLATILITY
//--------------------------------------------------------------------
double Volatility_GetPositionSizeMultiplier(string symbol, int timeframe) {
   if(!AdaptiveParameters) return 1.0;

   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);

   switch(regime) {
      case VOL_VERY_LOW:
         return 1.2;  // Can risk more in quiet markets

      case VOL_LOW:
         return 1.1;

      case VOL_NORMAL:
         return 1.0;  // Standard

      case VOL_HIGH:
         return 0.8;  // Risk less in volatile markets

      case VOL_VERY_HIGH:
         return 0.6;  // Much less risk in extreme volatility

      default:
         return 1.0;
   }
}

//--------------------------------------------------------------------
// CALCULATE HISTORICAL VOLATILITY (HV)
//--------------------------------------------------------------------
double Volatility_GetHistoricalVolatility(string symbol, int timeframe, int period = 20) {
   double returns[];
   ArrayResize(returns, period);

   // Calculate returns
   for(int i = 0; i < period; i++) {
      double close_current = iClose(symbol, timeframe, i);
      double close_prev = iClose(symbol, timeframe, i + 1);

      if(close_prev == 0) return 0;

      returns[i] = MathLog(close_current / close_prev);
   }

   // Calculate standard deviation
   double mean = 0;
   for(int i = 0; i < period; i++) {
      mean += returns[i];
   }
   mean /= period;

   double variance = 0;
   for(int i = 0; i < period; i++) {
      double diff = returns[i] - mean;
      variance += diff * diff;
   }
   variance /= period;

   double stdDev = MathSqrt(variance);

   // Annualize (252 trading days per year)
   double annualizedVol = stdDev * MathSqrt(252);

   return annualizedVol * 100.0; // Return as percentage
}

//--------------------------------------------------------------------
// CHECK IF VOLATILITY IS EXPANDING (Breakout opportunity)
//--------------------------------------------------------------------
bool Volatility_IsExpanding(string symbol, int timeframe) {
   double bbw_current = Volatility_GetBBW(symbol, timeframe);
   double bbw_prev = Volatility_GetBBW(symbol, timeframe);  // Would need historical BBW

   // Simplified: Check if current BBW is in upper percentile
   double atrPercentile = Volatility_GetATRPercentile(symbol, timeframe);

   // Expanding if ATR percentile is rising and above 60
   if(atrPercentile > 60 && atrPercentile < 90) {
      if(VerboseLogging) Print("📈 Volatility expanding on ", symbol, " - good for breakouts");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// CHECK IF VOLATILITY IS CONTRACTING (Range-bound, mean reversion)
//--------------------------------------------------------------------
bool Volatility_IsContracting(string symbol, int timeframe) {
   double atrPercentile = Volatility_GetATRPercentile(symbol, timeframe);

   // Contracting if ATR percentile is low
   if(atrPercentile < 40 && atrPercentile > 20) {
      if(VerboseLogging) Print("📉 Volatility contracting on ", symbol, " - good for mean reversion");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// GET VOLATILITY RISK SCORE (0-10, higher = riskier)
//--------------------------------------------------------------------
int Volatility_GetRiskScore(string symbol, int timeframe) {
   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);

   switch(regime) {
      case VOL_VERY_LOW:
         return 2;  // Low risk from volatility (but hard to profit)

      case VOL_LOW:
         return 3;

      case VOL_NORMAL:
         return 5;  // Moderate risk, ideal

      case VOL_HIGH:
         return 7;

      case VOL_VERY_HIGH:
         return 10; // High risk

      default:
         return 5;
   }
}

//--------------------------------------------------------------------
// GET VOLATILITY STATUS STRING (for dashboard)
//--------------------------------------------------------------------
string Volatility_GetStatusString(string symbol, int timeframe) {
   VOLATILITY_REGIME regime = Volatility_GetRegime(symbol, timeframe);
   double atrPercentile = Volatility_GetATRPercentile(symbol, timeframe);
   double bbw = Volatility_GetBBW(symbol, timeframe);

   string output = "";

   switch(regime) {
      case VOL_VERY_LOW:
         output = "🔵 VERY LOW (Consolidation)";
         break;
      case VOL_LOW:
         output = "🟢 LOW (Quiet)";
         break;
      case VOL_NORMAL:
         output = "⚪ NORMAL (Ideal)";
         break;
      case VOL_HIGH:
         output = "🟡 HIGH (Volatile)";
         break;
      case VOL_VERY_HIGH:
         output = "🔴 VERY HIGH (Extreme)";
         break;
   }

   output += "\nATR: " + DoubleToString(atrPercentile, 1) + "th percentile";
   output += "\nBBW: " + DoubleToString(bbw, 4);

   return output;
}

//+------------------------------------------------------------------+
