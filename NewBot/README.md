# MT5 Expert Advisors with Python Backend Integration

A comprehensive trading system featuring three specialized Expert Advisors (EAs) for MetaTrader 5, integrated with a Python WebSocket bridge for backend communication.

## System Overview

This system connects MT5 Expert Advisors to a Python backend via WebSocket for:
- Real-time signal processing and validation
- Advanced risk management
- Machine learning predictions (optional)
- Trade logging and analytics
- Multi-strategy execution

## Expert Advisors

### 1. stocksOnlymachine.mq5 - Stock Trading EA

**Purpose**: Automated stock trading with focus on US equities

**Features**:
- RSI + Moving Average strategy
- ATR-based position sizing
- Market hours filtering (09:30 - 16:00 EST)
- Dynamic risk management
- Trailing stops and partial close
- Daily trade limits

**Optimized for**: AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA, META, NFLX

**Default Settings**:
- Risk per trade: 1.0%
- Risk:Reward ratio: 1:2
- ATR period: 14
- Trend MA: 200
- Max daily trades: 10

### 2. GoldTrader.mq5 - Gold/Precious Metals EA

**Purpose**: Specialized trading for XAUUSD and precious metals

**Features**:
- Multiple strategies: Breakout, Mean Reversion, Trend Following, Hybrid
- Session-based trading (London, NY sessions)
- Volatility-based position sizing
- Confidence-weighted lot calculation
- Advanced breakeven and trailing mechanisms
- News avoidance filter (configurable)

**Strategies**:
1. **Breakout**: Trades breakouts from consolidation zones
2. **Mean Reversion**: Bollinger Band reversals with RSI/Stochastic confirmation
3. **Trend Following**: EMA crossovers with ADX filter
4. **Hybrid**: Automatically selects best strategy based on confidence

**Default Settings**:
- Risk per trade: 0.5% (conservative for gold volatility)
- ATR multiplier SL: 1.5
- ATR multiplier TP: 3.0
- Max daily trades: 5
- Max daily drawdown: 2.0%

### 3. forexMaster.mq5 - Multi-Currency Forex EA

**Purpose**: Trade multiple forex pairs simultaneously with correlation management

**Features**:
- Multi-pair trading (EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD)
- Correlation filtering to avoid overexposure
- Multiple strategies per pair
- Basket trading capability
- Dynamic position sizing across pairs
- Equity stop protection
- Session-based filters

**Strategies**:
1. **Trend**: MACD + EMA crossover with ADX confirmation
2. **Scalping**: Fast EMA with tight targets
3. **Swing**: Wide stops for longer-term moves
4. **Carry Trade**: Interest rate differential plays (placeholder)
5. **Multi**: Automatically selects best strategy per pair

**Default Settings**:
- Risk per trade: 1.0%
- Max simultaneous trades: 5
- Correlation threshold: 0.7
- Max daily trades: 20
- Equity stop: 5.0%

## Python WebSocket Bridge

### mt5_bridge.py

The bridge connects MT5 EAs to your backend via WebSocket.

**Features**:
- Async WebSocket server
- Real-time position monitoring
- Trade execution and management
- Backend signal integration
- Automatic reconnection
- Comprehensive logging

**Supported Operations**:
- Request trading signals from backend
- Execute trades
- Get positions and account info
- Close positions
- Real-time position updates
- Heartbeat mechanism

## Installation & Setup

### Prerequisites

1. **MetaTrader 5** installed on Windows (or via Wine on Mac/Linux)
2. **Python 3.8+** installed
3. **Backend server** running (from `/backend` folder)

### Step 1: Install Python Dependencies

```bash
cd NewBot
pip install -r requirements.txt
```

**Note**: On macOS, MetaTrader5 Python package requires MT5 to be running via Wine or Windows VM.

### Step 2: Configure Environment

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Edit `.env` with your MT5 credentials:
```env
MT5_LOGIN=your_account_number
MT5_PASSWORD=your_password
MT5_SERVER=broker_server_name
BACKEND_URL=http://localhost:5000
BACKEND_API_KEY=your_api_key
```

### Step 3: Install MT5 Expert Advisors

