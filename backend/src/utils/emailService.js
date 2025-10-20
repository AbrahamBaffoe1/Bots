const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

// Send welcome email with login credentials
exports.sendWelcomeEmail = async (email, password, licenseKey) => {
  const mailOptions = {
    from: `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_FROM}>`,
    to: email,
    subject: 'Welcome to Smart Stock Trader - Your Trial Account is Ready!',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background: linear-gradient(135deg, #ff7f00 0%, #ff5722 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
          }
          .header h1 {
            margin: 0;
            font-size: 28px;
          }
          .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 10px 10px;
          }
          .credentials-box {
            background: white;
            border: 2px solid #ff7f00;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
          }
          .credential-item {
            margin: 15px 0;
            padding: 10px;
            background: #fff5f0;
            border-left: 4px solid #ff7f00;
          }
          .credential-label {
            font-weight: bold;
            color: #ff7f00;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
          }
          .credential-value {
            font-size: 18px;
            font-family: 'Courier New', monospace;
            color: #333;
            margin-top: 5px;
          }
          .button {
            display: inline-block;
            background: linear-gradient(135deg, #ff7f00 0%, #ff5722 100%);
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: bold;
            margin: 20px 0;
          }
          .steps {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
          }
          .step {
            margin: 15px 0;
            padding-left: 30px;
            position: relative;
          }
          .step-number {
            position: absolute;
            left: 0;
            top: 0;
            background: #ff7f00;
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
          }
          .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 12px;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Welcome to Smart Stock Trader!</h1>
          <p>Your 7-Day Free Trial is Active</p>
        </div>

        <div class="content">
          <p>Hi there,</p>

          <p>Thank you for signing up for Smart Stock Trader! Your trial account has been created and is ready to use.</p>

          <div class="credentials-box">
            <h3 style="margin-top: 0; color: #ff7f00;">Your Login Credentials</h3>

            <div class="credential-item">
              <div class="credential-label">Email Address</div>
              <div class="credential-value">${email}</div>
            </div>

            <div class="credential-item">
              <div class="credential-label">Password</div>
              <div class="credential-value">${password}</div>
            </div>

            <div class="credential-item">
              <div class="credential-label">License Key (1 MT4 Account)</div>
              <div class="credential-value">${licenseKey}</div>
            </div>
          </div>

          <p style="text-align: center;">
            <a href="${process.env.FRONTEND_URL}" class="button">Login to Your Dashboard</a>
          </p>

          <div class="steps">
            <h3 style="color: #ff7f00; margin-top: 0;">Quick Start Guide</h3>

            <div class="step">
              <div class="step-number">1</div>
              <strong>Login to Your Account</strong><br>
              Use your email and password to access the dashboard
            </div>

            <div class="step">
              <div class="step-number">2</div>
              <strong>Activate Your Bot</strong><br>
              Go to the Bots section and click "Activate Bot with License Key"
            </div>

            <div class="step">
              <div class="step-number">3</div>
              <strong>Enter License Key</strong><br>
              Paste your license key: <code>${licenseKey}</code>
            </div>

            <div class="step">
              <div class="step-number">4</div>
              <strong>Configure MT4 Details</strong><br>
              Enter your MT4 account number, broker name, and server
            </div>

            <div class="step">
              <div class="step-number">5</div>
              <strong>Start Trading!</strong><br>
              Start your bot and let it trade automatically 24/7
            </div>
          </div>

          <p><strong>Important:</strong> Please save these credentials in a secure location. For security reasons, we recommend changing your password after your first login.</p>

          <p><strong>Trial Details:</strong></p>
          <ul>
            <li>Duration: 7 days from today</li>
            <li>MT4 Accounts: 1 account</li>
            <li>Features: Full access to all trading features</li>
            <li>Support: Email support available</li>
          </ul>

          <p>If you have any questions or need assistance, please don't hesitate to reply to this email.</p>

          <p>Happy Trading!<br>
          <strong>The Smart Stock Trader Team</strong></p>
        </div>

        <div class="footer">
          <p>This email was sent to ${email}</p>
          <p>&copy; ${new Date().getFullYear()} Smart Stock Trader. All rights reserved.</p>
        </div>
      </body>
      </html>
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Welcome email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Email sending error:', error);
    throw error;
  }
};

// Send license key email for paid plans
exports.sendLicenseKeyEmail = async (email, licenseKey, planType) => {
  const planNames = {
    'BASIC': 'Basic Plan',
    'PRO': 'Pro Plan',
    'ENTERPRISE': 'Enterprise Plan'
  };

  const planAccounts = {
    'BASIC': 1,
    'PRO': 3,
    'ENTERPRISE': 10
  };

  const mailOptions = {
    from: `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_FROM}>`,
    to: email,
    subject: `Your Smart Stock Trader License Key - ${planNames[planType]}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background: linear-gradient(135deg, #ff7f00 0%, #ff5722 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
          }
          .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 10px 10px;
          }
          .license-box {
            background: white;
            border: 3px solid #ff7f00;
            border-radius: 8px;
            padding: 25px;
            margin: 20px 0;
            text-align: center;
          }
          .license-key {
            font-size: 24px;
            font-family: 'Courier New', monospace;
            color: #ff7f00;
            font-weight: bold;
            letter-spacing: 2px;
            margin: 15px 0;
          }
          .button {
            display: inline-block;
            background: linear-gradient(135deg, #ff7f00 0%, #ff5722 100%);
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: bold;
            margin: 20px 0;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Payment Successful!</h1>
          <p>Thank you for purchasing ${planNames[planType]}</p>
        </div>

        <div class="content">
          <p>Hi there,</p>

          <p>Thank you for your purchase! Here is your license key:</p>

          <div class="license-box">
            <p style="margin: 0; color: #666; font-size: 14px;">YOUR LICENSE KEY</p>
            <div class="license-key">${licenseKey}</div>
            <p style="margin: 10px 0 0 0; color: #666; font-size: 12px;">Valid for ${planAccounts[planType]} MT4 Account${planAccounts[planType] > 1 ? 's' : ''} - 1 Year</p>
          </div>

          <p style="text-align: center;">
            <a href="${process.env.FRONTEND_URL}" class="button">Activate Your License</a>
          </p>

          <p><strong>Next Steps:</strong></p>
          <ol>
            <li>Login to your dashboard (or create an account if you haven't)</li>
            <li>Go to the Bots section</li>
            <li>Click "Activate Bot with License Key"</li>
            <li>Enter your license key and configure your MT4 details</li>
            <li>Start trading!</li>
          </ol>

          <p><strong>Plan Details:</strong></p>
          <ul>
            <li>License Type: ${planNames[planType]}</li>
            <li>MT4 Accounts: ${planAccounts[planType]} account${planAccounts[planType] > 1 ? 's' : ''}</li>
            <li>Duration: 1 Year</li>
            <li>Support: ${planType === 'ENTERPRISE' ? 'Dedicated' : planType === 'PRO' ? 'Priority' : 'Email'} Support</li>
          </ul>

          <p>If you have any questions, please reply to this email.</p>

          <p>Happy Trading!<br>
          <strong>The Smart Stock Trader Team</strong></p>
        </div>
      </body>
      </html>
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('License email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Email sending error:', error);
    throw error;
  }
};

module.exports = exports;
