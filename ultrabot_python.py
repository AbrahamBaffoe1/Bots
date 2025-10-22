#!/usr/bin/env python3
"""
Ultra Trading Bot - Python Version with MetaTrader 5 Integration
Copyright 2025 - Smart Stock Trader
ML-Powered Trading System with Advanced Risk Management
"""

from datetime import datetime, timedelta
import MetaTrader5 as mt5
import tensorflow as tf
import numpy as np
import pandas as pd
import time
import logging
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional
from sklearn.preprocessing import StandardScaler
import talib

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
mt5.initialize()


@dataclass
class BotConfig:
    """Configuration for the Ultra Trading Bot"""
    # Symbols to trade
    symbols: List[str] = None

    # Risk Management
    risk_per_trade: float = 0.01  # 1% per trade
    max_daily_loss: float = 0.05   # 5% max daily loss
    max_positions: int = 5

    # ML Settings
    use_ml: bool = True
    ml_confidence_threshold: float = 0.65
    ml_model_path: str = "models/ultra_bot_model.h5"
    training_bars: int = 1000

    # Trading Parameters
    atr_sl_multiplier: float = 1.5
    atr_tp_multiplier: float = 6.0  # 4:1 R:R
    use_smart_scaling: bool = True
    partial_close_percent: float = 0.25
    partial_close_rr: float = 2.0

    # Filters
    use_volatility_filter: bool = True
    use_trend_filter: bool = True
    use_time_filter: bool = True

    # ML Risk Management
    use_ml_risk_management: bool = True
    ml_high_conf_threshold: float = 0.75
    ml_low_conf_threshold: float = 0.60
    ml_high_conf_tp_mult: float = 1.2
    ml_low_conf_sl_mult: float = 0.8

    # Timeframe
    timeframe: int = mt5.TIMEFRAME_H1

    # Logging
    verbose: bool = True
    log_file: str = "ultrabot.log"

    def __post_init__(self):
        if self.symbols is None:
            self.symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA"]


# ═══════════════════════════════════════════════════════════════════════════
# LOGGING SETUP
# ═══════════════════════════════════════════════════════════════════════════

