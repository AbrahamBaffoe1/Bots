//+------------------------------------------------------------------+
//|                                         SST_LicenseManager.mqh |
//|                    Smart Stock Trader - License Protection       |
//|              Multi-layer license validation and expiration       |
//+------------------------------------------------------------------+
#property strict

//--------------------------------------------------------------------
// LICENSE PARAMETERS (To be set in main EA)
//--------------------------------------------------------------------
extern string  LicenseKey = "";                              // Enter your license key
extern datetime ExpirationDate = D'2026.12.31 23:59:59';    // License expiration date
extern string  AuthorizedAccounts = "";                     // Comma-separated account numbers (leave empty to disable)
extern bool    EnableHardwareIDLock = false;                // Enable hardware fingerprint lock
extern bool    RequireLicenseKey = true;                    // Require valid license key

//--------------------------------------------------------------------
// VALID LICENSE KEYS DATABASE
// (In production, these would be stored server-side)
//--------------------------------------------------------------------
string g_ValidLicenseKeys[] = {
   "SST-PRO-ABC123-XYZ789",
   "SST-PRO-DEF456-UVW012",
   "SST-PRO-GHI789-RST345"
};

//--------------------------------------------------------------------
// HARDWARE FINGERPRINT DATABASE
// (Authorized combinations of AccountNumber + AccountName + Server)
//--------------------------------------------------------------------
string g_AuthorizedFingerprints[] = {
   // Format: "AccountNumber-AccountName-ServerName"
   // Example: "12345678-JohnDoe-MetaQuotes-Demo"
   // Add authorized fingerprints here
};

//--------------------------------------------------------------------
// LICENSE VALIDATION FUNCTIONS
//--------------------------------------------------------------------

// Generate hardware fingerprint for this installation
string License_GetHardwareFingerprint() {
   string fingerprint = IntegerToString(AccountNumber()) + "-" +
                       AccountName() + "-" +
                       AccountServer();
   return fingerprint;
}

// Validate license key
bool License_ValidateKey(string key) {
   if(!RequireLicenseKey) return true;
   if(key == "") return false;

   // Check against valid keys
   for(int i = 0; i < ArraySize(g_ValidLicenseKeys); i++) {
      if(key == g_ValidLicenseKeys[i]) {
         return true;
      }
   }

   return false;
}

// Validate hardware fingerprint
bool License_ValidateHardwareID() {
   if(!EnableHardwareIDLock) return true;
   if(ArraySize(g_AuthorizedFingerprints) == 0) return true; // No restrictions if empty

   string currentFingerprint = License_GetHardwareFingerprint();

   // Check against authorized fingerprints
   for(int i = 0; i < ArraySize(g_AuthorizedFingerprints); i++) {
      if(currentFingerprint == g_AuthorizedFingerprints[i]) {
         return true;
      }
   }

   return false;
}

// Check if license has expired
bool License_CheckExpiration() {
   if(ExpirationDate == 0) return true; // No expiration set

   if(TimeCurrent() > ExpirationDate) {
      return false; // Expired
   }

   return true; // Still valid
}

// Check if account is authorized
bool License_CheckAccountAuthorization() {
   if(AuthorizedAccounts == "") return true; // No account restrictions

   string accountStr = IntegerToString(AccountNumber());

   // Check if account number is in comma-separated list
   if(StringFind(AuthorizedAccounts, accountStr) >= 0) {
      return true;
   }

   return false;
}

// Check broker restrictions (optional - can be customized)
bool License_CheckBroker() {
   // Example: Restrict to specific brokers
   // Uncomment and modify as needed
   /*
   string allowedBrokers[] = {"ICMarkets", "FXCM", "Pepperstone", "OANDA"};
   string currentBroker = AccountCompany();

   for(int i = 0; i < ArraySize(allowedBrokers); i++) {
      if(StringFind(currentBroker, allowedBrokers[i]) >= 0) {
         return true;
      }
   }

   Alert("EA not authorized for broker: " + currentBroker);
   return false;
   */

   return true; // No broker restrictions by default
}

// Calculate days until expiration
int License_GetDaysUntilExpiration() {
   if(ExpirationDate == 0) return 999999; // No expiration

   datetime current = TimeCurrent();
   if(current > ExpirationDate) return 0; // Already expired

   int secondsRemaining = (int)(ExpirationDate - current);
   int daysRemaining = secondsRemaining / 86400; // 86400 seconds in a day

   return daysRemaining;
}

