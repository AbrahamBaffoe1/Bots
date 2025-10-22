# MT4 EA Log Submission API Documentation

## Overview

This document describes the API endpoints for MT4 Expert Advisors (EAs) to submit logs to the backend server.

## Base URL
```
http://localhost:5000/api/bots
```

## Authentication

All endpoints require JWT authentication. Include the token in the `Authorization` header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## Endpoints

### 1. Submit Single Log

**Endpoint:** `POST /api/bots/:id/logs`

**Description:** Submit a single log entry from MT4 EA

**URL Parameters:**
- `id` (string, required): The bot instance ID

**Request Body:**
```json
{
  "log_level": "INFO",
  "category": "TRADE",
  "message": "Trade opened: EURUSD BUY 0.1 lots @ 1.0850",
  "metadata": {
    "ticket": "12345",
    "symbol": "EURUSD",
    "lot_size": 0.1
  }
}
```

**Fields:**
- `log_level` (string, required): One of: `INFO`, `WARNING`, `ERROR`, `DEBUG`
- `category` (string, required): Category of log (e.g., `TRADE`, `SYSTEM`, `ERROR`, `SIGNAL`)
- `message` (string, required): Human-readable log message
- `metadata` (object, optional): Additional structured data

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Log submitted successfully",
  "data": {
    "log_id": "uuid-of-log-entry",
    "created_at": "2025-10-21T19:30:00.000Z"
  }
}
```

**Error Responses:**

400 Bad Request:
```json
{
  "success": false,
  "message": "log_level, category, and message are required"
}
```

404 Not Found:
```json
{
  "success": false,
  "message": "Bot instance not found"
}
```

---

### 2. Submit Batch Logs

**Endpoint:** `POST /api/bots/:id/logs/batch`

**Description:** Submit multiple log entries at once (more efficient than individual submissions)

**URL Parameters:**
- `id` (string, required): The bot instance ID

**Request Body:**
```json
{
  "logs": [
    {
      "log_level": "INFO",
      "category": "STARTUP",
      "message": "EA initialized successfully"
    },
    {
      "log_level": "INFO",
      "category": "SIGNAL",
      "message": "Buy signal detected on EURUSD",
      "metadata": {
        "symbol": "EURUSD",
        "indicator": "MA_CROSSOVER"
      }
    },
    {
      "log_level": "WARNING",
      "category": "SYSTEM",
      "message": "High spread detected: 3.2 pips"
    }
  ]
}
```

**Fields:**
- `logs` (array, required): Array of log objects, each containing:
  - `log_level` (string, required): `INFO`, `WARNING`, `ERROR`, or `DEBUG`
  - `category` (string, required): Category name
  - `message` (string, required): Log message
  - `metadata` (object, optional): Additional data

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "3 logs submitted successfully",
  "data": {
    "count": 3,
    "logs": [
      {
        "id": "uuid-1",
        "created_at": "2025-10-21T19:30:00.000Z"
      },
      {
        "id": "uuid-2",
        "created_at": "2025-10-21T19:30:01.000Z"
      },
      {
        "id": "uuid-3",
        "created_at": "2025-10-21T19:30:02.000Z"
      }
    ]
  }
}
```

---

### 3. Get Bot Logs

**Endpoint:** `GET /api/bots/:id/logs`

**Description:** Retrieve logs for a specific bot

**URL Parameters:**
- `id` (string, required): The bot instance ID

**Query Parameters:**
- `limit` (number, optional): Number of logs to return (default: 50)
- `log_level` (string, optional): Filter by log level (`INFO`, `WARNING`, `ERROR`, `DEBUG`)
- `category` (string, optional): Filter by category

**Examples:**
```
GET /api/bots/abc123/logs?limit=100
GET /api/bots/abc123/logs?log_level=ERROR
GET /api/bots/abc123/logs?category=TRADE&limit=20
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "bot_instance_id": "abc123",
      "log_level": "INFO",
      "category": "TRADE",
      "message": "Trade opened: EURUSD BUY 0.1 lots",
      "metadata": {
        "ticket": "12345",
        "symbol": "EURUSD"
      },
      "created_at": "2025-10-21T19:30:00.000Z"
    }
  ]
}
```

---

## Log Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `INFO` | Informational messages | Normal operations, trade executions, signals |
| `WARNING` | Warning messages | High spread, unusual conditions, minor issues |
| `ERROR` | Error messages | Failed operations, critical issues |
| `DEBUG` | Debug messages | Detailed diagnostic information |