def setup_logging(config: BotConfig):
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO if config.verbose else logging.WARNING,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(config.log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════════════
# NEURAL NETWORK MODEL
# ═══════════════════════════════════════════════════════════════════════════

class MLModel:
    """Enhanced Neural Network for Trade Prediction"""

    def __init__(self, config: BotConfig):
        self.config = config
        self.model = None
        self.scaler = StandardScaler()
        self.accuracy = 0.0
        self.logger = logging.getLogger(__name__)

    def build_model(self, input_shape: int = 30):
        """Build multi-layer neural network"""
        self.model = tf.keras.Sequential([
            # Input layer
            tf.keras.layers.Dense(30, input_shape=(input_shape,), name='input'),

            # Hidden layer with ReLU activation
            tf.keras.layers.Dense(20, activation='relu', name='hidden',
                                kernel_initializer='glorot_uniform'),
            tf.keras.layers.Dropout(0.2),  # Regularization

            # Output layer with Softmax (BUY, SELL, NEUTRAL)
            tf.keras.layers.Dense(3, activation='softmax', name='output')
        ])

        # Compile with Adam optimizer
        self.model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )

        self.logger.info("✓ Neural network built: 30 → 20 → 3")
        return self.model

    def extract_features(self, symbol: str, timeframe: int, count: int = 100) -> np.ndarray:
        """Extract 30 technical features for ML"""
        # Get price data
        rates = mt5.copy_rates_from_pos(symbol, timeframe, 0, count)
        if rates is None or len(rates) < 50:
            return None

        df = pd.DataFrame(rates)
        df['time'] = pd.to_datetime(df['time'], unit='s')

        features = []

        # Calculate indicators using TA-Lib
        close = df['close'].values
        high = df['high'].values
        low = df['low'].values
        volume = df['tick_volume'].values

        # CATEGORY 1: TREND INDICATORS (10 features)
        features.append(talib.RSI(close, timeperiod=14)[-1] / 100.0)  # 0
        slowk, slowd = talib.STOCH(high, low, close, fastk_period=14, slowk_period=3, slowd_period=3)
        features.append(slowk[-1] / 100.0)  # 1
        features.append((talib.WILLR(high, low, close, timeperiod=14)[-1] + 100) / 100.0)  # 2
        features.append(talib.ADX(high, low, close, timeperiod=14)[-1] / 100.0)  # 3
        features.append(talib.PLUS_DI(high, low, close, timeperiod=14)[-1] / 100.0)  # 4
        features.append(talib.MINUS_DI(high, low, close, timeperiod=14)[-1] / 100.0)  # 5
        features.append((talib.CCI(high, low, close, timeperiod=14)[-1] + 200) / 400.0)  # 6

        ma10 = talib.EMA(close, timeperiod=10)[-1]
        features.append((close[-1] - ma10) / ma10 if ma10 > 0 else 0)  # 7

        ma50 = talib.SMA(close, timeperiod=50)[-1]
        features.append((close[-1] - ma50) / ma50 if ma50 > 0 else 0)  # 8

        ma200 = talib.SMA(close, timeperiod=200)[-1] if len(close) >= 200 else close[-1]
        features.append((close[-1] - ma200) / ma200 if ma200 > 0 else 0)  # 9

        # CATEGORY 2: MOMENTUM INDICATORS (5 features)
        macd, signal, hist = talib.MACD(close, fastperiod=12, slowperiod=26, signalperiod=9)
        features.append(macd[-1] / close[-1] if close[-1] > 0 else 0)  # 10
        features.append(signal[-1] / close[-1] if close[-1] > 0 else 0)  # 11
        features.append((close[-1] - close[-10]) / close[-10] if close[-10] > 0 else 0)  # 12
        features.append((close[-1] - close[-20]) / close[-20] if close[-20] > 0 else 0)  # 13
        features.append(talib.MOM(close, timeperiod=10)[-1] / close[-1] if close[-1] > 0 else 0)  # 14

        # CATEGORY 3: VOLATILITY INDICATORS (5 features)
        atr = talib.ATR(high, low, close, timeperiod=14)[-1]
        features.append(atr / close[-1] if close[-1] > 0 else 0)  # 15

        upper, middle, lower = talib.BBANDS(close, timeperiod=20, nbdevup=2, nbdevdn=2)
        features.append((upper[-1] - lower[-1]) / close[-1] if close[-1] > 0 else 0)  # 16
        features.append((close[-1] - lower[-1]) / (upper[-1] - lower[-1]) if upper[-1] != lower[-1] else 0.5)  # 17
        features.append(talib.STDDEV(close, timeperiod=20)[-1] / close[-1] if close[-1] > 0 else 0)  # 18
        features.append(talib.NATR(high, low, close, timeperiod=14)[-1] / 100.0)  # 19

        # CATEGORY 4: VOLUME INDICATORS (3 features)
        avg_vol = np.mean(volume[-20:])
        features.append(volume[-1] / avg_vol if avg_vol > 0 else 1.0)  # 20
        features.append(talib.OBV(close, volume)[-1] / 1000000.0)  # 21 (normalized)
        features.append(talib.AD(high, low, close, volume)[-1] / 1000000.0)  # 22

        # CATEGORY 5: PRICE ACTION PATTERNS (5 features)
        body = abs(df['close'].iloc[-1] - df['open'].iloc[-1])
        range_val = df['high'].iloc[-1] - df['low'].iloc[-1]
        features.append(body / range_val if range_val > 0 else 0.5)  # 23

        upper_shadow = df['high'].iloc[-1] - max(df['open'].iloc[-1], df['close'].iloc[-1])
        features.append(upper_shadow / range_val if range_val > 0 else 0)  # 24

        lower_shadow = min(df['open'].iloc[-1], df['close'].iloc[-1]) - df['low'].iloc[-1]
        features.append(lower_shadow / range_val if range_val > 0 else 0)  # 25

        # Bullish score (last 5 candles)
        bullish = sum([1 if df['close'].iloc[-i] > df['open'].iloc[-i] else -1 for i in range(1, 6)])
        features.append((bullish + 5) / 10.0)  # 26

        # Structure score (higher highs/lower lows)
        structure = 0
        for i in range(1, 5):
            if df['high'].iloc[-i] > df['high'].iloc[-i-1] and df['low'].iloc[-i] > df['low'].iloc[-i-1]:
                structure += 1
            elif df['high'].iloc[-i] < df['high'].iloc[-i-1] and df['low'].iloc[-i] < df['low'].iloc[-i-1]:
                structure -= 1
        features.append((structure + 4) / 8.0)  # 27

        # CATEGORY 6: MULTI-TIMEFRAME (2 features)
        # H4 trend (if on H1)
        if timeframe == mt5.TIMEFRAME_H1:
            h4_rates = mt5.copy_rates_from_pos(symbol, mt5.TIMEFRAME_H4, 0, 50)
            if h4_rates is not None and len(h4_rates) >= 50:
                h4_close = h4_rates[-1]['close']
                h4_ma50 = np.mean([r['close'] for r in h4_rates[-50:]])
                features.append((h4_close - h4_ma50) / h4_ma50 if h4_ma50 > 0 else 0)  # 28
            else:
                features.append(0)
        else:
            features.append(0)

        # D1 trend
        d1_rates = mt5.copy_rates_from_pos(symbol, mt5.TIMEFRAME_D1, 0, 200)
        if d1_rates is not None and len(d1_rates) >= 200:
            d1_close = d1_rates[-1]['close']
            d1_ma200 = np.mean([r['close'] for r in d1_rates[-200:]])
            features.append((d1_close - d1_ma200) / d1_ma200 if d1_ma200 > 0 else 0)  # 29
        else:
            features.append(0)

        return np.array(features)

    def train(self, symbol: str, timeframe: int, bars: int = 1000):
        """Train the neural network on historical data"""
        self.logger.info(f"🧠 Training neural network on {bars} bars of {symbol}...")

        # Get historical data
        rates = mt5.copy_rates_from_pos(symbol, timeframe, 0, bars + 50)
        if rates is None or len(rates) < bars:
            self.logger.error(f"Not enough data for training (need {bars}, got {len(rates) if rates else 0})")
            return False

        X = []
        y = []

        # Extract features and labels
        for i in range(50, len(rates) - 5):
            # Get features at this point
            features = self.extract_features(symbol, timeframe, i)
            if features is None:
                continue

            # Determine actual outcome (5 bars ahead)
            current_price = rates[i]['close']
            future_price = rates[i + 5]['close']
            price_change = (future_price - current_price) / current_price * 100.0

            # Create label (BUY, SELL, NEUTRAL)
            if price_change > 0.5:
                label = [1, 0, 0]  # BUY
            elif price_change < -0.5:
                label = [0, 1, 0]  # SELL
            else:
                label = [0, 0, 1]  # NEUTRAL

            X.append(features)
            y.append(label)

        if len(X) < 100:
            self.logger.error("Not enough valid training samples")
            return False

        X = np.array(X)
        y = np.array(y)

        # Normalize features
        X = self.scaler.fit_transform(X)

        # Build model if not exists
        if self.model is None:
            self.build_model(input_shape=X.shape[1])

        # Train with early stopping
        early_stop = tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=5,
            restore_best_weights=True
        )

        # Train
        history = self.model.fit(
            X, y,
            epochs=50,
            batch_size=32,
            validation_split=0.2,
            callbacks=[early_stop],
            verbose=1 if self.config.verbose else 0
        )

        # Get final accuracy
        self.accuracy = history.history['val_accuracy'][-1]

        self.logger.info(f"✓ Training complete - Validation Accuracy: {self.accuracy*100:.1f}%")
        return True

    def predict(self, symbol: str, timeframe: int) -> Tuple[int, float]:
        """
        Predict trade direction
        Returns: (direction, confidence)
        direction: 0=BUY, 1=SELL, 2=NEUTRAL
        confidence: 0.0-1.0
        """
        if self.model is None:
            return 2, 0.0  # NEUTRAL with no confidence

        # Extract features
        features = self.extract_features(symbol, timeframe)
        if features is None:
            return 2, 0.0

        # Normalize
        features_scaled = self.scaler.transform(features.reshape(1, -1))

        # Predict
        prediction = self.model.predict(features_scaled, verbose=0)[0]

        # Get direction and confidence
        direction = np.argmax(prediction)
        confidence = prediction[direction]

        # Calibrate confidence based on historical accuracy
        if self.accuracy > 0.5:
            confidence = confidence * self.accuracy

        return direction, confidence

    def save_model(self, path: str = None):
        """Save trained model"""
        if self.model is None:
            return

        path = path or self.config.ml_model_path
        self.model.save(path)
        self.logger.info(f"✓ Model saved to {path}")

    def load_model(self, path: str = None):
        """Load trained model"""
        path = path or self.config.ml_model_path
        try:
            self.model = tf.keras.models.load_model(path)
            self.logger.info(f"✓ Model loaded from {path}")
            return True
        except:
            self.logger.warning(f"Could not load model from {path}")
            return False


