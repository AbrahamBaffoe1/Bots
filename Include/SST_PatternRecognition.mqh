//+------------------------------------------------------------------+
//|                                      SST_PatternRecognition.mqh |
//|                 Smart Stock Trader - Pattern Recognition         |
//|          Candlestick patterns and chart pattern detection        |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// PATTERN TYPES
//--------------------------------------------------------------------
enum PATTERN_TYPE {
   PATTERN_NONE,
   // Bullish Candlestick Patterns
   PATTERN_HAMMER,
   PATTERN_INVERTED_HAMMER,
   PATTERN_BULLISH_ENGULFING,
   PATTERN_PIERCING_LINE,
   PATTERN_MORNING_STAR,
   PATTERN_THREE_WHITE_SOLDIERS,
   // Bearish Candlestick Patterns
   PATTERN_SHOOTING_STAR,
   PATTERN_HANGING_MAN,
   PATTERN_BEARISH_ENGULFING,
   PATTERN_DARK_CLOUD_COVER,
   PATTERN_EVENING_STAR,
   PATTERN_THREE_BLACK_CROWS,
   // Neutral Patterns
   PATTERN_DOJI,
   PATTERN_SPINNING_TOP,
   // Chart Patterns
   PATTERN_DOUBLE_TOP,
   PATTERN_DOUBLE_BOTTOM,
   PATTERN_HEAD_SHOULDERS,
   PATTERN_INVERSE_HEAD_SHOULDERS
};

//--------------------------------------------------------------------
// CANDLESTICK PATTERN DETECTION
//--------------------------------------------------------------------

// Helper: Get candle body size
double Pattern_GetBodySize(string symbol, int timeframe, int shift) {
   double open = iOpen(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);
   return MathAbs(close - open);
}

// Helper: Get candle range
double Pattern_GetCandleRange(string symbol, int timeframe, int shift) {
   double high = iHigh(symbol, timeframe, shift);
   double low = iLow(symbol, timeframe, shift);
   return high - low;
}

// Helper: Is bullish candle
bool Pattern_IsBullish(string symbol, int timeframe, int shift) {
   return iClose(symbol, timeframe, shift) > iOpen(symbol, timeframe, shift);
}

// Detect Hammer pattern
double Pattern_DetectHammer(string symbol, int timeframe, int shift) {
   double open = iOpen(symbol, timeframe, shift);
   double high = iHigh(symbol, timeframe, shift);
   double low = iLow(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);

   double body = Pattern_GetBodySize(symbol, timeframe, shift);
   double range = Pattern_GetCandleRange(symbol, timeframe, shift);

   if(range == 0) return 0;

   double lowerShadow = MathMin(open, close) - low;
   double upperShadow = high - MathMax(open, close);

   // Hammer criteria: small body, long lower shadow, little/no upper shadow
   if(body < range * 0.3 &&
      lowerShadow > body * 2.0 &&
      upperShadow < body * 0.3) {
      return 0.85; // High confidence
   }

   return 0;
}

// Detect Shooting Star pattern
double Pattern_DetectShootingStar(string symbol, int timeframe, int shift) {
   double open = iOpen(symbol, timeframe, shift);
   double high = iHigh(symbol, timeframe, shift);
   double low = iLow(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);

   double body = Pattern_GetBodySize(symbol, timeframe, shift);
   double range = Pattern_GetCandleRange(symbol, timeframe, shift);

   if(range == 0) return 0;

   double lowerShadow = MathMin(open, close) - low;
   double upperShadow = high - MathMax(open, close);

   // Shooting star: small body, long upper shadow, little/no lower shadow
   if(body < range * 0.3 &&
      upperShadow > body * 2.0 &&
      lowerShadow < body * 0.3) {
      return 0.85;
   }

   return 0;
}

// Detect Doji pattern
double Pattern_DetectDoji(string symbol, int timeframe, int shift) {
   double body = Pattern_GetBodySize(symbol, timeframe, shift);
   double range = Pattern_GetCandleRange(symbol, timeframe, shift);

   if(range == 0) return 0;

   // Doji: very small body relative to range
   if(body < range * 0.1) {
      return 0.75;
   }

   return 0;
}

// Detect Bullish Engulfing
double Pattern_DetectBullishEngulfing(string symbol, int timeframe, int shift) {
   if(shift < 1) return 0;

   double open0 = iOpen(symbol, timeframe, shift);
   double close0 = iClose(symbol, timeframe, shift);
   double open1 = iOpen(symbol, timeframe, shift + 1);
   double close1 = iClose(symbol, timeframe, shift + 1);

   // Previous candle bearish, current candle bullish
   if(close1 < open1 && close0 > open0) {
      // Current candle engulfs previous
      if(open0 < close1 && close0 > open1) {
         return 0.90;
      }
   }

   return 0;
}

