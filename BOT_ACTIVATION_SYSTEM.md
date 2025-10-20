# Bot Activation & License Management System

## Complete Implementation Guide

### Overview
This system allows users to activate trading bots using license keys, configure bot settings, and manage multiple bot instances across different MT4 accounts.

---

## Backend Implementation

### 1. License Controller (`backend/src/controllers/licenseController.js`)

**Features:**
- License key generation with type-specific prefixes (TRL, BSC, PRO, ENT)
- License validation and activation
- User license management
- Expiration and status tracking

**Key Endpoints:**
- `GET /api/licenses` - Get all user licenses
- `POST /api/licenses/validate` - Validate and activate license key
- `POST /api/licenses` - Create new license (admin/purchase)
- `PUT /api/licenses/:id/revoke` - Revoke license

**License Key Format:**
```
PREFIX-XXXX-XXXX-XXXX-XXXX
Examples:
- TRL-A1B2-C3D4-E5F6-G7H8 (Trial)
- BSC-1234-5678-9ABC-DEF0 (Basic)
- PRO-9876-5432-1FED-CBA0 (Pro)
- ENT-ABCD-1234-EFGH-5678 (Enterprise)
```

### 2. Bot Controller Updates (`backend/src/controllers/botController.js`)

**Updated `createBot` Function:**
- Accepts `license_key` or `license_id`
- Validates license status and expiration
- Checks max account limits
- Auto-assigns unassigned licenses to users
- Prevents license sharing between users

**Validation Flow:**
1. Find license by key or ID
2. Check license status (must be 'active')
3. Check expiration date
4. Verify user ownership
5. Check account slots availability
6. Create bot instance

### 3. Database Schema

**Licenses Table:**
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users)
- license_key (VARCHAR, Unique)
- license_type (ENUM: TRIAL, BASIC, PRO, ENTERPRISE)
- max_accounts (INTEGER)
- status (ENUM: active, suspended, expired, revoked)
- issued_at (TIMESTAMP)
- expires_at (TIMESTAMP)
- hardware_id (VARCHAR, for future hardware binding)
- last_validated (TIMESTAMP)
- activation_count (INTEGER)
```

**Bot Instances Table:**
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users)
- license_id (UUID, Foreign Key → licenses)
- instance_name (VARCHAR)
- mt4_account (VARCHAR)
- broker_name (VARCHAR)
- broker_server (VARCHAR)
- status (ENUM: running, stopped, paused, error)
- is_live (BOOLEAN)
- created_at (TIMESTAMP)
```

---

## Frontend Implementation

### 1. AddBotModal Component (`landing/src/components/AddBotModal.js`)

**3-Step Wizard:**

**Step 1: License Activation**
- Enter license key
- Format validation (XXX-XXXX-XXXX-XXXX-XXXX)
- Real-time server validation
- Error handling for invalid/expired licenses

**Step 2: Bot Configuration**
- License info display (type, available slots)
- Bot name input
- MT4 account number
- Broker name
- Broker server (optional)
- Account type toggle (Live/Demo)

**Step 3: Success**
- Confirmation message
- Next steps guide
- Auto-redirect to dashboard

### 2. Dashboard Integration

**Add Bot Button:**
```javascript
// In Dashboard bots section
<button className="add-bot-btn" onClick={() => setAddBotModalOpen(true)}>
  <svg>...</svg>
  Add New Bot
</button>

<AddBotModal
  isOpen={addBotModalOpen}
  onClose={() => setAddBotModalOpen(false)}
  onBotAdded={(bot) => {
    setBots([...bots, bot]);
    fetchDashboardData(token);
  }}
/>
```

---

## User Flow

### Complete Bot Setup Journey

1. **Purchase License** (Landing Page → Pricing Section)
   - User clicks "Get Started" on pricing tier
   - PurchaseModal opens with payment options
   - After payment, license key is generated
   - User receives license key via email and on-screen

2. **Navigate to Dashboard**
   - User logs in
   - Goes to "Bots" section
   - Clicks "Add New Bot"

3. **License Activation** (AddBotModal Step 1)
   - Enters purchased license key
   - System validates:
     - Format correctness
     - License exists in database
     - Not expired
     - Not already used by another user
     - Has available slots
   - If valid, proceeds to Step 2

4. **Bot Configuration** (AddBotModal Step 2)
   - Shows license info (type, available slots)
   - User enters:
     - Bot name (e.g., "EUR/USD Scalper")
     - MT4 account number
     - Broker name
     - Broker server
     - Account type (Live/Demo)
   - Submits configuration

5. **Bot Created** (AddBotModal Step 3)
   - Success message displayed
   - Bot appears in dashboard
   - User can now:
     - Start/Stop bot
     - View bot stats
     - Download EA file
     - Monitor trades

6. **Bot Management** (Dashboard)
   - View all bots
   - Start/Stop bots
   - View real-time status
   - Monitor performance
   - Manage settings