# ═══════════════════════════════════════════════════════════════════════════
# RISK MANAGER
# ═══════════════════════════════════════════════════════════════════════════

class RiskManager:
    """Advanced Risk Management"""

    def __init__(self, config: BotConfig):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.daily_start_equity = 0.0
        self.daily_pnl = 0.0

    def check_daily_loss_limit(self) -> bool:
        """Check if daily loss limit exceeded"""
        account_info = mt5.account_info()
        if account_info is None:
            return False

        if self.daily_start_equity == 0:
            self.daily_start_equity = account_info.equity

        current_equity = account_info.equity
        self.daily_pnl = (current_equity - self.daily_start_equity) / self.daily_start_equity

        if self.daily_pnl < -self.config.max_daily_loss:
            self.logger.warning(f"⚠ Daily loss limit reached: {self.daily_pnl*100:.2f}%")
            return False

        return True

    def calculate_position_size(self, symbol: str, sl_pips: float) -> float:
        """Calculate position size based on risk"""
        account_info = mt5.account_info()
        if account_info is None:
            return 0.0

        symbol_info = mt5.symbol_info(symbol)
        if symbol_info is None:
            return 0.0

        # Risk amount in account currency
        risk_amount = account_info.equity * self.config.risk_per_trade

        # Convert SL pips to price
        point = symbol_info.point
        sl_distance = sl_pips * point * 10

        # Calculate lot size
        tick_value = symbol_info.trade_tick_value
        lot_size = risk_amount / (sl_distance / point * tick_value)

        # Round to valid lot step
        lot_step = symbol_info.volume_step
        lot_size = round(lot_size / lot_step) * lot_step

        # Clamp to min/max
        lot_size = max(symbol_info.volume_min, min(lot_size, symbol_info.volume_max))

        return lot_size

    def adjust_sl_tp_by_confidence(self, sl_pips: float, tp_pips: float,
                                     ml_confidence: float) -> Tuple[float, float]:
        """Adjust SL/TP based on ML confidence (NEW!)"""
        if not self.config.use_ml_risk_management or ml_confidence == 0:
            return sl_pips, tp_pips

        if ml_confidence >= self.config.ml_high_conf_threshold:
            # HIGH CONFIDENCE: Widen TP for bigger wins
            tp_pips *= self.config.ml_high_conf_tp_mult
            self.logger.info(f"🎯 ML HIGH CONFIDENCE ({ml_confidence*100:.1f}%) - TP increased by 20%")

        elif ml_confidence < self.config.ml_low_conf_threshold:
            # LOW CONFIDENCE: Tighten SL to reduce risk
            sl_pips *= self.config.ml_low_conf_sl_mult
            self.logger.info(f"⚠ ML LOW CONFIDENCE ({ml_confidence*100:.1f}%) - SL tightened by 20%")

        else:
            # MEDIUM CONFIDENCE: Standard SL/TP
            self.logger.info(f"📊 ML MEDIUM CONFIDENCE ({ml_confidence*100:.1f}%) - Standard SL/TP")

        return sl_pips, tp_pips


