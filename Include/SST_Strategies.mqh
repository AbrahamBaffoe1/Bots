//+------------------------------------------------------------------+
//|                                            SST_Strategies.mqh |
//|                  Smart Stock Trader - Trading Strategies         |
//|    Momentum, Mean Reversion, Breakout, Trend, Volume, Gap, MTF  |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// STRATEGY SIGNAL STRUCTURE
//--------------------------------------------------------------------
struct StrategySignal {
   bool canTrade;
   int direction; // 1 = buy, -1 = sell, 0 = no signal
   double confidence;
   string strategyName;
   double suggestedSL;
   double suggestedTP;
};

//--------------------------------------------------------------------
// 1. MOMENTUM STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_Momentum(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseMomentumStrategy;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Momentum";

   if(!UseMomentumStrategy) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);

   // Bullish momentum: RSI rising, MACD positive and rising, price above MAs
   if(ind.rsi > 50 && ind.rsi < 70 &&
      ind.macdMain > ind.macdSignal && ind.macdMain > 0 &&
      ind.isBullishMA && ind.adxPlus > ind.adxMinus) {

      sig.direction = 1;
      sig.confidence = 0.70;

      // Higher confidence if volume confirms
      if(ind.highVolume) sig.confidence += 0.15;
      if(ind.stochK > 50 && ind.stochK < 80) sig.confidence += 0.10;
   }

   // Bearish momentum
   else if(ind.rsi < 50 && ind.rsi > 30 &&
           ind.macdMain < ind.macdSignal && ind.macdMain < 0 &&
           ind.isBearishMA && ind.adxMinus > ind.adxPlus) {

      sig.direction = -1;
      sig.confidence = 0.70;

      if(ind.highVolume) sig.confidence += 0.15;
      if(ind.stochK < 50 && ind.stochK > 20) sig.confidence += 0.10;
   }

   return sig;
}

//--------------------------------------------------------------------
// 2. MEAN REVERSION STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_MeanReversion(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseMeanReversion;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Mean Reversion";

   if(!UseMeanReversion) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);
   double currentPrice = iClose(symbol, timeframe, 0);

   // Buy at lower Bollinger Band (oversold)
   if(currentPrice <= ind.bbLower && ind.isOversold) {
      sig.direction = 1;
      sig.confidence = 0.65;

      // Higher confidence if at support
      if(Structure_IsNearSupport(symbol, currentPrice)) sig.confidence += 0.15;

      // Price should be below VWAP for mean reversion
      if(currentPrice < ind.vwap) sig.confidence += 0.10;
   }

   // Sell at upper Bollinger Band (overbought)
   else if(currentPrice >= ind.bbUpper && ind.isOverbought) {
      sig.direction = -1;
      sig.confidence = 0.65;

      if(Structure_IsNearResistance(symbol, currentPrice)) sig.confidence += 0.15;
      if(currentPrice > ind.vwap) sig.confidence += 0.10;
   }

   return sig;
}

//--------------------------------------------------------------------
// 3. BREAKOUT STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_Breakout(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseBreakoutStrategy;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Breakout";

   if(!UseBreakoutStrategy) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);
   double currentPrice = iClose(symbol, timeframe, 0);

   // Find recent high
   double recentHigh = -999999;
   double recentLow = 999999;
   for(int i = 1; i <= 20; i++) {
      if(iHigh(symbol, timeframe, i) > recentHigh) recentHigh = iHigh(symbol, timeframe, i);
      if(iLow(symbol, timeframe, i) < recentLow) recentLow = iLow(symbol, timeframe, i);
   }

   // Bullish breakout
   if(currentPrice > recentHigh && ind.isTrending) {
      sig.direction = 1;
      sig.confidence = 0.70;

      // Must have volume confirmation for breakouts
      if(RequireVolumeConfirm && ind.highVolume) {
         sig.confidence += 0.15;
      } else if(!RequireVolumeConfirm) {
         sig.confidence += 0.05;
      }

      // Better if breaking resistance
      if(Structure_IsNearResistance(symbol, recentHigh)) sig.confidence += 0.10;
   }

   // Bearish breakdown
   else if(currentPrice < recentLow && ind.isTrending) {
      sig.direction = -1;
      sig.confidence = 0.70;

      if(RequireVolumeConfirm && ind.highVolume) {
         sig.confidence += 0.15;
      } else if(!RequireVolumeConfirm) {
         sig.confidence += 0.05;
      }

      if(Structure_IsNearSupport(symbol, recentLow)) sig.confidence += 0.10;
   }

   return sig;
}

