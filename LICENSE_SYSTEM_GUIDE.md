# 🔐 Smart Stock Trader - License System Guide

## Complete License Protection Implementation

Your Smart Stock Trader EA now includes a **professional multi-layer license protection system** to secure your commercial product.

---

## ✅ **What's Been Added**

### **1. License Validation Module** (`SST_LicenseManager.mqh`)
- License key validation
- Expiration date checking
- Account number restrictions
- Hardware fingerprint locking
- Automatic expiration warnings
- Optional online server validation

### **2. Integrated Protection**
Both EA versions now include license validation:
- ✅ `SmartStockTrader.mq4` (modular version)
- ✅ `SmartStockTrader_Single.mq4` (single-file version)

### **3. License Key Generator** (`LicenseKeyGenerator.html`)
- Beautiful web-based generator
- Creates unique license keys
- Tracks customer information
- Exports to CSV
- Stores history locally

---

## 🚀 **How to Use the License System**

### **STEP 1: Generate License Keys for Customers**

1. **Open the License Generator**
   - Double-click `LicenseKeyGenerator.html`
   - Opens in your web browser

2. **Enter Customer Information**
   ```
   Customer Name: John Doe
   Email: john@example.com
   License Type: Professional
   Account Number: 12345678 (optional)
   Expiration: 365 days
   ```

3. **Click "Generate License Key"**
   - Creates a unique key like: `SST-PRO-A4B9C2-X7Y3Z1-F8D4`
   - Shows expiration date
   - Provides MQL4 configuration code

4. **Copy License Information**
   - Click "Copy License Key" button
   - Or manually copy the MQL4 configuration

5. **Export Keys** (Optional)
   - Click "Export All Keys" to save CSV file
   - Useful for record-keeping and customer management

---

### **STEP 2: Configure EA with License**

#### **Method A: Directly in Code (Before Compiling)**

Edit the license parameters at the top of the EA file:

```mql4
//--------------------------------------------------------------------
// LICENSE PARAMETERS (Edit these before compiling)
//--------------------------------------------------------------------
extern string  LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4";  // Customer's key
extern datetime ExpirationDate = D'2026.12.31 23:59:59';   // Expiration date
extern string  AuthorizedAccounts = "12345678";            // Account numbers (comma-separated)
extern bool    RequireLicenseKey = true;                   // Require valid key
```

**Then:**
1. Compile to `.ex4`
2. Send `.ex4` file to customer (NOT `.mq4`)

---

#### **Method B: Customer Enters Key (After Installing)**

Leave parameters blank in code:

```mql4
extern string  LicenseKey = "";
extern datetime ExpirationDate = D'2026.12.31 23:59:59';
extern string  AuthorizedAccounts = "";
extern bool    RequireLicenseKey = true;
```

**Customer enters key in MT4:**
1. Drag EA to chart
2. In "Inputs" tab, enter license key
3. Click OK

---

### **STEP 3: Add Valid Keys to Database**

Edit the valid keys array in the code:

**In `SST_LicenseManager.mqh` (modular version):**
```mql4
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345",
   // Add more keys here
};
```

**In `SmartStockTrader_Single.mq4` (single-file version):**
```mql4
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345",
   // Add more keys here
};
```

**⚠️ IMPORTANT:** Recompile the EA each time you add new keys!

---

## 🔒 **License Protection Features**

### **1. License Key Validation**
- Customer must enter valid license key
- Key is checked against authorized database
- Invalid keys prevent EA from trading

### **2. Expiration Date**
- Set specific expiration date for each license
- EA stops working after expiration
- Automatic 30-day warning before expiration
- Forces customers to renew

### **3. Account Number Lock**
- Restrict EA to specific MT4 account numbers
- Prevents sharing licenses
- Enter account numbers as comma-separated list: `"12345,67890,11111"`
- Leave blank (`""`) to allow any account

### **4. Hardware Fingerprint**
- Creates unique ID from: Account Number + Account Name + Broker Server
- Can be enabled for maximum security
- Locks EA to specific installation

### **5. Broker Restrictions** (Optional)
- Restrict to specific brokers
- Uncomment and configure in `SST_LicenseManager.mqh`:

