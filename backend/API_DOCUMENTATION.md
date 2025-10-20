# Smart Stock Trader API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication
All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

---

## Authentication Endpoints

### 1. Register User
Create a new user account.

**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "is_active": true,
      "email_verified": false,
      "created_at": "2025-01-20T10:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 2. Login
Authenticate and receive JWT token.

**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { /* user object */ },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 3. Get Current User
Get authenticated user details.

**Endpoint:** `GET /auth/me`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "licenses": [ /* array of licenses */ ],
      "botInstances": [ /* array of bot instances */ ]
    }
  }
}
```

---

### 4. Update Profile
Update user profile information.

**Endpoint:** `PUT /auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user": { /* updated user object */ }
  }
}
```

---

### 5. Change Password
Change user password.

**Endpoint:** `PUT /auth/password`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "current_password": "OldPassword123",
  "new_password": "NewPassword456"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## Bot Management Endpoints

### 1. Get All Bots
Get all bot instances for the authenticated user.

**Endpoint:** `GET /bots`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "bots": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "license_id": "uuid",
        "instance_name": "My Trading Bot",
        "mt4_account": "12345678",
        "broker_name": "IC Markets",
        "broker_server": "ICMarkets-Demo01",
        "status": "running",
        "is_live": false,
        "last_heartbeat": "2025-01-20T10:00:00.000Z",
        "started_at": "2025-01-20T09:00:00.000Z",
        "created_at": "2025-01-15T10:00:00.000Z",
        "license": { /* license object */ },
        "trades": [ /* array of open trades */ ]
      }
    ]
  }
}
```

---

### 2. Get Single Bot
Get detailed information about a specific bot.

**Endpoint:** `GET /bots/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "bot": {
      "id": "uuid",
      "instance_name": "My Trading Bot",
      "status": "running",
      "is_live": false,
      "last_heartbeat": "2025-01-20T10:00:00.000Z",
      "license": { /* license details */ },
      "trades": [ /* recent trades */ ]
    }
  }
}
```

---

### 3. Create Bot Instance
Create a new bot instance.

**Endpoint:** `POST /bots`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "license_id": "uuid",
  "instance_name": "My Trading Bot",
  "mt4_account": "12345678",
  "broker_name": "IC Markets",
  "broker_server": "ICMarkets-Demo01",
  "is_live": false
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Bot instance created successfully",
  "data": {
    "bot": { /* bot instance object */ }
  }
}
```

---

### 4. Start Bot
Start a stopped bot instance.

**Endpoint:** `POST /bots/:id/start`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Bot started successfully",
  "data": {
    "bot": {
      "id": "uuid",
      "status": "running",
      "started_at": "2025-01-20T10:00:00.000Z"
    }
  }
}
```

---

### 5. Stop Bot
Stop a running bot instance.

**Endpoint:** `POST /bots/:id/stop`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Bot stopped successfully",
  "data": {
    "bot": {
      "id": "uuid",
      "status": "stopped",
      "stopped_at": "2025-01-20T10:00:00.000Z"
    }
  }
}
```

---

### 6. Update Heartbeat
Update bot heartbeat (called by MT4 EA every minute).

**Endpoint:** `POST /bots/:id/heartbeat`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "status": "running",
    "isOnline": true
  }
}
```

---

### 7. Get Bot Statistics
Get comprehensive statistics for a bot.

**Endpoint:** `GET /bots/:id/stats`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "bot": {
      "id": "uuid",
      "name": "My Trading Bot",
      "status": "running",
      "isOnline": true,
      "uptime": 3600
    },
    "trades": {
      "total": 150,
      "open": 3,
      "closed": 147,
      "winning": 95,
      "losing": 52
    },
    "performance": {
      "totalProfit": "2450.75",
      "grossProfit": "3200.00",
      "grossLoss": "749.25",
      "winRate": "64.63",
      "profitFactor": "4.27",
      "avgWin": "33.68",
      "avgLoss": "14.41"
    }
  }
}
```

---

### 8. Get Bot Logs
Get logs for a specific bot.

**Endpoint:** `GET /bots/:id/logs`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `level` (optional): Filter by log level (INFO, WARNING, ERROR, DEBUG)
- `category` (optional): Filter by category (TRADE, SYSTEM, STRATEGY, ERROR)
- `limit` (optional): Number of logs to return (default: 100)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": "uuid",
        "bot_instance_id": "uuid",
        "log_level": "INFO",
        "category": "TRADE",
        "message": "BUY trade opened: EUR/USD @ 1.08545",
        "metadata": {
          "trade_id": "uuid",
          "ticket_number": "123456"
        },
        "created_at": "2025-01-20T10:00:00.000Z"
      }
    ]
  }
}
```

---

### 9. Delete Bot
Delete a bot instance (must be stopped first).

**Endpoint:** `DELETE /bots/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Bot instance deleted successfully"
}
```

---

## Trade Endpoints

### 1. Get Trades for Bot
Get all trades for a specific bot.

