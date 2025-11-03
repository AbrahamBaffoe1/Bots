//+------------------------------------------------------------------+
//|                                        SST_ScalpingStrategy.mqh  |
//|                        Copyright 2025, SmartStockTrader Team    |
//|                                      https://smartstocktrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, SmartStockTrader Team"
#property link      "https://smartstocktrader.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Scalping Strategy Types                                         |
//+------------------------------------------------------------------+
enum ENUM_SCALP_STRATEGY
{
   SCALP_BREAKOUT,      // Range breakout scalping
   SCALP_VWAP_BOUNCE,   // VWAP support/resistance bounce
   SCALP_MOMENTUM,      // Momentum with pattern confirmation
   SCALP_HYBRID         // All strategies combined
};

//+------------------------------------------------------------------+
//| Scalping Signal Structure                                       |
//+------------------------------------------------------------------+
struct ScalpSignal
{
   int               signal;           // 1=BUY, -1=SELL, 0=NONE
   double            entry_price;      // Suggested entry price
   double            stop_loss;        // Calculated stop loss
   double            take_profit;      // Calculated take profit
   double            confidence;       // Signal confidence (0.0-1.0)
   string            reason;           // Signal reason/description
   ENUM_SCALP_STRATEGY strategy_type;  // Which strategy triggered
   datetime          signal_time;      // When signal was generated
   double            atr_value;        // Current ATR value
   double            spread_points;    // Current spread in points
};

//+------------------------------------------------------------------+
//| Range Detection Structure                                        |
//+------------------------------------------------------------------+
struct RangeInfo
{
   double            high;             // Range high
   double            low;              // Range low
   double            size_pips;        // Range size in pips
   int               bars_in_range;    // Number of bars in range
   bool              is_valid;         // Is range valid for trading
   datetime          range_start;      // Range start time
};

//+------------------------------------------------------------------+
//| Scalping Strategy Class                                         |
//+------------------------------------------------------------------+
class CScalpingStrategy
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_range_bars;           // Bars to detect range
   double            m_min_range_pips;       // Minimum range size
   double            m_max_range_pips;       // Maximum range size
   double            m_vwap_bounce_pips;     // Distance for VWAP bounce
   double            m_breakout_confirm_pips; // Breakout confirmation
   int               m_atr_handle;           // ATR indicator handle
   int               m_rsi_handle;           // RSI indicator handle

   // VWAP calculation variables
   double            m_vwap_value;

   bool              CalculateVWAP(int bars_back = 20);
   bool              DetectRange(RangeInfo &range_info);
   bool              IsBreakoutValid(const RangeInfo &range, int direction);
   bool              IsVWAPBounceValid(double current_price, int direction);
   bool              IsMomentumValid(int direction);
   double            GetATR(int period = 14);
   double            GetRSI(int period = 14);
   double            GetCurrentSpread();

public:
                     CScalpingStrategy(string symbol, ENUM_TIMEFRAMES timeframe);
                    ~CScalpingStrategy();

   // Main signal generation
   ScalpSignal       GenerateSignal(ENUM_SCALP_STRATEGY strategy, double max_spread_points);

   // Individual strategy methods
   ScalpSignal       BreakoutScalping(double max_spread_points);
   ScalpSignal       VWAPBounceScalping(double max_spread_points);
   ScalpSignal       MomentumScalping(double max_spread_points);

   // Utility methods
   bool              IsSpreadAcceptable(double max_spread_points);
   double            CalculateStopLoss(int direction, double atr_value, int sl_pips);
   double            CalculateTakeProfit(int direction, double atr_value, int tp_pips);
   void              SetRangeBars(int bars) { m_range_bars = bars; }
   void              SetMinRangePips(double pips) { m_min_range_pips = pips; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CScalpingStrategy::CScalpingStrategy(string symbol, ENUM_TIMEFRAMES timeframe)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_range_bars = 5;                    // 5-bar range default
   m_min_range_pips = 10;               // Minimum 10 pips range
   m_max_range_pips = 100;              // Maximum 100 pips range
   m_vwap_bounce_pips = 5;              // 5 pips from VWAP
   m_breakout_confirm_pips = 3;         // 3 pips beyond range
   m_vwap_value = 0.0;

   // Initialize indicators
   m_atr_handle = iATR(m_symbol, m_timeframe, 14);
   m_rsi_handle = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE);

   if(m_atr_handle == INVALID_HANDLE || m_rsi_handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles in CScalpingStrategy");
   }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CScalpingStrategy::~CScalpingStrategy()
{
   if(m_atr_handle != INVALID_HANDLE) IndicatorRelease(m_atr_handle);
   if(m_rsi_handle != INVALID_HANDLE) IndicatorRelease(m_rsi_handle);
}

