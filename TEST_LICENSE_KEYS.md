# Test License Keys for Bot Activation

## Available Test Licenses

Use these license keys to test the bot activation system in the dashboard:

### Trial License
- **License Key**: `TRL-C983-9442-4A9B-3018`
- **Type**: TRIAL
- **Max Accounts**: 1
- **Expires**: 10/27/2025

### Basic License
- **License Key**: `BSC-4CDE-7998-3E95-D888`
- **Type**: BASIC
- **Max Accounts**: 1
- **Expires**: 10/20/2026

### Pro License
- **License Key**: `PRO-AD41-9539-E50C-0F11`
- **Type**: PRO
- **Max Accounts**: 3
- **Expires**: 10/20/2026

### Enterprise License
- **License Key**: `ENT-E3B0-728E-A59A-1BD4`
- **Type**: ENTERPRISE
- **Max Accounts**: 10
- **Expires**: 10/20/2026

## How to Test

1. **Start the Backend Server**:
   ```bash
   cd backend && node src/server.js
   ```

2. **Start the Frontend**:
   ```bash
   cd landing && npm start
   ```

3. **Register a New Account or Login**

4. **Go to Dashboard and Navigate to Bots Section**

5. **Click "Add New Bot"**

6. **Enter License Key** (use any of the keys above)

7. **Configure Your Bot**:
   - Bot Name: e.g., "EUR/USD Scalper"
   - MT4 Account: e.g., "12345678"
   - Broker Name: e.g., "IC Markets"
   - Broker Server: e.g., "ICMarkets-Demo01"
   - Account Type: Live or Demo

8. **Submit and Verify**:
   - Bot should appear in your dashboard
   - License should be assigned to your user account
   - You should be able to start/stop the bot

## License Activation Flow

1. **License Validation** (Step 1 in AddBotModal):
   - Validates license key format
   - Checks if license exists
   - Verifies license is not expired
   - Checks if license has available slots
   - Auto-assigns unassigned licenses to current user

2. **Bot Configuration** (Step 2 in AddBotModal):
   - Shows license info (type, available slots)
   - Collects bot configuration details

3. **Bot Creation** (Step 3 - Success):
   - Creates bot instance linked to license
   - Displays success message
   - Redirects to dashboard

## Testing Different Scenarios

### Test 1: First-Time License Activation
- Use `PRO-AD41-9539-E50C-0F11`
- Should auto-assign to your user
- Should allow creating bot

### Test 2: Multi-Account License
- Use the same PRO license key
- Create a second bot
- Should work (PRO allows 3 accounts)
- Try creating a 4th bot - should fail

### Test 3: License Already Used by Another User
- Register a second user account
- Try using a license already assigned to first user
- Should fail with error message

### Test 4: Expired License
- Currently all licenses are valid
- To test: manually update expires_at in database to past date
- Should fail validation

### Test 5: Single Account Limit
- Use `BSC-4CDE-7998-3E95-D888` (Basic license - 1 account max)
- Create one bot - should work
- Try creating second bot with same license - should fail

## Troubleshooting

### License Not Found
- Verify license key format: `XXX-XXXX-XXXX-XXXX-XXXX`
- Check database: `SELECT * FROM licenses;`

### License Already Activated
- Check license ownership: `SELECT user_id, license_key FROM licenses WHERE license_key = 'YOUR-KEY';`
- If needed, manually unassign: `UPDATE licenses SET user_id = NULL WHERE license_key = 'YOUR-KEY';`

### Bot Creation Fails
- Check backend logs for errors
- Verify license_id foreign key constraint
- Ensure user is authenticated

## Database Queries for Testing

```sql
-- View all licenses
SELECT license_key, license_type, max_accounts, user_id, status, expires_at FROM licenses;

-- View all bots
SELECT instance_name, mt4_account, broker_name, status FROM bot_instances;

-- Count bots per license
SELECT l.license_key, COUNT(b.id) as bot_count, l.max_accounts
FROM licenses l
LEFT JOIN bot_instances b ON l.id = b.license_id
GROUP BY l.id;

-- Reset a license (unassign from user)
UPDATE licenses SET user_id = NULL WHERE license_key = 'YOUR-LICENSE-KEY';

-- Delete all test bots
DELETE FROM bot_instances WHERE user_id = 'YOUR-USER-ID';
```

## Next Steps

1. Update PurchaseModal to generate license keys automatically when users purchase
2. Add email delivery of license keys
3. Implement license management tab in dashboard
4. Add hardware binding for additional security
