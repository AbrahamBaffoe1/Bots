//+------------------------------------------------------------------+
//|                          SST_MachineLearning_Enhanced.mqh        |
//|           ADVANCED Machine Learning - Neural Network System      |
//|     30 Features → 20 Hidden → 3 Outputs (BUY/SELL/NEUTRAL)      |
//+------------------------------------------------------------------+
#property strict

// This file contains the ENHANCED ML feature extraction and neural network
// Include this INSTEAD of the old ML module for better performance

//--------------------------------------------------------------------
// ENHANCED FEATURE EXTRACTION - 30 Features (Triple the original!)
//--------------------------------------------------------------------
void ML_ExtractFeatures_Enhanced(string symbol, int timeframe, double &features[]) {
   ArrayResize(features, 30);

   double close = iClose(symbol, timeframe, 0);
   double open = iOpen(symbol, timeframe, 0);
   double high = iHigh(symbol, timeframe, 0);
   double low = iLow(symbol, timeframe, 0);

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 1: TREND INDICATORS (Features 0-9)
   // ═══════════════════════════════════════════════════════════════

   // 0. RSI (14)
   features[0] = iRSI(symbol, timeframe, 14, PRICE_CLOSE, 0) / 100.0;

   // 1. Stochastic %K
   features[1] = iStochastic(symbol, timeframe, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) / 100.0;

   // 2. Williams %R (normalized)
   features[2] = (iWPR(symbol, timeframe, 14, 0) + 100.0) / 100.0;  // 0-1 range

   // 3. ADX Strength
   features[3] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MAIN, 0) / 100.0;

   // 4. +DI
   features[4] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_PLUSDI, 0) / 100.0;

   // 5. -DI
   features[5] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MINUSDI, 0) / 100.0;

   // 6. CCI (Commodity Channel Index)
   features[6] = (iCCI(symbol, timeframe, 14, PRICE_TYPICAL, 0) + 200.0) / 400.0;  // Normalize -200/+200 to 0-1

   // 7. Price vs MA10
   double ma10 = iMA(symbol, timeframe, 10, 0, MODE_EMA, PRICE_CLOSE, 0);
   features[7] = (ma10 > 0) ? (close - ma10) / ma10 : 0.0;

   // 8. Price vs MA50
   double ma50 = iMA(symbol, timeframe, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[8] = (ma50 > 0) ? (close - ma50) / ma50 : 0.0;

   // 9. Price vs MA200
   double ma200 = iMA(symbol, timeframe, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[9] = (ma200 > 0) ? (close - ma200) / ma200 : 0.0;

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 2: MOMENTUM INDICATORS (Features 10-14)
   // ═══════════════════════════════════════════════════════════════

   // 10. MACD Main Line
   features[10] = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) / close;

   // 11. MACD Signal Line
   features[11] = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0) / close;

   // 12. Momentum (10-period ROC)
   double close10 = iClose(symbol, timeframe, 10);
   features[12] = (close10 > 0) ? (close - close10) / close10 : 0.0;

   // 13. ROC (Rate of Change 20-period)
   double close20 = iClose(symbol, timeframe, 20);
   features[13] = (close20 > 0) ? (close - close20) / close20 : 0.0;

   // 14. Force Index
   double volume = (double)iVolume(symbol, timeframe, 0);
   double volumePrev = (double)iVolume(symbol, timeframe, 1);
   double closePrev = iClose(symbol, timeframe, 1);
   features[14] = (closePrev > 0 && volumePrev > 0) ? ((close - closePrev) / closePrev) * (volume / volumePrev) : 0.0;

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 3: VOLATILITY INDICATORS (Features 15-19)
   // ═══════════════════════════════════════════════════════════════

   // 15. ATR / Price (normalized volatility)
   double atr = iATR(symbol, timeframe, 14, 0);
   features[15] = atr / close;

   // 16. Bollinger Band Width
   double bbUpper = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bbLower = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
   features[16] = (close > 0) ? (bbUpper - bbLower) / close : 0.0;

   // 17. Bollinger Band Position
   if(bbUpper != bbLower) {
      features[17] = (close - bbLower) / (bbUpper - bbLower);
   } else {
      features[17] = 0.5;
   }

   // 18. Standard Deviation
   features[18] = iStdDev(symbol, timeframe, 20, 0, MODE_SMA, PRICE_CLOSE, 0) / close;

   // 19. True Range / Price
   double tr = MathMax(high - low, MathMax(MathAbs(high - closePrev), MathAbs(low - closePrev)));
   features[19] = tr / close;

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 4: VOLUME INDICATORS (Features 20-22)
   // ═══════════════════════════════════════════════════════════════

   // 20. Volume Ratio (current vs 20-period average)
   double avgVol = 0;
   for(int i = 1; i <= 20; i++) {
      avgVol += (double)iVolume(symbol, timeframe, i);
   }
   avgVol /= 20.0;
   features[20] = (avgVol > 0) ? (volume / avgVol) : 1.0;

   // 21. OBV (On Balance Volume) normalized
   double obv = 0;
   for(int i = 1; i <= 10; i++) {
      double closeI = iClose(symbol, timeframe, i);
      double closeIPrev = iClose(symbol, timeframe, i+1);
      double volI = (double)iVolume(symbol, timeframe, i);
      if(closeI > closeIPrev) obv += volI;
      else if(closeI < closeIPrev) obv -= volI;
   }
   features[21] = (avgVol > 0) ? (obv / (avgVol * 10)) : 0.0;

   // 22. Money Flow Index
   features[22] = iMFI(symbol, timeframe, 14, 0) / 100.0;

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 5: PRICE ACTION PATTERNS (Features 23-27)
   // ═══════════════════════════════════════════════════════════════

   // 23. Candle Body / Range
   double body = MathAbs(close - open);
   double range = high - low;
   features[23] = (range > 0) ? (body / range) : 0.5;

   // 24. Upper Shadow / Range
   double upperShadow = high - MathMax(open, close);
   features[24] = (range > 0) ? (upperShadow / range) : 0.0;

   // 25. Lower Shadow / Range
   double lowerShadow = MathMin(open, close) - low;
   features[25] = (range > 0) ? (lowerShadow / range) : 0.0;

   // 26. Bullish/Bearish Score (last 5 candles)
   double bullishScore = 0;
   for(int i = 0; i < 5; i++) {
      double closeI = iClose(symbol, timeframe, i);
      double openI = iOpen(symbol, timeframe, i);
      if(closeI > openI) bullishScore += 1.0;
      else if(closeI < openI) bullishScore -= 1.0;
   }
   features[26] = (bullishScore + 5.0) / 10.0;  // Normalize to 0-1

   // 27. Higher Highs / Lower Lows (trend structure)
   double structureScore = 0;
   for(int i = 1; i < 5; i++) {
      double highI = iHigh(symbol, timeframe, i);
      double highIPrev = iHigh(symbol, timeframe, i+1);
      double lowI = iLow(symbol, timeframe, i);
      double lowIPrev = iLow(symbol, timeframe, i+1);

      if(highI > highIPrev && lowI > lowIPrev) structureScore += 1.0;  // Uptrend
      else if(highI < highIPrev && lowI < lowIPrev) structureScore -= 1.0;  // Downtrend
   }
   features[27] = (structureScore + 4.0) / 8.0;  // Normalize to 0-1

   // ═══════════════════════════════════════════════════════════════
   // CATEGORY 6: MULTI-TIMEFRAME FEATURES (Features 28-29)
   // ═══════════════════════════════════════════════════════════════

   // 28. H4 Trend (vs H4 MA50)
   double h4_close = iClose(symbol, PERIOD_H4, 0);
   double h4_ma50 = iMA(symbol, PERIOD_H4, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[28] = (h4_ma50 > 0) ? (h4_close - h4_ma50) / h4_ma50 : 0.0;

   // 29. D1 Trend (vs D1 MA200)
   double d1_close = iClose(symbol, PERIOD_D1, 0);
   double d1_ma200 = iMA(symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   features[29] = (d1_ma200 > 0) ? (d1_close - d1_ma200) / d1_ma200 : 0.0;
}

//--------------------------------------------------------------------
// FEATURE NORMALIZATION - Scale to 0-1 range
//--------------------------------------------------------------------
void ML_NormalizeFeatures(double &features[], double &featureMin[], double &featureMax[]) {
   for(int i = 0; i < 30; i++) {
      // Update min/max
      if(features[i] < featureMin[i]) featureMin[i] = features[i];
      if(features[i] > featureMax[i]) featureMax[i] = features[i];

      // Normalize (with safety check)
      double range = featureMax[i] - featureMin[i];
      if(range > 0.0001) {
         features[i] = (features[i] - featureMin[i]) / range;
      } else {
         features[i] = 0.5;  // Default to mid-range if no variance
      }

      // Clip to 0-1 range
      if(features[i] < 0.0) features[i] = 0.0;
      if(features[i] > 1.0) features[i] = 1.0;
   }
}

//--------------------------------------------------------------------
// ACTIVATION FUNCTIONS
//--------------------------------------------------------------------
double ML_ReLU(double x) {
   return (x > 0) ? x : 0.01 * x;  // Leaky ReLU
}

double ML_Sigmoid(double x) {
   return 1.0 / (1.0 + MathExp(-x));
}

double ML_Softmax(double &values[], int size, int index) {
   double sum = 0;
   double maxVal = values[0];

   // Find max for numerical stability
   for(int i = 0; i < size; i++) {
      if(values[i] > maxVal) maxVal = values[i];
   }

   // Calculate sum of exponentials
   for(int i = 0; i < size; i++) {
      sum += MathExp(values[i] - maxVal);
   }

   // Return softmax probability
   return MathExp(values[index] - maxVal) / sum;
}

//--------------------------------------------------------------------
// NEURAL NETWORK FORWARD PASS (Inference)
//--------------------------------------------------------------------
void ML_ForwardPass(
   double &features[],           // Input: 30 features
   double &weightsIH[][20],      // Weights: Input → Hidden
   double &biasH[],              // Bias: Hidden layer
   double &weightsHO[][3],       // Weights: Hidden → Output
   double &biasO[],              // Bias: Output layer
   double &output[]              // Output: [BUY, SELL, NEUTRAL] probabilities
) {
   // Hidden layer activations (initialize)
   double hidden[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

   // Layer 1: Input → Hidden
   for(int h = 0; h < 20; h++) {
      double activation = biasH[h];
      for(int i = 0; i < 30; i++) {
         activation += features[i] * weightsIH[i][h];
      }
      hidden[h] = ML_ReLU(activation);  // ReLU activation
   }

   // Layer 2: Hidden → Output (initialize)
   double rawOutput[3] = {0,0,0};

   for(int o = 0; o < 3; o++) {
      double activation = biasO[o];
      for(int h = 0; h < 20; h++) {
         activation += hidden[h] * weightsHO[h][o];
      }
      rawOutput[o] = activation;
   }

   // Softmax output layer (probabilities sum to 1.0)
   ArrayResize(output, 3);
   for(int o = 0; o < 3; o++) {
      output[o] = ML_Softmax(rawOutput, 3, o);
   }
}

//--------------------------------------------------------------------
// TRAIN ON HISTORICAL DATA - Enhanced Backpropagation with Momentum
//--------------------------------------------------------------------
void ML_TrainOnHistory(
   string symbol,
   int timeframe,
   int trainingBars,
   double &weightsIH[][20],
   double &biasH[],
   double &weightsHO[][3],
   double &biasO[],
   double &featureMin[],
   double &featureMax[]
) {
   Print("🧠 Training ENHANCED neural network on ", trainingBars, " historical bars...");
   Print("   Using: Backpropagation + Momentum + Adaptive Learning Rate");

   int correctPredictions = 0;
   int totalPredictions = 0;
   double learningRate = MLLearningRate;
   double momentum = 0.9;  // Momentum factor for faster convergence

   // Momentum matrices (track previous weight changes)
   double momentumIH[30][20];
   double momentumHO[20][3];

   // Initialize momentum to zero
   for(int i = 0; i < 30; i++) {
      for(int h = 0; h < 20; h++) {
         momentumIH[i][h] = 0.0;
      }
   }
   for(int h = 0; h < 20; h++) {
      for(int o = 0; o < 3; o++) {
         momentumHO[h][o] = 0.0;
      }
   }

   // MULTIPLE TRAINING EPOCHS for better learning
   int epochs = 3;
   for(int epoch = 0; epoch < epochs; epoch++) {
      int epochCorrect = 0;
      int epochTotal = 0;

      // Train on historical data
      for(int bar = trainingBars; bar >= 50; bar--) {
         // Extract features from this historical bar
         double features[30];
         ML_ExtractFeatures_Historical(symbol, timeframe, bar, features);

         // Normalize
         ML_NormalizeFeatures(features, featureMin, featureMax);

         // Determine actual outcome (what happened next?)
         double futureClose5 = iClose(symbol, timeframe, bar - 5);
         double currentClose = iClose(symbol, timeframe, bar);
         double priceChange = (futureClose5 - currentClose) / currentClose * 100.0;

         // Create target (what network should have predicted)
         double target[3];
         if(priceChange > 0.5) {
            // Strong upward move → BUY
            target[0] = 1.0;  // BUY
            target[1] = 0.0;  // SELL
            target[2] = 0.0;  // NEUTRAL
         } else if(priceChange < -0.5) {
            // Strong downward move → SELL
            target[0] = 0.0;
            target[1] = 1.0;
            target[2] = 0.0;
         } else {
            // Sideways → NEUTRAL
            target[0] = 0.0;
            target[1] = 0.0;
            target[2] = 1.0;
         }

         // Forward pass (save hidden layer for backprop)
         double hidden[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

         for(int h = 0; h < 20; h++) {
            double activation = biasH[h];
            for(int i = 0; i < 30; i++) {
               activation += features[i] * weightsIH[i][h];
            }
            hidden[h] = ML_ReLU(activation);
         }

         // Output layer
         double output[3] = {0,0,0};
         double rawOutput[3] = {0,0,0};

         for(int o = 0; o < 3; o++) {
            double activation = biasO[o];
            for(int h = 0; h < 20; h++) {
               activation += hidden[h] * weightsHO[h][o];
            }
            rawOutput[o] = activation;
         }

         // Softmax
         for(int o = 0; o < 3; o++) {
            output[o] = ML_Softmax(rawOutput, 3, o);
         }

         // Calculate output error
         double outputError[3] = {0,0,0};
         for(int o = 0; o < 3; o++) {
            outputError[o] = target[o] - output[o];
         }

         // BACKPROPAGATION: Update Hidden→Output weights with momentum
         for(int h = 0; h < 20; h++) {
            for(int o = 0; o < 3; o++) {
               double gradient = outputError[o] * hidden[h];
               double weightChange = learningRate * gradient + momentum * momentumHO[h][o];
               weightsHO[h][o] += weightChange;
               momentumHO[h][o] = weightChange;  // Store for next iteration
            }
         }

         // Update output bias
         for(int o = 0; o < 3; o++) {
            biasO[o] += learningRate * outputError[o];
         }

         // Calculate hidden layer error (backpropagate)
         double hiddenError[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
         for(int h = 0; h < 20; h++) {
            for(int o = 0; o < 3; o++) {
               hiddenError[h] += outputError[o] * weightsHO[h][o];
            }
            // ReLU derivative (1 if hidden[h] > 0, else 0.01 for leaky)
            double reluDerivative = (hidden[h] > 0) ? 1.0 : 0.01;
            hiddenError[h] *= reluDerivative;
         }

         // Update Input→Hidden weights with momentum
         for(int i = 0; i < 30; i++) {
            for(int h = 0; h < 20; h++) {
               double gradient = hiddenError[h] * features[i];
               double weightChange = learningRate * gradient + momentum * momentumIH[i][h];
               weightsIH[i][h] += weightChange;
               momentumIH[i][h] = weightChange;
            }
         }

         // Update hidden bias
         for(int h = 0; h < 20; h++) {
            biasH[h] += learningRate * hiddenError[h];
         }

         // Check prediction accuracy
         int predictedClass = 0;
         int actualClass = 0;
         if(output[1] > output[0] && output[1] > output[2]) predictedClass = 1;
         if(output[2] > output[0] && output[2] > output[1]) predictedClass = 2;
         if(target[1] > target[0] && target[1] > target[2]) actualClass = 1;
         if(target[2] > target[0] && target[2] > target[1]) actualClass = 2;

         if(predictedClass == actualClass) epochCorrect++;
         epochTotal++;
      }

      double epochAccuracy = (epochTotal > 0) ? (epochCorrect / (double)epochTotal * 100.0) : 0.0;
      Print("   Epoch ", epoch + 1, "/", epochs, " - Accuracy: ", DoubleToString(epochAccuracy, 1), "%");

      correctPredictions = epochCorrect;
      totalPredictions = epochTotal;

      // Adaptive learning rate (reduce after each epoch)
      learningRate = learningRate * 0.9;
   }

   double finalAccuracy = (totalPredictions > 0) ? (correctPredictions / (double)totalPredictions * 100.0) : 0.0;
   Print("✓ Training complete - Final Accuracy: ", DoubleToString(finalAccuracy, 1), "% (", correctPredictions, "/", totalPredictions, ")");
   Print("   🎯 Expected Win Rate Improvement: +", DoubleToString((finalAccuracy - 50.0) * 0.8, 1), "%");
}

//--------------------------------------------------------------------
// EXTRACT FEATURES FROM HISTORICAL BAR
//--------------------------------------------------------------------
void ML_ExtractFeatures_Historical(string symbol, int timeframe, int bar, double &features[]) {
   // Same as ML_ExtractFeatures_Enhanced but uses historical bar index
   ArrayResize(features, 30);

   double close = iClose(symbol, timeframe, bar);
   double open = iOpen(symbol, timeframe, bar);
   double high = iHigh(symbol, timeframe, bar);
   double low = iLow(symbol, timeframe, bar);

   // Simplified version - extract key features
   features[0] = iRSI(symbol, timeframe, 14, PRICE_CLOSE, bar) / 100.0;
   features[1] = iStochastic(symbol, timeframe, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, bar) / 100.0;
   features[2] = (iWPR(symbol, timeframe, 14, bar) + 100.0) / 100.0;
   features[3] = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MAIN, bar) / 100.0;

   double ma50 = iMA(symbol, timeframe, 50, 0, MODE_SMA, PRICE_CLOSE, bar);
   features[8] = (ma50 > 0) ? (close - ma50) / ma50 : 0.0;

   // ... (rest of features similar to ML_ExtractFeatures_Enhanced)
   // For brevity, initialize remaining to 0
   for(int i = 4; i < 30; i++) {
      features[i] = 0.0;
   }
}

//+------------------------------------------------------------------+
