//+------------------------------------------------------------------+
//|                                    SST_MachineLearning.mqh       |
//|           Smart Stock Trader - Machine Learning Module           |
//|     Pattern Recognition, Price Prediction, Confidence Scoring    |
//|                  ENHANCED: 30 Features, Deep Learning            |
//+------------------------------------------------------------------+
#property strict

// Include enhanced ML features and neural network
#include <SST_MachineLearning_Enhanced.mqh>

//--------------------------------------------------------------------
// MACHINE LEARNING PARAMETERS - ENHANCED
//--------------------------------------------------------------------
extern bool    UseMLPredictions      = true;         // Enable ML-based predictions
extern bool    UsePatternRecognition = true;         // Candlestick pattern recognition
extern int     MLTrainingPeriod      = 1000;         // Bars to use for training (INCREASED)
extern double  MLConfidenceThreshold = 65.0;         // Minimum confidence % to trade (OPTIMIZED for better balance)
extern bool    UseAdaptiveLearning   = true;         // Update weights based on results
extern int     MLLookbackBars        = 50;           // Bars to analyze for patterns (INCREASED)
extern bool    UsePriceActionML      = true;         // Price action pattern detection
extern bool    UseDeepLearning       = true;         // Multi-layer neural network (NEW)
extern int     MLHiddenLayerSize     = 20;           // Hidden layer neurons (NEW)
extern double  MLLearningRate        = 0.001;        // Learning rate for training (NEW)
extern bool    UseFeatureScaling     = true;         // Normalize features (NEW)
extern bool    UseWinRatePrediction  = true;         // Predict win probability (NEW)

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

// ENHANCED: Multi-Layer Neural Network
#define ML_INPUT_SIZE 30        // 30 input features (increased from 10)
#define ML_HIDDEN_SIZE 20       // 20 hidden neurons
#define ML_OUTPUT_SIZE 3        // 3 outputs: BUY, SELL, NEUTRAL probability

// Layer 1: Input → Hidden
double g_MLWeights_IH[30][20];  // Input to Hidden weights
double g_MLBias_H[20];          // Hidden layer bias

// Layer 2: Hidden → Output
double g_MLWeights_HO[20][3];   // Hidden to Output weights
double g_MLBias_O[3];           // Output layer bias

// Training history
double g_MLAccuracy = 0.0;      // Current ML accuracy
int g_MLCorrectPredictions = 0;
int g_MLTotalPredictions = 0;
bool g_MLInitialized = false;

// Feature normalization
double g_MLFeatureMin[30];
double g_MLFeatureMax[30];