**Endpoint:** `GET /trades/bot/:botId`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `status` (optional): Filter by status (open, closed, cancelled)
- `symbol` (optional): Filter by trading pair (e.g., EUR/USD)
- `limit` (optional): Number of trades to return (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "trades": [
      {
        "id": "uuid",
        "bot_instance_id": "uuid",
        "ticket_number": "123456",
        "symbol": "EUR/USD",
        "trade_type": "BUY",
        "lot_size": "0.10",
        "open_price": "1.08545",
        "close_price": "1.08645",
        "stop_loss": "1.08345",
        "take_profit": "1.08845",
        "commission": "-2.50",
        "swap": "-0.15",
        "profit": "9.85",
        "profit_percentage": "0.92",
        "status": "closed",
        "strategy_used": "Breakout",
        "opened_at": "2025-01-20T09:00:00.000Z",
        "closed_at": "2025-01-20T10:30:00.000Z",
        "duration_seconds": 5400
      }
    ],
    "total": 150,
    "limit": 50,
    "offset": 0
  }
}
```

---

### 2. Get Single Trade
Get detailed information about a specific trade.

**Endpoint:** `GET /trades/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "trade": { /* trade object */ }
  }
}
```

---

### 3. Create Trade
Create a new trade (called by MT4 EA).

**Endpoint:** `POST /trades/bot/:botId`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "ticket_number": "123456",
  "symbol": "EUR/USD",
  "trade_type": "BUY",
  "lot_size": 0.10,
  "open_price": 1.08545,
  "stop_loss": 1.08345,
  "take_profit": 1.08845,
  "strategy_used": "Breakout"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Trade created successfully",
  "data": {
    "trade": { /* trade object */ }
  }
}
```

---

### 4. Update Trade
Update trade details (called by MT4 EA when trade closes).

**Endpoint:** `PUT /trades/:id`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "close_price": 1.08645,
  "profit": 9.85,
  "commission": -2.50,
  "swap": -0.15
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Trade updated successfully",
  "data": {
    "trade": { /* updated trade object */ }
  }
}
```

---

### 5. Get Trade History
Get trade history with statistics and charts.

**Endpoint:** `GET /trades/history`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `period` (optional): Time period (24h, 7d, 30d, 90d) - default: 7d
- `botId` (optional): Filter by specific bot

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "period": "7d",
    "totalTrades": 45,
    "chartData": [
      {
        "date": "2025-01-14",
        "profit": "125.50"
      },
      {
        "date": "2025-01-15",
        "profit": "85.25"
      }
    ],
    "trades": [ /* latest 20 trades */ ]
  }
}
```

---

## Error Responses

All error responses follow this format:

**4xx Client Errors:**
```json
{
  "success": false,
  "message": "Error description"
}
```

**5xx Server Errors:**
```json
{
  "success": false,
  "message": "Internal server error",
  "error": "Detailed error message"
}
```

### Common Error Codes:
- `400` Bad Request - Invalid input data
- `401` Unauthorized - Missing or invalid authentication token
- `403` Forbidden - Insufficient permissions
- `404` Not Found - Resource not found
- `429` Too Many Requests - Rate limit exceeded
- `500` Internal Server Error - Server-side error

---

## Rate Limiting

API requests are rate-limited to prevent abuse:
- **Window:** 15 minutes
- **Max Requests:** 100 per IP address

When rate limit is exceeded:
```json
{
  "success": false,
  "message": "Too many requests from this IP, please try again later"
}
```

---

## WebSocket Events (Future Implementation)

Real-time updates for:
- Trade opens/closes
- Bot status changes
- Account balance updates
- System notifications

---

## Best Practices

1. **Authentication**
   - Store JWT tokens securely (localStorage/sessionStorage)
   - Include token in all protected requests
   - Refresh token before expiry

2. **Error Handling**
   - Always check `success` field in responses
   - Handle network errors gracefully
   - Display user-friendly error messages

3. **Performance**
   - Use pagination for large datasets
   - Cache frequently accessed data
   - Minimize API calls where possible

4. **Security**
   - Never expose JWT secret
   - Use HTTPS in production
   - Validate all user inputs
   - Implement CSRF protection

---

## Example Integration (JavaScript)

```javascript
// Login
const login = async (email, password) => {
  const response = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });

  const data = await response.json();
  if (data.success) {
    localStorage.setItem('token', data.data.token);
    return data.data.user;
  }
  throw new Error(data.message);
};

// Get Bots
const getBots = async () => {
  const token = localStorage.getItem('token');
  const response = await fetch('http://localhost:5000/api/bots', {
    headers: { 'Authorization': `Bearer ${token}` }
  });

  const data = await response.json();
  return data.data.bots;
};

// Start Bot
const startBot = async (botId) => {
  const token = localStorage.getItem('token');
  const response = await fetch(`http://localhost:5000/api/bots/${botId}/start`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  });

  const data = await response.json();
  return data.data.bot;
};
```
