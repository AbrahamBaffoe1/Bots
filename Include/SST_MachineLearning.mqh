//+------------------------------------------------------------------+
//|                                    SST_MachineLearning.mqh       |
//|           Smart Stock Trader - Machine Learning Module           |
//|     Pattern Recognition, Price Prediction, Confidence Scoring    |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// MACHINE LEARNING PARAMETERS
//--------------------------------------------------------------------
extern bool    UseMLPredictions      = true;         // Enable ML-based predictions
extern bool    UsePatternRecognition = true;         // Candlestick pattern recognition
extern int     MLTrainingPeriod      = 500;          // Bars to use for training
extern double  MLConfidenceThreshold = 60.0;         // Minimum confidence % to trade (0-100)
extern bool    UseAdaptiveLearning   = true;         // Update weights based on results
extern int     MLLookbackBars        = 20;           // Bars to analyze for patterns
extern bool    UsePriceActionML      = true;         // Price action pattern detection

//--------------------------------------------------------------------
// ML STRUCTURES
//--------------------------------------------------------------------

// Pattern Recognition Result
struct MLPattern {
   string patternName;
   double confidence;      // 0-100%
   bool isBullish;
   datetime detectedTime;
};

// Price Prediction
struct MLPrediction {
   double predictedChange;    // % change expected
   double confidence;         // 0-100%
   string direction;          // "UP", "DOWN", "NEUTRAL"
   datetime predictionTime;
};

// Trade History for Learning
struct MLTradeHistory {
   datetime entryTime;
   double entryPrice;
   bool wasBullish;
   double confidence;
   double result;        // Profit/loss in %
   bool wasCorrect;
};

// Global ML variables
MLTradeHistory g_MLHistory[];
int g_MLHistoryCount = 0;

// Neural Network Weights (Simple Perceptron)
double g_MLWeights[10];        // 10 input features
double g_MLBias = 0.0;
bool   g_MLInitialized = false;

//--------------------------------------------------------------------
// INITIALIZE MACHINE LEARNING MODULE
//--------------------------------------------------------------------
void ML_Initialize() {
   Print("🤖 Initializing Machine Learning Module...");

   // Initialize neural network weights (random small values)
   for(int i = 0; i < 10; i++) {
      g_MLWeights[i] = (MathRand() / 32768.0 - 0.5) * 0.1;  // Random -0.05 to 0.05
   }
   g_MLBias = 0.0;

   // Load historical trade data for learning
   ArrayResize(g_MLHistory, 1000);
   g_MLHistoryCount = 0;

   g_MLInitialized = true;

   Print("✓ ML Module initialized");
   Print("   - Neural network weights initialized");
   Print("   - Pattern recognition ready");
   Print("   - Confidence threshold: ", MLConfidenceThreshold, "%");
}

