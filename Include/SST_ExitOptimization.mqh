//+------------------------------------------------------------------+
//|                                    SST_ExitOptimization.mqh      |
//|           Smart Stock Trader - Advanced Exit Management          |
//|  Dynamic trailing, structure-based exits, time-based, profit lock|
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// EXIT OPTIMIZATION PARAMETERS
//--------------------------------------------------------------------
extern bool    UseAdvancedExits      = true;         // Enable advanced exit logic
extern bool    UseStructureExits     = true;         // Exit at S/R levels
extern bool    UseTimeBasedExits     = true;         // Exit if trade open too long
extern int     MaxHoursInTrade       = 8;            // Max hours before forced exit
extern bool    UseProfitLock         = true;         // Lock in profits at milestones
extern double  ProfitLockLevel1      = 1.0;          // Lock at 1R (risk:reward)
extern double  ProfitLockLevel2      = 2.0;          // Lock at 2R
extern double  ProfitLockPercent     = 50.0;         // Lock in 50% of profit
extern bool    UseVolatilityTrailing = true;         // Trail based on current volatility
extern bool    ExitOnReversal        = true;         // Exit on pattern reversal
extern bool    ExitBeforeNews        = true;         // Close before major news

//--------------------------------------------------------------------
// DYNAMIC TRAILING STOP MANAGEMENT
//--------------------------------------------------------------------
double ExitOpt_CalculateTrailingDistance(string symbol, int timeframe, bool isBuy, double entryPrice, double currentPrice) {
   if(!UseAdvancedExits) {
      // Use standard ATR-based trailing
      double atr = iATR(symbol, timeframe, 14, 0);
      return atr * 2.0;
   }

   // ADVANCED: Adjust trailing based on profit level and volatility
   double point = MarketInfo(symbol, MODE_POINT);
   double profitPips = MathAbs(currentPrice - entryPrice) / (point * 10.0);
   double atr = iATR(symbol, timeframe, 14, 0);
   double atrPips = atr / (point * 10.0);

   // Start with base ATR distance
   double trailDistance = atrPips * 2.0;

   // Adjust based on profit level
   if(profitPips > atrPips * 3.0) {
      // At 3x ATR profit, tighten to 1.5x ATR
      trailDistance = atrPips * 1.5;
      if(VerboseLogging) Print("📌 Profit at 3R - tightening trail to 1.5x ATR");
   } else if(profitPips > atrPips * 5.0) {
      // At 5x ATR profit, tighten to 1x ATR
      trailDistance = atrPips * 1.0;
      if(VerboseLogging) Print("📌 Profit at 5R - tightening trail to 1x ATR");
   }

   // Adjust for current volatility regime
   if(UseVolatilityTrailing) {
      double volMultiplier = Volatility_GetSLMultiplier(symbol, timeframe);
      trailDistance *= volMultiplier;
   }

   return trailDistance * point * 10.0;
}