// Detect Bearish Engulfing
double Pattern_DetectBearishEngulfing(string symbol, int timeframe, int shift) {
   if(shift < 1) return 0;

   double open0 = iOpen(symbol, timeframe, shift);
   double close0 = iClose(symbol, timeframe, shift);
   double open1 = iOpen(symbol, timeframe, shift + 1);
   double close1 = iClose(symbol, timeframe, shift + 1);

   // Previous candle bullish, current candle bearish
   if(close1 > open1 && close0 < open0) {
      // Current candle engulfs previous
      if(open0 > close1 && close0 < open1) {
         return 0.90;
      }
   }

   return 0;
}

// Detect Morning Star
double Pattern_DetectMorningStar(string symbol, int timeframe, int shift) {
   if(shift < 2) return 0;

   bool candle0Bullish = Pattern_IsBullish(symbol, timeframe, shift);
   bool candle1Small = Pattern_GetBodySize(symbol, timeframe, shift + 1) < Pattern_GetCandleRange(symbol, timeframe, shift + 1) * 0.3;
   bool candle2Bearish = !Pattern_IsBullish(symbol, timeframe, shift + 2);

   if(candle2Bearish && candle1Small && candle0Bullish) {
      double body0 = Pattern_GetBodySize(symbol, timeframe, shift);
      double body2 = Pattern_GetBodySize(symbol, timeframe, shift + 2);

      // Strong reversal if third candle penetrates into first candle
      if(body0 > body2 * 0.5) {
         return 0.80;
      }
   }

   return 0;
}

// Detect Evening Star
double Pattern_DetectEveningStar(string symbol, int timeframe, int shift) {
   if(shift < 2) return 0;

   bool candle0Bearish = !Pattern_IsBullish(symbol, timeframe, shift);
   bool candle1Small = Pattern_GetBodySize(symbol, timeframe, shift + 1) < Pattern_GetCandleRange(symbol, timeframe, shift + 1) * 0.3;
   bool candle2Bullish = Pattern_IsBullish(symbol, timeframe, shift + 2);

   if(candle2Bullish && candle1Small && candle0Bearish) {
      double body0 = Pattern_GetBodySize(symbol, timeframe, shift);
      double body2 = Pattern_GetBodySize(symbol, timeframe, shift + 2);

      if(body0 > body2 * 0.5) {
         return 0.80;
      }
   }

   return 0;
}

//--------------------------------------------------------------------
// SCAN FOR ALL CANDLESTICK PATTERNS
//--------------------------------------------------------------------
void Pattern_ScanCandlestick(string symbol, int timeframe, int shift) {
   if(!DetectCandlePatterns) return;

   double confidence = 0;
   string patternName = "";
   bool isBullish = false;

   // Check bullish patterns
   confidence = Pattern_DetectHammer(symbol, timeframe, shift);
   if(confidence >= PatternMinConfidence) {
      patternName = "Hammer";
      isBullish = true;
   }

   if(patternName == "") {
      confidence = Pattern_DetectBullishEngulfing(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Bullish Engulfing";
         isBullish = true;
      }
   }

   if(patternName == "") {
      confidence = Pattern_DetectMorningStar(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Morning Star";
         isBullish = true;
      }
   }

   // Check bearish patterns
   if(patternName == "") {
      confidence = Pattern_DetectShootingStar(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Shooting Star";
         isBullish = false;
      }
   }

   if(patternName == "") {
      confidence = Pattern_DetectBearishEngulfing(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Bearish Engulfing";
         isBullish = false;
      }
   }

   if(patternName == "") {
      confidence = Pattern_DetectEveningStar(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Evening Star";
         isBullish = false;
      }
   }

   // Check neutral patterns
   if(patternName == "") {
      confidence = Pattern_DetectDoji(symbol, timeframe, shift);
      if(confidence >= PatternMinConfidence) {
         patternName = "Doji";
         isBullish = false; // Neutral, but often reversal
      }
   }

   // Add pattern to detected patterns array
   if(patternName != "" && confidence >= PatternMinConfidence) {
      DetectedPattern dp;
      dp.symbol = symbol;
      dp.patternName = patternName;
      dp.timeframe = timeframe;
      dp.detected = TimeCurrent();
      dp.confidence = confidence;
      dp.isBullish = isBullish;
      dp.barIndex = shift;

      int size = ArraySize(g_Patterns);
      ArrayResize(g_Patterns, size + 1);
      g_Patterns[size] = dp;

      if(DebugMode) {
         Print("Pattern detected: ", patternName, " on ", symbol, " (", timeframe, ") - Confidence: ",
               DoubleToString(confidence * 100, 1), "%");
      }
   }
}