---

## License Types & Limits

| Type | Max Accounts | Duration | Price | Features |
|------|--------------|----------|-------|----------|
| **Trial** | 1 | 7 days | Free | Basic features, Demo only |
| **Basic** | 1 | 1 year | $99 | All features, Live trading |
| **Pro** | 3 | 1 year | $249 | All features, Priority support |
| **Enterprise** | 10 | 1 year | $799 | All features, Dedicated support |

---

## API Endpoints Summary

### License Endpoints
```
GET    /api/licenses              - Get user's licenses
POST   /api/licenses/validate     - Validate license key
POST   /api/licenses              - Create license
PUT    /api/licenses/:id/revoke   - Revoke license
```

### Bot Endpoints
```
GET    /api/bots                  - Get all user bots
POST   /api/bots                  - Create bot (requires license)
GET    /api/bots/:id              - Get bot details
PUT    /api/bots/:id              - Update bot
DELETE /api/bots/:id              - Delete bot
POST   /api/bots/:id/start        - Start bot
POST   /api/bots/:id/stop         - Stop bot
GET    /api/bots/:id/stats        - Get bot statistics
```

---

## Testing the System

### 1. Generate Test License
```javascript
// In Node.js console or create a script
const crypto = require('crypto');

function generateLicenseKey(type) {
  const prefix = { 'TRIAL': 'TRL', 'BASIC': 'BSC', 'PRO': 'PRO', 'ENTERPRISE': 'ENT' }[type];
  const randomPart = crypto.randomBytes(12).toString('hex').toUpperCase();
  return `${prefix}-${randomPart.substring(0,4)}-${randomPart.substring(4,8)}-${randomPart.substring(8,12)}-${randomPart.substring(12,16)}`;
}

console.log(generateLicenseKey('PRO'));
// Output: PRO-A1B2-C3D4-E5F6-G7H8
```

### 2. Create License in Database
```sql
INSERT INTO licenses (
  id,
  license_key,
  license_type,
  max_accounts,
  status,
  expires_at,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'PRO-A1B2-C3D4-E5F6-G7H8',
  'PRO',
  3,
  'active',
  NOW() + INTERVAL '365 days',
  NOW(),
  NOW()
);
```

### 3. Test Bot Creation Flow
1. Start backend: `cd backend && node src/server.js`
2. Start frontend: `cd landing && npm start`
3. Login to dashboard
4. Click "Add New Bot"
5. Enter test license key
6. Configure bot details
7. Verify bot appears in dashboard

---

## Security Considerations

1. **License Key Security**
   - License keys are validated server-side only
   - Cannot be guessed (cryptographically random)
   - One-time assignment to user

2. **License Sharing Prevention**
   - License locked to first user who activates it
   - Cannot be transferred between users
   - Admin revocation available

3. **Account Limit Enforcement**
   - Server-side validation
   - Prevents exceeding max_accounts
   - Real-time slot availability check

4. **Expiration Handling**
   - Checked on every bot creation
   - Checked on license validation
   - Auto-disable expired licenses

---

## Next Steps

1. **Update PurchaseModal** to generate and display license keys after purchase
2. **Add License Management Tab** to dashboard for viewing all licenses
3. **Implement License Transfer** (admin feature)
4. **Add Hardware Binding** for additional security
5. **Email Integration** for sending license keys
6. **Auto-renewal System** for subscriptions

---

## File Locations

**Backend:**
- `backend/src/controllers/licenseController.js` - License management
- `backend/src/controllers/botController.js` - Bot management (updated)
- `backend/src/routes/licenses.js` - License routes
- `backend/src/server.js` - Added license routes

**Frontend:**
- `landing/src/components/AddBotModal.js` - Bot activation modal
- `landing/src/components/AddBotModal.css` - Modal styling
- `landing/src/pages/Dashboard.js` - Dashboard (needs integration)

---

## Support & Troubleshooting

**Common Issues:**

1. **"License key not found"**
   - Verify license exists in database
   - Check format (XXX-XXXX-XXXX-XXXX-XXXX)

2. **"License is already activated by another user"**
   - Each license can only be used by one user
   - Contact support for transfer

3. **"License has reached maximum account limit"**
   - Check license type and max_accounts
   - Upgrade to higher tier if needed

4. **"License has expired"**
   - Check expires_at date
   - Renew license or purchase new one

---

## Completed Features ✓

- [x] License key generation system
- [x] License validation endpoint
- [x] Bot creation with license
- [x] AddBotModal component (3-step wizard)
- [x] License info display
- [x] Account limit enforcement
- [x] Expiration checking
- [x] Error handling

## Pending Features

- [ ] PurchaseModal license generation
- [ ] License management tab in dashboard
- [ ] Email delivery of license keys
- [ ] Hardware binding
- [ ] License transfer (admin)
- [ ] Auto-renewal system

