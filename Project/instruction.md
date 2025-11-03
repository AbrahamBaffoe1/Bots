
It captures your original idea — *“the bot should open many trades based on the balance, close all when in profit, and reopen again in the same direction if trend continues”* — and expands it into a detailed technical specification and logic flow suitable for implementation.

---

# 📘 **Technical Specification Document**

## Project Title: **Gold Martingale Auto-Trading Bot (Python + MetaTrader5 API)**

---

### **1. Project Overview**

The **Gold Martingale Auto-Trading Bot** is an algorithmic trading system designed for **XAU/USD (Gold)** on the **MetaTrader5 platform**, implemented in **Python** using the official **MT5 API**.

The bot automates trading by:

* Opening **multiple trades simultaneously** based on account balance.
* Using a **trend detection system** to determine trade direction (BUY/SELL).
* Employing a **pure martingale logic** — doubling trade size after each losing position.
* Monitoring **cumulative floating profit** across all trades and closing **all open positions** once the target profit is reached.
* Automatically **restarting** the trading sequence in the same market direction if the trend remains intact.

The strategy is designed to **capitalize on gold’s volatility** and **compound profits dynamically** based on account growth.

---

### **2. Core Concept Summary**

#### 🔸 Trading Principle:

1. Determine the **current market trend** using moving averages or user-specified direction.
2. Open multiple small trades in the direction of the trend — **number of trades scales with account balance**.
3. If price moves against the trades (unfavorable), **open additional positions** in the same direction with **increased lot size (doubling)**.
4. Once **total net profit (across all open trades)** turns positive and hits a **target threshold**, the bot **closes all positions** instantly to lock profits.
5. The bot then **evaluates the market again** —

   * If the trend remains the same, it **reopens new trades** in that same direction.
   * If the trend reverses, it **switches direction** and starts a new martingale sequence.

This cycle repeats indefinitely, allowing continuous compounding.

---

### **3. Strategy Design Components**

#### 3.1. **Trend Detection**

* **Indicator:** Exponential Moving Averages (EMA)
* **Logic:**

  * If **EMA(50) > EMA(200)** → market trend is **bullish (BUY)**.
  * If **EMA(50) < EMA(200)** → market trend is **bearish (SELL)**.
* **Optional Override:** User can force direction (`BUY` or `SELL`) manually if desired.

#### 3.2. **Trade Initialization**

* **Symbol:** `XAUUSD` (configurable)
* **Initial Lot Size:** User-defined (e.g., `0.01`)
* **Number of Initial Trades:** Based on account balance (e.g., 1 trade per $2,000 of balance)
* **Trade Spacing:** Optional grid spacing by price distance (e.g., every 100 pips) or time interval.

#### 3.3. **Martingale Logic**

* **Pure Martingale Scaling:**
  Each time the total of all open trades is in loss, a new trade is opened in the same direction with **lot size doubled** relative to the last trade.

| Trade Level | Lot Size |
| ----------- | -------- |
| 1           | 0.01     |
| 2           | 0.02     |
| 3           | 0.04     |
| 4           | 0.08     |
| ...         | ...      |

* **Maximum Levels:** Configurable (e.g., `7 levels` to prevent infinite exposure)
* **Condition to Add New Trade:**

  * Either a predefined price move against the position (e.g., 100 pips)
  * Or total floating loss threshold reached.

#### 3.4. **Profit Target System**

* **Target Type:**

  * Fixed Dollar Target (e.g., $20 per cycle) **or**
  * Dynamic Target based on account balance (e.g., 0.5% of balance per cycle)
* **Condition:**
  When **sum of all open trades’ floating profit ≥ profit target**, close **all trades** at once.
* **Result:**
  Lock profit, then **restart** a new sequence immediately.

#### 3.5. **Reopen & Restart Logic**

After profit closure:

1. The bot checks if the **trend direction is still valid** (EMA50 vs EMA200).
2. If **trend unchanged** → Reopen grid sequence in same direction.
3. If **trend reversed** → Switch to opposite direction (from BUY → SELL or vice versa).

This ensures continuous operation aligned with dominant market direction.

---

### **4. Dynamic Risk Management**

#### 4.1. **Balance-Based Scaling**

* The **number of open trades** and **initial lot size** scale with account balance.
  Example formula:

  ```
  num_trades = int(balance / 2000)
  base_lot = balance * 0.0001
  ```
* As account grows, the system automatically increases trading volume proportionally.

#### 4.2. **Equity Drawdown Limit**

* Bot monitors **real-time equity drawdown**.
* If drawdown exceeds e.g. **15% of balance**, all trades are closed and bot stops to prevent account wipeout.

#### 4.3. **Exposure Control**

* Maximum total open lots capped (e.g., 10 lots total).
* Bot cannot open new trades if total volume exceeds this threshold.

#### 4.4. **Stop Conditions**