```mql4
bool License_CheckBroker() {
   string allowedBrokers[] = {"ICMarkets", "FXCM", "Pepperstone"};
   string currentBroker = AccountCompany();

   for(int i = 0; i < ArraySize(allowedBrokers); i++) {
      if(StringFind(currentBroker, allowedBrokers[i]) >= 0) {
         return true;
      }
   }

   Alert("EA not authorized for broker: " + currentBroker);
   return false;
}
```

---

## 📋 **License Types & Pricing Examples**

### **Basic License**
```
Key Format: SST-BASIC-XXXXXX-YYYYYY-ZZZZ
Price: $297
Duration: 1 year
Accounts: 1
Features: All 8 strategies
```

### **Professional License**
```
Key Format: SST-PRO-XXXXXX-YYYYYY-ZZZZ
Price: $497
Duration: Lifetime
Accounts: 3
Features: All features + priority support
```

### **Enterprise License**
```
Key Format: SST-ENTERPRISE-XXXXXX-YYYYYY-ZZZZ
Price: $997
Duration: Lifetime
Accounts: Unlimited
Features: Everything + custom configuration
```

### **Trial License**
```
Key Format: SST-TRIAL-XXXXXX-YYYYYY-ZZZZ
Price: Free
Duration: 30 days
Accounts: 1 (demo only)
Features: Limited features
```

---

## 🛡️ **Best Practices for Commercial Distribution**

### **✅ DO:**
1. **Only distribute .EX4 files** (compiled, not source `.mq4`)
2. **Keep `.mq4` source code private** (never share)
3. **Update license database regularly** (add new customer keys)
4. **Recompile after adding keys**
5. **Track all issued licenses** (use CSV export)
6. **Set appropriate expiration dates**
7. **Test license validation before sending**

### **❌ DON'T:**
1. **Never share `.mq4` source code** with customers
2. **Don't use weak/predictable keys**
3. **Don't skip expiration dates** (loss of recurring revenue)
4. **Don't give lifetime licenses too cheaply**
5. **Don't forget to update the keys array**

---

## 📧 **Customer Support Messages**

When license validation fails, customers see clear messages:

### **Invalid License Key**
```
INVALID LICENSE KEY!

The license key you entered is not valid.

Please check your license key and try again.
Contact support if you need assistance.

Email: support@smartstocktrader.com
```

### **License Expired**
```
LICENSE EXPIRED!

Your Smart Stock Trader license expired on 2025.12.31

Please contact support to renew your license.

Email: support@smartstocktrader.com
```

### **Account Not Authorized**
```
ACCOUNT NOT AUTHORIZED!

Account #12345678 is not authorized to use this EA.

Please contact support to authorize this account.

Email: support@smartstocktrader.com
```

### **Expiration Warning (30 Days)**
```
LICENSE EXPIRATION WARNING

Your Smart Stock Trader license will expire in 25 days.

Expiration Date: 2025.12.31

Please renew soon to avoid service interruption.

Email: support@smartstocktrader.com
```

---

## 🌐 **Optional: Online License Validation**

For even stronger protection, enable server-based validation:

### **How it works:**
1. EA sends license key + account info to your server
2. Server validates and responds (VALID, INVALID, or EXPIRED)
3. EA only trades if server approves

### **To Enable:**

1. **Uncomment the code** in `SST_LicenseManager.mqh`:
   ```mql4
   bool License_ValidateOnline(string licenseKey) {
      string url = "https://yourwebsite.com/api/validate-license.php";
      // ... rest of code
   }
   ```

2. **Create server endpoint** (PHP example):
   ```php
   <?php
   // validate-license.php
   $key = $_GET['key'];
   $account = $_GET['account'];

   // Check database
   $valid = checkLicenseInDatabase($key, $account);

   if($valid && !isExpired($key)) {
      echo "VALID";
   } else if(isExpired($key)) {
      echo "EXPIRED";
   } else {
      echo "INVALID";
   }
   ?>
   ```

3. **Enable WebRequest in MT4:**
   - Tools → Options → Expert Advisors
   - Check "Allow WebRequest for listed URL"
   - Add: `https://yourwebsite.com`

---

## 🔧 **Testing Your License System**

### **Test 1: Valid License**
```mql4
LicenseKey = "SST-PRO-ABC123-XYZ789"  // Valid key from database
ExpirationDate = D'2026.12.31 23:59:59'  // Future date
AuthorizedAccounts = ""  // No restriction
```
**Expected:** ✅ EA starts successfully

### **Test 2: Invalid License**
```mql4
LicenseKey = "SST-INVALID-000000-000000"  // Not in database
```
**Expected:** ❌ EA fails to initialize with error message