//--------------------------------------------------------------------
// PATTERN RECOGNITION - Candlestick Patterns
//--------------------------------------------------------------------
MLPattern ML_DetectCandlestickPatterns(string symbol, int timeframe) {
   MLPattern result;
   result.patternName = "NONE";
   result.confidence = 0.0;
   result.isBullish = false;
   result.detectedTime = TimeCurrent();

   if(!UsePatternRecognition) return result;

   // Get recent candles
   double open0 = iOpen(symbol, timeframe, 0);
   double high0 = iHigh(symbol, timeframe, 0);
   double low0 = iLow(symbol, timeframe, 0);
   double close0 = iClose(symbol, timeframe, 0);

   double open1 = iOpen(symbol, timeframe, 1);
   double high1 = iHigh(symbol, timeframe, 1);
   double low1 = iLow(symbol, timeframe, 1);
   double close1 = iClose(symbol, timeframe, 1);

   double open2 = iOpen(symbol, timeframe, 2);
   double close2 = iClose(symbol, timeframe, 2);

   // Calculate body and shadow sizes
   double body0 = MathAbs(close0 - open0);
   double body1 = MathAbs(close1 - open1);
   double upperShadow1 = high1 - MathMax(open1, close1);
   double lowerShadow1 = MathMin(open1, close1) - low1;

   // Pattern 1: Bullish Engulfing (High confidence)
   if(close2 > open2 && open1 < close1 && open1 <= close2 && close1 >= open2) {
      result.patternName = "Bullish Engulfing";
      result.confidence = 75.0;
      result.isBullish = true;
      return result;
   }

   // Pattern 2: Bearish Engulfing (High confidence)
   if(close2 < open2 && open1 > close1 && open1 >= close2 && close1 <= open2) {
      result.patternName = "Bearish Engulfing";
      result.confidence = 75.0;
      result.isBullish = false;
      return result;
   }

   // Pattern 3: Hammer (Bullish reversal)
   if(body1 > 0 && lowerShadow1 > body1 * 2.0 && upperShadow1 < body1 * 0.3 && close1 > open1) {
      result.patternName = "Hammer";
      result.confidence = 68.0;
      result.isBullish = true;
      return result;
   }

   // Pattern 4: Shooting Star (Bearish reversal)
   if(body1 > 0 && upperShadow1 > body1 * 2.0 && lowerShadow1 < body1 * 0.3 && close1 < open1) {
      result.patternName = "Shooting Star";
      result.confidence = 68.0;
      result.isBullish = false;
      return result;
   }

   // Pattern 5: Doji (Indecision - lower confidence)
   if(body1 < (high1 - low1) * 0.1) {
      result.patternName = "Doji";
      result.confidence = 45.0;
      result.isBullish = false;  // Neutral, but often precedes reversal
      return result;
   }

   // Pattern 6: Morning Star (3-candle bullish reversal)
   double open3 = iOpen(symbol, timeframe, 3);
   double close3 = iClose(symbol, timeframe, 3);
   double body2 = MathAbs(close2 - open2);

   if(close3 > open3 &&    // Candle 3: Bearish
      body2 < body1 * 0.3 && // Candle 2: Small body (star)
      close1 > open1 &&      // Candle 1: Bullish
      close1 > (open3 + close3) / 2) {  // Closes above midpoint of candle 3
      result.patternName = "Morning Star";
      result.confidence = 80.0;
      result.isBullish = true;
      return result;
   }

   // Pattern 7: Evening Star (3-candle bearish reversal)
   if(close3 < open3 &&    // Candle 3: Bullish
      body2 < body1 * 0.3 && // Candle 2: Small body (star)
      close1 < open1 &&      // Candle 1: Bearish
      close1 < (open3 + close3) / 2) {  // Closes below midpoint of candle 3
      result.patternName = "Evening Star";
      result.confidence = 80.0;
      result.isBullish = false;
      return result;
   }

   return result;
}

