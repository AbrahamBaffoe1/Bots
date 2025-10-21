//+------------------------------------------------------------------+
//|                                         SST_MultiAsset.mqh       |
//|          Smart Stock Trader - Multi-Asset Confirmation System    |
//|    SPY, sector ETFs, bonds, dollar, VIX - complete market view   |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// MULTI-ASSET PARAMETERS
//--------------------------------------------------------------------
extern bool    UseMultiAssetFilter   = true;         // Enable multi-asset confirmation
extern string  MarketIndex           = "SPY";        // Main market index (SPY, QQQ, DIA)
extern string  SectorETF             = "";           // Sector ETF (XLK=tech, XLF=finance, etc.)
extern string  BondSymbol            = "TLT";        // 20-year Treasury
extern string  DollarSymbol          = "DXY";        // US Dollar Index
extern string  VIXSymbol             = "VIX";        // Volatility Index
extern int     MarketTrendMA         = 50;           // MA period for market trend
extern double  VIXLowThreshold       = 15.0;         // VIX below = complacency
extern double  VIXHighThreshold      = 25.0;         // VIX above = fear

//--------------------------------------------------------------------
// MARKET REGIME ENUM
//--------------------------------------------------------------------
enum MARKET_REGIME {
   REGIME_RISK_ON,        // Stocks up, VIX low, bonds down = bullish
   REGIME_RISK_OFF,       // Stocks down, VIX high, bonds up = bearish
   REGIME_ROTATION,       // Mixed signals, sector rotation
   REGIME_UNCERTAIN       // Unclear, conflicting signals
};

//--------------------------------------------------------------------
// SECTOR ETF MAP
//--------------------------------------------------------------------
struct SectorETFMap {
   string symbol;          // Stock symbol
   string etf;            // Corresponding sector ETF
   string sectorName;     // Sector name
};

SectorETFMap g_SectorETFs[];

//--------------------------------------------------------------------
// INITIALIZE SECTOR ETF MAPPING
//--------------------------------------------------------------------
void MultiAsset_InitSectorETFs() {
   ArrayResize(g_SectorETFs, 50);
   int index = 0;

   // Technology - XLK
   MultiAsset_AddSectorETF("AAPL", "XLK", "Technology", index++);
   MultiAsset_AddSectorETF("MSFT", "XLK", "Technology", index++);
   MultiAsset_AddSectorETF("GOOGL", "XLK", "Technology", index++);
   MultiAsset_AddSectorETF("NVDA", "XLK", "Technology", index++);
   MultiAsset_AddSectorETF("AMD", "XLK", "Technology", index++);

   // Finance - XLF
   MultiAsset_AddSectorETF("JPM", "XLF", "Finance", index++);
   MultiAsset_AddSectorETF("BAC", "XLF", "Finance", index++);
   MultiAsset_AddSectorETF("WFC", "XLF", "Finance", index++);
   MultiAsset_AddSectorETF("GS", "XLF", "Finance", index++);

   // Healthcare - XLV
   MultiAsset_AddSectorETF("JNJ", "XLV", "Healthcare", index++);
   MultiAsset_AddSectorETF("UNH", "XLV", "Healthcare", index++);
   MultiAsset_AddSectorETF("PFE", "XLV", "Healthcare", index++);

   // Energy - XLE
   MultiAsset_AddSectorETF("XOM", "XLE", "Energy", index++);
   MultiAsset_AddSectorETF("CVX", "XLE", "Energy", index++);

   // Consumer - XLY
   MultiAsset_AddSectorETF("AMZN", "XLY", "Consumer", index++);
   MultiAsset_AddSectorETF("TSLA", "XLY", "Consumer", index++);
   MultiAsset_AddSectorETF("HD", "XLY", "Consumer", index++);

   ArrayResize(g_SectorETFs, index);
   Print("📊 Sector ETF mapping initialized: ", index, " symbols");
}

void MultiAsset_AddSectorETF(string symbol, string etf, string sector, int &idx) {
   g_SectorETFs[idx].symbol = symbol;
   g_SectorETFs[idx].etf = etf;
   g_SectorETFs[idx].sectorName = sector;
}

//--------------------------------------------------------------------
// GET SECTOR ETF FOR SYMBOL
//--------------------------------------------------------------------
string MultiAsset_GetSectorETF(string symbol) {
   for(int i = 0; i < ArraySize(g_SectorETFs); i++) {
      if(g_SectorETFs[i].symbol == symbol) {
         return g_SectorETFs[i].etf;
      }
   }
   return "SPY"; // Default to market
}

//--------------------------------------------------------------------
// CHECK MARKET DIRECTION (Bullish/Bearish)
//--------------------------------------------------------------------
bool MultiAsset_IsMarketBullish() {
   double spyPrice = iClose(MarketIndex, PERIOD_D1, 0);
   double spyMA = iMA(MarketIndex, PERIOD_D1, MarketTrendMA, 0, MODE_SMA, PRICE_CLOSE, 0);

   if(spyPrice == 0 || spyMA == 0) {
      if(VerboseLogging) Print("⚠ ", MarketIndex, " data not available");
      return true; // Default to allow trading
   }

   return (spyPrice > spyMA);
}

