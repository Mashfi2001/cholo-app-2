const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendOtpEmail = async (to, otp) => {
  try {
    const info = await transporter.sendMail({
      from: `"Cholo App" <${process.env.SMTP_FROM}>`,
      to,
      subject: "Verify Your Cholo App Account",
      text: `Your OTP for Cholo App verification is: ${otp}. It will expire in 15 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Welcome to Cholo App!</h2>
          <p>Please use the following OTP to verify your email address. This OTP is valid for 15 minutes.</p>
          <div style="background-color: #f4f4f4; padding: 15px; text-align: center; border-radius: 5px;">
            <h1 style="letter-spacing: 5px; color: #F98825; margin: 0;">${otp}</h1>
          </div>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    });
    console.log("Message sent: %s", info.messageId);
    return true;
  } catch (error) {
    console.error("Error sending email: ", error);
    return false;
  }
};

exports.sendPasswordResetEmail = async (to, otp) => {
  try {
    const info = await transporter.sendMail({
      from: `"Cholo App" <${process.env.SMTP_FROM}>`,
      to,
      subject: "Reset Your Cholo App Password",
      text: `Your OTP to reset your Cholo App password is: ${otp}. It will expire in 10 minutes. If you did not request a password reset, please ignore this email.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Password Reset Request</h2>
          <p>We received a request to reset the password for your Cholo App account. Use the OTP below to continue. This OTP is valid for 10 minutes.</p>
          <div style="background-color: #f4f4f4; padding: 15px; text-align: center; border-radius: 5px;">
            <h1 style="letter-spacing: 5px; color: #F98825; margin: 0;">${otp}</h1>
          </div>
          <p>If you did not request a password reset, please ignore this email. Your password will remain unchanged.</p>
        </div>
      `,
    });
    console.log("Password reset email sent: %s", info.messageId);
    return true;
  } catch (error) {
    console.error("Error sending password reset email: ", error);
    return false;
  }
};