* Max martingale levels reached and still in loss → pause new entries until recovery.
* Connection or symbol errors trigger pause with error log.

---

### **5. Key Functional Components**

| Function                       | Description                                                          |
| ------------------------------ | -------------------------------------------------------------------- |
| **connect_mt5()**              | Initialize and connect to MetaTrader5 terminal.                      |
| **detect_trend()**             | Reads EMA(50/200) data from MT5 to identify trend direction.         |
| **open_trade(direction, lot)** | Sends market order via MT5 API.                                      |
| **compute_total_profit()**     | Calculates cumulative floating P/L for all open trades.              |
| **close_all_trades()**         | Closes every trade associated with the bot’s magic comment.          |
| **run_martingale_cycle()**     | Main loop: executes one complete cycle of trade→scale→close→restart. |
| **main_loop()**                | Keeps bot running continuously with restart logic after each cycle.  |

---

### **6. Parameters & Configuration**

| Parameter                          | Type   | Description                      | Example        |
| ---------------------------------- | ------ | -------------------------------- | -------------- |
| `SYMBOL`                           | String | Trading pair                     | `"XAUUSD"`     |
| `INITIAL_LOT`                      | Float  | Starting lot size                | `0.01`         |
| `MAX_LEVELS`                       | Int    | Maximum martingale levels        | `7`            |
| `PROFIT_TARGET_USD`                | Float  | Profit per cycle (USD)           | `20.0`         |
| `PROFIT_TARGET_PERCENT_OF_BALANCE` | Float  | Dynamic % target                 | `0.005` (0.5%) |
| `MAX_DRAWDOWN_PERCENT`             | Float  | Max allowed equity drawdown      | `0.15` (15%)   |
| `MAX_TOTAL_VOLUME_LOTS`            | Float  | Max total lots open              | `10.0`         |
| `DEVIATION`                        | Int    | Max price slippage allowed       | `20` points    |
| `MAGIC_COMMENT`                    | String | Identifier for this bot’s trades | `"GOLD_MG"`    |
| `SLEEP_SECONDS`                    | Int    | Loop sleep time                  | `5` seconds    |

---

### **7. Workflow Diagram (Simplified)**

```
 ┌──────────────────────────────┐
 │  Start / Connect to MT5      │
 └──────────────┬───────────────┘
                │
        Detect market trend
                │
        ┌───────▼────────┐
        │  BUY or SELL?  │
        └───────┬────────┘
                │
     Open multiple trades (based on balance)
                │
       Monitor total floating P/L
                │
      ┌─────────┴─────────┐
      │ P/L >= target?    │───Yes──► Close all trades, restart cycle
      │                   │
      │ No                │
      ▼                   │
   Open next martingale level (double lot)
                │
     Re-check safety/drawdown limits
                │
      ┌─────────┴─────────┐
      │ Max drawdown?     │───Yes──► Close all, stop bot
      └───────────────────┘
```

---

### **8. Developer Requirements**

#### **Language & Libraries**

* **Python 3.10+**
* Libraries:

  * `MetaTrader5`
  * `numpy`
  * `logging`
  * `datetime`
  * `math`

#### **Platform**

* Compatible with **MetaTrader 5 terminal (desktop)** connected to any broker supporting `XAUUSD`.

#### **Testing Mode**

* Must include a **`DRY_RUN` flag** for simulation (no live trades) with mock data for safe testing.

#### **Logging**

* Log all actions, errors, and results to both console and a `.log` file.
* Example log entries:

  ```
  2025-11-02 10:04:23 INFO: Opened level 3 BUY 0.08 lots
  2025-11-02 10:06:50 INFO: Total floating profit = $24.13, target = $20.00
  2025-11-02 10:06:51 INFO: Profit target reached, closing all positions.
  ```

---

### **9. Risk Disclaimer**

This system uses **pure martingale scaling**, which is **extremely high-risk**.
Developers must:

* Ensure all safety parameters are functional (drawdown limit, level cap, exposure limit).
* Default configuration should start in **`DRY_RUN` (simulation) mode**.
* Require explicit confirmation before trading live.
* Add manual override command to halt trading instantly.

---

### **10. Future Enhancements (Optional)**

* Integrate **Telegram or email notifications** on trade events.
* Add **web dashboard** to view live stats and performance.
* Support **multiple symbols** or **hedging modes**.
* Implement **backtesting module** to simulate on historical data before live deployment.
* Include **smart trailing profit-lock system** to secure gains mid-cycle.

---

### **11. Deliverables**

1. Fully functional **Python script** (`gold_martingale_bot.py`)
2. **Configuration file** (`config.json`) with adjustable parameters
3. **Installation guide** (dependencies + MT5 setup)
4. **Operation manual** (how to start/stop bot, change settings, interpret logs)
5. **Fail-safe verification tests** (dry-run logs proving all core logic works)

---
