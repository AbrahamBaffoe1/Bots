# MT5 Expert Advisors - Converted from MQ4

This folder contains MT5 (MetaTrader 5) versions of the trading EAs, converted from their original MQ4 (MetaTrader 4) format.

## 📁 Files in this Folder

### SmartStockTrader Series
- **SmartStockTrader.mq5** - Main multi-strategy stock trading EA for MT5
- **SmartStockTrader_Backtest.mq5** - Optimized backtest version with no time/license restrictions

### UltraBot Series
- **ultraBot.v1.mq5** - Advanced forex trading EA with hybrid intelligence system
- **ultraBot_diagnostic.mq5** - Diagnostic version for troubleshooting

---

## 🔄 Key Differences: MT4 vs MT5

### 1. **Input Parameters**
- **MT4**: Uses `extern` keyword
- **MT5**: Uses `input` keyword
```mql5
// MT4
extern double RiskPercent = 1.0;

// MT5
input double RiskPercent = 1.0;
```

### 2. **Symbol Information**
- **MT4**: `MarketInfo()` function
- **MT5**: `SymbolInfo*()` functions
```mql5
// MT4
double spread = MarketInfo(symbol, MODE_SPREAD);
double minLot = MarketInfo(symbol, MODE_MINLOT);

// MT5
long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
```

### 3. **Account Information**
- **MT4**: `Account*()` functions
- **MT5**: `AccountInfo*()` functions
```mql5
// MT4
double balance = AccountBalance();
double equity = AccountEquity();

// MT5
double balance = AccountInfoDouble(ACCOUNT_BALANCE);
double equity = AccountInfoDouble(ACCOUNT_EQUITY);
```

### 4. **Order Management**
- **MT4**: Direct `OrderSend()`, `OrderClose()`, `OrderModify()`
- **MT5**: Use `CTrade` class (recommended) or new trading functions
```mql5
// MT5 - Using CTrade class
#include <Trade\Trade.mqh>
CTrade trade;

// Open position
trade.Buy(lotSize, symbol, price, sl, tp, "Comment");

// Close position
trade.PositionClose(ticket);

// Modify position
trade.PositionModify(ticket, newSL, newTP);
```

### 5. **Position vs Order System**
- **MT4**: Combined system (OrdersTotal() for everything)
- **MT5**: Separated system
  - `PositionsTotal()` - Open positions
  - `OrdersTotal()` - Pending orders
  - `HistorySelect()` - Historical orders/positions

### 6. **Indicator Functions**
- **MT4**: Direct indicator calls return values
- **MT5**: Handle-based system with CopyBuffer()
```mql5
// MT4
double ma = iMA(symbol, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE, 0);

// MT5
int h_MA = iMA(symbol, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE);
double ma_buffer[];
ArraySetAsSeries(ma_buffer, true);
CopyBuffer(h_MA, 0, 0, 3, ma_buffer);
double ma = ma_buffer[0];
```

### 7. **Symbol Name**
- **MT4**: `Symbol()` function
- **MT5**: `_Symbol` predefined variable
```mql5
// MT4
string sym = Symbol();

// MT5
string sym = _Symbol;
```

### 8. **Time Functions**
- **MT4**: `Year()`, `Month()`, `Day()`, etc.
- **MT5**: `MqlDateTime` structure
```mql5
// MT5
MqlDateTime dt;
TimeToStruct(TimeCurrent(), dt);
int currentHour = dt.hour;
int currentDay = dt.day;
```

---

## 🚀 Installation Instructions

### For MT5 Terminal:

