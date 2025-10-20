//+------------------------------------------------------------------+
//|                                       SST_MarketStructure.mqh |
//|                Smart Stock Trader - Market Structure Analysis    |
//|     Support/Resistance, Order Blocks, Supply/Demand Zones       |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// MARKET STRUCTURE FUNCTIONS
//--------------------------------------------------------------------

// Find Support and Resistance levels
void Structure_FindSRLevels(string symbol, int timeframe) {
   if(!UseSupportResistance) return;

   // Clear old levels for this symbol
   for(int i = ArraySize(g_SRLevels) - 1; i >= 0; i--) {
      if(g_SRLevels[i].symbol == symbol) {
         for(int j = i; j < ArraySize(g_SRLevels) - 1; j++) {
            g_SRLevels[j] = g_SRLevels[j + 1];
         }
         ArrayResize(g_SRLevels, ArraySize(g_SRLevels) - 1);
      }
   }

   // Find swing points
   double point = MarketInfo(symbol, MODE_POINT);
   double tolerance = 50 * point; // Price tolerance for level clustering

   // Scan for swing highs (resistance)
   for(int i = 5; i < SR_Lookback - 5; i++) {
      double high = iHigh(symbol, timeframe, i);
      bool isSwingHigh = true;

      // Check if this is a local high
      for(int j = 1; j <= 3; j++) {
         if(iHigh(symbol, timeframe, i - j) >= high || iHigh(symbol, timeframe, i + j) >= high) {
            isSwingHigh = false;
            break;
         }
      }

      if(isSwingHigh) {
         // Count touches of this level
         int touches = 1;
         datetime lastTouch = iTime(symbol, timeframe, i);

         for(int k = 0; k < SR_Lookback; k++) {
            if(k == i) continue;
            double testHigh = iHigh(symbol, timeframe, k);
            if(MathAbs(testHigh - high) <= tolerance) {
               touches++;
               if(iTime(symbol, timeframe, k) > lastTouch) {
                  lastTouch = iTime(symbol, timeframe, k);
               }
            }
         }

         // Add if strong enough
         if(touches >= SR_Strength) {
            SupportResistance sr;
            sr.symbol = symbol;
            sr.level = high;
            sr.touches = touches;
            sr.lastTouch = lastTouch;
            sr.isSupport = false;

            int size = ArraySize(g_SRLevels);
            ArrayResize(g_SRLevels, size + 1);
            g_SRLevels[size] = sr;
         }
      }
   }

   // Scan for swing lows (support)
   for(int i = 5; i < SR_Lookback - 5; i++) {
      double low = iLow(symbol, timeframe, i);
      bool isSwingLow = true;

      // Check if this is a local low
      for(int j = 1; j <= 3; j++) {
         if(iLow(symbol, timeframe, i - j) <= low || iLow(symbol, timeframe, i + j) <= low) {
            isSwingLow = false;
            break;
         }
      }

      if(isSwingLow) {
         // Count touches of this level
         int touches = 1;
         datetime lastTouch = iTime(symbol, timeframe, i);

         for(int k = 0; k < SR_Lookback; k++) {
            if(k == i) continue;
            double testLow = iLow(symbol, timeframe, k);
            if(MathAbs(testLow - low) <= tolerance) {
               touches++;
               if(iTime(symbol, timeframe, k) > lastTouch) {
                  lastTouch = iTime(symbol, timeframe, k);
               }
            }
         }

         // Add if strong enough
         if(touches >= SR_Strength) {
            SupportResistance sr;
            sr.symbol = symbol;
            sr.level = low;
            sr.touches = touches;
            sr.lastTouch = lastTouch;
            sr.isSupport = true;

            int size = ArraySize(g_SRLevels);
            ArrayResize(g_SRLevels, size + 1);
            g_SRLevels[size] = sr;
         }
      }
   }

   if(DebugMode) {
      Print("Found ", ArraySize(g_SRLevels), " S/R levels for ", symbol);
   }
}

// Check if price is near support
bool Structure_IsNearSupport(string symbol, double price) {
   double point = MarketInfo(symbol, MODE_POINT);
   double tolerance = 30 * point;

   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].symbol == symbol && g_SRLevels[i].isSupport) {
         if(MathAbs(price - g_SRLevels[i].level) <= tolerance) {
            return true;
         }
      }
   }

   return false;
}

// Check if price is near resistance
bool Structure_IsNearResistance(string symbol, double price) {
   double point = MarketInfo(symbol, MODE_POINT);
   double tolerance = 30 * point;

   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].symbol == symbol && !g_SRLevels[i].isSupport) {
         if(MathAbs(price - g_SRLevels[i].level) <= tolerance) {
            return true;
         }
      }
   }

   return false;
}

// Get nearest support level
double Structure_GetNearestSupport(string symbol, double price) {
   double nearestSupport = 0;
   double minDistance = 999999;

   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].symbol == symbol && g_SRLevels[i].isSupport) {
         double distance = price - g_SRLevels[i].level;
         if(distance > 0 && distance < minDistance) {
            minDistance = distance;
            nearestSupport = g_SRLevels[i].level;
         }
      }
   }

   return nearestSupport;
}