// Main license validation (call this in OnInit)
bool License_Validate() {
   Print("=== LICENSE VALIDATION ===" );
   Print("Hardware Fingerprint: ", License_GetHardwareFingerprint());
   Print("Account Number: ", AccountNumber());
   Print("Account Name: ", AccountName());
   Print("Broker: ", AccountCompany());
   Print("Server: ", AccountServer());

   // Step 1: Check expiration date
   if(!License_CheckExpiration()) {
      datetime expDate = ExpirationDate;
      Alert("LICENSE EXPIRED!\n\nYour Smart Stock Trader license expired on " +
            TimeToString(expDate, TIME_DATE) +
            "\n\nPlease contact support to renew your license.\n" +
            "Email: support@smartstocktrader.com");
      Print("ERROR: License expired on ", TimeToString(expDate, TIME_DATE));
      return false;
   }

   // Step 2: Check license key
   if(!License_ValidateKey(LicenseKey)) {
      Alert("INVALID LICENSE KEY!\n\n" +
            "The license key you entered is not valid.\n\n" +
            "Please check your license key and try again.\n" +
            "Contact support if you need assistance.\n\n" +
            "Email: support@smartstocktrader.com");
      Print("ERROR: Invalid license key");
      return false;
   }

   // Step 3: Check hardware ID lock
   if(!License_ValidateHardwareID()) {
      Alert("HARDWARE ID MISMATCH!\n\n" +
            "This license is not authorized for this account.\n\n" +
            "Hardware Fingerprint: " + License_GetHardwareFingerprint() + "\n\n" +
            "Please contact support to authorize this installation.\n" +
            "Email: support@smartstocktrader.com");
      Print("ERROR: Hardware ID not authorized");
      return false;
   }

   // Step 4: Check account authorization
   if(!License_CheckAccountAuthorization()) {
      Alert("ACCOUNT NOT AUTHORIZED!\n\n" +
            "Account #" + IntegerToString(AccountNumber()) + " is not authorized to use this EA.\n\n" +
            "Please contact support to authorize this account.\n" +
            "Email: support@smartstocktrader.com");
      Print("ERROR: Account not authorized");
      return false;
   }

   // Step 5: Check broker (if enabled)
   if(!License_CheckBroker()) {
      return false;
   }

   // All checks passed
   int daysLeft = License_GetDaysUntilExpiration();
   Print("LICENSE VALIDATION: PASSED");
   Print("License valid for ", daysLeft, " more days");

   // Show expiration warning if less than 30 days
   if(daysLeft <= 30 && daysLeft > 0) {
      Alert("LICENSE EXPIRATION WARNING\n\n" +
            "Your Smart Stock Trader license will expire in " +
            IntegerToString(daysLeft) + " days.\n\n" +
            "Expiration Date: " + TimeToString(ExpirationDate, TIME_DATE) + "\n\n" +
            "Please renew soon to avoid service interruption.\n" +
            "Email: support@smartstocktrader.com");
   }

   Print("========================");
   return true;
}

// Display license info (can be called from dashboard)
string License_GetInfo() {
   string info = "";

   if(RequireLicenseKey) {
      info += "License Key: " + StringSubstr(LicenseKey, 0, 15) + "...\n";
   } else {
      info += "License Key: Not Required\n";
   }

   info += "Account: " + IntegerToString(AccountNumber()) + "\n";
   info += "Broker: " + AccountCompany() + "\n";

   if(ExpirationDate > 0) {
      int daysLeft = License_GetDaysUntilExpiration();
      info += "Expires: " + TimeToString(ExpirationDate, TIME_DATE);
      info += " (" + IntegerToString(daysLeft) + " days)\n";
   } else {
      info += "Expires: Never\n";
   }

   if(EnableHardwareIDLock) {
      info += "Hardware Lock: ENABLED\n";
   }

   return info;
}

//--------------------------------------------------------------------
// ONLINE LICENSE VALIDATION (Optional - for server-based licensing)
//--------------------------------------------------------------------

/*
// Uncomment this section to enable online license validation
// Requires WebRequest to be enabled for your validation URL

bool License_ValidateOnline(string licenseKey) {
   // Your license validation server URL
   string url = "https://yourwebsite.com/api/validate-license.php";

   // Build request parameters
   string params = "?key=" + licenseKey +
                  "&account=" + IntegerToString(AccountNumber()) +
                  "&name=" + AccountName() +
                  "&broker=" + AccountCompany() +
                  "&server=" + AccountServer();

   string fullURL = url + params;

   // Make HTTP request
   string cookie = NULL;
   string referer = NULL;
   int timeout = 5000; // 5 second timeout
   char post[];
   char result[];
   string resultHeaders;

   int res = WebRequest("GET", fullURL, cookie, referer, timeout, post, 0, result, resultHeaders);

   if(res == 200) {
      string response = CharArrayToString(result);

      // Check response (adjust based on your API)
      if(StringFind(response, "VALID") >= 0) {
         Print("Online license validation: SUCCESS");
         return true;
      } else if(StringFind(response, "EXPIRED") >= 0) {
         Alert("Your license has expired. Please renew at www.yourwebsite.com");
         return false;
      } else if(StringFind(response, "INVALID") >= 0) {
         Alert("Invalid license key. Please contact support.");
         return false;
      }
   } else {
      Print("WARNING: Could not connect to license server (Error ", res, ")");
      Print("Falling back to offline validation...");
      // Fallback to offline validation if server is unreachable
      return License_ValidateKey(licenseKey);
   }

   return false;
}
*/

//+------------------------------------------------------------------+
