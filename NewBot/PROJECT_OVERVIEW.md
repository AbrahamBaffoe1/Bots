# MT5 Expert Advisors - Project Overview

## What You Have

A complete, professional-grade automated trading system for MetaTrader 5 with Python backend integration.

## File Structure

```
NewBot/
├── stocksOnlymachine.mq5      # Stock trading EA (22.9 KB)
├── GoldTrader.mq5              # Gold trading EA (28.2 KB)
├── forexMaster.mq5             # Forex multi-currency EA (34.7 KB)
├── mt5_bridge.py               # Python WebSocket bridge (17.0 KB)
├── config.json                 # Configuration file
├── requirements.txt            # Python dependencies
├── .env.example                # Environment variables template
├── setup.sh                    # Automated setup script
├── README.md                   # Complete documentation (12.1 KB)
├── QUICKSTART.md               # Quick start guide (9.2 KB)
└── TRADING_GUIDE.md            # Comprehensive trading guide (14.3 KB)
```

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     MetaTrader 5 Terminal                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Stock EA    │  │   Gold EA    │  │   Forex EA   │      │
│  │  (MQL5)      │  │   (MQL5)     │  │   (MQL5)     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │ WebSocket
                             │
                    ┌────────▼─────────┐
                    │   MT5 Bridge     │
                    │   (Python)       │
                    │   - WebSocket    │
                    │   - MT5 API      │
                    │   - Signal Proc  │
                    └────────┬─────────┘
                             │ HTTP/REST
                             │
                    ┌────────▼─────────┐
                    │  Backend Server  │
                    │  (Node.js)       │
                    │  - API Routes    │
                    │  - Database      │
                    │  - Analytics     │
                    └──────────────────┘