//--------------------------------------------------------------------
// INITIALIZE MACHINE LEARNING MODULE - ENHANCED
//--------------------------------------------------------------------
void ML_Initialize() {
   Print("🤖 Initializing ENHANCED Machine Learning Module...");

   // Initialize multi-layer neural network weights (Xavier initialization)
   // Layer 1: Input → Hidden (30 x 20)
   double xavier_ih = MathSqrt(2.0 / (ML_INPUT_SIZE + ML_HIDDEN_SIZE));
   for(int i = 0; i < ML_INPUT_SIZE; i++) {
      for(int h = 0; h < ML_HIDDEN_SIZE; h++) {
         g_MLWeights_IH[i][h] = (MathRand() / 32768.0 - 0.5) * 2.0 * xavier_ih;
      }
   }

   // Hidden layer bias
   for(int h = 0; h < ML_HIDDEN_SIZE; h++) {
      g_MLBias_H[h] = 0.0;
   }

   // Layer 2: Hidden → Output (20 x 3)
   double xavier_ho = MathSqrt(2.0 / (ML_HIDDEN_SIZE + ML_OUTPUT_SIZE));
   for(int h = 0; h < ML_HIDDEN_SIZE; h++) {
      for(int o = 0; o < ML_OUTPUT_SIZE; o++) {
         g_MLWeights_HO[h][o] = (MathRand() / 32768.0 - 0.5) * 2.0 * xavier_ho;
      }
   }

   // Output layer bias
   for(int o = 0; o < ML_OUTPUT_SIZE; o++) {
      g_MLBias_O[o] = 0.0;
   }

   // Initialize feature normalization
   for(int i = 0; i < ML_INPUT_SIZE; i++) {
      g_MLFeatureMin[i] = 999999;
      g_MLFeatureMax[i] = -999999;
   }

   // Load historical trade data for learning
   ArrayResize(g_MLHistory, 2000);
   g_MLHistoryCount = 0;

   g_MLAccuracy = 0.0;
   g_MLCorrectPredictions = 0;
   g_MLTotalPredictions = 0;

   g_MLInitialized = true;

   Print("✓ ENHANCED ML Module initialized");
   Print("   - Multi-layer neural network: 30 → 20 → 3");
   Print("   - Xavier weight initialization");
   Print("   - Feature scaling enabled");
   Print("   - Confidence threshold: ", MLConfidenceThreshold, "%");
   Print("   - Training period: ", MLTrainingPeriod, " bars");

   // AUTO-TRAIN on historical data (if sufficient bars available)
   if(UsePriceActionML && MLTrainingPeriod > 100) {
      string symbol = Symbol();
      int availableBars = iBars(symbol, PERIOD_H1);

      if(availableBars >= MLTrainingPeriod) {
         Print("🧠 Auto-training on ", MLTrainingPeriod, " historical bars...");
         ML_TrainOnHistory(
            symbol,
            PERIOD_H1,
            MLTrainingPeriod,
            g_MLWeights_IH,
            g_MLBias_H,
            g_MLWeights_HO,
            g_MLBias_O,
            g_MLFeatureMin,
            g_MLFeatureMax
         );
      } else {
         Print("⚠ Not enough historical data for training (need ", MLTrainingPeriod, ", have ", availableBars, ")");
      }
   }
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
// ENHANCED FEATURE EXTRACTION - 30 Features
//--------------------------------------------------------------------
void ML_ExtractFeatures(string symbol, int timeframe, double &features[]) {
   // Ensure array is sized correctly
   if(ArraySize(features) < ML_INPUT_SIZE) {
      ArrayResize(features, ML_INPUT_SIZE);
   }

   double close = iClose(symbol, timeframe, 0);

   // === TREND INDICATORS (Features 0-7) ===

   // Feature 1: RSI (normalized 0-1)
   features[0] = iRSI(symbol, timeframe, 14, PRICE_CLOSE, 0) / 100.0;

   // Feature 2: Stochastic (normalized 0-1)
   features[1] = iStochastic(symbol, timeframe, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) / 100.0;

   // Feature 3: ADX strength (normalized 0-1)
   features[2] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MAIN, 0) / 100.0;

   // Feature 4: Price vs MA50 (normalized)
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

   // Additional features are extracted by ML_ExtractFeatures_Enhanced
   // This function now just sets up the first 10 basic features
}

//--------------------------------------------------------------------
// PRICE PREDICTION USING NEURAL NETWORK
//--------------------------------------------------------------------
MLPrediction ML_PredictPriceAction(string symbol, int timeframe) {
   MLPrediction prediction;
   prediction.direction = "NEUTRAL";
   prediction.confidence = 50.0;
   prediction.predictedChange = 0.0;
   prediction.predictionTime = TimeCurrent();

   if(!UseDeepLearning) return prediction;

   // Extract ALL 30 features
   double features[30];
   ML_ExtractFeatures_Enhanced(symbol, timeframe, features);

   // Normalize features
   if(UseFeatureScaling) {
      ML_NormalizeFeatures(features, g_MLFeatureMin, g_MLFeatureMax);
   }

   // Run forward pass through neural network
   double output[3];  // [BUY, SELL, NEUTRAL] probabilities
   ML_ForwardPass(features, g_MLWeights_IH, g_MLBias_H, g_MLWeights_HO, g_MLBias_O, output);

   // Determine prediction from output probabilities
   int predictedClass = 0;  // 0=BUY, 1=SELL, 2=NEUTRAL
   double maxProb = output[0];

   if(output[1] > maxProb) {
      predictedClass = 1;
      maxProb = output[1];
   }
   if(output[2] > maxProb) {
      predictedClass = 2;
      maxProb = output[2];
   }

   // Set prediction based on highest probability
   if(predictedClass == 0) {
      prediction.direction = "UP";
      prediction.confidence = maxProb * 100.0;
      prediction.predictedChange = maxProb * 2.0;
   } else if(predictedClass == 1) {
      prediction.direction = "DOWN";
      prediction.confidence = maxProb * 100.0;
      prediction.predictedChange = -maxProb * 2.0;
   } else {
      prediction.direction = "NEUTRAL";
      prediction.confidence = maxProb * 100.0;
      prediction.predictedChange = 0.0;
   }

   // Calibrate confidence based on historical accuracy
   if(g_MLAccuracy > 0.5) {
      prediction.confidence = prediction.confidence * g_MLAccuracy;
   }

   if(VerboseLogging) {
      Print("🤖 ML Neural Network: ", prediction.direction,
            " | Conf: ", DoubleToString(prediction.confidence, 1), "%",
            " | Probs: BUY=", DoubleToString(output[0]*100, 1),
            "% SELL=", DoubleToString(output[1]*100, 1),
            "% NEUTRAL=", DoubleToString(output[2]*100, 1), "%");
   }

   return prediction;
}