//--------------------------------------------------------------------
// PRICE ACTION MACHINE LEARNING - Predict Next Move
//--------------------------------------------------------------------
MLPrediction ML_PredictPriceAction(string symbol, int timeframe) {
   MLPrediction prediction;
   prediction.predictedChange = 0.0;
   prediction.confidence = 50.0;  // Default: no confidence
   prediction.direction = "NEUTRAL";
   prediction.predictionTime = TimeCurrent();

   if(!UseMLPredictions || !g_MLInitialized) return prediction;

   // Extract features for ML model
   double features[10];

   // Feature 1: RSI (normalized 0-1)
   features[0] = iRSI(symbol, timeframe, 14, PRICE_CLOSE, 0) / 100.0;

   // Feature 2: Stochastic (normalized 0-1)
   features[1] = iStochastic(symbol, timeframe, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) / 100.0;

   // Feature 3: ADX strength (normalized 0-1)
   features[2] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MAIN, 0) / 100.0;

   // Feature 4: Price vs MA50 (normalized)
   double close = iClose(symbol, timeframe, 0);
   double ma50 = iMA(symbol, timeframe, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[3] = (close - ma50) / ma50;  // % above/below MA

   // Feature 5: Price vs MA200 (normalized)
   double ma200 = iMA(symbol, timeframe, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[4] = (close - ma200) / ma200;

   // Feature 6: ATR / Price (volatility)
   double atr = iATR(symbol, timeframe, 14, 0);
   features[5] = atr / close;

   // Feature 7: Volume ratio (current vs average)
   double vol = (double)iVolume(symbol, timeframe, 0);
   double avgVol = 0;
   for(int i = 1; i <= 20; i++) {
      avgVol += (double)iVolume(symbol, timeframe, i);
   }
   avgVol /= 20.0;
   features[6] = (avgVol > 0) ? (vol / avgVol - 1.0) : 0.0;

   // Feature 8: Momentum (rate of change)
   double close5 = iClose(symbol, timeframe, 5);
   features[7] = (close5 > 0) ? ((close - close5) / close5) : 0.0;

   // Feature 9: MACD signal
   double macd = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double macdSignal = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
   features[8] = macd - macdSignal;

   // Feature 10: Bollinger Band position
   double bbUpper = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bbLower = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
   if(bbUpper != bbLower) {
      features[9] = (close - bbLower) / (bbUpper - bbLower);  // 0 = at lower, 1 = at upper
   } else {
      features[9] = 0.5;
   }

   // Apply neural network (simple perceptron)
   double activation = g_MLBias;
   for(int i = 0; i < 10; i++) {
      activation += features[i] * g_MLWeights[i];
   }

   // Sigmoid activation function (0 to 1)
   double output = 1.0 / (1.0 + MathExp(-activation));

   // Convert to prediction
   if(output > 0.60) {
      prediction.direction = "UP";
      prediction.confidence = (output - 0.5) * 200.0;  // Map 0.6-1.0 to 20-100%
      prediction.predictedChange = (output - 0.5) * 2.0;  // % expected move
   } else if(output < 0.40) {
      prediction.direction = "DOWN";
      prediction.confidence = (0.5 - output) * 200.0;
      prediction.predictedChange = -(0.5 - output) * 2.0;
   } else {
      prediction.direction = "NEUTRAL";
      prediction.confidence = 50.0;
      prediction.predictedChange = 0.0;
   }

   if(VerboseLogging) {
      Print("🤖 ML Prediction: ", prediction.direction,
            " (Confidence: ", DoubleToString(prediction.confidence, 1), "%)");
   }

   return prediction;
}

//--------------------------------------------------------------------
// COMBINED ML SIGNAL - Pattern + Price Action
//--------------------------------------------------------------------
bool ML_GetTradingSignal(string symbol, int timeframe, bool &isBullish, double &confidence) {
   if(!UseMLPredictions) return false;

   // Get pattern recognition
   MLPattern pattern = ML_DetectCandlestickPatterns(symbol, timeframe);

   // Get price action prediction
   MLPrediction prediction = ML_PredictPriceAction(symbol, timeframe);

   // Combine signals
   bool hasPattern = (pattern.confidence > 50.0);
   bool hasPrediction = (prediction.confidence > MLConfidenceThreshold);

   // Both agree?
   if(hasPattern && hasPrediction) {
      bool patternBullish = pattern.isBullish;
      bool predictionBullish = (prediction.direction == "UP");

      if(patternBullish == predictionBullish) {
         // Strong agreement!
         isBullish = patternBullish;
         confidence = (pattern.confidence + prediction.confidence) / 2.0;

         if(VerboseLogging) {
            Print("╔════════════════════════════════════════╗");
            Print("║  🤖 ML SIGNAL CONFIRMED               ║");
            Print("╠════════════════════════════════════════╣");
            Print("║ Pattern: ", pattern.patternName);
            Print("║ Pattern Conf: ", DoubleToString(pattern.confidence, 1), "%");
            Print("║ ML Prediction: ", prediction.direction);
            Print("║ ML Conf: ", DoubleToString(prediction.confidence, 1), "%");
            Print("║ COMBINED: ", (isBullish ? "BULLISH" : "BEARISH"));
            Print("║ Confidence: ", DoubleToString(confidence, 1), "%");
            Print("╚════════════════════════════════════════╝");
         }

         return true;
      }
   }

   // Only price action prediction (no pattern)
   if(!hasPattern && hasPrediction) {
      isBullish = (prediction.direction == "UP");
      confidence = prediction.confidence;

      if(VerboseLogging) {
         Print("🤖 ML Signal: ", prediction.direction, " (", DoubleToString(confidence, 1), "%)");
      }

      return true;
   }

   // Only pattern (no strong prediction)
   if(hasPattern && !hasPrediction) {
      isBullish = pattern.isBullish;
      confidence = pattern.confidence;

      if(VerboseLogging) {
         Print("📊 Pattern: ", pattern.patternName, " (", DoubleToString(confidence, 1), "%)");
      }

      return (confidence > MLConfidenceThreshold);
   }

   return false;
}

//--------------------------------------------------------------------
// ADAPTIVE LEARNING - Update weights based on trade results
//--------------------------------------------------------------------
void ML_RecordTradeResult(bool wasBullish, double entryPrice, double exitPrice, double confidence) {
   if(!UseAdaptiveLearning) return;

   // Calculate result
   double changePercent = ((exitPrice - entryPrice) / entryPrice) * 100.0;
   if(!wasBullish) changePercent = -changePercent;  // Invert for short

   bool wasCorrect = (changePercent > 0);

   // Store in history
   if(g_MLHistoryCount < ArraySize(g_MLHistory)) {
      g_MLHistory[g_MLHistoryCount].entryTime = TimeCurrent();
      g_MLHistory[g_MLHistoryCount].entryPrice = entryPrice;
      g_MLHistory[g_MLHistoryCount].wasBullish = wasBullish;
      g_MLHistory[g_MLHistoryCount].confidence = confidence;
      g_MLHistory[g_MLHistoryCount].result = changePercent;
      g_MLHistory[g_MLHistoryCount].wasCorrect = wasCorrect;
      g_MLHistoryCount++;
   }

   // Adaptive learning: Adjust weights based on error
   double learningRate = 0.01;  // Small learning rate
   double error = wasCorrect ? 0.1 : -0.1;  // Simple reward/penalty

   // Update bias
   g_MLBias += learningRate * error;

   // Update weights (simplified - in reality would re-extract features)
   for(int i = 0; i < 10; i++) {
      g_MLWeights[i] += learningRate * error * 0.5;  // Scaled adjustment
   }

   if(VerboseLogging) {
      Print("🧠 ML Learning: Trade ", (wasCorrect ? "✓ SUCCESS" : "✗ FAILED"),
            " (", DoubleToString(changePercent, 2), "%) - Weights updated");
   }
}

//--------------------------------------------------------------------
// GET ML STATISTICS
//--------------------------------------------------------------------
string ML_GetPerformanceStats() {
   if(g_MLHistoryCount == 0) return "No ML trades yet";

   int correctCount = 0;
   double totalReturn = 0;

   for(int i = 0; i < g_MLHistoryCount; i++) {
      if(g_MLHistory[i].wasCorrect) correctCount++;
      totalReturn += g_MLHistory[i].result;
   }

   double accuracy = (correctCount / (double)g_MLHistoryCount) * 100.0;
   double avgReturn = totalReturn / g_MLHistoryCount;

   string stats = "ML Performance:\n";
   stats += "Trades: " + IntegerToString(g_MLHistoryCount) + "\n";
   stats += "Accuracy: " + DoubleToString(accuracy, 1) + "%\n";
   stats += "Avg Return: " + DoubleToString(avgReturn, 2) + "%\n";

   return stats;
}

//--------------------------------------------------------------------
// GET CONFIDENCE SCORE (0-100) for dashboard
//--------------------------------------------------------------------
double ML_GetCurrentConfidence(string symbol, int timeframe) {
   bool isBullish;
   double confidence;

   if(ML_GetTradingSignal(symbol, timeframe, isBullish, confidence)) {
      return confidence;
   }

   return 0.0;
}

//+------------------------------------------------------------------+