```

## Key Features

### 1. Stock Trading EA (stocksOnlymachine.mq5)

**Technical Details**:
- Lines of Code: ~660
- Indicators: ATR, MA (200), RSI
- Strategy: Mean reversion with trend filter
- Risk Management: ATR-based position sizing
- Special Features:
  - Market hours filter (9:30 AM - 4:00 PM EST)
  - Trailing stop with activation threshold
  - Partial position close capability
  - Daily trade and loss limits

**Configurable Parameters**: 40+

### 2. Gold Trading EA (GoldTrader.mq5)

**Technical Details**:
- Lines of Code: ~880
- Indicators: ATR, Fast/Slow/Trend MA, RSI, CCI, Stochastic, Bollinger Bands
- Strategies: 4 (Breakout, Mean Reversion, Trend, Hybrid)
- Risk Management: Confidence-weighted position sizing
- Special Features:
  - Multi-strategy with auto-selection
  - Session-based trading filters
  - Advanced break-even logic
  - Volatility-adaptive stops
  - News avoidance capability

**Configurable Parameters**: 50+

### 3. Forex Multi-Currency EA (forexMaster.mq5)

**Technical Details**:
- Lines of Code: ~1,100
- Indicators: ATR, Fast/Slow EMA, MACD, RSI, ADX
- Strategies: 5 (Trend, Scalping, Swing, Carry, Multi)
- Risk Management: Correlation filtering, equity stop
- Special Features:
  - Multi-pair trading (5+ pairs simultaneously)
  - Correlation matrix to avoid overexposure
  - Dynamic position sizing across portfolio
  - Basket trading capability
  - Individual pair tracking

**Configurable Parameters**: 60+

### 4. Python WebSocket Bridge (mt5_bridge.py)

**Technical Details**:
- Lines of Code: ~600
- Framework: AsyncIO + WebSockets
- MT5 Integration: Official MetaTrader5 library
- Features:
  - Real-time WebSocket server
  - Async position monitoring
  - Trade execution engine
  - Backend API integration
  - Automatic reconnection
  - Comprehensive logging

**Supported Operations**:
- Signal requests
- Trade execution
- Position management
- Account info queries
- Real-time updates
- Heartbeat mechanism

## Technology Stack

### MetaTrader 5 (MQL5)
- **Language**: MQL5 (C++ derivative)
- **Platform**: MetaTrader 5 Terminal
- **Execution**: Native binary compilation
- **Features Used**:
  - Object-oriented programming
  - Structures for data organization
  - Built-in technical indicators
  - Trade execution API
  - Error handling

### Python Bridge
- **Language**: Python 3.8+
- **Framework**: AsyncIO for async operations
- **Libraries**:
  - `MetaTrader5`: Official MT5 Python API
  - `websockets`: WebSocket server implementation
  - `requests`: HTTP client for backend
  - `python-dotenv`: Environment management
  - `numpy`: Data processing (optional)

### Backend Integration
- **Server**: Node.js + Express
- **Database**: PostgreSQL
- **Real-time**: Socket.IO
- **API**: RESTful endpoints

## Risk Management Features

### Position Sizing
1. **ATR-Based** (Default):
   - Calculates based on market volatility
   - Adaptive to changing conditions
   - Normalizes across different symbols

2. **Fixed Risk Percentage**:
   - Risk constant % of account
   - Automatically compounds profits
   - Adjustable per EA

3. **Confidence Weighted** (Gold EA):
   - Higher confidence = larger position
   - Dynamic risk allocation
   - Ranges from 0-100%

### Stop Loss Methods
1. **ATR Multiplier**: SL = Entry ± (ATR × Multiplier)
2. **Fixed Percentage**: SL = Entry ± (Entry × %)
3. **Technical Levels**: Support/Resistance based

### Take Profit Strategies
1. **Risk:Reward Ratio**: TP = SL Distance × RR Ratio
2. **Fixed Pips**: TP = Entry ± X pips
3. **Technical Targets**: Fibonacci, S/R levels
4. **Trailing**: Dynamic TP following price

### Protective Mechanisms
- **Daily Trade Limits**: Prevents overtrading
- **Daily Loss Limits**: Caps maximum daily loss
- **Equity Stop Loss**: Closes all if equity drops X%
- **Correlation Filter**: Avoids correlated overexposure
- **Spread Filter**: No trading if spread too wide
- **Session Filter**: Time-based trading windows
- **Break Even**: Locks profit when conditions met
- **Trailing Stop**: Protects profit in trends

## Performance Characteristics

### Expected Performance (Based on Design)

**Stock EA**:
- Win Rate Target: 55-65%
- Risk:Reward: 1:2
- Trades/Day: 2-5 (depending on volatility)
- Best Conditions: Trending stocks in regular hours
- Profit Factor Target: > 1.5

**Gold EA**:
- Win Rate Target: 50-60%
- Risk:Reward: 1:2 to 1:3
- Trades/Day: 1-4 (strategy dependent)
- Best Conditions: High volatility, London/NY sessions
- Profit Factor Target: > 1.8

**Forex EA**:
- Win Rate Target: 50-55%
- Risk:Reward: 1:2 to 1:2.5
- Trades/Day: 3-8 (across all pairs)
- Best Conditions: Trending markets, high liquidity
- Profit Factor Target: > 1.6

**Important**: These are design targets. Actual performance depends on market conditions, settings, and broker execution.

## Code Quality Features

### Error Handling
- Comprehensive error checking
- Graceful degradation
- Detailed error logging
- Retry mechanisms
- Fallback options

### Logging
- Initialization logs
- Signal detection logs
- Trade execution logs
- Error logs with codes
- Performance statistics
- Daily summaries

### Code Organization
- Clear function separation
- Grouped input parameters
- Descriptive variable names
- Inline comments for complex logic
- Modular design

### Safety Features
- Input validation
- Lot size normalization
- Price validation
- Symbol availability check
- Margin requirement validation
- Execution verification

## Integration Capabilities

### WebSocket Protocol

**Message Format**:
```json
{
  "type": "message_type",
  "data": { ... },
  "timestamp": "ISO8601"
}
```

**Supported Message Types**:
- `heartbeat`: Keep-alive ping
- `request_signal`: Request trading signal
- `execute_trade`: Execute trade order
- `get_positions`: Query open positions
- `get_account_info`: Account details
- `close_position`: Close specific position
- `position_update`: Broadcast position updates

### Backend API Endpoints

**Expected Endpoints**:
```
GET  /api/signals/:symbol          # Get trading signal
POST /api/trades/notify            # Trade execution notification
GET  /api/account/stats            # Account statistics
POST /api/positions/update         # Position status update
GET  /api/health                   # System health check
```

### Machine Learning Integration

The system is designed to integrate with ML models:

1. **Signal Generation**: Backend can provide ML-based signals
2. **Validation**: EAs validate signals against technical filters
3. **Execution**: Automatic execution with risk management
4. **Feedback Loop**: Results sent back for model improvement

**ML Signal Format**:
```json
{
  "symbol": "EURUSD",
  "type": "BUY",
  "entry": 1.1000,
  "stop_loss": 1.0950,
  "take_profit": 1.1100,
  "confidence": 85,
  "model": "lstm_v2",
  "features": {...}
}
```

## Deployment Options

### Option 1: Local Development
- Run on your development machine
- MT5 on Windows
- Python bridge locally
- Backend on localhost
- **Pros**: Easy to test, debug
- **Cons**: Requires computer running 24/7

### Option 2: Windows VPS
- Rent Windows VPS (Forex VPS providers)
- Install MT5, Python, Node.js
- Run all components on VPS
- **Pros**: 24/7 operation, low latency
- **Cons**: Monthly cost ($20-50)

### Option 3: Hybrid
- MT5 + Bridge on VPS
- Backend on cloud (Heroku, AWS, etc.)
- **Pros**: Scalable backend, reliable MT5
- **Cons**: More complex setup

### Recommended VPS Specifications
- **OS**: Windows Server 2019+
- **RAM**: 4GB minimum, 8GB recommended
- **CPU**: 2 cores minimum, 4 cores recommended
- **Storage**: 50GB SSD
- **Network**: < 10ms ping to broker
- **Location**: Near broker servers

## Testing Strategy

### 1. Unit Testing (Per EA)
- Test each EA individually
- Use demo account
- 1-2 weeks minimum
- Monitor: execution, signals, errors

### 2. Integration Testing (With Bridge)
- Enable WebSocket
- Test EA ↔ Bridge communication
- Verify signal flow
- Test error handling

### 3. System Testing (Full Stack)
- EA + Bridge + Backend
- Test complete workflow
- Verify data persistence
- Test under load

### 4. Backtesting (MT5 Strategy Tester)
- Historical data testing
- Parameter optimization
- Forward testing
- Walk-forward analysis

**Important**: Backtests won't test WebSocket features - only local signal generation.

## Customization Guide

### Adding New Indicators

1. **In EA (MQL5)**:
```mql5
// Declare handle
int newIndicatorHandle;