//--------------------------------------------------------------------
// 4. TREND FOLLOWING STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_TrendFollowing(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseTrendFollowing;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Trend Following";

   if(!UseTrendFollowing) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);
   double currentPrice = iClose(symbol, timeframe, 0);

   // Strong uptrend
   if(ind.isBullishMA && ind.isTrending &&
      currentPrice > ind.trendMA && currentPrice > ind.vwap) {

      // Look for pullback to moving average (buy dip in uptrend)
      if(currentPrice < ind.fastMA && currentPrice > ind.slowMA) {
         sig.direction = 1;
         sig.confidence = 0.75;

         // Ichimoku confirmation
         if(currentPrice > ind.ichimokuSenkouA && currentPrice > ind.ichimokuSenkouB) {
            sig.confidence += 0.10;
         }

         // Price action confirmation
         int bullishPatterns = Pattern_GetBullishSignals(symbol, timeframe);
         if(bullishPatterns > 0) sig.confidence += 0.10;
      }
   }

   // Strong downtrend
   else if(ind.isBearishMA && ind.isTrending &&
           currentPrice < ind.trendMA && currentPrice < ind.vwap) {

      // Look for pullback to moving average (sell rally in downtrend)
      if(currentPrice > ind.fastMA && currentPrice < ind.slowMA) {
         sig.direction = -1;
         sig.confidence = 0.75;

         if(currentPrice < ind.ichimokuSenkouA && currentPrice < ind.ichimokuSenkouB) {
            sig.confidence += 0.10;
         }

         int bearishPatterns = Pattern_GetBearishSignals(symbol, timeframe);
         if(bearishPatterns > 0) sig.confidence += 0.10;
      }
   }

   return sig;
}

//--------------------------------------------------------------------
// 5. VOLUME ANALYSIS STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_Volume(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseVolumeAnalysis;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Volume Analysis";

   if(!UseVolumeAnalysis) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);

   // Volume spike with price increase (accumulation)
   if(ind.highVolume && ind.obv > 0) {
      double priceChange = iClose(symbol, timeframe, 0) - iClose(symbol, timeframe, 1);

      if(priceChange > 0 && ind.rsi > 45 && ind.rsi < 70) {
         sig.direction = 1;
         sig.confidence = 0.65;

         // Check if breaking out with volume
         double prevHigh = iHigh(symbol, timeframe, 1);
         if(iClose(symbol, timeframe, 0) > prevHigh) sig.confidence += 0.15;
      }
   }

   // Volume spike with price decrease (distribution)
   if(ind.highVolume && ind.obv < 0) {
      double priceChange = iClose(symbol, timeframe, 0) - iClose(symbol, timeframe, 1);

      if(priceChange < 0 && ind.rsi < 55 && ind.rsi > 30) {
         sig.direction = -1;
         sig.confidence = 0.65;

         double prevLow = iLow(symbol, timeframe, 1);
         if(iClose(symbol, timeframe, 0) < prevLow) sig.confidence += 0.15;
      }
   }

   return sig;
}

//--------------------------------------------------------------------
// 6. GAP TRADING STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_Gap(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseGapTrading;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Gap Trading";

   if(!UseGapTrading) return sig;

   // Only check for gaps at market open
   SESSION_TYPE session = Session_GetCurrent();
   if(session != SESSION_REGULAR && session != SESSION_PRE_MARKET) return sig;

   // Check if there's a gap
   double prevClose = iClose(symbol, PERIOD_D1, 1);
   double currentOpen = iOpen(symbol, PERIOD_D1, 0);
   double gapSize = MathAbs(currentOpen - prevClose);
   double gapPercent = (gapSize / prevClose) * 100.0;

   // Check gap size requirements
   if(gapPercent < MinGapPercent || gapPercent > MaxGapPercent) return sig;

   // Gap up
   if(currentOpen > prevClose) {
      if(FadeGaps) {
         // Fade the gap (sell/short)
         sig.direction = -1;
         sig.confidence = 0.60;
         sig.strategyName = "Gap Fade (Up)";
      } else if(FollowGaps) {
         // Follow the gap (buy)
         sig.direction = 1;
         sig.confidence = 0.55;
         sig.strategyName = "Gap Follow (Up)";
      }
   }

   // Gap down
   else if(currentOpen < prevClose) {
      if(FadeGaps) {
         // Fade the gap (buy)
         sig.direction = 1;
         sig.confidence = 0.60;
         sig.strategyName = "Gap Fade (Down)";
      } else if(FollowGaps) {
         // Follow the gap (sell/short)
         sig.direction = -1;
         sig.confidence = 0.55;
         sig.strategyName = "Gap Follow (Down)";
      }
   }

   if(DebugMode && sig.direction != 0) {
      Print("Gap detected on ", symbol, ": ", DoubleToString(gapPercent, 2), "% - Strategy: ", sig.strategyName);
   }

   return sig;
}