---

## Recommended Categories

| Category | Description |
|----------|-------------|
| `STARTUP` | EA initialization and startup |
| `SHUTDOWN` | EA shutdown and cleanup |
| `TRADE` | Trade executions (open/close) |
| `SIGNAL` | Trading signals detected |
| `SYSTEM` | System-level messages |
| `ERROR` | Error conditions |
| `HEARTBEAT` | Periodic status updates |
| `CONNECTION` | Broker connection status |

---

## Best Practices

### 1. Use Batch Submission
Instead of sending logs one at a time, batch them and send periodically:
```
// Good - Batch every 30 seconds or 10 logs
if (logQueue.length >= 10 OR timeElapsed >= 30s) {
  SendLogsBatch(logQueue);
  logQueue.clear();
}

// Bad - Send each log immediately
SendLog(message);  // Creates too many HTTP requests
```

### 2. Include Useful Metadata
Add structured data to help with debugging:
```json
{
  "log_level": "ERROR",
  "category": "TRADE",
  "message": "Failed to open trade",
  "metadata": {
    "symbol": "EURUSD",
    "lot_size": 0.1,
    "error_code": 134,
    "error_description": "Not enough money",
    "account_balance": 1000.50
  }
}
```

### 3. Log Important Events
- EA startup/shutdown
- Trade opens/closes
- Errors and warnings
- Signal detections
- Connection issues

### 4. Don't Spam Logs
Avoid logging on every tick. Use batching and throttling:
```
// Good
if (newBarDetected) {
  Log("New bar opened");
}

// Bad
OnTick() {
  Log("Tick received");  // Too frequent!
}
```

---

## Error Handling

Always handle HTTP errors in your EA:

```cpp
// Pseudo-code example
if (SendLog(data) == HTTP_ERROR) {
  // Store in local queue
  AddToLocalQueue(data);

  // Retry later
  ScheduleRetry();
}
```

---

## Example MT4 Integration

```cpp
// Example function to send logs
bool SendLogToServer(string level, string category, string message) {
   string url = "http://localhost:5000/api/bots/" + BotInstanceID + "/logs";
   string token = "YOUR_JWT_TOKEN";

   string json = "{";
   json += "\"log_level\":\"" + level + "\",";
   json += "\"category\":\"" + category + "\",";
   json += "\"message\":\"" + message + "\"";
   json += "}";

   char post[];
   char result[];
   string headers = "Content-Type: application/json\r\n";
   headers += "Authorization: Bearer " + token + "\r\n";

   ArrayResize(post, StringToCharArray(json, post, 0, WHOLE_ARRAY) - 1);

   int res = WebRequest("POST", url, headers, 5000, post, result, headers);

   return (res == 200);
}

// Usage
SendLogToServer("INFO", "TRADE", "Trade opened: EURUSD BUY 0.1 lots");
```

---

## Server Info Capture

**NOTE:** The server information (broker server name) is already being captured during bot registration!

When you register a bot, include the `broker_server` or `server_name` field:

```json
POST /api/bots
{
  "account_number": "12345678",
  "broker_name": "Exness",
  "server_name": "Exness-Real20",  // ← Server info captured here
  "bot_name": "My EA Bot",
  "is_live": true
}
```

This information is stored in the `bot_instances` table in the `broker_server` column and is displayed in both user and admin dashboards.

---

## Testing

Test the endpoints using curl:

```bash
# Submit single log
curl -X POST http://localhost:5000/api/bots/YOUR_BOT_ID/logs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "log_level": "INFO",
    "category": "TEST",
    "message": "Test log from curl"
  }'

# Submit batch logs
curl -X POST http://localhost:5000/api/bots/YOUR_BOT_ID/logs/batch \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "logs": [
      {"log_level": "INFO", "category": "TEST", "message": "Log 1"},
      {"log_level": "WARNING", "category": "TEST", "message": "Log 2"}
    ]
  }'

# Get logs
curl http://localhost:5000/api/bots/YOUR_BOT_ID/logs?limit=10 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Summary

✅ **COMPLETED:**
1. Created `/api/bots/:id/logs` - Submit single log
2. Created `/api/bots/:id/logs/batch` - Submit multiple logs (recommended)
3. Created `/api/bots/:id/logs` GET - Retrieve bot logs
4. Server info already captured during bot registration

🔧 **TODO (MT4 EA Side):**
1. Implement log batching in MT4 EA
2. Add periodic log submission (every 30-60 seconds)
3. Test log submission from live MT4 EA