//--------------------------------------------------------------------
// CHART PATTERN DETECTION
//--------------------------------------------------------------------

// Find swing highs
double Pattern_FindSwingHigh(string symbol, int timeframe, int lookback, int &barIndex) {
   double highest = -999999;
   int highestBar = -1;

   for(int i = 2; i < lookback - 2; i++) {
      double high = iHigh(symbol, timeframe, i);
      double prevHigh = iHigh(symbol, timeframe, i + 1);
      double nextHigh = iHigh(symbol, timeframe, i - 1);

      // Check if this is a swing high
      if(high > prevHigh && high > nextHigh && high > highest) {
         highest = high;
         highestBar = i;
      }
   }

   barIndex = highestBar;
   return highest;
}

// Find swing lows
double Pattern_FindSwingLow(string symbol, int timeframe, int lookback, int &barIndex) {
   double lowest = 999999;
   int lowestBar = -1;

   for(int i = 2; i < lookback - 2; i++) {
      double low = iLow(symbol, timeframe, i);
      double prevLow = iLow(symbol, timeframe, i + 1);
      double nextLow = iLow(symbol, timeframe, i - 1);

      // Check if this is a swing low
      if(low < prevLow && low < nextLow && low < lowest) {
         lowest = low;
         lowestBar = i;
      }
   }

   barIndex = lowestBar;
   return lowest;
}

// Detect Double Top
double Pattern_DetectDoubleTop(string symbol, int timeframe) {
   int bar1 = -1, bar2 = -1;
   double high1 = Pattern_FindSwingHigh(symbol, timeframe, PatternLookback / 2, bar1);
   double high2 = Pattern_FindSwingHigh(symbol, timeframe, PatternLookback, bar2);

   if(bar1 >= 0 && bar2 >= 0 && bar2 > bar1) {
      // Check if peaks are similar (within 1%)
      if(MathAbs(high1 - high2) / high1 < 0.01) {
         return 0.75;
      }
   }

   return 0;
}

// Detect Double Bottom
double Pattern_DetectDoubleBottom(string symbol, int timeframe) {
   int bar1 = -1, bar2 = -1;
   double low1 = Pattern_FindSwingLow(symbol, timeframe, PatternLookback / 2, bar1);
   double low2 = Pattern_FindSwingLow(symbol, timeframe, PatternLookback, bar2);

   if(bar1 >= 0 && bar2 >= 0 && bar2 > bar1) {
      // Check if troughs are similar (within 1%)
      if(MathAbs(low1 - low2) / low1 < 0.01) {
         return 0.75;
      }
   }

   return 0;
}

// Get recent bullish patterns for symbol
int Pattern_GetBullishSignals(string symbol, int timeframe) {
   int count = 0;
   datetime cutoffTime = TimeCurrent() - (3600 * 4); // Last 4 hours

   for(int i = 0; i < ArraySize(g_Patterns); i++) {
      if(g_Patterns[i].symbol == symbol &&
         g_Patterns[i].timeframe == timeframe &&
         g_Patterns[i].isBullish &&
         g_Patterns[i].detected > cutoffTime) {
         count++;
      }
   }

   return count;
}

// Get recent bearish patterns for symbol
int Pattern_GetBearishSignals(string symbol, int timeframe) {
   int count = 0;
   datetime cutoffTime = TimeCurrent() - (3600 * 4); // Last 4 hours

   for(int i = 0; i < ArraySize(g_Patterns); i++) {
      if(g_Patterns[i].symbol == symbol &&
         g_Patterns[i].timeframe == timeframe &&
         !g_Patterns[i].isBullish &&
         g_Patterns[i].detected > cutoffTime) {
         count++;
      }
   }

   return count;
}

// Clean old patterns
void Pattern_CleanOld() {
   datetime cutoffTime = TimeCurrent() - (3600 * 24); // Keep patterns for 24 hours

   for(int i = ArraySize(g_Patterns) - 1; i >= 0; i--) {
      if(g_Patterns[i].detected < cutoffTime) {
         // Remove old pattern
         for(int j = i; j < ArraySize(g_Patterns) - 1; j++) {
            g_Patterns[j] = g_Patterns[j + 1];
         }
         ArrayResize(g_Patterns, ArraySize(g_Patterns) - 1);
      }
   }
}

//+------------------------------------------------------------------+
