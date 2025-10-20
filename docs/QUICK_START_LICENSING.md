# 🚀 Quick Start - License System

## For You (EA Seller)

### **1. Generate License Key**
1. Open `LicenseKeyGenerator.html` in browser
2. Enter customer details
3. Click "Generate License Key"
4. Copy the generated key

### **2. Add Key to EA**
Open the appropriate file and add to array:

**`Include/SST_LicenseManager.mqh`** (modular) or **`SmartStockTrader_Single.mq4`** (line ~77)

```mql4
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "YOUR-NEW-KEY-HERE",  // ← Add here
};
```

### **3. Recompile & Send**
1. Press **F7** in MetaEditor to compile
2. Find `.ex4` file in `MQL4/Experts/`
3. Send **ONLY** `.ex4` to customer (never `.mq4`)
4. Send license key via email

---

## For Customer (EA Buyer)

### **Installation:**
1. Copy `SmartStockTrader.ex4` to `MT4/MQL4/Experts/`
2. Restart MetaTrader 4
3. Drag EA to chart
4. In "Inputs" tab, enter your license key
5. Click OK

### **If License Error:**
- Double-check license key (no spaces)
- Verify expiration date hasn't passed
- Contact: support@smartstocktrader.com

---

## License Key Format

```
SST-[TYPE]-[6CHARS]-[6CHARS]-[4CHARS]

Example: SST-PRO-A4B9C2-X7Y3Z1-F8D4
```

**Types:**
- `BASIC` - Basic license
- `PRO` - Professional license
- `ENTERPRISE` - Enterprise license
- `TRIAL` - Trial license

---

## Quick Configuration

### **No Restrictions (Testing):**
```mql4
LicenseKey = "SST-PRO-ABC123-XYZ789"
ExpirationDate = D'2030.12.31 23:59:59'
AuthorizedAccounts = ""
RequireLicenseKey = true
```

### **Single Account Lock:**
```mql4
LicenseKey = "SST-PRO-ABC123-XYZ789"
ExpirationDate = D'2026.12.31 23:59:59'
AuthorizedAccounts = "12345678"
RequireLicenseKey = true
```

### **Multiple Accounts:**
```mql4
AuthorizedAccounts = "12345678,87654321,11111111"
```

### **1 Year Expiration:**
```mql4
ExpirationDate = D'2026.01.15 23:59:59'  // Jan 15, 2026
```

---

## Files Overview

| File | Purpose |
|------|---------|
| `LicenseKeyGenerator.html` | Generate license keys |
| `SST_LicenseManager.mqh` | License validation code (modular) |
| `SmartStockTrader.mq4` | Main EA (with license) |
| `SmartStockTrader_Single.mq4` | Single-file EA (with license) |
| `LICENSE_SYSTEM_GUIDE.md` | Full documentation |
| `COMMERCIALIZATION_GUIDE.md` | How to sell your EA |

---

## Testing Checklist

- [ ] Valid key works ✅
- [ ] Invalid key blocks EA ❌
- [ ] Expired date blocks EA ❌
- [ ] Wrong account blocked ❌
- [ ] 30-day warning shows ⚠️

---

## Emergency: Disable License System

If you need to quickly disable for testing:

```mql4
RequireLicenseKey = false  // Set to false
```

**⚠️ Remember to re-enable before distributing!**

---

## Support Contact Template

```
Your License: SST-PRO-XXXXXX-YYYYYY-ZZZZ
Expires: 2026.12.31
Account: [Your MT4 Account Number]

Support: support@smartstocktrader.com
Website: www.smartstocktrader.com
```

---

**📚 Full Documentation:** See `LICENSE_SYSTEM_GUIDE.md`