//--------------------------------------------------------------------
// 7. MULTI-TIMEFRAME STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_MultiTimeframe(string symbol) {
   StrategySignal sig;
   sig.canTrade = UseMultiTimeframe;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Multi-Timeframe";

   if(!UseMultiTimeframe) return sig;

   int mtfSignal = Ind_GetMultiTimeframeSignal(symbol);

   if(mtfSignal == 1) {
      sig.direction = 1;
      sig.confidence = 0.80; // High confidence when multiple timeframes align
   } else if(mtfSignal == -1) {
      sig.direction = -1;
      sig.confidence = 0.80;
   }

   return sig;
}

//--------------------------------------------------------------------
// 8. MARKET REGIME ADAPTIVE STRATEGY
//--------------------------------------------------------------------
StrategySignal Strategy_RegimeAdaptive(string symbol, int timeframe) {
   StrategySignal sig;
   sig.canTrade = UseMarketRegime;
   sig.direction = 0;
   sig.confidence = 0;
   sig.strategyName = "Regime Adaptive";

   if(!UseMarketRegime) return sig;

   IndicatorSignals ind = Ind_GetSignals(symbol, timeframe);

   // In trending markets, use trend following
   if(ind.isTrending) {
      return Strategy_TrendFollowing(symbol, timeframe);
   }

   // In ranging markets, use mean reversion
   if(ind.isRanging) {
      return Strategy_MeanReversion(symbol, timeframe);
   }

   return sig;
}

//--------------------------------------------------------------------
// COMBINE ALL STRATEGIES
//--------------------------------------------------------------------
StrategySignal Strategy_GetBestSignal(string symbol, int timeframe) {
   StrategySignal signals[8];
   signals[0] = Strategy_Momentum(symbol, timeframe);
   signals[1] = Strategy_MeanReversion(symbol, timeframe);
   signals[2] = Strategy_Breakout(symbol, timeframe);
   signals[3] = Strategy_TrendFollowing(symbol, timeframe);
   signals[4] = Strategy_Volume(symbol, timeframe);
   signals[5] = Strategy_Gap(symbol, timeframe);
   signals[6] = Strategy_MultiTimeframe(symbol);
   signals[7] = Strategy_RegimeAdaptive(symbol, timeframe);

   // Find signal with highest confidence
   StrategySignal bestSignal;
   bestSignal.direction = 0;
   bestSignal.confidence = 0;
   bestSignal.strategyName = "None";

   int bullishCount = 0;
   int bearishCount = 0;
   double totalBullishConfidence = 0;
   double totalBearishConfidence = 0;

   for(int i = 0; i < 8; i++) {
      if(signals[i].canTrade && signals[i].direction == 1) {
         bullishCount++;
         totalBullishConfidence += signals[i].confidence;

         if(signals[i].confidence > bestSignal.confidence) {
            bestSignal = signals[i];
         }
      } else if(signals[i].canTrade && signals[i].direction == -1) {
         bearishCount++;
         totalBearishConfidence += signals[i].confidence;

         if(signals[i].confidence > bestSignal.confidence) {
            bestSignal = signals[i];
         }
      }
   }

   // Require at least 2 strategies to agree for higher confidence
   if(bullishCount >= 2 && bullishCount > bearishCount) {
      bestSignal.confidence = totalBullishConfidence / bullishCount;
      bestSignal.direction = 1;
   } else if(bearishCount >= 2 && bearishCount > bullishCount) {
      bestSignal.confidence = totalBearishConfidence / bearishCount;
      bestSignal.direction = -1;
   }

   return bestSignal;
}

//+------------------------------------------------------------------+