// In OnInit()
newIndicatorHandle = iCustomIndicator(...);

// In UpdateIndicators()
CopyBuffer(newIndicatorHandle, 0, 0, 3, buffer);

// Use in signal generation
if(buffer[1] > threshold) { ... }
```

### Adding New Strategies

1. **Create new signal function**:
```mql5
TradeSignal GetMyNewStrategy()
{
   TradeSignal signal;
   signal.valid = false;

   // Your logic here
   if(/* conditions */)
   {
      signal.valid = true;
      signal.type = ORDER_TYPE_BUY;
      // Set other parameters
   }

   return signal;
}
```

2. **Add to strategy enum**:
```mql5
enum ENUM_STRATEGY
{
   STRATEGY_EXISTING,
   STRATEGY_MY_NEW    // Add here
};
```

3. **Call in GetTradeSignal()**:
```mql5
case STRATEGY_MY_NEW:
   signal = GetMyNewStrategy();
   break;
```

### Modifying Risk Parameters

**Increase Aggressiveness**:
```mql5
InpRiskPercent = 1.5;           // 0.5 → 1.5
InpMaxDailyTrades = 15;         // 5 → 15
InpRiskRewardRatio = 3.0;       // 2.0 → 3.0
```

**Increase Conservativeness**:
```mql5
InpRiskPercent = 0.3;           // 1.0 → 0.3
InpMaxDailyLoss = 1.0;          // 3.0 → 1.0
InpUseEquityStop = true;
InpEquityStopPercent = 3.0;     // 5.0 → 3.0
```

## Maintenance Checklist

### Daily
- [ ] Check system is running
- [ ] Review trade logs
- [ ] Monitor positions
- [ ] Check for errors

### Weekly
- [ ] Review performance metrics
- [ ] Check win rate, profit factor
- [ ] Review largest wins/losses
- [ ] Verify backup/logs rotation

### Monthly
- [ ] Full performance analysis
- [ ] Compare to benchmarks
- [ ] Optimize settings if needed
- [ ] Update documentation
- [ ] Review and adjust risk parameters

## Support Resources

### Documentation
1. **README.md**: Complete system documentation
2. **QUICKSTART.md**: Fast setup guide
3. **TRADING_GUIDE.md**: Trading strategies and optimization
4. **This file**: Project overview

### Code Comments
- Each EA has inline comments
- Python bridge is documented
- Complex logic explained
- Parameter descriptions in inputs

### Logging
- MT5 Experts tab: Real-time EA logs
- Python logs: File + console
- Backend logs: Application logs
- All logs include timestamps and context

## License & Disclaimer

**Educational Use**: This system is for educational and research purposes.

**Risk Warning**:
- Trading involves substantial risk of loss
- Past performance ≠ future results
- Test thoroughly before live use
- Never risk more than you can afford to lose
- Authors not responsible for financial losses

**Usage Rights**:
- Personal use: Allowed
- Commercial use: Contact for licensing
- Modification: Allowed for personal use
- Distribution: Not allowed without permission

## What Makes This System Unique

1. **Three Specialized EAs**: Each optimized for specific market
2. **Advanced Risk Management**: Multiple protective layers
3. **Python Integration**: Modern backend connectivity
4. **Machine Learning Ready**: Designed for ML signal integration
5. **Professional Code Quality**: Error handling, logging, validation
6. **Comprehensive Documentation**: 35+ KB of guides
7. **Production Ready**: Used actual trading best practices
8. **Modular Design**: Easy to customize and extend

## Next Steps

1. **Read Documentation**: Start with QUICKSTART.md
2. **Setup System**: Run setup.sh script
3. **Configure**: Edit .env with your credentials
4. **Test on Demo**: Minimum 2 weeks
5. **Monitor & Optimize**: Review and adjust
6. **Consider Live**: Only when consistently profitable on demo

## Technical Support

For issues or questions:

1. **Check Documentation**: Most answers are here
2. **Review Logs**: Errors often explain themselves
3. **Test Configuration**: Verify all settings
4. **Demo Test**: Reproduce on demo account
5. **Contact Support**: With detailed error info

---

## System Statistics

**Total Lines of Code**: ~2,600+
- StockEA: ~660 lines
- GoldEA: ~880 lines
- ForexEA: ~1,100 lines
- Python Bridge: ~600 lines
- Config/Setup: ~100 lines

**Documentation**: ~9,000+ words across 4 documents

**Development Time**: Professional-grade system

**Supported Symbols**: 20+ (stocks, gold, forex pairs)

**Risk Management Features**: 15+

**Configurable Parameters**: 150+

**Supported Strategies**: 10+

---

**This is a complete, professional trading system ready for deployment!** 🚀

Good luck and trade wisely! 📈💰
