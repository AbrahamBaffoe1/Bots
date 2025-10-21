//+------------------------------------------------------------------+
//|                                      SST_CorrelationMatrix.mqh   |
//|              Smart Stock Trader - Portfolio Correlation Manager  |
//|        Prevent correlated losses, sector limits, risk parity     |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// CORRELATION PARAMETERS
//--------------------------------------------------------------------
extern bool    UseCorrelationFilter  = true;         // Enable correlation filtering
extern double  MaxCorrelation        = 0.70;         // Max correlation between positions (0-1)
extern int     CorrelationPeriod     = 50;           // Lookback period for correlation
extern int     MaxPositionsPerSector = 3;            // Max positions in same sector
extern double  MaxSectorExposure     = 0.30;         // Max 30% of portfolio in one sector
extern bool    UseRiskParity         = true;         // Equal risk contribution per position

//--------------------------------------------------------------------
// SECTOR DEFINITIONS
//--------------------------------------------------------------------
enum SECTOR_TYPE {
   SECTOR_TECHNOLOGY,
   SECTOR_FINANCE,
   SECTOR_HEALTHCARE,
   SECTOR_ENERGY,
   SECTOR_CONSUMER,
   SECTOR_INDUSTRIAL,
   SECTOR_MATERIALS,
   SECTOR_UTILITIES,
   SECTOR_REALESTATE,
   SECTOR_TELECOM,
   SECTOR_OTHER
};

// Symbol to Sector mapping
struct SymbolSector {
   string symbol;
   SECTOR_TYPE sector;
   string sectorName;
};

SymbolSector g_SectorMap[];

//--------------------------------------------------------------------
// CORRELATION CACHE
//--------------------------------------------------------------------
struct CorrelationPair {
   string symbol1;
   string symbol2;
   double correlation;
   datetime calculatedTime;
};

CorrelationPair g_CorrelationCache[];
int g_CacheSize = 0;