1. Copy the EA files to MT5's `Experts` folder:
   - Windows: `C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[InstanceID]\MQL5\Experts\`
   - Or use MT5 Navigator: File → Open Data Folder → MQL5 → Experts

2. Copy files:
   - `stocksOnlymachine.mq5`
   - `GoldTrader.mq5`
   - `forexMaster.mq5`

3. Compile the EAs in MT5:
   - Open MetaEditor (F4 in MT5)
   - Open each EA file
   - Click Compile (F7)

### Step 4: Start the System

1. **Start the backend**:
```bash
cd ../backend
npm start
```

2. **Start the Python bridge**:
```bash
cd ../NewBot
python mt5_bridge.py
```

3. **Attach EA to chart in MT5**:
   - Open MT5
   - Open a chart for your desired symbol
   - Drag the EA from Navigator → Expert Advisors onto the chart
   - Configure settings in the dialog
   - Click "Allow automated trading"
   - Click OK

## Configuration

### EA Configuration (Input Parameters)

Each EA has comprehensive input parameters organized into groups:

**Connection Settings**:
- Server URL
- API Key
- WebSocket enable/disable

**Trading Settings**:
- Enable/disable trading
- Risk percentage
- Magic number
- Comment

**Risk Management**:
- ATR-based stops
- Max spread
- Slippage tolerance

**Advanced Features**:
- Trailing stops
- Break even
- Partial close
- Daily limits

### Python Bridge Configuration

Edit `config.json` to customize:
- EA-specific settings
- Global risk parameters
- Indicator settings
- WebSocket options
- Logging preferences

## Risk Management Features

### Position Sizing
- ATR-based dynamic position sizing
- Percentage risk model
- Account balance protection
- Lot normalization

### Stop Loss Strategies
1. **ATR-based**: Adaptive stops based on volatility
2. **Fixed percentage**: Conservative fixed risk
3. **Support/Resistance**: Technical level stops

### Protective Mechanisms
- Daily trade limits
- Daily loss limits
- Maximum drawdown protection
- Equity stop loss
- Correlation filters (Forex EA)
- Spread filters
- Session filters

## Trading Sessions

### Stock EA
- **Market Hours**: 09:30 - 16:00 EST
- Avoids pre-market and after-hours

### Gold EA
- **Asian Session**: 00:00 - 09:00 (optional)
- **London Session**: 08:00 - 17:00 (recommended)
- **NY Session**: 13:00 - 22:00 (recommended)

### Forex EA
- Configurable per session
- Overlap detection
- High-liquidity period preference

## WebSocket Protocol

### Message Types

**From EA to Bridge**:
```json
{
  "type": "request_signal",
  "symbol": "EURUSD"
}
```

**From Bridge to EA**:
```json
{
  "type": "signal",
  "data": {
    "symbol": "EURUSD",
    "type": "BUY",
    "entry": 1.1000,
    "stop_loss": 1.0950,
    "take_profit": 1.1100,
    "lot_size": 0.1,
    "confidence": 75
  }
}
```

**Trade Execution**:
```json
{
  "type": "execute_trade",
  "signal": { /* signal data */ }
}
```

**Position Updates** (automatic broadcast):
```json
{
  "type": "position_update",
  "data": [
    {
      "ticket": 123456,
      "symbol": "EURUSD",
      "type": "BUY",
      "volume": 0.1,
      "profit": 15.50
    }
  ]
}
```

## Monitoring & Logging

### MT5 EA Logs
- Check MT5 Experts tab for EA logs
- Logs show: initialization, signals, trades, errors

### Python Bridge Logs
- File: `mt5_bridge_YYYYMMDD.log`
- Console output with color coding
- Includes: connections, signals, trades, errors

### Backend Integration
- Trades logged to database
- Real-time notifications
- Performance analytics

## Testing

### Demo Account Testing

**ALWAYS test on demo account first!**

1. Open demo account with your broker
2. Configure `.env` with demo credentials
3. Run system for at least 1-2 weeks
4. Monitor:
   - Win rate
   - Risk:Reward ratio
   - Drawdown
   - Execution quality

### Backtesting (MT5)

1. Open Strategy Tester (Ctrl+R)
2. Select EA
3. Configure:
   - Symbol
   - Timeframe
   - Date range
   - Initial deposit
4. Run test
5. Analyze report

**Note**: WebSocket features won't work in backtest mode - EAs will use local signals only.

## Best Practices

### Risk Management
1. Never risk more than 1-2% per trade
2. Set daily loss limits
3. Use proper position sizing
4. Don't overtrade
5. Monitor correlation in Forex EA

### System Monitoring
1. Check logs daily
2. Monitor backend connectivity
3. Verify trade execution
4. Track performance metrics
5. Review slippage and spreads

### Optimization
1. Test on demo first
2. Optimize one parameter at a time
3. Avoid over-optimization
4. Consider market conditions
5. Regular performance review

## Troubleshooting

### EA Not Trading

**Check**:
1. AutoTrading button enabled (MT5 toolbar)
2. EA Inputs → "Enable Trading" = true
3. Daily limits not reached
4. Market hours (for Stock EA)
5. Spread not too high

### WebSocket Connection Failed

**Check**:
1. Python bridge running
2. Firewall not blocking port 8765
3. Correct URL in EA settings
4. Backend server running
5. Check bridge logs for errors

### Trades Not Executing

**Check**:
1. MT5 account has sufficient margin
2. Symbol is tradeable
3. Broker allows automated trading
4. No connection errors in logs
5. Check MT5 Terminal tab for errors

### High Slippage

**Solutions**:
1. Increase slippage tolerance
2. Trade during high liquidity periods
3. Use better broker
4. Check internet connection

## Performance Optimization

### For Stock EA
- Trade liquid stocks (high volume)
- Avoid earnings announcements
- Best performance during regular market hours
- Consider reducing risk during high volatility

### For Gold EA
- Best during London/NY sessions
- Avoid major news events
- Use News Filter
- Consider strategy based on volatility regime

### For Forex EA
- Trade major pairs for best spreads
- Enable correlation filter
- Limit simultaneous trades
- Monitor exposure per currency

## Advanced Features

### Machine Learning Integration

The system is designed to integrate ML predictions:

1. Backend generates ML signals
2. Bridge fetches signals via API
3. EA validates and executes
4. Results feed back for model training

### Custom Indicators

Add custom indicators by:
1. Create indicator in MQL5
2. Add handle in EA initialization
3. Copy buffer in UpdateIndicators()
4. Use in signal generation logic

### Multi-Timeframe Analysis

EAs can be enhanced with MTF:
```mql5
// Example: Check higher timeframe trend
double h4_ma = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
```

## API Integration

### Backend Endpoints (Expected)

```
GET  /api/signals/:symbol     - Get trading signal
POST /api/trades/notify       - Notify trade execution
GET  /api/account/stats       - Get account statistics
POST /api/positions/update    - Update position status
```

## Safety Features

### Emergency Stop
- Press "Remove EA" in MT5 to stop
- Or disable AutoTrading button
- Python bridge: Ctrl+C

### Position Limits
- Max simultaneous positions
- Max daily trades
- Max drawdown protection
- Equity stop loss

### Validation Checks
- Price validation
- Lot size normalization
- Stop loss minimum distance
- Take profit validation
- Spread filtering

## System Requirements

### Minimum
- Windows 10 / Windows Server 2016+
- 4GB RAM
- 2 CPU cores
- 10GB disk space
- Stable internet connection

### Recommended
- Windows 11
- 8GB+ RAM
- 4+ CPU cores
- SSD storage
- Low-latency internet (< 50ms to broker)

## License & Disclaimer

**IMPORTANT DISCLAIMER**:
This trading system is provided for educational purposes. Trading carries substantial risk of loss. Past performance does not guarantee future results. Always test thoroughly on demo accounts before live trading. The authors are not responsible for any financial losses incurred using this system.

## Support & Updates

For issues, questions, or contributions:
1. Check logs first
2. Review this documentation
3. Test on demo account
4. Contact support with detailed error info

## Version History

### v1.0.0 (Current)
- Initial release
- Three specialized EAs
- Python WebSocket bridge
- Backend integration
- Comprehensive risk management
- Multi-strategy support

---

**Happy Trading! Remember: Test thoroughly, manage risk wisely, and never risk more than you can afford to lose.**