//--------------------------------------------------------------------
// CHECK SECTOR STRENGTH
//--------------------------------------------------------------------
bool MultiAsset_IsSectorStrong(string symbol) {
   string sectorETF = MultiAsset_GetSectorETF(symbol);

   double sectorPrice = iClose(sectorETF, PERIOD_D1, 0);
   double sectorMA = iMA(sectorETF, PERIOD_D1, 20, 0, MODE_SMA, PRICE_CLOSE, 0);

   if(sectorPrice == 0 || sectorMA == 0) {
      return true; // If no data, allow trade
   }

   // Sector must be above its 20-day MA
   if(sectorPrice > sectorMA) {
      if(VerboseLogging) Print("✓ Sector ", sectorETF, " strong (", DoubleToString(sectorPrice, 2),
                               " > MA20: ", DoubleToString(sectorMA, 2), ")");
      return true;
   }

   if(VerboseLogging) Print("✗ Sector ", sectorETF, " weak (", DoubleToString(sectorPrice, 2),
                            " < MA20: ", DoubleToString(sectorMA, 2), ")");
   return false;
}

//--------------------------------------------------------------------
// GET VIX LEVEL (Fear gauge)
//--------------------------------------------------------------------
double MultiAsset_GetVIX() {
   double vix = iClose(VIXSymbol, PERIOD_D1, 0);

   if(vix == 0) {
      if(VerboseLogging) Print("⚠ VIX data not available");
      return 20.0; // Default neutral level
   }

   return vix;
}

//--------------------------------------------------------------------
// CHECK VIX REGIME
//--------------------------------------------------------------------
string MultiAsset_GetVIXRegime() {
   double vix = MultiAsset_GetVIX();

   if(vix < VIXLowThreshold) {
      return "🟢 LOW (Complacency)";
   } else if(vix > VIXHighThreshold) {
      return "🔴 HIGH (Fear)";
   } else {
      return "🟡 NORMAL";
   }
}

//--------------------------------------------------------------------
// CHECK BONDS (Risk-off indicator)
//--------------------------------------------------------------------
bool MultiAsset_AreBondsRising() {
   // Rising bonds (TLT) = flight to safety = risk-off
   double tltClose = iClose(BondSymbol, PERIOD_D1, 0);
   double tltPrev = iClose(BondSymbol, PERIOD_D1, 5);

   if(tltClose == 0 || tltPrev == 0) return false;

   return (tltClose > tltPrev);
}

//--------------------------------------------------------------------
// CHECK DOLLAR STRENGTH (Affects stocks)
//--------------------------------------------------------------------
bool MultiAsset_IsDollarRising() {
   // Rising dollar often = falling stocks (inverse relationship)
   double dxyClose = iClose(DollarSymbol, PERIOD_D1, 0);
   double dxyPrev = iClose(DollarSymbol, PERIOD_D1, 5);

   if(dxyClose == 0 || dxyPrev == 0) return false;

   return (dxyClose > dxyPrev);
}

//--------------------------------------------------------------------
// DETERMINE MARKET REGIME
//--------------------------------------------------------------------
MARKET_REGIME MultiAsset_GetMarketRegime() {
   bool marketBullish = MultiAsset_IsMarketBullish();
   double vix = MultiAsset_GetVIX();
   bool bondsRising = MultiAsset_AreBondsRising();
   bool dollarRising = MultiAsset_IsDollarRising();

   // RISK-ON: Market up, VIX low, bonds down
   if(marketBullish && vix < VIXLowThreshold && !bondsRising) {
      if(VerboseLogging) Print("📈 Market Regime: RISK-ON");
      return REGIME_RISK_ON;
   }

   // RISK-OFF: Market down, VIX high, bonds up
   if(!marketBullish && vix > VIXHighThreshold && bondsRising) {
      if(VerboseLogging) Print("📉 Market Regime: RISK-OFF");
      return REGIME_RISK_OFF;
   }

   // ROTATION: Mixed signals
   if(marketBullish != !bondsRising) {
      if(VerboseLogging) Print("🔄 Market Regime: ROTATION");
      return REGIME_ROTATION;
   }

   // UNCERTAIN: Conflicting signals
   if(VerboseLogging) Print("❓ Market Regime: UNCERTAIN");
   return REGIME_UNCERTAIN;
}

