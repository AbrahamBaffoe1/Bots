//+------------------------------------------------------------------+
//|                                        SST_HTMLDashboard.mqh |
//|                    HTML Dashboard Generator for Web View         |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// GENERATE HTML DASHBOARD
//--------------------------------------------------------------------
void HTMLDashboard_Generate() {
   string filename = "SmartStockTrader_Dashboard.html";
   int fileHandle = FileOpen(filename, FILE_WRITE | FILE_TXT);

   if(fileHandle == INVALID_HANDLE) {
      Print("ERROR: Could not create HTML dashboard file");
      return;
   }

   string html = "";

   // HTML Header
   html += "<!DOCTYPE html>\n";
   html += "<html lang='en'>\n";
   html += "<head>\n";
   html += "  <meta charset='UTF-8'>\n";
   html += "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>\n";
   html += "  <title>Smart Stock Trader - Live Dashboard</title>\n";
   html += "  <meta http-equiv='refresh' content='5'>\n"; // Auto-refresh every 5 seconds
   html += "  <style>\n";
   html += "    * { margin: 0; padding: 0; box-sizing: border-box; }\n";
   html += "    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: #fff; padding: 20px; }\n";
   html += "    .container { max-width: 1400px; margin: 0 auto; }\n";
   html += "    h1 { text-align: center; margin-bottom: 30px; font-size: 2.5em; text-shadow: 2px 2px 4px rgba(0,0,0,0.5); }\n";
   html += "    .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }\n";
   html += "    .card { background: rgba(255, 255, 255, 0.1); backdrop-filter: blur(10px); border-radius: 15px; padding: 25px; box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37); border: 1px solid rgba(255, 255, 255, 0.18); }\n";
   html += "    .card h2 { color: #4FC3F7; margin-bottom: 20px; font-size: 1.5em; border-bottom: 2px solid #4FC3F7; padding-bottom: 10px; }\n";
   html += "    .stat-row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid rgba(255,255,255,0.1); }\n";
   html += "    .stat-label { font-weight: 500; color: #B0BEC5; }\n";
   html += "    .stat-value { font-weight: bold; font-size: 1.1em; }\n";
   html += "    .positive { color: #66BB6A; }\n";
   html += "    .negative { color: #EF5350; }\n";
   html += "    .neutral { color: #FFA726; }\n";
   html += "    .status-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; font-size: 0.9em; font-weight: bold; }\n";
   html += "    .status-ready { background: #66BB6A; color: #fff; }\n";
   html += "    .status-suspended { background: #EF5350; color: #fff; }\n";
   html += "    .status-recovery { background: #FFA726; color: #fff; }\n";
   html += "    .timestamp { text-align: center; margin-top: 30px; color: #B0BEC5; font-size: 0.9em; }\n";
   html += "    .big-number { font-size: 2em; font-weight: bold; text-align: center; margin: 20px 0; }\n";
   html += "    .progress-bar { background: rgba(255,255,255,0.2); height: 20px; border-radius: 10px; overflow: hidden; margin-top: 10px; }\n";
   html += "    .progress-fill { background: linear-gradient(90deg, #4FC3F7, #66BB6A); height: 100%; transition: width 0.3s; }\n";
   html += "  </style>\n";
   html += "</head>\n";
   html += "<body>\n";
   html += "  <div class='container'>\n";
   html += "    <h1>🚀 SMART STOCK TRADER - LIVE DASHBOARD</h1>\n";
   html += "    <div class='dashboard'>\n";

   // Card 1: EA Status
   html += "      <div class='card'>\n";
   html += "        <h2>⚙️ EA Status</h2>\n";

   string statusClass = "status-ready";
   string statusText = "READY";
   if(g_EAState == STATE_SUSPENDED) {
      statusClass = "status-suspended";
      statusText = "SUSPENDED";
   } else if(g_EAState == STATE_RECOVERY) {
      statusClass = "status-recovery";
      statusText = "RECOVERY MODE";
   }

   html += "        <div class='stat-row'><span class='stat-label'>Status:</span><span class='status-badge " + statusClass + "'>" + statusText + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Session:</span><span class='stat-value'>" + Session_GetCurrentName() + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Trading:</span><span class='stat-value " + (Session_IsTradingTime() ? "positive'>ACTIVE" : "neutral'>PAUSED") + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Open Positions:</span><span class='stat-value'>" + IntegerToString(ArraySize(g_OpenTrades)) + "</span></div>\n";
   html += "      </div>\n";

   // Card 2: Account Summary
   html += "      <div class='card'>\n";
   html += "        <h2>💰 Account Summary</h2>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Balance:</span><span class='stat-value positive'>$" + DoubleToString(AccountBalance(), 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Equity:</span><span class='stat-value'>$" + DoubleToString(AccountEquity(), 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Margin:</span><span class='stat-value'>$" + DoubleToString(AccountMargin(), 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Free Margin:</span><span class='stat-value'>$" + DoubleToString(AccountFreeMargin(), 2) + "</span></div>\n";
   html += "      </div>\n";

   // Card 3: Today's Performance
   double dailyPL = AccountEquity() - g_DailyStartEquity;
   double dailyPct = (g_DailyStartEquity > 0) ? (dailyPL / g_DailyStartEquity * 100.0) : 0;
   string plClass = (dailyPL >= 0) ? "positive" : "negative";
   string plSign = (dailyPL >= 0) ? "+" : "";

   html += "      <div class='card'>\n";
   html += "        <h2>📊 Today's Performance</h2>\n";
   html += "        <div class='big-number " + plClass + "'>" + plSign + "$" + DoubleToString(dailyPL, 2) + "</div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Daily Return:</span><span class='stat-value " + plClass + "'>" + plSign + DoubleToString(dailyPct, 2) + "%</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Trades Today:</span><span class='stat-value'>" + IntegerToString(g_DailyTrades) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Wins / Losses:</span><span class='stat-value'>" + IntegerToString(g_DailyWins) + " / " + IntegerToString(g_DailyLosses) + "</span></div>\n";

   double todayWR = (g_DailyTrades > 0) ? (g_DailyWins / (double)g_DailyTrades * 100.0) : 0;
   string wrClass = (todayWR >= 50) ? "positive" : "neutral";
   html += "        <div class='stat-row'><span class='stat-label'>Win Rate:</span><span class='stat-value " + wrClass + "'>" + DoubleToString(todayWR, 1) + "%</span></div>\n";
   html += "        <div class='progress-bar'><div class='progress-fill' style='width:" + DoubleToString(todayWR, 0) + "%'></div></div>\n";
   html += "      </div>\n";

   // Card 4: Overall Statistics
   double totalWR = Analytics_GetWinRate();
   double pf = Analytics_GetProfitFactor();
   string wrClassTotal = (totalWR >= 50) ? "positive" : "neutral";
   string pfClass = (pf >= 1.5) ? "positive" : ((pf >= 1.0) ? "neutral" : "negative");

   html += "      <div class='card'>\n";
   html += "        <h2>📈 Overall Statistics</h2>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Total Trades:</span><span class='stat-value'>" + IntegerToString(g_TotalTrades) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Wins / Losses:</span><span class='stat-value'>" + IntegerToString(g_TotalWins) + " / " + IntegerToString(g_TotalLosses) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Win Rate:</span><span class='stat-value " + wrClassTotal + "'>" + DoubleToString(totalWR, 1) + "%</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Profit Factor:</span><span class='stat-value " + pfClass + "'>" + DoubleToString(pf, 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Total Profit:</span><span class='stat-value positive'>$" + DoubleToString(g_TotalProfit, 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Total Loss:</span><span class='stat-value negative'>$" + DoubleToString(g_TotalLoss, 2) + "</span></div>\n";
   html += "        <div class='stat-row'><span class='stat-label'>Net P/L:</span><span class='stat-value " + (g_TotalProfit - g_TotalLoss >= 0 ? "positive" : "negative") + "'>$" + DoubleToString(g_TotalProfit - g_TotalLoss, 2) + "</span></div>\n";
   html += "      </div>\n";

   // Card 5: Streaks & Warnings
   html += "      <div class='card'>\n";
   html += "        <h2>⚡ Streaks & Alerts</h2>\n";

   if(g_ConsecutiveWins > 0) {
      html += "        <div class='stat-row'><span class='stat-label'>Win Streak:</span><span class='stat-value positive'>" + IntegerToString(g_ConsecutiveWins) + " 🔥</span></div>\n";
   } else if(g_ConsecutiveLosses > 0) {
      html += "        <div class='stat-row'><span class='stat-label'>Loss Streak:</span><span class='stat-value negative'>" + IntegerToString(g_ConsecutiveLosses) + " ⚠️</span></div>\n";
   } else {
      html += "        <div class='stat-row'><span class='stat-label'>Current Streak:</span><span class='stat-value neutral'>None</span></div>\n";
   }

   if(g_RecoveryModeActive) {
      html += "        <div class='stat-row'><span class='stat-label'>Recovery Mode:</span><span class='status-badge status-recovery'>ACTIVE</span></div>\n";
   }

   double dailyLossRemaining = MaxDailyLossPercent - MathAbs(dailyPct);
   html += "        <div class='stat-row'><span class='stat-label'>Daily Loss Remaining:</span><span class='stat-value'>" + DoubleToString(dailyLossRemaining, 2) + "%</span></div>\n";
   html += "      </div>\n";

   // Card 6: Active Strategies
   html += "      <div class='card'>\n";
   html += "        <h2>🎯 Active Strategies</h2>\n";

   int activeStrategies = 0;
   if(UseMomentumStrategy) { html += "        <div class='stat-row'><span class='stat-label'>✅ Momentum Trading</span></div>\n"; activeStrategies++; }
   if(UseMeanReversion) { html += "        <div class='stat-row'><span class='stat-label'>✅ Mean Reversion</span></div>\n"; activeStrategies++; }
   if(UseBreakoutStrategy) { html += "        <div class='stat-row'><span class='stat-label'>✅ Breakout Trading</span></div>\n"; activeStrategies++; }
   if(UseTrendFollowing) { html += "        <div class='stat-row'><span class='stat-label'>✅ Trend Following</span></div>\n"; activeStrategies++; }
   if(UseVolumeAnalysis) { html += "        <div class='stat-row'><span class='stat-label'>✅ Volume Analysis</span></div>\n"; activeStrategies++; }
   if(UseGapTrading) { html += "        <div class='stat-row'><span class='stat-label'>✅ Gap Trading</span></div>\n"; activeStrategies++; }
   if(UseMultiTimeframe) { html += "        <div class='stat-row'><span class='stat-label'>✅ Multi-Timeframe</span></div>\n"; activeStrategies++; }
   if(UseMarketRegime) { html += "        <div class='stat-row'><span class='stat-label'>✅ Market Regime</span></div>\n"; activeStrategies++; }

   html += "        <div class='big-number positive'>" + IntegerToString(activeStrategies) + " / 8</div>\n";
   html += "      </div>\n";

   html += "    </div>\n";

   // Timestamp
   html += "    <div class='timestamp'>Last Updated: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " | Auto-refresh: 5 seconds</div>\n";

   html += "  </div>\n";
   html += "</body>\n";
   html += "</html>\n";

   FileWriteString(fileHandle, html);
   FileClose(fileHandle);

   Print("HTML Dashboard generated: ", filename);
}

//+------------------------------------------------------------------+
