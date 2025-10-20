//+------------------------------------------------------------------+
//|                                             SST_Analytics.mqh |
//|                 Smart Stock Trader - Performance Analytics       |
//|        Calculate and track comprehensive performance metrics     |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// ANALYTICS CALCULATIONS
//--------------------------------------------------------------------

// Calculate win rate
double Analytics_GetWinRate() {
   if(g_TotalTrades == 0) return 0;
   return (g_TotalWins / (double)g_TotalTrades) * 100.0;
}

// Calculate profit factor
double Analytics_GetProfitFactor() {
   if(g_TotalLoss == 0) return 0;
   return MathAbs(g_TotalProfit / g_TotalLoss);
}

// Calculate average win
double Analytics_GetAverageWin() {
   if(g_TotalWins == 0) return 0;
   return g_TotalProfit / g_TotalWins;
}

// Calculate average loss
double Analytics_GetAverageLoss() {
   if(g_TotalLosses == 0) return 0;
   return g_TotalLoss / g_TotalLosses;
}

// Calculate expectancy
double Analytics_GetExpectancy() {
   if(g_TotalTrades == 0) return 0;

   double avgWin = Analytics_GetAverageWin();
   double avgLoss = Analytics_GetAverageLoss();
   double winRate = Analytics_GetWinRate() / 100.0;
   double lossRate = 1.0 - winRate;

   return (avgWin * winRate) - (avgLoss * lossRate);
}

// Calculate Sharpe Ratio (simplified)
double Analytics_GetSharpeRatio() {
   // This would require tracking returns over time
   // Simplified version using profit factor as proxy
   double pf = Analytics_GetProfitFactor();
   if(pf == 0) return 0;
   return (pf - 1.0) * MathSqrt(g_TotalTrades);
}

// Calculate maximum drawdown
double Analytics_GetMaxDrawdown() {
   double maxDD = 0;
   double peak = g_DailyStartEquity;

   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         if(OrderMagicNumber() == MagicNumber) {
            double equity = AccountEquity();
            if(equity > peak) {
               peak = equity;
            }

            double dd = ((peak - equity) / peak) * 100.0;
            if(dd > maxDD) {
               maxDD = dd;
            }
         }
      }
   }

   return maxDD;
}

// Calculate R-multiple for a trade
double Analytics_CalculateRMultiple(double entryPrice, double exitPrice, double stopLoss, bool isBuy) {
   double risk = MathAbs(entryPrice - stopLoss);
   if(risk == 0) return 0;

   double reward = isBuy ? (exitPrice - entryPrice) : (entryPrice - exitPrice);
   return reward / risk;
}

// Open log file for CSV logging
void Analytics_OpenLogFile() {
   if(!LogToCSV) return;
   if(g_LogFileHandle != INVALID_HANDLE) return;

   string filename = "SmartStockTrader_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
   g_LogFileHandle = FileOpen(filename, FILE_CSV | FILE_WRITE | FILE_READ, ',');

   if(g_LogFileHandle != INVALID_HANDLE) {
      // Write CSV header
      FileSeek(g_LogFileHandle, 0, SEEK_END);
      if(FileSize(g_LogFileHandle) == 0) {
         FileWrite(g_LogFileHandle,
                  "Ticket", "Symbol", "Type", "OpenTime", "CloseTime",
                  "OpenPrice", "ClosePrice", "Lots", "StopLoss", "TakeProfit",
                  "Profit", "Commission", "Swap", "NetProfit",
                  "Pips", "RMultiple", "Strategy", "Duration");
      }
      FileFlush(g_LogFileHandle);
      Print("Trade log file opened: ", filename);
   } else {
      Print("ERROR: Could not open log file. Error code: ", GetLastError());
   }
}