//--------------------------------------------------------------------
// CHECK IF NEAR MAJOR STRUCTURE (S/R level)
//--------------------------------------------------------------------
bool ExitOpt_IsNearStructure(string symbol, double currentPrice, bool isBuy) {
   if(!UseStructureExits) return false;

   // Check if price is near major S/R level
   // Would use SST_MarketStructure.mqh SRLevel data

   // Simplified: Check if near round numbers (psychological levels)
   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);

   // Round to nearest 0.50 or 1.00 level
   double roundLevel = MathRound(currentPrice * 2) / 2.0;
   double distanceToLevel = MathAbs(currentPrice - roundLevel);

   // If within 10 pips of round number
   if(distanceToLevel < 10 * point * 10.0) {
      if(VerboseLogging) Print("🎯 Near structure level: ", DoubleToString(roundLevel, digits),
                               " (distance: ", DoubleToString(distanceToLevel / point / 10.0, 1), " pips)");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// CHECK TIME-BASED EXIT
//--------------------------------------------------------------------
bool ExitOpt_ShouldExitByTime(datetime entryTime) {
   if(!UseTimeBasedExits) return false;

   int hoursOpen = (int)((TimeCurrent() - entryTime) / 3600);

   if(hoursOpen >= MaxHoursInTrade) {
      if(VerboseLogging) Print("⏰ Trade open for ", hoursOpen, " hours - time-based exit triggered");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// CALCULATE PROFIT LOCK LEVEL
//--------------------------------------------------------------------
double ExitOpt_GetProfitLockStop(double entryPrice, double initialSL, double currentPrice, bool isBuy) {
   if(!UseProfitLock) return 0;

   double point = MarketInfo(Symbol(), MODE_POINT);
   double risk = MathAbs(entryPrice - initialSL);

   // Calculate R-multiple (how many times initial risk)
   double profitDistance = isBuy ? (currentPrice - entryPrice) : (entryPrice - currentPrice);
   double rMultiple = profitDistance / risk;

   double lockPrice = 0;

   // Lock profit at milestones
   if(rMultiple >= ProfitLockLevel2) {
      // Lock 50% of profit at 2R
      double profitToLock = profitDistance * (ProfitLockPercent / 100.0);
      lockPrice = isBuy ? (entryPrice + profitToLock) : (entryPrice - profitToLock);

      if(VerboseLogging) Print("🔒 Profit Lock Level 2 (2R) - Locking 50% at ",
                               DoubleToString(lockPrice, _Digits));
   } else if(rMultiple >= ProfitLockLevel1) {
      // Move to break-even at 1R
      lockPrice = entryPrice;

      if(VerboseLogging) Print("🔒 Profit Lock Level 1 (1R) - Moving to break-even");
   }

   return lockPrice;
}

//--------------------------------------------------------------------
// CHECK REVERSAL PATTERN (Exit signal)
//--------------------------------------------------------------------
bool ExitOpt_DetectReversal(string symbol, int timeframe, bool isLongPosition) {
   if(!ExitOnReversal) return false;

   // Check for reversal candlestick patterns
   // For LONG positions, look for bearish reversals
   // For SHORT positions, look for bullish reversals

   double open1 = iOpen(symbol, timeframe, 1);
   double high1 = iHigh(symbol, timeframe, 1);
   double low1 = iLow(symbol, timeframe, 1);
   double close1 = iClose(symbol, timeframe, 1);

   double open2 = iOpen(symbol, timeframe, 2);
   double close2 = iClose(symbol, timeframe, 2);

   if(isLongPosition) {
      // Check for bearish engulfing
      bool bearishEngulfing = (close2 > open2) && // Previous candle bullish
                             (open1 > close1) &&  // Current candle bearish
                             (open1 >= close2) && // Opens at/above previous close
                             (close1 <= open2);   // Closes at/below previous open

      if(bearishEngulfing) {
         if(VerboseLogging) Print("🔄 Bearish Engulfing detected - reversal signal for LONG");
         return true;
      }

      // Check for shooting star
      double body = MathAbs(close1 - open1);
      double upperShadow = high1 - MathMax(open1, close1);
      double lowerShadow = MathMin(open1, close1) - low1;

      bool shootingStar = (upperShadow > body * 2.0) && (lowerShadow < body * 0.3) && (close1 < open1);

      if(shootingStar) {
         if(VerboseLogging) Print("🔄 Shooting Star detected - reversal signal for LONG");
         return true;
      }
   } else {
      // Check for bullish engulfing (exit SHORT)
      bool bullishEngulfing = (close2 < open2) && // Previous candle bearish
                             (open1 < close1) &&  // Current candle bullish
                             (open1 <= close2) && // Opens at/below previous close
                             (close1 >= open2);   // Closes at/above previous open

      if(bullishEngulfing) {
         if(VerboseLogging) Print("🔄 Bullish Engulfing detected - reversal signal for SHORT");
         return true;
      }

      // Check for hammer
      double body = MathAbs(close1 - open1);
      double upperShadow = high1 - MathMax(open1, close1);
      double lowerShadow = MathMin(open1, close1) - low1;

      bool hammer = (lowerShadow > body * 2.0) && (upperShadow < body * 0.3) && (close1 > open1);

      if(hammer) {
         if(VerboseLogging) Print("🔄 Hammer detected - reversal signal for SHORT");
         return true;
      }
   }

   return false;
}

//--------------------------------------------------------------------
// CHECK IF SHOULD EXIT BEFORE NEWS
//--------------------------------------------------------------------
bool ExitOpt_ShouldExitBeforeNews() {
   if(!ExitBeforeNews) return false;

   // Check if major news in next 30 minutes
   // Uses SST_NewsFilter.mqh
   if(News_IsNewsTime()) {
      if(VerboseLogging) Print("📰 Major news approaching - exiting positions");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// GET EXIT RECOMMENDATION (Main decision function)
//--------------------------------------------------------------------
bool ExitOpt_ShouldExit(int ticket, string symbol, int timeframe, bool isLong, double entryPrice,
                       double currentPrice, datetime entryTime, double currentSL) {
   if(!UseAdvancedExits) return false;

   // Check 1: Time-based exit
   if(ExitOpt_ShouldExitByTime(entryTime)) {
      Print("⏰ EXIT SIGNAL: Time-based (", MaxHoursInTrade, " hours)");
      return true;
   }

   // Check 2: Near structure (take profit at resistance/support)
   if(ExitOpt_IsNearStructure(symbol, currentPrice, isLong)) {
      // Only exit if in profit
      double profitPips = isLong ? (currentPrice - entryPrice) : (entryPrice - currentPrice);
      if(profitPips > 0) {
         Print("🎯 EXIT SIGNAL: Near major structure level");
         return true;
      }
   }

   // Check 3: Reversal pattern
   if(ExitOpt_DetectReversal(symbol, timeframe, isLong)) {
      Print("🔄 EXIT SIGNAL: Reversal pattern detected");
      return true;
   }

   // Check 4: News approaching
   if(ExitOpt_ShouldExitBeforeNews()) {
      Print("📰 EXIT SIGNAL: Major news approaching");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// UPDATE TRAILING STOP (Advanced logic)
//--------------------------------------------------------------------
bool ExitOpt_UpdateTrailingStop(int ticket, string symbol, int timeframe) {
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return false;

   bool isLong = (OrderType() == OP_BUY);
   double entryPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();
   double currentPrice = isLong ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);

   // Calculate new trailing distance
   double trailDistance = ExitOpt_CalculateTrailingDistance(symbol, timeframe, isLong, entryPrice, currentPrice);

   // Calculate new SL
   double newSL = isLong ? (currentPrice - trailDistance) : (currentPrice + trailDistance);
   newSL = NormalizeDouble(newSL, _Digits);

   // Check profit lock
   double lockSL = ExitOpt_GetProfitLockStop(entryPrice, OrderStopLoss(), currentPrice, isLong);
   if(lockSL > 0) {
      if(isLong && lockSL > newSL) newSL = lockSL;
      if(!isLong && lockSL < newSL) newSL = lockSL;
   }

   // Only move SL if it's better than current
   bool shouldUpdate = false;

   if(isLong && newSL > currentSL && newSL < currentPrice) {
      shouldUpdate = true;
   } else if(!isLong && (currentSL == 0 || newSL < currentSL) && newSL > currentPrice) {
      shouldUpdate = true;
   }

   if(shouldUpdate) {
      if(OrderModify(ticket, entryPrice, newSL, OrderTakeProfit(), 0, clrYellow)) {
         Print("✅ Trailing stop updated for #", ticket, ": ", DoubleToString(newSL, _Digits));
         return true;
      }
   }

   return false;
}

//--------------------------------------------------------------------
// CALCULATE OPTIMAL EXIT PRICE (Advanced)
//--------------------------------------------------------------------
double ExitOpt_GetOptimalExitPrice(string symbol, bool isLong) {
   // Find optimal exit based on structure, volatility, and market conditions

   double currentPrice = isLong ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
   double atr = iATR(symbol, PERIOD_H1, 14, 0);

   // Default: 2x ATR target
   double targetDistance = atr * 2.0;

   // Adjust for volatility regime
   VOLATILITY_REGIME volRegime = Volatility_GetRegime(symbol, PERIOD_H1);

   if(volRegime == VOL_HIGH || volRegime == VOL_VERY_HIGH) {
      targetDistance = atr * 3.0; // Wider targets in volatile markets
   } else if(volRegime == VOL_LOW || volRegime == VOL_VERY_LOW) {
      targetDistance = atr * 1.5; // Tighter targets in quiet markets
   }

   // Calculate target price
   double targetPrice = isLong ? (currentPrice + targetDistance) : (currentPrice - targetDistance);

   return NormalizeDouble(targetPrice, _Digits);
}

//--------------------------------------------------------------------
// GET EXIT STATUS STRING (for dashboard)
//--------------------------------------------------------------------
string ExitOpt_GetStatusString(int ticket) {
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return "No order";

   string status = "";
   bool isLong = (OrderType() == OP_BUY);
   double currentPrice = isLong ? MarketInfo(OrderSymbol(), MODE_BID) : MarketInfo(OrderSymbol(), MODE_ASK);
   double profitPips = isLong ? (currentPrice - OrderOpenPrice()) : (OrderOpenPrice() - currentPrice);
   profitPips /= (MarketInfo(OrderSymbol(), MODE_POINT) * 10.0);

   status += "Profit: " + DoubleToString(profitPips, 1) + " pips\n";

   // Calculate R-multiple
   double risk = MathAbs(OrderOpenPrice() - OrderStopLoss());
   if(risk > 0) {
      double profit = MathAbs(currentPrice - OrderOpenPrice());
      double rMultiple = profit / risk;
      status += "R-Multiple: " + DoubleToString(rMultiple, 2) + "R\n";
   }

   // Time in trade
   int hoursOpen = (int)((TimeCurrent() - OrderOpenTime()) / 3600);
   status += "Time: " + IntegerToString(hoursOpen) + "h / " + IntegerToString(MaxHoursInTrade) + "h max";

   return status;
}

//+------------------------------------------------------------------+