//+------------------------------------------------------------------+
//| Main Signal Generation                                           |
//+------------------------------------------------------------------+
ScalpSignal CScalpingStrategy::GenerateSignal(ENUM_SCALP_STRATEGY strategy, double max_spread_points)
{
   ScalpSignal signal;
   signal.signal = 0;
   signal.confidence = 0.0;
   signal.signal_time = TimeCurrent();
   signal.spread_points = GetCurrentSpread();
   signal.atr_value = GetATR();

   // Check spread first
   if(!IsSpreadAcceptable(max_spread_points))
   {
      signal.reason = "Spread too wide: " + DoubleToString(signal.spread_points, 1) + " points";
      return signal;
   }

   switch(strategy)
   {
      case SCALP_BREAKOUT:
         return BreakoutScalping(max_spread_points);
      case SCALP_VWAP_BOUNCE:
         return VWAPBounceScalping(max_spread_points);
      case SCALP_MOMENTUM:
         return MomentumScalping(max_spread_points);
      case SCALP_HYBRID:
         // Try all strategies, return highest confidence
         ScalpSignal s1 = BreakoutScalping(max_spread_points);
         ScalpSignal s2 = VWAPBounceScalping(max_spread_points);
         ScalpSignal s3 = MomentumScalping(max_spread_points);

         if(s1.confidence >= s2.confidence && s1.confidence >= s3.confidence) return s1;
         if(s2.confidence >= s1.confidence && s2.confidence >= s3.confidence) return s2;
         return s3;
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Breakout Scalping Strategy                                      |
//+------------------------------------------------------------------+
ScalpSignal CScalpingStrategy::BreakoutScalping(double max_spread_points)
{
   ScalpSignal signal;
   signal.signal = 0;
   signal.confidence = 0.0;
   signal.strategy_type = SCALP_BREAKOUT;
   signal.signal_time = TimeCurrent();
   signal.atr_value = GetATR();
   signal.spread_points = GetCurrentSpread();

   RangeInfo range;
   if(!DetectRange(range) || !range.is_valid)
   {
      signal.reason = "No valid range detected";
      return signal;
   }

   double current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double breakout_buffer = m_breakout_confirm_pips * point * 10; // Convert to price units

   // Check for bullish breakout
   if(current_price > range.high + breakout_buffer)
   {
      if(IsBreakoutValid(range, 1))
      {
         signal.signal = 1; // BUY
         signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         signal.stop_loss = range.low;
         signal.take_profit = signal.entry_price + (signal.entry_price - signal.stop_loss) * 2.0;
         signal.confidence = 0.75;
         signal.reason = "Bullish breakout above " + DoubleToString(range.high, _Digits) +
                        " (Range: " + DoubleToString(range.size_pips, 1) + " pips)";

         // Increase confidence with volume
         double volume = (double)iVolume(m_symbol, m_timeframe, 0);
         double avg_volume = 0;
         for(int i = 1; i <= 10; i++) avg_volume += (double)iVolume(m_symbol, m_timeframe, i);
         avg_volume /= 10.0;

         if(volume > avg_volume * 1.5) signal.confidence += 0.15;
      }
   }
   // Check for bearish breakout
   else if(current_price < range.low - breakout_buffer)
   {
      if(IsBreakoutValid(range, -1))
      {
         signal.signal = -1; // SELL
         signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         signal.stop_loss = range.high;
         signal.take_profit = signal.entry_price - (signal.stop_loss - signal.entry_price) * 2.0;
         signal.confidence = 0.75;
         signal.reason = "Bearish breakout below " + DoubleToString(range.low, _Digits) +
                        " (Range: " + DoubleToString(range.size_pips, 1) + " pips)";

         // Increase confidence with volume
         double volume = (double)iVolume(m_symbol, m_timeframe, 0);
         double avg_volume = 0;
         for(int i = 1; i <= 10; i++) avg_volume += (double)iVolume(m_symbol, m_timeframe, i);
         avg_volume /= 10.0;

         if(volume > avg_volume * 1.5) signal.confidence += 0.15;
      }
   }
   else
   {
      signal.reason = "Price still within range [" + DoubleToString(range.low, _Digits) +
                     " - " + DoubleToString(range.high, _Digits) + "]";
   }

   return signal;
}

//+------------------------------------------------------------------+
//| VWAP Bounce Scalping Strategy                                   |
//+------------------------------------------------------------------+
ScalpSignal CScalpingStrategy::VWAPBounceScalping(double max_spread_points)
{
   ScalpSignal signal;
   signal.signal = 0;
   signal.confidence = 0.0;
   signal.strategy_type = SCALP_VWAP_BOUNCE;
   signal.signal_time = TimeCurrent();
   signal.atr_value = GetATR();
   signal.spread_points = GetCurrentSpread();

   if(!CalculateVWAP(20))
   {
      signal.reason = "VWAP calculation failed";
      return signal;
   }

   double current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double vwap_distance = MathAbs(current_price - m_vwap_value) / (point * 10); // Pips

   // Check if price is near VWAP
   if(vwap_distance <= m_vwap_bounce_pips)
   {
      double rsi = GetRSI();

      // Bullish bounce from VWAP support
      if(current_price <= m_vwap_value && rsi < 50)
      {
         if(IsVWAPBounceValid(current_price, 1))
         {
            signal.signal = 1; // BUY
            signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
            signal.stop_loss = signal.entry_price - (signal.atr_value * 0.5);
            signal.take_profit = signal.entry_price + (signal.atr_value * 1.0);
            signal.confidence = 0.70;
            signal.reason = "VWAP support bounce (VWAP: " + DoubleToString(m_vwap_value, _Digits) +
                           ", Distance: " + DoubleToString(vwap_distance, 1) + " pips, RSI: " +
                           DoubleToString(rsi, 1) + ")";

            if(rsi < 40) signal.confidence += 0.10; // Stronger oversold
         }
      }
      // Bearish bounce from VWAP resistance
      else if(current_price >= m_vwap_value && rsi > 50)
      {
         if(IsVWAPBounceValid(current_price, -1))
         {
            signal.signal = -1; // SELL
            signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
            signal.stop_loss = signal.entry_price + (signal.atr_value * 0.5);
            signal.take_profit = signal.entry_price - (signal.atr_value * 1.0);
            signal.confidence = 0.70;
            signal.reason = "VWAP resistance bounce (VWAP: " + DoubleToString(m_vwap_value, _Digits) +
                           ", Distance: " + DoubleToString(vwap_distance, 1) + " pips, RSI: " +
                           DoubleToString(rsi, 1) + ")";

            if(rsi > 60) signal.confidence += 0.10; // Stronger overbought
         }
      }
   }
   else
   {
      signal.reason = "Price too far from VWAP (" + DoubleToString(vwap_distance, 1) + " pips)";
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Momentum Scalping Strategy                                      |
//+------------------------------------------------------------------+
ScalpSignal CScalpingStrategy::MomentumScalping(double max_spread_points)
{
   ScalpSignal signal;
   signal.signal = 0;
   signal.confidence = 0.0;
   signal.strategy_type = SCALP_MOMENTUM;
   signal.signal_time = TimeCurrent();
   signal.atr_value = GetATR();
   signal.spread_points = GetCurrentSpread();

   // Get candlestick data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(m_symbol, m_timeframe, 0, 3, rates) < 3)
   {
      signal.reason = "Failed to get price data";
      return signal;
   }

   double rsi = GetRSI();
   double close1 = rates[1].close;
   double open1 = rates[1].open;
   double high1 = rates[1].high;
   double low1 = rates[1].low;
   double body_size = MathAbs(close1 - open1);
   double candle_range = high1 - low1;
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // Volume check
   double volume = (double)iVolume(m_symbol, m_timeframe, 1);
   double avg_volume = 0;
   for(int i = 2; i <= 11; i++) avg_volume += (double)iVolume(m_symbol, m_timeframe, i);
   avg_volume /= 10.0;

   bool volume_spike = volume > avg_volume * 1.5;
   bool strong_candle = body_size > (candle_range * 0.6); // Body is 60%+ of range

   // Bullish momentum
   if(close1 > open1 && strong_candle && volume_spike && rsi > 50 && rsi < 70)
   {
      if(IsMomentumValid(1))
      {
         signal.signal = 1; // BUY
         signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         signal.stop_loss = low1 - (signal.atr_value * 0.3);
         signal.take_profit = signal.entry_price + ((signal.entry_price - signal.stop_loss) * 2.0);
         signal.confidence = 0.75;
         signal.reason = "Bullish momentum (Volume: " + DoubleToString(volume/avg_volume, 2) + "x avg, " +
                        "Body: " + DoubleToString(body_size/(point*10), 1) + " pips, RSI: " +
                        DoubleToString(rsi, 1) + ")";

         if(rsi > 55 && rsi < 65) signal.confidence += 0.10; // Ideal RSI zone
      }
   }
   // Bearish momentum
   else if(close1 < open1 && strong_candle && volume_spike && rsi < 50 && rsi > 30)
   {
      if(IsMomentumValid(-1))
      {
         signal.signal = -1; // SELL
         signal.entry_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         signal.stop_loss = high1 + (signal.atr_value * 0.3);
         signal.take_profit = signal.entry_price - ((signal.stop_loss - signal.entry_price) * 2.0);
         signal.confidence = 0.75;
         signal.reason = "Bearish momentum (Volume: " + DoubleToString(volume/avg_volume, 2) + "x avg, " +
                        "Body: " + DoubleToString(body_size/(point*10), 1) + " pips, RSI: " +
                        DoubleToString(rsi, 1) + ")";

         if(rsi > 35 && rsi < 45) signal.confidence += 0.10; // Ideal RSI zone
      }
   }
   else
   {
      signal.reason = "No strong momentum detected (Vol: " + DoubleToString(volume/avg_volume, 2) +
                     "x, Body%: " + DoubleToString((body_size/candle_range)*100, 1) + "%)";
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Calculate VWAP                                                   |
//+------------------------------------------------------------------+
bool CScalpingStrategy::CalculateVWAP(int bars_back = 20)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(m_symbol, m_timeframe, 0, bars_back, rates) < bars_back)
      return false;

   double sum_pv = 0.0;  // Sum of (price * volume)
   double sum_v = 0.0;   // Sum of volume

   for(int i = 0; i < bars_back; i++)
   {
      double typical_price = (rates[i].high + rates[i].low + rates[i].close) / 3.0;
      double volume = (double)rates[i].tick_volume;

      sum_pv += typical_price * volume;
      sum_v += volume;
   }

   if(sum_v > 0)
   {
      m_vwap_value = sum_pv / sum_v;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Trading Range                                            |
//+------------------------------------------------------------------+
bool CScalpingStrategy::DetectRange(RangeInfo &range_info)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(m_symbol, m_timeframe, 1, m_range_bars, rates) < m_range_bars)
      return false;

   double high = rates[0].high;
   double low = rates[0].low;

   // Find range high and low
   for(int i = 1; i < m_range_bars; i++)
   {
      if(rates[i].high > high) high = rates[i].high;
      if(rates[i].low < low) low = rates[i].low;
   }

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double range_pips = (high - low) / (point * 10);

   range_info.high = high;
   range_info.low = low;
   range_info.size_pips = range_pips;
   range_info.bars_in_range = m_range_bars;
   range_info.range_start = rates[m_range_bars - 1].time;
   range_info.is_valid = (range_pips >= m_min_range_pips && range_pips <= m_max_range_pips);

   return true;
}

//+------------------------------------------------------------------+
//| Validate Breakout                                               |
//+------------------------------------------------------------------+
bool CScalpingStrategy::IsBreakoutValid(const RangeInfo &range, int direction)
{
   // Add additional confirmation here (e.g., trend alignment, pattern)
   // For now, basic validation
   return range.is_valid;
}

//+------------------------------------------------------------------+
//| Validate VWAP Bounce                                            |
//+------------------------------------------------------------------+
bool CScalpingStrategy::IsVWAPBounceValid(double current_price, int direction)
{
   // Add additional confirmation (e.g., candlestick pattern)
   return true;
}

//+------------------------------------------------------------------+
//| Validate Momentum                                               |
//+------------------------------------------------------------------+
bool CScalpingStrategy::IsMomentumValid(int direction)
{
   // Add additional confirmation (e.g., higher timeframe alignment)
   return true;
}

//+------------------------------------------------------------------+
//| Get ATR Value                                                    |
//+------------------------------------------------------------------+
double CScalpingStrategy::GetATR(int period = 14)
{
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);

   if(CopyBuffer(m_atr_handle, 0, 0, 1, atr_buffer) <= 0)
      return 0.0;

   return atr_buffer[0];
}

//+------------------------------------------------------------------+
//| Get RSI Value                                                    |
//+------------------------------------------------------------------+
double CScalpingStrategy::GetRSI(int period = 14)
{
   double rsi_buffer[];
   ArraySetAsSeries(rsi_buffer, true);

   if(CopyBuffer(m_rsi_handle, 0, 0, 1, rsi_buffer) <= 0)
      return 50.0; // Neutral default

   return rsi_buffer[0];
}

//+------------------------------------------------------------------+
//| Get Current Spread in Points                                    |
//+------------------------------------------------------------------+
double CScalpingStrategy::GetCurrentSpread()
{
   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   return (ask - bid) / point;
}

//+------------------------------------------------------------------+
//| Check if Spread is Acceptable                                   |
//+------------------------------------------------------------------+
bool CScalpingStrategy::IsSpreadAcceptable(double max_spread_points)
{
   return GetCurrentSpread() <= max_spread_points;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                             |
//+------------------------------------------------------------------+
double CScalpingStrategy::CalculateStopLoss(int direction, double atr_value, int sl_pips)
{
   double current_price = direction > 0 ? SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                                          SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double sl_distance = sl_pips * point * 10; // Convert pips to price units

   if(direction > 0)
      return current_price - sl_distance;
   else
      return current_price + sl_distance;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                           |
//+------------------------------------------------------------------+
double CScalpingStrategy::CalculateTakeProfit(int direction, double atr_value, int tp_pips)
{
   double current_price = direction > 0 ? SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                                          SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double tp_distance = tp_pips * point * 10; // Convert pips to price units

   if(direction > 0)
      return current_price + tp_distance;
   else
      return current_price - tp_distance;
}
//+------------------------------------------------------------------+
