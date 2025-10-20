# 🧪 License System Testing Guide

## Quick Test Process

### **Test 1: Valid License (Should PASS ✅)**

1. **Generate a test key** in LicenseKeyGenerator.html
   - Customer Name: "Test User"
   - Email: "test@example.com"
   - Type: Professional
   - Expiration: 365 days
   - Click "Generate License Key"
   - **Copy the generated key** (e.g., `SST-PRO-A4B9C2-X7Y3Z1-F8D4`)

2. **Add key to EA:**
   Open `SmartStockTrader_Single.mq4` in MetaEditor

   Find line 77-81:
   ```mql4
   string g_ValidLicenseKeys[] = {
      "SST-PRO-ABC123-XYZ789",
      "SST-PRO-DEF456-UVW012",
      "SST-PRO-GHI789-RST345",
      "SST-PRO-A4B9C2-X7Y3Z1-F8D4"  // ← Your generated key
   };
   ```

3. **Set license parameters** (top of file, around line 14):
   ```mql4
   extern string  LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4";
   extern datetime ExpirationDate = D'2026.12.31 23:59:59';
   extern string  AuthorizedAccounts = "";
   extern bool    RequireLicenseKey = true;
   ```

4. **Compile:**
   - Press **F7** in MetaEditor
   - Should say: "0 error(s), 0 warning(s)"

5. **Test in MT4:**
   - Drag EA to chart
   - Check "Experts" tab in Terminal
   - Should see:
     ```
     === LICENSE VALIDATION ===
     Hardware Fingerprint: [your account info]
     Account: [your number]
     Broker: [your broker]
     LICENSE VALID - XXX days remaining
     ========================
     ✓ License validated successfully
     ```

**Expected Result:** ✅ EA starts and initializes successfully

---

### **Test 2: Invalid License (Should FAIL ❌)**

1. **Change license key to invalid one:**
   ```mql4
   extern string  LicenseKey = "SST-INVALID-000000-000000";
   ```

2. **Compile and test**

**Expected Result:**
- ❌ Alert popup: "INVALID LICENSE KEY!"
- ❌ Log shows: "LICENSE VALIDATION FAILED!"
- ❌ EA returns INIT_FAILED (won't trade)

---

### **Test 3: Expired License (Should FAIL ❌)**

1. **Set expiration to past date:**
   ```mql4
   extern string  LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4";
   extern datetime ExpirationDate = D'2020.01.01 00:00:00';
   ```

2. **Compile and test**

**Expected Result:**
- ❌ Alert popup: "LICENSE EXPIRED!"
- ❌ Shows expiration date
- ❌ EA returns INIT_FAILED

---

### **Test 4: Account Lock (Should FAIL ❌ on different account)**

1. **Restrict to specific account:**
   ```mql4
   extern string  LicenseKey = "SST-PRO-A4B9C2-X7Y3Z1-F8D4";
   extern datetime ExpirationDate = D'2026.12.31 23:59:59';
   extern string  AuthorizedAccounts = "99999999";  // Different from your account
   ```

2. **Compile and test**

**Expected Result:**
- ❌ Alert popup: "ACCOUNT NOT AUTHORIZED!"
- ❌ Shows your account number
- ❌ EA returns INIT_FAILED

---

### **Test 5: Expiration Warning (Should WARN ⚠️ but still work)**

1. **Set expiration to less than 30 days:**
   ```mql4
   extern datetime ExpirationDate = D'2025.11.15 23:59:59';
   ```

2. **Compile and test**

**Expected Result:**
- ⚠️ Alert popup: "LICENSE EXPIRATION WARNING - Expires in X days"
- ✅ EA still starts and works
- ✅ Just shows warning

---

## 📋 Testing Checklist

Copy this and check off as you test:

```
[ ] Test 1: Valid license - EA starts ✅
[ ] Test 2: Invalid key - EA blocked ❌
[ ] Test 3: Expired date - EA blocked ❌
[ ] Test 4: Wrong account - EA blocked ❌
[ ] Test 5: 30-day warning - Shows warning but works ⚠️
[ ] Generated multiple keys in web tool
[ ] Keys saved to CSV export
[ ] Compiled to .EX4 successfully
```

---

## 🎯 Quick Testing (5 Minutes)

**Fastest way to verify it works:**

1. **Open License Generator** → Generate ONE key
2. **Copy that key**
3. **Open `SmartStockTrader_Single.mq4` in MetaEditor**
4. **Line 77:** Add your key to array
5. **Line 14:** Paste key in `LicenseKey = "YOUR-KEY-HERE"`
6. **Line 15:** Set future date: `D'2026.12.31 23:59:59'`
7. **Line 16:** Leave empty: `AuthorizedAccounts = ""`
8. **Press F7** to compile
9. **Drag to chart** in MT4
10. **Check Experts tab** - should see "LICENSE VALID"

**If you see "LICENSE VALID" → System works! ✅**

---

## 🐛 Common Issues

### "License key not found in database"
→ Make sure you added the key to `g_ValidLicenseKeys[]` array

### "Compilation errors"
→ Check for typos in the key, make sure quotes are correct

### "EA doesn't load in MT4"
→ Make sure you compiled (F7) and the .EX4 file was created

### "Can't find the array"
→ In Single version: Line 77
→ In Modular version: Open `Include/SST_LicenseManager.mqh` line ~27

---

## 💡 Pro Tip: Testing Mode

For quick testing without editing code every time:

**Set this to FALSE temporarily:**
```mql4
extern bool RequireLicenseKey = false;  // Disables license checking
```

This lets you test the EA without license validation.

**⚠️ REMEMBER to set back to `true` before selling!**

---

## 📞 Need Help?

If something doesn't work:

1. Check the **Experts tab** in MT4 Terminal
2. Look for error messages
3. Verify the key was added to the array
4. Make sure expiration date is in the future
5. Confirm compilation was successful (0 errors)

**The license system is working if:**
- ✅ Valid key = EA starts
- ❌ Invalid key = EA shows error and stops

That's it! 🎉