// Log a completed trade
void Analytics_LogTrade(int ticket, string strategy, datetime openTime, datetime closeTime) {
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) return;

   string symbol = OrderSymbol();
   int type = OrderType();
   double openPrice = OrderOpenPrice();
   double closePrice = OrderClosePrice();
   double lots = OrderLots();
   double stopLoss = OrderStopLoss();
   double takeProfit = OrderTakeProfit();
   double profit = OrderProfit();
   double commission = OrderCommission();
   double swap = OrderSwap();
   double netProfit = profit + commission + swap;

   // Calculate pips
   double point = MarketInfo(symbol, MODE_POINT);
   double pips = 0;
   if(point > 0) {
      if(type == OP_BUY) {
         pips = (closePrice - openPrice) / point / 10.0;
      } else {
         pips = (openPrice - closePrice) / point / 10.0;
      }
   }

   // Calculate R-multiple
   bool isBuy = (type == OP_BUY);
   double rMultiple = Analytics_CalculateRMultiple(openPrice, closePrice, stopLoss, isBuy);

   // Duration
   int durationSeconds = (int)(closeTime - openTime);
   int hours = durationSeconds / 3600;
   int minutes = (durationSeconds % 3600) / 60;
   string duration = IntegerToString(hours) + "h " + IntegerToString(minutes) + "m";

   // Write to CSV
   if(g_LogFileHandle != INVALID_HANDLE) {
      FileSeek(g_LogFileHandle, 0, SEEK_END);
      FileWrite(g_LogFileHandle,
               ticket, symbol, (type == OP_BUY ? "BUY" : "SELL"),
               TimeToString(openTime, TIME_DATE|TIME_MINUTES),
               TimeToString(closeTime, TIME_DATE|TIME_MINUTES),
               DoubleToString(openPrice, _Digits),
               DoubleToString(closePrice, _Digits),
               DoubleToString(lots, 2),
               DoubleToString(stopLoss, _Digits),
               DoubleToString(takeProfit, _Digits),
               DoubleToString(profit, 2),
               DoubleToString(commission, 2),
               DoubleToString(swap, 2),
               DoubleToString(netProfit, 2),
               DoubleToString(pips, 1),
               DoubleToString(rMultiple, 2),
               strategy,
               duration);
      FileFlush(g_LogFileHandle);
   }

   // Update global statistics
   g_TotalTrades++;
   if(netProfit > 0) {
      g_TotalWins++;
      g_TotalProfit += netProfit;
      g_ConsecutiveWins++;
      g_ConsecutiveLosses = 0;

      g_DailyWins++;
   } else {
      g_TotalLosses++;
      g_TotalLoss += MathAbs(netProfit);
      g_ConsecutiveLosses++;
      g_ConsecutiveWins = 0;

      g_DailyLosses++;
   }

   g_DailyTrades++;
   g_DailyProfit += netProfit;

   // Update recovery mode
   Risk_UpdateRecoveryMode();

   // Send notification
   if(SendNotifications) {
      string msg = "Smart Stock Trader: " + symbol + " " + (type == OP_BUY ? "BUY" : "SELL") + " closed\n";
      msg += "P/L: $" + DoubleToString(netProfit, 2) + " (" + DoubleToString(pips, 1) + " pips)\n";
      msg += "Strategy: " + strategy + "\n";
      msg += "Win Rate: " + DoubleToString(Analytics_GetWinRate(), 1) + "%";

      SendNotification(msg);
   }

   if(DebugMode) {
      Print("=== TRADE CLOSED ===");
      Print("Symbol: ", symbol);
      Print("Type: ", (type == OP_BUY ? "BUY" : "SELL"));
      Print("Entry: ", openPrice, " | Exit: ", closePrice);
      Print("Profit: $", netProfit, " (", pips, " pips)");
      Print("R-Multiple: ", DoubleToString(rMultiple, 2));
      Print("Strategy: ", strategy);
      Print("Duration: ", duration);
      Print("Win Rate: ", DoubleToString(Analytics_GetWinRate(), 1), "%");
      Print("Profit Factor: ", DoubleToString(Analytics_GetProfitFactor(), 2));
      Print("====================");
   }
}