1. **Copy Files to MT5 Data Folder**
   - Open MT5 Terminal
   - Click `File` → `Open Data Folder`
   - Navigate to `MQL5\Experts\`
   - Copy the `.mq5` files here

2. **Compile the EA**
   - In MT5, open MetaEditor (F4 or click MetaEditor icon)
   - Open the `.mq5` file you want to use
   - Click `Compile` (F7) or the compile button
   - Check for errors in the Toolbox window

3. **Attach to Chart**
   - In MT5 Navigator window, find your EA under `Expert Advisors`
   - Drag and drop onto a chart
   - Configure parameters in the dialog
   - Enable `AutoTrading` button

---

## ⚙️ Configuration Tips

### SmartStockTrader.mq5
```
Recommended Settings for Stocks:
- TradingSymbols: "AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA,META,NFLX"
- RiskPercentPerTrade: 1.0%
- UseATRStops: true
- MaxPositions: 3
- TradingStartHour: 9 (Market open)
- TradingEndHour: 16 (Market close)
```

### UltraBot.v1.mq5
```
Recommended Settings for Forex:
- Pairs: "EURUSD,GBPUSD,USDJPY,AUDUSD"
- TradeCurrentChartOnly: false (to trade multiple pairs)
- RiskPercentPerTrade: 1.0%
- UseAdaptiveStops: true
- UseMultiTimeframe: true
- UseATRSweetSpot: true
```

---

## 🧪 Testing

### Strategy Tester
1. In MT5, click `View` → `Strategy Tester` (Ctrl+R)
2. Select your EA from the dropdown
3. Choose symbol and timeframe
4. Set date range
5. Click `Start` to run backtest

### Visual Mode
- Enable "Visualization" checkbox in Strategy Tester
- Watch trades execute in real-time on the chart
- Useful for understanding EA behavior

---

## 🔍 Troubleshooting

### Common Issues

#### 1. "Trade is disabled"
- **Solution**: Enable AutoTrading button in MT5 toolbar
- Check that EA allows live trading in properties

#### 2. "Invalid stops"
- **Solution**: Broker may have minimum distance requirements
- Increase `BaseStopLossPips` or adjust ATR multipliers

#### 3. "No open orders but EA is running"
- **Solution**: Use diagnostic version to see why trades are blocked
- Check logs in Experts tab for filter messages

#### 4. Indicators not working
- **Solution**: Ensure indicator handles are initialized in OnInit()
- Check that CopyBuffer() returns > 0 (data copied successfully)

#### 5. "Array out of range"
- **Solution**: Always use `ArraySetAsSeries(array, true)` before copying indicator buffers
- Check that array size matches requested data count

---

## 📊 Performance Monitoring

### Built-in Dashboard
All EAs include an on-chart dashboard showing:
- Current equity
- Daily P/L
- Open positions
- Total trades
- Win rate

### Log Files
Check MT5 Experts tab for detailed logs:
- Entry/exit signals
- Filter checks
- Risk calculations
- Trade execution results

---

## 🔐 Risk Management Features

Both EA families include:
- ✅ **Position Sizing** - Risk-based lot calculation
- ✅ **Stop Loss** - ATR-based or fixed pip stops
- ✅ **Take Profit** - Multiple R:R targets
- ✅ **Trailing Stops** - Lock in profits
- ✅ **Break-even** - Move SL to entry when profitable
- ✅ **Partial Closes** - Scale out at profit targets
- ✅ **Daily Loss Limit** - Circuit breaker to stop trading
- ✅ **Spread Filter** - Avoid high spread conditions
- ✅ **Correlation Filter** - Prevent over-exposure (UltraBot)
- ✅ **Pyramid Building** - Add to winning positions (UltraBot)

---

## 📝 Important Notes

### MT5 vs MT4 Differences to Remember
1. **No hedging by default** - MT5 uses netting (one position per symbol)
   - Can enable hedging in account settings if broker allows
2. **Different order types** - Market execution is standard
3. **Indicator handles** - Must initialize in OnInit(), release in OnDeinit()
4. **Time functions** - Use MqlDateTime structure
5. **Symbol() replaced with _Symbol** - Predefined variable

### Backtest Considerations
- MT5 backtests are more accurate than MT4
- Use "Every tick based on real ticks" for best accuracy
- Ensure sufficient historical data is downloaded
- Variable spread settings affect results significantly

### Live Trading
- Always test on demo account first
- Start with minimum lot sizes
- Monitor for first 24 hours
- Gradually increase risk after proven performance
- Keep MT5 terminal running (EA stops when terminal closes)
- Ensure stable internet connection

---

## 📞 Support & Resources

### Documentation
- MT5 MQL5 Reference: https://www.mql5.com/en/docs
- MQL5 Forum: https://www.mql5.com/en/forum
- MetaTrader 5 Help: Built-in help (F1)

### Migration Guide
- Official MQL4 to MQL5 Migration: https://www.mql5.com/en/articles/81

---

## 🎯 Strategy Descriptions

### SmartStockTrader
**Multi-Strategy Stock EA** designed for US stock markets
- Momentum Trading (MA crossover + RSI)
- Mean Reversion (Bollinger Bands + RSI)
- Breakout Trading (Support/Resistance breaks)
- Trend Following (200 MA + multi-timeframe confirmation)
- Volume Analysis (Above-average volume confirmation)
- Gap Trading (Opening gap strategies)

### UltraBot
**Advanced Forex EA** with hybrid intelligence
- Trend Following (Multi-timeframe MA system)
- Mean Reversion (Supply/Demand zones)
- Ichimoku Cloud filtering
- Parabolic SAR confirmation
- Envelope channel detection
- ATR Sweet Spot (optimal volatility range)
- Market Regime detection (ADX-based)
- Smart Pyramid Building (add to winners)

---

## ✅ Version History

### v5.00 (Current)
- Initial MT5 conversion from MQ4
- Implemented CTrade class for order management
- Updated all API calls to MT5 standards
- Converted indicator calls to handle-based system
- Updated time functions to MqlDateTime
- Fixed account/symbol info functions
- Tested and verified compilation in MT5

---

## 📧 Questions?

If you encounter issues:
1. Check MT5 Experts tab for error messages
2. Use diagnostic version to troubleshoot
3. Review this README for common solutions
4. Check broker specifications (min lot, max positions, etc.)
5. Ensure correct symbol names for your broker

---

**Happy Trading! 📈**

*Remember: Past performance does not guarantee future results. Always trade responsibly and never risk more than you can afford to lose.*