# ═══════════════════════════════════════════════════════════════════════════
# ULTRA TRADING BOT
# ═══════════════════════════════════════════════════════════════════════════

class UltraTradingBot:
    """Main Trading Bot with ML Integration"""

    def __init__(self, config: BotConfig):
        self.config = config
        self.logger = setup_logging(config)
        self.ml_model = MLModel(config) if config.use_ml else None
        self.risk_manager = RiskManager(config)
        self.positions = {}
        self.running = False

    def initialize(self) -> bool:
        """Initialize MT5 connection and models"""
        self.logger.info("=" * 60)
        self.logger.info("🚀 ULTRA TRADING BOT - Python Version")
        self.logger.info("=" * 60)

        # Initialize MT5
        if not mt5.initialize():
            self.logger.error("❌ MT5 initialization failed")
            return False

        self.logger.info("✓ MT5 connected")

        # Login info
        account_info = mt5.account_info()
        if account_info:
            self.logger.info(f"✓ Account: {account_info.login} | Balance: ${account_info.balance:.2f}")

        # Train or load ML model
        if self.config.use_ml and self.ml_model:
            # Try to load existing model
            if not self.ml_model.load_model():
                # Train new model on first symbol
                self.logger.info("No existing model found, training new model...")
                if self.config.symbols:
                    self.ml_model.train(
                        self.config.symbols[0],
                        self.config.timeframe,
                        self.config.training_bars
                    )
                    self.ml_model.save_model()

        self.logger.info("✓ Ultra Bot initialized successfully")
        return True

    def check_filters(self, symbol: str) -> bool:
        """Check all trading filters"""
        # Add your filter logic here
        # - Volatility filter
        # - Trend filter
        # - Time filter
        # - News filter
        # etc.
        return True

    def get_trading_signal(self, symbol: str) -> Tuple[Optional[str], float]:
        """
        Get trading signal for symbol
        Returns: (signal, confidence)
        signal: 'BUY', 'SELL', or None
        confidence: 0.0-1.0
        """
        # Get ML prediction
        ml_direction = 2  # NEUTRAL
        ml_confidence = 0.0

        if self.config.use_ml and self.ml_model:
            ml_direction, ml_confidence = self.ml_model.predict(symbol, self.config.timeframe)

        # Get traditional signals (simplified here)
        traditional_signal = self.get_traditional_signal(symbol)

        # Combine signals
        if ml_direction == 0 and ml_confidence >= self.config.ml_confidence_threshold:
            # ML says BUY with high confidence
            if traditional_signal == 'BUY':
                return 'BUY', ml_confidence * 1.2  # Both agree - boost confidence
            elif ml_confidence >= 0.75:
                return 'BUY', ml_confidence

        elif ml_direction == 1 and ml_confidence >= self.config.ml_confidence_threshold:
            # ML says SELL with high confidence
            if traditional_signal == 'SELL':
                return 'SELL', ml_confidence * 1.2
            elif ml_confidence >= 0.75:
                return 'SELL', ml_confidence

        # Fall back to traditional if ML is neutral or low confidence
        if traditional_signal in ['BUY', 'SELL']:
            return traditional_signal, 0.6  # Default confidence

        return None, 0.0

    def get_traditional_signal(self, symbol: str) -> Optional[str]:
        """Get traditional technical signal"""
        rates = mt5.copy_rates_from_pos(symbol, self.config.timeframe, 0, 100)
        if rates is None or len(rates) < 50:
            return None

        close = np.array([r['close'] for r in rates])
        high = np.array([r['high'] for r in rates])
        low = np.array([r['low'] for r in rates])

        # Simple MA crossover
        ma_fast = talib.EMA(close, timeperiod=10)
        ma_slow = talib.SMA(close, timeperiod=50)

        # RSI
        rsi = talib.RSI(close, timeperiod=14)

        # Check for BUY signal
        if (ma_fast[-1] > ma_slow[-1] and ma_fast[-2] <= ma_slow[-2] and
            50 < rsi[-1] < 70):
            return 'BUY'

        # Check for SELL signal
        if (ma_fast[-1] < ma_slow[-1] and ma_fast[-2] >= ma_slow[-2] and
            30 < rsi[-1] < 50):
            return 'SELL'

        return None

    def execute_trade(self, symbol: str, signal: str, confidence: float):
        """Execute trade with ML-driven risk management"""
        # Calculate ATR for SL/TP
        rates = mt5.copy_rates_from_pos(symbol, self.config.timeframe, 0, 20)
        if rates is None:
            return

        high = np.array([r['high'] for r in rates])
        low = np.array([r['low'] for r in rates])
        close = np.array([r['close'] for r in rates])

        atr = talib.ATR(high, low, close, timeperiod=14)[-1]
        symbol_info = mt5.symbol_info(symbol)
        point = symbol_info.point

        # Calculate SL/TP in pips
        sl_pips = (atr / point / 10.0) * self.config.atr_sl_multiplier
        tp_pips = (atr / point / 10.0) * self.config.atr_tp_multiplier

        # ADJUST SL/TP BASED ON ML CONFIDENCE (NEW!)
        sl_pips, tp_pips = self.risk_manager.adjust_sl_tp_by_confidence(
            sl_pips, tp_pips, confidence
        )

        # Calculate position size
        lot_size = self.risk_manager.calculate_position_size(symbol, sl_pips)

        # Get current price
        if signal == 'BUY':
            price = mt5.symbol_info_tick(symbol).ask
            sl = price - (sl_pips * point * 10)
            tp = price + (tp_pips * point * 10)
            order_type = mt5.ORDER_TYPE_BUY
        else:
            price = mt5.symbol_info_tick(symbol).bid
            sl = price + (sl_pips * point * 10)
            tp = price - (tp_pips * point * 10)
            order_type = mt5.ORDER_TYPE_SELL

        # Prepare request
        request = {
            "action": mt5.TRADE_ACTION_DEAL,
            "symbol": symbol,
            "volume": lot_size,
            "type": order_type,
            "price": price,
            "sl": sl,
            "tp": tp,
            "deviation": 10,
            "magic": 555777,
            "comment": f"UltraBot ML:{confidence*100:.0f}%",
            "type_time": mt5.ORDER_TIME_GTC,
            "type_filling": mt5.ORDER_FILLING_IOC,
        }

        # Send order
        result = mt5.order_send(request)

        if result.retcode == mt5.TRADE_RETCODE_DONE:
            self.logger.info("╔" + "=" * 40 + "╗")
            self.logger.info("║  ✓ NEW TRADE OPENED" + " " * 19 + "║")
            self.logger.info("╠" + "=" * 40 + "╣")
            self.logger.info(f"║ Symbol: {symbol}")
            self.logger.info(f"║ Type: {signal}")
            self.logger.info(f"║ Price: {price:.5f}")
            self.logger.info(f"║ Lots: {lot_size:.2f}")
            self.logger.info(f"║ SL: {sl:.5f} ({sl_pips:.1f} pips)")
            self.logger.info(f"║ TP: {tp:.5f} ({tp_pips:.1f} pips)")
            self.logger.info(f"║ ML Confidence: {confidence*100:.1f}%")
            self.logger.info("╚" + "=" * 40 + "╝")

            self.positions[result.order] = {
                'symbol': symbol,
                'type': signal,
                'entry_price': price,
                'sl': sl,
                'tp': tp,
                'lots': lot_size,
                'confidence': confidence
            }
        else:
            self.logger.error(f"❌ Order failed: {result.retcode} - {result.comment}")

    def manage_positions(self):
        """Manage open positions (smart scaling, trailing, etc.)"""
        positions = mt5.positions_get()
        if positions is None:
            return

        for pos in positions:
            if pos.magic != 555777:
                continue

            # Smart scaling logic here
            # Check if we've hit 2:1 R:R for partial close
            if self.config.use_smart_scaling:
                profit_pips = abs(pos.price_current - pos.price_open) / pos.symbol
                risk_pips = abs(pos.price_open - pos.sl) / pos.symbol

                if risk_pips > 0:
                    rr_ratio = profit_pips / risk_pips

                    if rr_ratio >= self.config.partial_close_rr:
                        # Close partial position
                        close_volume = pos.volume * self.config.partial_close_percent
                        self.close_partial_position(pos.ticket, close_volume)

    def close_partial_position(self, ticket: int, volume: float):
        """Close partial position"""
        # Implementation here
        pass

    def run(self):
        """Main bot loop"""
        self.running = True
        self.logger.info("🤖 Ultra Bot started - Scanning for signals...")

        try:
            while self.running:
                # Check daily loss limit
                if not self.risk_manager.check_daily_loss_limit():
                    self.logger.warning("Daily loss limit reached - stopping trading")
                    time.sleep(3600)  # Wait 1 hour
                    continue

                # Check each symbol
                for symbol in self.config.symbols:
                    # Check if we can trade
                    if not self.check_filters(symbol):
                        continue

                    # Get signal
                    signal, confidence = self.get_trading_signal(symbol)

                    if signal and confidence >= self.config.ml_confidence_threshold:
                        # Check position limits
                        positions = mt5.positions_get(symbol=symbol)
                        if positions and len(positions) >= self.config.max_positions:
                            continue

                        # Execute trade
                        self.execute_trade(symbol, signal, confidence)

                # Manage existing positions
                self.manage_positions()

                # Wait before next iteration
                time.sleep(60)  # Check every minute

        except KeyboardInterrupt:
            self.logger.info("Bot stopped by user")

        finally:
            self.shutdown()

    def shutdown(self):
        """Shutdown bot gracefully"""
        self.logger.info("Shutting down Ultra Bot...")
        mt5.shutdown()
        self.logger.info("✓ Ultra Bot stopped")


# ═══════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

def main():
    """Main entry point"""
    # Create configuration
    config = BotConfig(
        symbols=["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA"],
        risk_per_trade=0.01,
        use_ml=True,
        ml_confidence_threshold=0.65,
        use_ml_risk_management=True,
        verbose=True
    )

    # Create and run bot
    bot = UltraTradingBot(config)

    if bot.initialize():
        bot.run()


if __name__ == "__main__":
    main()

mt5.shutdown()