//--------------------------------------------------------------------
// ENHANCED COMBINED ML SIGNAL - Pattern + Neural Network Prediction
//--------------------------------------------------------------------
bool ML_GetTradingSignal(string symbol, int timeframe, bool &isBullish, double &confidence) {
   if(!UseMLPredictions) return false;

   // Get pattern recognition
   MLPattern pattern = ML_DetectCandlestickPatterns(symbol, timeframe);

   // Get ENHANCED price action prediction (30 features, deep learning)
   MLPrediction prediction = ML_PredictPriceAction(symbol, timeframe);

   // Track prediction for accuracy calculation
   g_MLTotalPredictions++;

   // Combine signals with SMART weighting
   bool hasPattern = (pattern.confidence > 55.0);
   bool hasStrongPrediction = (prediction.confidence > MLConfidenceThreshold);
   bool hasWeakPrediction = (prediction.confidence > 60.0);

   // STRATEGY 1: Both neural network AND pattern agree (HIGHEST CONFIDENCE)
   if(hasPattern && hasStrongPrediction) {
      bool patternBullish = pattern.isBullish;
      bool predictionBullish = (prediction.direction == "UP");

      if(patternBullish == predictionBullish) {
         // Perfect alignment - both agree!
         isBullish = patternBullish;
         // Weight neural network MORE (70%) since it has 30 features
         confidence = (pattern.confidence * 0.3) + (prediction.confidence * 0.7);

         if(VerboseLogging) {
            Print("╔════════════════════════════════════════╗");
            Print("║  🎯 ML SUPER SIGNAL - BOTH AGREE!     ║");
            Print("╠════════════════════════════════════════╣");
            Print("║ Pattern: ", pattern.patternName);
            Print("║ Pattern Conf: ", DoubleToString(pattern.confidence, 1), "%");
            Print("║ Neural Network: ", prediction.direction);
            Print("║ Network Conf: ", DoubleToString(prediction.confidence, 1), "%");
            Print("║ COMBINED: ", (isBullish ? "BULLISH" : "BEARISH"));
            Print("║ Final Conf: ", DoubleToString(confidence, 1), "%");
            if(g_MLAccuracy > 0) {
               Print("║ ML Accuracy: ", DoubleToString(g_MLAccuracy * 100, 1), "%");
            }
            Print("╚════════════════════════════════════════╝");
         }

         return true;
      }
   }

   // STRATEGY 2: Strong neural network prediction alone (no pattern needed)
   if(hasStrongPrediction && prediction.confidence > MLConfidenceThreshold) {
      isBullish = (prediction.direction == "UP");
      confidence = prediction.confidence;

      // Adjust confidence based on historical accuracy
      if(g_MLAccuracy > 0.5) {
         confidence = confidence * g_MLAccuracy;  // Scale by accuracy
      }

      if(VerboseLogging) {
         Print("🤖 ML NEURAL NETWORK SIGNAL: ", prediction.direction);
         Print("   Confidence: ", DoubleToString(confidence, 1), "%");
         if(g_MLAccuracy > 0) {
            Print("   Historical Accuracy: ", DoubleToString(g_MLAccuracy * 100, 1), "%");
         }
      }

      return true;
   }

   // STRATEGY 3: Strong pattern + weak neural network confirmation
   if(hasPattern && hasWeakPrediction) {
      bool patternBullish = pattern.isBullish;
      bool predictionBullish = (prediction.direction == "UP");

      if(patternBullish == predictionBullish) {
         isBullish = patternBullish;
         confidence = pattern.confidence;

         if(VerboseLogging) {
            Print("📊 PATTERN SIGNAL (ML confirmed): ", pattern.patternName);
            Print("   Confidence: ", DoubleToString(confidence, 1), "%");
         }

         return (confidence > MLConfidenceThreshold - 10);  // Lower threshold
      }
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

   // Update accuracy tracker
   if(wasCorrect) g_MLCorrectPredictions++;

   // Calculate running accuracy
   if(g_MLHistoryCount > 0) {
      g_MLAccuracy = (double)g_MLCorrectPredictions / (double)g_MLHistoryCount;
   }

   // Adaptive learning would update neural network weights here
   // For now, we track accuracy and use it to calibrate confidence
   if(VerboseLogging) {
      Print("🧠 ML Learning: Trade ", (wasCorrect ? "✓ SUCCESS" : "✗ FAILED"),
            " (", DoubleToString(changePercent, 2), "%) | Accuracy: ",
            DoubleToString(g_MLAccuracy * 100, 1), "%");
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
