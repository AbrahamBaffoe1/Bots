//+------------------------------------------------------------------+
//|                                             SST_Indicators.mqh |
//|                    Smart Stock Trader - Technical Indicators     |
//|            All indicator calculations and signal generation      |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// INDICATOR SIGNAL STRUCTURE
//--------------------------------------------------------------------
struct IndicatorSignals {
   // Trend indicators
   double fastMA;
   double slowMA;
   double trendMA;
   double vwap;

   // Momentum indicators
   double rsi;
   double macdMain;
   double macdSignal;
   double stochK;
   double stochD;

   // Volatility indicators
   double atr;
   double bbUpper;
   double bbMiddle;
   double bbLower;
   double bbWidth;

   // Trend strength
   double adx;
   double adxPlus;
   double adxMinus;

   // Volume
   double volume;
   double volumeMA;
   double obv;

   // Ichimoku
   double ichimokuTenkan;
   double ichimokuKijun;
   double ichimokuSenkouA;
   double ichimokuSenkouB;

   // Signal booleans
   bool isBullishMA;
   bool isBearishMA;
   bool isOverbought;
   bool isOversold;
   bool isTrending;
   bool isRanging;
   bool highVolume;
};

//--------------------------------------------------------------------
// CALCULATE VWAP (Volume Weighted Average Price)
//--------------------------------------------------------------------
double Ind_CalculateVWAP(string symbol, int timeframe) {
   // VWAP calculation for stocks
   double sumPV = 0;
   double sumV = 0;

   // Get start of day
   datetime dayStart = iTime(symbol, PERIOD_D1, 0);
   int barsSinceOpen = iBarShift(symbol, timeframe, dayStart, false);

   if(barsSinceOpen < 0) barsSinceOpen = 100; // Default lookback

   for(int i = 0; i < barsSinceOpen; i++) {
      double typical = (iHigh(symbol, timeframe, i) + iLow(symbol, timeframe, i) + iClose(symbol, timeframe, i)) / 3.0;
      double vol = (double)iVolume(symbol, timeframe, i);

      sumPV += typical * vol;
      sumV += vol;
   }

   if(sumV > 0) {
      return sumPV / sumV;
   }

   return iClose(symbol, timeframe, 0);
}

//--------------------------------------------------------------------
// CALCULATE OBV (On Balance Volume)
//--------------------------------------------------------------------
double Ind_CalculateOBV(string symbol, int timeframe, int period) {
   double obv = 0;

   for(int i = period - 1; i >= 0; i--) {
      double close = iClose(symbol, timeframe, i);
      double prevClose = iClose(symbol, timeframe, i + 1);
      double volume = (double)iVolume(symbol, timeframe, i);

      if(close > prevClose) {
         obv += volume;
      } else if(close < prevClose) {
         obv -= volume;
      }
   }

   return obv;
}

//--------------------------------------------------------------------
// GET ALL INDICATORS FOR A SYMBOL
//--------------------------------------------------------------------
IndicatorSignals Ind_GetSignals(string symbol, int timeframe) {
   IndicatorSignals signals;

   // Moving Averages
   signals.fastMA = iMA(symbol, timeframe, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
   signals.slowMA = iMA(symbol, timeframe, SlowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   signals.trendMA = iMA(symbol, timeframe, TrendMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);

   // VWAP
   signals.vwap = Ind_CalculateVWAP(symbol, timeframe);

   // RSI
   signals.rsi = iRSI(symbol, timeframe, RSI_Period, PRICE_CLOSE, 0);

   // MACD
   signals.macdMain = iMACD(symbol, timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
   signals.macdSignal = iMACD(symbol, timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);

   // Stochastic
   signals.stochK = iStochastic(symbol, timeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
   signals.stochD = iStochastic(symbol, timeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, 0);

   // ATR
   signals.atr = iATR(symbol, timeframe, ATR_Period, 0);

   // Bollinger Bands
   signals.bbUpper = iBands(symbol, timeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   signals.bbMiddle = iBands(symbol, timeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
   signals.bbLower = iBands(symbol, timeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   signals.bbWidth = (signals.bbUpper - signals.bbLower) / signals.bbMiddle * 100.0;

   // ADX
   signals.adx = iADX(symbol, timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   signals.adxPlus = iADX(symbol, timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, 0);
   signals.adxMinus = iADX(symbol, timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, 0);

   // Volume
   signals.volume = (double)iVolume(symbol, timeframe, 0);
   signals.volumeMA = 0;
   for(int i = 0; i < VolumeMA_Period; i++) {
      signals.volumeMA += (double)iVolume(symbol, timeframe, i);
   }
   signals.volumeMA /= VolumeMA_Period;
   signals.obv = Ind_CalculateOBV(symbol, timeframe, 50);

   // Ichimoku
   signals.ichimokuTenkan = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_TENKANSEN, 0);
   signals.ichimokuKijun = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_KIJUNSEN, 0);
   signals.ichimokuSenkouA = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANA, 0);
   signals.ichimokuSenkouB = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANB, 0);

   // Derive boolean signals
   double currentPrice = iClose(symbol, timeframe, 0);

   signals.isBullishMA = (signals.fastMA > signals.slowMA) && (currentPrice > signals.trendMA);
   signals.isBearishMA = (signals.fastMA < signals.slowMA) && (currentPrice < signals.trendMA);
   signals.isOverbought = (signals.rsi > RSI_Overbought) || (signals.stochK > 80);
   signals.isOversold = (signals.rsi < RSI_Oversold) || (signals.stochK < 20);
   signals.isTrending = (signals.adx > ADX_TrendThreshold);
   signals.isRanging = (signals.adx < ADX_TrendThreshold);
   signals.highVolume = (signals.volume > signals.volumeMA * VolumeSpikeThreshold);

   return signals;
}

//--------------------------------------------------------------------
// MULTI-TIMEFRAME CONFLUENCE
//--------------------------------------------------------------------
int Ind_GetMultiTimeframeSignal(string symbol) {
   int bullishCount = 0;
   int bearishCount = 0;

   // Check each timeframe
   int timeframes[3] = {MTF_Timeframe1, MTF_Timeframe2, MTF_Timeframe3};

   for(int i = 0; i < 3; i++) {
      IndicatorSignals sig = Ind_GetSignals(symbol, timeframes[i]);

      // Score this timeframe
      if(sig.isBullishMA && sig.macdMain > sig.macdSignal && sig.adxPlus > sig.adxMinus) {
         bullishCount++;
      }

      if(sig.isBearishMA && sig.macdMain < sig.macdSignal && sig.adxPlus < sig.adxMinus) {
         bearishCount++;
      }
   }

   // Return signal if minimum confluence met
   if(bullishCount >= MTF_MinConfluence) {
      return 1;  // Bullish
   }

   if(bearishCount >= MTF_MinConfluence) {
      return -1;  // Bearish
   }

   return 0;  // Neutral
}

//+------------------------------------------------------------------+