### **Test 3: Expired License**
```mql4
LicenseKey = "SST-PRO-ABC123-XYZ789"
ExpirationDate = D'2020.01.01 00:00:00'  // Past date
```
**Expected:** ❌ "LICENSE EXPIRED" message

### **Test 4: Unauthorized Account**
```mql4
LicenseKey = "SST-PRO-ABC123-XYZ789"
AuthorizedAccounts = "99999999"  // Different account number
```
**Expected:** ❌ "ACCOUNT NOT AUTHORIZED" message

### **Test 5: Expiration Warning**
```mql4
ExpirationDate = D'2025.11.15 23:59:59'  // Less than 30 days away
```
**Expected:** ⚠️ Warning message but EA still works

---

## 💰 **Revenue Protection**

This license system protects your revenue by:

1. **Preventing piracy** - Only valid keys work
2. **Preventing sharing** - Account locks prevent sharing
3. **Enforcing renewals** - Expiration dates create recurring revenue
4. **Tracking customers** - Know who has which licenses
5. **Remote control** - Can deactivate keys if needed

### **Example Revenue Model:**

```
Year 1: Sell 100 licenses @ $497 = $49,700
Year 2: 70% renew @ $147/year = $10,290
Year 3: 50 new + 50 renewals = $32,200
Year 4: 50 new + 70 renewals = $35,150

Total 4-Year Revenue: $127,340
```

---

## 📊 **License Management Workflow**

```
1. Customer purchases license
   ↓
2. You generate license key (LicenseKeyGenerator.html)
   ↓
3. Add key to EA database (g_ValidLicenseKeys array)
   ↓
4. Recompile EA to .EX4
   ↓
5. Send .EX4 + license key to customer
   ↓
6. Customer installs and enters key
   ↓
7. EA validates license
   ↓
8. If valid → EA trades
   If invalid → EA shows error
```

---

## 🎓 **Advanced: Custom License Server**

For large-scale operations:

1. **Build license management dashboard**
   - Web interface to manage all licenses
   - Generate keys automatically
   - Track activations
   - Remote deactivation

2. **Implement API endpoints**
   - `/validate` - Check if license is valid
   - `/activate` - Activate new license
   - `/deactivate` - Revoke license
   - `/renew` - Extend expiration

3. **Use database**
   - Store all licenses
   - Track usage statistics
   - Monitor for suspicious activity

4. **Benefits:**
   - Instant license activation
   - No need to recompile EA
   - Real-time control
   - Better customer management

---

## 📞 **Support Email Template**

When customers have license issues:

```
Subject: Smart Stock Trader License Support

Dear [Customer Name],

Thank you for purchasing Smart Stock Trader!

Your License Information:
------------------------
License Key: SST-PRO-XXXXXX-YYYYYY-ZZZZ
Expiration: 2026.12.31
Authorized Account: 12345678

Installation Instructions:
--------------------------
1. Copy SmartStockTrader.ex4 to MT4/MQL4/Experts/
2. Restart MetaTrader 4
3. Drag EA to chart
4. In "Inputs" tab, enter your license key
5. Click OK

If you have any issues, please reply with:
- Your MT4 account number
- Error message (if any)
- Screenshot of the error

Support: support@smartstocktrader.com
Website: www.smartstocktrader.com

Best regards,
Smart Stock Trader Support Team
```

---

## ✅ **Final Checklist**

Before selling your EA:

- [ ] License system tested with valid keys
- [ ] License system tested with invalid keys
- [ ] Expiration dates work correctly
- [ ] Account restrictions work correctly
- [ ] Error messages are clear
- [ ] Only .EX4 files are distributed (not .MQ4)
- [ ] Valid keys are added to database
- [ ] EA recompiled after adding keys
- [ ] Customer documentation prepared
- [ ] Support email setup
- [ ] Refund policy defined
- [ ] Payment processor configured

---

## 🎉 **You're Ready to Sell!**

Your Smart Stock Trader EA now has **professional-grade license protection** equivalent to commercial EAs sold for thousands of dollars.

**Next Steps:**
1. Test the license system thoroughly
2. Generate keys for test customers
3. Create sales page (see COMMERCIALIZATION_GUIDE.md)
4. List on MQL5 Market or your own website
5. Start earning! 💰

**Good luck with your EA business! 🚀**