// Get nearest resistance level
double Structure_GetNearestResistance(string symbol, double price) {
   double nearestResistance = 999999;
   double minDistance = 999999;

   for(int i = 0; i < ArraySize(g_SRLevels); i++) {
      if(g_SRLevels[i].symbol == symbol && !g_SRLevels[i].isSupport) {
         double distance = g_SRLevels[i].level - price;
         if(distance > 0 && distance < minDistance) {
            minDistance = distance;
            nearestResistance = g_SRLevels[i].level;
         }
      }
   }

   return nearestResistance;
}

// Detect Order Blocks (simplified version)
bool Structure_IsOrderBlock(string symbol, int timeframe, int shift, bool &isBullish) {
   if(!UseOrderBlocks) return false;

   // Order block: Strong candle followed by consolidation/reversal
   double body = Pattern_GetBodySize(symbol, timeframe, shift);
   double avgBody = 0;

   for(int i = shift + 1; i <= shift + 5; i++) {
      avgBody += Pattern_GetBodySize(symbol, timeframe, i);
   }
   avgBody /= 5;

   // Strong candle (2x average)
   if(body > avgBody * 2.0) {
      isBullish = Pattern_IsBullish(symbol, timeframe, shift);
      return true;
   }

   return false;
}

// Detect Supply/Demand Zones
bool Structure_IsSupplyDemandZone(string symbol, int timeframe, double price, bool &isSupply) {
   if(!UseSupplyDemand) return false;

   double point = MarketInfo(symbol, MODE_POINT);
   double zoneSize = 50 * point;

   // Look for zones with strong moves away from them
   for(int i = 10; i < 50; i++) {
      double high = iHigh(symbol, timeframe, i);
      double low = iLow(symbol, timeframe, i);

      // Check if price is in this zone
      if(price >= low - zoneSize && price <= high + zoneSize) {
         // Check for strong move after this zone
         double moveAfter = 0;
         for(int j = i - 1; j >= MathMax(0, i - 5); j--) {
            moveAfter += MathAbs(iClose(symbol, timeframe, j) - iClose(symbol, timeframe, j + 1));
         }

         double avgMove = moveAfter / 5.0;
         double currentBody = Pattern_GetBodySize(symbol, timeframe, i);

         if(avgMove > currentBody * 3.0) {
            // Strong move detected - this is a S/D zone
            double moveDirection = iClose(symbol, timeframe, i - 1) - iClose(symbol, timeframe, i);
            isSupply = (moveDirection < 0); // Move down = supply zone
            return true;
         }
      }
   }

   return false;
}

// Check if trend structure is intact (higher highs/higher lows for uptrend)
int Structure_GetTrendStructure(string symbol, int timeframe, int lookback = 50) {
   int swingHighs = 0;
   int swingLows = 0;
   double lastSwingHigh = 0;
   double lastSwingLow = 999999;
   bool higherHighs = true;
   bool higherLows = true;
   bool lowerHighs = true;
   bool lowerLows = true;

   for(int i = 3; i < lookback - 3; i++) {
      // Check for swing high
      if(iHigh(symbol, timeframe, i) > iHigh(symbol, timeframe, i - 1) &&
         iHigh(symbol, timeframe, i) > iHigh(symbol, timeframe, i + 1)) {

         if(swingHighs > 0) {
            if(iHigh(symbol, timeframe, i) <= lastSwingHigh) higherHighs = false;
            if(iHigh(symbol, timeframe, i) >= lastSwingHigh) lowerHighs = false;
         }

         lastSwingHigh = iHigh(symbol, timeframe, i);
         swingHighs++;
      }

      // Check for swing low
      if(iLow(symbol, timeframe, i) < iLow(symbol, timeframe, i - 1) &&
         iLow(symbol, timeframe, i) < iLow(symbol, timeframe, i + 1)) {

         if(swingLows > 0) {
            if(iLow(symbol, timeframe, i) <= lastSwingLow) lowerLows = false;
            if(iLow(symbol, timeframe, i) >= lastSwingLow) higherLows = false;
         }

         lastSwingLow = iLow(symbol, timeframe, i);
         swingLows++;
      }
   }

   // Determine trend
   if(higherHighs && higherLows && swingHighs >= 2 && swingLows >= 2) {
      return 1; // Uptrend
   } else if(lowerHighs && lowerLows && swingHighs >= 2 && swingLows >= 2) {
      return -1; // Downtrend
   }

   return 0; // No clear trend
}

// Initialize market structure analysis for all symbols
void Structure_Init() {
   Print("=== Market Structure Analyzer Initialized ===");

   for(int i = 0; i < g_SymbolCount; i++) {
      Structure_FindSRLevels(g_Symbols[i], PERIOD_H1);
   }

   Print("Total S/R levels found: ", ArraySize(g_SRLevels));
}

// Update market structure (call periodically)
void Structure_Update() {
   static datetime lastUpdate = 0;

   // Update every hour
   if(TimeCurrent() - lastUpdate > 3600) {
      for(int i = 0; i < g_SymbolCount; i++) {
         Structure_FindSRLevels(g_Symbols[i], PERIOD_H1);
      }
      lastUpdate = TimeCurrent();

      if(DebugMode) Print("Market structure updated");
   }
}

//+------------------------------------------------------------------+