//--------------------------------------------------------------------
// INITIALIZE SECTOR MAP
//--------------------------------------------------------------------
void Correlation_InitializeSectorMap() {
   Print("🏢 Initializing Sector Map...");

   int mapSize = 0;
   ArrayResize(g_SectorMap, 100);  // Room for 100 symbols

   // TECHNOLOGY SECTOR
   Correlation_AddToSectorMap("AAPL", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("MSFT", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("GOOGL", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("GOOG", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("AMZN", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("META", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("NVDA", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("AMD", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("NFLX", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("TSLA", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("CRM", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("ORCL", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("ADBE", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("INTC", SECTOR_TECHNOLOGY, "Technology", mapSize++);
   Correlation_AddToSectorMap("CSCO", SECTOR_TECHNOLOGY, "Technology", mapSize++);

   // FINANCE SECTOR
   Correlation_AddToSectorMap("JPM", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("BAC", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("WFC", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("GS", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("MS", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("C", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("V", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("MA", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("AXP", SECTOR_FINANCE, "Finance", mapSize++);
   Correlation_AddToSectorMap("BRK.B", SECTOR_FINANCE, "Finance", mapSize++);

   // HEALTHCARE SECTOR
   Correlation_AddToSectorMap("JNJ", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("UNH", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("PFE", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("ABT", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("TMO", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("MRK", SECTOR_HEALTHCARE, "Healthcare", mapSize++);
   Correlation_AddToSectorMap("LLY", SECTOR_HEALTHCARE, "Healthcare", mapSize++);

   // ENERGY SECTOR
   Correlation_AddToSectorMap("XOM", SECTOR_ENERGY, "Energy", mapSize++);
   Correlation_AddToSectorMap("CVX", SECTOR_ENERGY, "Energy", mapSize++);
   Correlation_AddToSectorMap("COP", SECTOR_ENERGY, "Energy", mapSize++);
   Correlation_AddToSectorMap("SLB", SECTOR_ENERGY, "Energy", mapSize++);

   // CONSUMER SECTOR
   Correlation_AddToSectorMap("WMT", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("PG", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("KO", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("PEP", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("COST", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("NKE", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("MCD", SECTOR_CONSUMER, "Consumer", mapSize++);
   Correlation_AddToSectorMap("DIS", SECTOR_CONSUMER, "Consumer", mapSize++);

   // INDUSTRIAL SECTOR
   Correlation_AddToSectorMap("BA", SECTOR_INDUSTRIAL, "Industrial", mapSize++);
   Correlation_AddToSectorMap("CAT", SECTOR_INDUSTRIAL, "Industrial", mapSize++);
   Correlation_AddToSectorMap("GE", SECTOR_INDUSTRIAL, "Industrial", mapSize++);
   Correlation_AddToSectorMap("MMM", SECTOR_INDUSTRIAL, "Industrial", mapSize++);
   Correlation_AddToSectorMap("UPS", SECTOR_INDUSTRIAL, "Industrial", mapSize++);

   ArrayResize(g_SectorMap, mapSize);

   Print("✓ Sector map initialized with ", mapSize, " symbols across 7 sectors");
}

void Correlation_AddToSectorMap(string symbol, SECTOR_TYPE sector, string sectorName, int &index) {
   g_SectorMap[index].symbol = symbol;
   g_SectorMap[index].sector = sector;
   g_SectorMap[index].sectorName = sectorName;
}

//--------------------------------------------------------------------
// GET SECTOR FOR SYMBOL
//--------------------------------------------------------------------
SECTOR_TYPE Correlation_GetSector(string symbol) {
   for(int i = 0; i < ArraySize(g_SectorMap); i++) {
      if(g_SectorMap[i].symbol == symbol) {
         return g_SectorMap[i].sector;
      }
   }
   return SECTOR_OTHER;
}

string Correlation_GetSectorName(string symbol) {
   for(int i = 0; i < ArraySize(g_SectorMap); i++) {
      if(g_SectorMap[i].symbol == symbol) {
         return g_SectorMap[i].sectorName;
      }
   }
   return "Other";
}

//--------------------------------------------------------------------
// CALCULATE CORRELATION BETWEEN TWO SYMBOLS
//--------------------------------------------------------------------
double Correlation_Calculate(string symbol1, string symbol2, int period) {
   // Check cache first
   double cachedCorr = Correlation_GetFromCache(symbol1, symbol2);
   if(cachedCorr != -999.0) return cachedCorr;

   // Calculate Pearson correlation coefficient
   double returns1[];
   double returns2[];
   ArrayResize(returns1, period);
   ArrayResize(returns2, period);

   // Get returns for both symbols
   for(int i = 0; i < period; i++) {
      double close1_current = iClose(symbol1, PERIOD_D1, i);
      double close1_prev = iClose(symbol1, PERIOD_D1, i + 1);
      double close2_current = iClose(symbol2, PERIOD_D1, i);
      double close2_prev = iClose(symbol2, PERIOD_D1, i + 1);

      if(close1_prev == 0 || close2_prev == 0) {
         // Data not available
         return 0.0;
      }

      returns1[i] = (close1_current - close1_prev) / close1_prev;
      returns2[i] = (close2_current - close2_prev) / close2_prev;
   }

   // Calculate means
   double mean1 = 0, mean2 = 0;
   for(int i = 0; i < period; i++) {
      mean1 += returns1[i];
      mean2 += returns2[i];
   }
   mean1 /= period;
   mean2 /= period;

   // Calculate correlation
   double numerator = 0;
   double sumSq1 = 0;
   double sumSq2 = 0;

   for(int i = 0; i < period; i++) {
      double diff1 = returns1[i] - mean1;
      double diff2 = returns2[i] - mean2;

      numerator += diff1 * diff2;
      sumSq1 += diff1 * diff1;
      sumSq2 += diff2 * diff2;
   }

   double denominator = MathSqrt(sumSq1) * MathSqrt(sumSq2);

   if(denominator == 0) return 0.0;

   double correlation = numerator / denominator;

   // Cache the result
   Correlation_AddToCache(symbol1, symbol2, correlation);

   return correlation;
}

//--------------------------------------------------------------------
// CACHE MANAGEMENT
//--------------------------------------------------------------------
double Correlation_GetFromCache(string symbol1, string symbol2) {
   datetime currentTime = TimeCurrent();

   for(int i = 0; i < g_CacheSize; i++) {
      bool match = (g_CorrelationCache[i].symbol1 == symbol1 && g_CorrelationCache[i].symbol2 == symbol2) ||
                   (g_CorrelationCache[i].symbol1 == symbol2 && g_CorrelationCache[i].symbol2 == symbol1);

      if(match) {
         // Check if cache is still fresh (less than 24 hours old)
         if(currentTime - g_CorrelationCache[i].calculatedTime < 86400) {
            return g_CorrelationCache[i].correlation;
         }
      }
   }

   return -999.0; // Not found
}

void Correlation_AddToCache(string symbol1, string symbol2, double correlation) {
   ArrayResize(g_CorrelationCache, g_CacheSize + 1);

   g_CorrelationCache[g_CacheSize].symbol1 = symbol1;
   g_CorrelationCache[g_CacheSize].symbol2 = symbol2;
   g_CorrelationCache[g_CacheSize].correlation = correlation;
   g_CorrelationCache[g_CacheSize].calculatedTime = TimeCurrent();

   g_CacheSize++;
}

//--------------------------------------------------------------------
// CHECK IF NEW POSITION WOULD BE TOO CORRELATED
//--------------------------------------------------------------------
bool Correlation_CheckNewPosition(string newSymbol) {
   if(!UseCorrelationFilter) return true;

   // Get all currently open positions
   string openSymbols[];
   int openCount = 0;
   ArrayResize(openSymbols, OrdersTotal());

   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            openSymbols[openCount] = OrderSymbol();
            openCount++;
         }
      }
   }

   if(openCount == 0) return true; // No open positions, OK to trade

   // Check correlation with each open position
   for(int i = 0; i < openCount; i++) {
      double corr = Correlation_Calculate(newSymbol, openSymbols[i], CorrelationPeriod);

      if(MathAbs(corr) > MaxCorrelation) {
         if(VerboseLogging) Print("✗ High correlation detected: ", newSymbol, " vs ", openSymbols[i],
                                  " = ", DoubleToString(corr, 3), " (max: ", MaxCorrelation, ")");
         return false;
      }
   }

   return true;
}

//--------------------------------------------------------------------
// CHECK SECTOR EXPOSURE
//--------------------------------------------------------------------
bool Correlation_CheckSectorLimits(string newSymbol) {
   SECTOR_TYPE newSector = Correlation_GetSector(newSymbol);
   string sectorName = Correlation_GetSectorName(newSymbol);

   // Count positions in same sector
   int sectorPositions = 0;
   double sectorRisk = 0.0;
   double totalRisk = 0.0;

   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            string symbol = OrderSymbol();
            SECTOR_TYPE sector = Correlation_GetSector(symbol);

            double positionRisk = OrderLots() * MarketInfo(symbol, MODE_TICKVALUE);
            totalRisk += positionRisk;

            if(sector == newSector) {
               sectorPositions++;
               sectorRisk += positionRisk;
            }
         }
      }
   }

   // Check max positions per sector
   if(sectorPositions >= MaxPositionsPerSector) {
      if(VerboseLogging) Print("✗ Sector limit reached: ", sectorName, " has ", sectorPositions,
                               " positions (max: ", MaxPositionsPerSector, ")");
      return false;
   }

   // Check sector exposure percentage
   if(totalRisk > 0) {
      double sectorExposure = sectorRisk / totalRisk;
      if(sectorExposure > MaxSectorExposure) {
         if(VerboseLogging) Print("✗ Sector exposure too high: ", sectorName, " = ",
                                  DoubleToString(sectorExposure * 100, 1), "% (max: ",
                                  DoubleToString(MaxSectorExposure * 100, 1), "%)");
         return false;
      }
   }

   return true;
}

//--------------------------------------------------------------------
// GET PORTFOLIO DIVERSIFICATION SCORE (0-100)
//--------------------------------------------------------------------
double Correlation_GetDiversificationScore() {
   int totalPositions = 0;
   int uniqueSectors = 0;
   bool sectorHasPosition[11]; // 11 sector types

   // Initialize
   for(int i = 0; i < 11; i++) sectorHasPosition[i] = false;

   // Count positions and sectors
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            totalPositions++;
            SECTOR_TYPE sector = Correlation_GetSector(OrderSymbol());
            if(!sectorHasPosition[sector]) {
               sectorHasPosition[sector] = true;
               uniqueSectors++;
            }
         }
      }
   }

   if(totalPositions == 0) return 100.0;

   // Calculate average correlation between positions
   double totalCorrelation = 0;
   int correlationCount = 0;

   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            string symbol1 = OrderSymbol();

            for(int j = i + 1; j < OrdersTotal(); j++) {
               if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
                  if(OrderMagicNumber() == MagicNumber) {
                     string symbol2 = OrderSymbol();
                     double corr = Correlation_Calculate(symbol1, symbol2, CorrelationPeriod);
                     totalCorrelation += MathAbs(corr);
                     correlationCount++;
                  }
               }
            }
         }
      }
   }

   double avgCorrelation = (correlationCount > 0) ? (totalCorrelation / correlationCount) : 0.0;

   // Score calculation:
   // - Lower average correlation = better
   // - More unique sectors = better
   double correlationScore = (1.0 - avgCorrelation) * 70.0; // 70% weight
   double sectorScore = (uniqueSectors / 7.0) * 30.0;      // 30% weight (7 major sectors)

   return correlationScore + sectorScore;
}

//--------------------------------------------------------------------
// GET CORRELATION MATRIX (for display/analysis)
//--------------------------------------------------------------------
string Correlation_GetMatrixDisplay() {
   string output = "=== CORRELATION MATRIX ===\n";

   string openSymbols[];
   int openCount = 0;
   ArrayResize(openSymbols, OrdersTotal());

   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber) {
            openSymbols[openCount] = OrderSymbol();
            openCount++;
         }
      }
   }

   if(openCount == 0) {
      return "No open positions";
   }

   for(int i = 0; i < openCount; i++) {
      output += openSymbols[i] + " vs:\n";
      for(int j = 0; j < openCount; j++) {
         if(i != j) {
            double corr = Correlation_Calculate(openSymbols[i], openSymbols[j], CorrelationPeriod);
            output += "  " + openSymbols[j] + ": " + DoubleToString(corr, 3) + "\n";
         }
      }
   }

   return output;
}

//+------------------------------------------------------------------+