//--------------------------------------------------------------------
// CHECK MULTI-ASSET CONFIRMATION FOR TRADE
//--------------------------------------------------------------------
bool MultiAsset_ConfirmTrade(string symbol, bool isLong) {
   if(!UseMultiAssetFilter) return true;

   int confirmations = 0;
   int signals = 0;

   // Check 1: Market Direction
   bool marketBullish = MultiAsset_IsMarketBullish();
   signals++;

   if(isLong && marketBullish) {
      confirmations++;
      if(VerboseLogging) Print("✓ Market bullish - supports LONG");
   } else if(!isLong && !marketBullish) {
      confirmations++;
      if(VerboseLogging) Print("✓ Market bearish - supports SHORT");
   } else {
      if(VerboseLogging) Print("✗ Market direction conflicts with trade");
   }

   // Check 2: Sector Strength
   bool sectorStrong = MultiAsset_IsSectorStrong(symbol);
   signals++;

   if(isLong && sectorStrong) {
      confirmations++;
      if(VerboseLogging) Print("✓ Sector strong - supports LONG");
   } else if(isLong && !sectorStrong) {
      if(VerboseLogging) Print("✗ Sector weak - conflicts with LONG");
   }

   // Check 3: VIX Level
   double vix = MultiAsset_GetVIX();
   signals++;

   if(isLong && vix < VIXHighThreshold) {
      confirmations++;
      if(VerboseLogging) Print("✓ VIX reasonable (", DoubleToString(vix, 1), ") - supports LONG");
   } else if(isLong && vix >= VIXHighThreshold) {
      if(VerboseLogging) Print("✗ VIX high (", DoubleToString(vix, 1), ") - fear mode");
   }

   // Check 4: Bonds (Risk-off check)
   bool bondsRising = MultiAsset_AreBondsRising();
   signals++;

   if(isLong && !bondsRising) {
      confirmations++;
      if(VerboseLogging) Print("✓ Bonds not rising - risk-on supports LONG");
   } else if(isLong && bondsRising) {
      if(VerboseLogging) Print("✗ Bonds rising - flight to safety");
   }

   // Need at least 75% confirmation
   double confirmationRate = (double)confirmations / signals;

   if(VerboseLogging) {
      Print("📊 Multi-Asset Confirmation: ", confirmations, "/", signals,
            " (", DoubleToString(confirmationRate * 100, 0), "%)");
   }

   return (confirmationRate >= 0.75); // Need 75% agreement
}

//--------------------------------------------------------------------
// GET INTERMARKET DIVERGENCE (Warning signal)
//--------------------------------------------------------------------
bool MultiAsset_DetectDivergence() {
   // Check if stocks rising but breadth weakening
   // (Advanced: would check NYSE advance/decline, new highs/lows)

   bool marketBullish = MultiAsset_IsMarketBullish();
   double vix = MultiAsset_GetVIX();

   // Divergence: Stocks up but VIX not falling (hidden fear)
   if(marketBullish && vix > 20.0) {
      if(VerboseLogging) Print("⚠ DIVERGENCE: Market up but VIX elevated - caution!");
      return true;
   }

   return false;
}

//--------------------------------------------------------------------
// GET MARKET BREADTH SCORE (0-100)
//--------------------------------------------------------------------
double MultiAsset_GetBreadthScore() {
   // Simplified breadth calculation
   // Real implementation would check:
   // - % of stocks above 50-day MA
   // - Advance/decline line
   // - New highs vs new lows

   double score = 50.0; // Neutral

   if(MultiAsset_IsMarketBullish()) score += 25.0;

   double vix = MultiAsset_GetVIX();
   if(vix < VIXLowThreshold) score += 15.0;
   else if(vix > VIXHighThreshold) score -= 15.0;

   if(!MultiAsset_AreBondsRising()) score += 10.0;
   else score -= 10.0;

   if(score > 100) score = 100;
   if(score < 0) score = 0;

   return score;
}

//--------------------------------------------------------------------
// GET MARKET STATUS STRING (for dashboard)
//--------------------------------------------------------------------
string MultiAsset_GetStatusString() {
   string status = "";

   // Market trend
   status += MarketIndex + ": ";
   status += MultiAsset_IsMarketBullish() ? "🟢 Bullish\n" : "🔴 Bearish\n";

   // VIX
   double vix = MultiAsset_GetVIX();
   status += "VIX: " + DoubleToString(vix, 1) + " " + MultiAsset_GetVIXRegime() + "\n";

   // Regime
   MARKET_REGIME regime = MultiAsset_GetMarketRegime();
   status += "Regime: ";
   switch(regime) {
      case REGIME_RISK_ON: status += "📈 RISK-ON\n"; break;
      case REGIME_RISK_OFF: status += "📉 RISK-OFF\n"; break;
      case REGIME_ROTATION: status += "🔄 ROTATION\n"; break;
      case REGIME_UNCERTAIN: status += "❓ UNCERTAIN\n"; break;
   }

   // Breadth
   double breadth = MultiAsset_GetBreadthScore();
   status += "Breadth: " + DoubleToString(breadth, 0) + "/100";

   return status;
}

//+------------------------------------------------------------------+
