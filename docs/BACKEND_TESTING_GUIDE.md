# Backend Testing Guide - MT4 EA Integration

## 🎯 Quick Test Steps

### Step 1: Start the Backend Server

```bash
cd backend
npm install  # If not done already
npm start
```

You should see:
```
Server running on port 5000
Database connected successfully
```

---

### Step 2: Create a Test User Account

#### Option A: Using cURL
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "trader@test.com",
    "password": "password123",
    "name": "Test Trader"
  }'
```

#### Option B: Using the Frontend Dashboard
```bash
cd landing
npm install
npm start
```
Then register via the UI at `http://localhost:3000/register`

---

### Step 3: Login and Get Auth Token

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "trader@test.com",
    "password": "password123"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "trader@test.com",
      "name": "Test Trader"
    }
  }
}
```

**Copy the `token` value!**

---

### Step 4: Test Bot Registration (Simulating MT4 EA)

```bash
# Replace YOUR_TOKEN_HERE with the token from Step 3
curl -X POST http://localhost:5000/api/bots \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "bot_name": "SST_12345_EURUSD",
    "account_number": 12345,
    "account_name": "Test Account",
    "broker_name": "Test Broker",
    "server_name": "TestBroker-Live",
    "version": "1.0"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Bot registered successfully",
  "data": {
    "id": "abc123...",
    "_id": "abc123...",
    "bot_name": "SST_12345_EURUSD",
    "status": "running",
    "isNewRegistration": true
  }
}
```

**Copy the `id` value!**

---

### Step 5: Test Heartbeat (Simulating MT4 EA)

```bash
# Replace BOT_ID_HERE and YOUR_TOKEN_HERE
curl -X POST http://localhost:5000/api/bots/BOT_ID_HERE/heartbeat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "balance": 10000.00,
    "equity": 10050.00,
    "margin": 500.00,
    "free_margin": 9500.00,
    "open_positions": 2,
    "status": "RUNNING"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Heartbeat updated",
  "data": {
    "bot_id": "abc123...",
    "status": "running",
    "isOnline": true,
    "last_heartbeat": "2025-10-21T..."
  }
}
```

---

### Step 6: Get Bot List

```bash
curl -X GET http://localhost:5000/api/bots \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "abc123...",
      "instance_name": "SST_12345_EURUSD",
      "mt4_account": "12345",
      "broker_name": "Test Broker",
      "status": "running",
      "last_heartbeat": "2025-10-21T...",
      "current_balance": "10000.00",
      "current_equity": "10050.00"
    }
  ]
}
```

---

### Step 7: Get Bot Statistics

```bash
curl -X GET http://localhost:5000/api/bots/BOT_ID_HERE/stats \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🔍 Testing with MT4 EA

### Configure EA Parameters:

```mql4
API_BaseURL      = "http://localhost:5000"
API_UserEmail    = "trader@test.com"
API_UserPassword = "password123"
API_EnableSync   = true
```

### What Should Happen:

1. **On EA Start (OnInit):**
   - ✅ Login request to `/api/auth/login`
   - ✅ Bot registration to `/api/bots`
   - ✅ Initial heartbeat to `/api/bots/{id}/heartbeat`

2. **Every 60 Seconds:**
   - ✅ Heartbeat update to `/api/bots/{id}/heartbeat`

3. **When Trade Opens:**
   - ✅ Trade data sent to `/api/trades/bot/{id}`

4. **When Trade Closes:**
   - ✅ Trade update to `/api/trades/{tradeId}`

---

## 🐛 Troubleshooting

### Error: "WebRequest not allowed"
**Solution:** Add `http://localhost:5000` to MT4 WebRequest whitelist
```
Tools → Options → Expert Advisors → Allow WebRequest for:
http://localhost:5000
```

---

### Error: 401 Unauthorized
**Solution:** Token expired or invalid. Login again to get new token.

---

### Error: 404 Not Found - Bot Instance
**Solution:** Bot ID is incorrect. Check the ID from registration response.

---

### Error: 500 Internal Server Error
**Solution:** Check backend console logs for detailed error:
```bash
# Backend will show errors like:
Error: Cannot find module 'sequelize'
→ Run: npm install sequelize

Database connection failed
→ Check database configuration in .env
```

---

## 📊 Verify in Dashboard

1. Start frontend:
```bash
cd landing
npm start
```

2. Open browser: `http://localhost:3000`

3. Login with: `trader@test.com` / `password123`

4. Go to "My Bots" page

5. You should see your bot listed with:
   - ✅ Status: Running
   - ✅ Last Heartbeat: Just now
   - ✅ Balance: $10,000.00

---

## ✅ Success Checklist

- [ ] Backend server running on port 5000
- [ ] User account created
- [ ] Login successful (token received)
- [ ] Bot registration successful
- [ ] Heartbeat update successful
- [ ] Bot appears in GET /api/bots
- [ ] Bot visible in web dashboard
- [ ] MT4 EA can authenticate
- [ ] MT4 EA can register bot
- [ ] MT4 EA sends heartbeats

---

## 🔗 Next Steps

Once backend is working:

1. **Test Trade Sync:**
   ```bash
   curl -X POST http://localhost:5000/api/trades/bot/BOT_ID_HERE \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -d '{
       "ticket_number": 123456,
       "symbol": "EURUSD",
       "trade_type": "BUY",
       "lot_size": 0.10,
       "open_price": 1.0850,
       "stop_loss": 1.0800,
       "take_profit": 1.0900,
       "strategy_used": "Momentum",
       "open_time": "2025-10-21T10:00:00Z"
     }'
   ```

2. **Test Trade Close:**
   ```bash
   curl -X PUT http://localhost:5000/api/trades/TRADE_ID_HERE \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -d '{
       "close_price": 1.0875,
       "profit": 25.00,
       "commission": -2.50,
       "swap": -0.15,
       "close_time": "2025-10-21T11:00:00Z"
     }'
   ```

3. **Enable MT4 EA Integration**
4. **Watch Real-Time Updates in Dashboard**

---

## 📝 Common API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Create user account |
| POST | `/api/auth/login` | Login & get token |
| GET | `/api/auth/profile` | Get user profile |
| POST | `/api/bots` | Register bot (MT4 EA) |
| GET | `/api/bots` | List user's bots |
| GET | `/api/bots/{id}` | Get bot details |
| POST | `/api/bots/{id}/heartbeat` | Update heartbeat |
| GET | `/api/bots/{id}/stats` | Get statistics |
| POST | `/api/trades/bot/{botId}` | Create trade |
| PUT | `/api/trades/{id}` | Update trade |
| GET | `/api/trades` | List all trades |

---

**✅ Your backend is now ready for MT4 EA integration!**

