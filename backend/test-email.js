require('dotenv').config();
const nodemailer = require('nodemailer');

async function testEmail() {
  console.log('Testing email configuration...\n');

  // Create transporter
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  // Verify connection
  try {
    await transporter.verify();
    console.log('✓ SMTP connection verified successfully!');
    console.log(`✓ Connected to: ${process.env.SMTP_HOST}:${process.env.SMTP_PORT}`);
    console.log(`✓ User: ${process.env.SMTP_USER}\n`);
  } catch (error) {
    console.error('✗ SMTP connection failed:', error.message);
    return;
  }

  // Send test email
  try {
    console.log('Sending test email...');
    const info = await transporter.sendMail({
      from: `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_FROM}>`,
      to: process.env.SMTP_USER, // Send to yourself as test
      subject: 'Smart Stock Trader - Email Test',
      text: 'This is a test email from Smart Stock Trader backend.',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #ff6b35;">Smart Stock Trader</h2>
          <p>This is a test email to verify your email configuration is working correctly.</p>
          <p><strong>SMTP Configuration:</strong></p>
          <ul>
            <li>Host: ${process.env.SMTP_HOST}</li>
            <li>Port: ${process.env.SMTP_PORT}</li>
            <li>From: ${process.env.SMTP_FROM}</li>
          </ul>
          <p style="color: #22c55e;">✓ Email system is working correctly!</p>
          <hr style="border: 1px solid #e5e7eb; margin: 20px 0;">
          <p style="color: #6b7280; font-size: 12px;">
            This is an automated test email from Smart Stock Trader backend.
          </p>
        </div>
      `
    });

    console.log('\n✓ Test email sent successfully!');
    console.log(`✓ Message ID: ${info.messageId}`);
    console.log(`✓ Sent to: ${process.env.SMTP_USER}`);
    console.log('\nCheck your inbox for the test email.');
  } catch (error) {
    console.error('\n✗ Failed to send email:', error.message);
  }
}

testEmail();