// Generate performance report
string Analytics_GenerateReport() {
   string report = "\n========== SMART STOCK TRADER PERFORMANCE REPORT ==========\n\n";

   report += "=== Account Summary ===\n";
   report += "Balance: $" + DoubleToString(AccountBalance(), 2) + "\n";
   report += "Equity: $" + DoubleToString(AccountEquity(), 2) + "\n";
   report += "Margin: $" + DoubleToString(AccountMargin(), 2) + "\n";
   report += "Free Margin: $" + DoubleToString(AccountFreeMargin(), 2) + "\n\n";

   report += "=== Overall Statistics ===\n";
   report += "Total Trades: " + IntegerToString(g_TotalTrades) + "\n";
   report += "Wins: " + IntegerToString(g_TotalWins) + " | Losses: " + IntegerToString(g_TotalLosses) + "\n";
   report += "Win Rate: " + DoubleToString(Analytics_GetWinRate(), 1) + "%\n";
   report += "Total Profit: $" + DoubleToString(g_TotalProfit, 2) + "\n";
   report += "Total Loss: $" + DoubleToString(g_TotalLoss, 2) + "\n";
   report += "Net P/L: $" + DoubleToString(g_TotalProfit - g_TotalLoss, 2) + "\n";
   report += "Profit Factor: " + DoubleToString(Analytics_GetProfitFactor(), 2) + "\n";
   report += "Average Win: $" + DoubleToString(Analytics_GetAverageWin(), 2) + "\n";
   report += "Average Loss: $" + DoubleToString(Analytics_GetAverageLoss(), 2) + "\n";
   report += "Expectancy: $" + DoubleToString(Analytics_GetExpectancy(), 2) + "\n";
   report += "Sharpe Ratio: " + DoubleToString(Analytics_GetSharpeRatio(), 2) + "\n";
   report += "Max Drawdown: " + DoubleToString(Analytics_GetMaxDrawdown(), 2) + "%\n\n";

   report += "=== Today's Performance ===\n";
   report += "Trades: " + IntegerToString(g_DailyTrades) + "\n";
   report += "Wins: " + IntegerToString(g_DailyWins) + " | Losses: " + IntegerToString(g_DailyLosses) + "\n";
   double dailyWinRate = (g_DailyTrades > 0) ? (g_DailyWins / (double)g_DailyTrades * 100.0) : 0;
   report += "Win Rate: " + DoubleToString(dailyWinRate, 1) + "%\n";
   report += "Daily P/L: $" + DoubleToString(g_DailyProfit, 2) + "\n";
   double dailyPct = (g_DailyStartEquity > 0) ? (g_DailyProfit / g_DailyStartEquity * 100.0) : 0;
   report += "Daily Return: " + DoubleToString(dailyPct, 2) + "%\n\n";

   report += "=== Current Status ===\n";
   report += "EA State: ";
   switch(g_EAState) {
      case STATE_READY: report += "READY\n"; break;
      case STATE_SUSPENDED: report += "SUSPENDED (Daily loss limit reached)\n"; break;
      case STATE_RECOVERY: report += "RECOVERY MODE (Reduced risk)\n"; break;
      case STATE_NEWS_PAUSE: report += "NEWS PAUSE\n"; break;
   }
   report += "Session: " + Session_GetCurrentName() + "\n";
   report += "Trading Allowed: " + (Session_IsTradingTime() ? "YES" : "NO") + "\n";
   report += "Open Positions: " + IntegerToString(ArraySize(g_OpenTrades)) + "\n";
   report += "Consecutive Wins: " + IntegerToString(g_ConsecutiveWins) + "\n";
   report += "Consecutive Losses: " + IntegerToString(g_ConsecutiveLosses) + "\n\n";

   report += "==========================================================\n";

   return report;
}

// Initialize analytics
void Analytics_Init() {
   Print("=== Analytics Module Initialized ===");
   Analytics_OpenLogFile();
}

// Close analytics (cleanup)
void Analytics_Deinit() {
   if(g_LogFileHandle != INVALID_HANDLE) {
      FileClose(g_LogFileHandle);
      g_LogFileHandle = INVALID_HANDLE;
      Print("Trade log file closed");
   }

   // Print final report
   if(ShowBacktestStats) {
      Print(Analytics_GenerateReport());
   }
}

//+------------------------------------------------------------------+
