-- =============================================
-- Email Template Manager Sample Data Script
-- Created: July 2025
-- Description: Inserts sample templates and data for testing
-- =============================================

USE [EmailTemplateManagerDB];
GO

-- =============================================
-- Insert Sample Templates
-- =============================================

-- Clear existing sample data (optional - comment out if you want to keep existing data)
-- DELETE FROM [dbo].[EmailLogs];
-- DELETE FROM [dbo].[Templates];
-- DBCC CHECKIDENT ('Templates', RESEED, 0);
-- DBCC CHECKIDENT ('EmailLogs', RESEED, 0);

-- Sample Template 1: Welcome Email
IF NOT EXISTS (SELECT 1 FROM [dbo].[Templates] WHERE [Name] = 'Welcome Email')
BEGIN
    INSERT INTO [dbo].[Templates] ([Name], [Description], [HtmlContent], [CreatedAt], [CreatedBy], [IsActive], [Variables])
    VALUES (
        'Welcome Email',
        'A welcome email template for new users or customers',
        '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome Email</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #007bff; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f8f9fa; }
        .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #28a745; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to {{CompanyName}}!</h1>
        </div>
        <div class="content">
            <h2>Hello {{FirstName}} {{LastName}},</h2>
            <p>Welcome to {{CompanyName}}! We''re excited to have you on board.</p>
            <p>Your account has been successfully created with the email: <strong>{{Email}}</strong></p>
            <p>Here are your next steps:</p>
            <ul>
                <li>Complete your profile setup</li>
                <li>Explore our features</li>
                <li>Contact support if you need help</li>
            </ul>
            <p style="text-align: center;">
                <a href="{{LoginUrl}}" class="button">Get Started</a>
            </p>
        </div>
        <div class="footer">
            <p>&copy; 2025 {{CompanyName}}. All rights reserved.</p>
            <p>{{CompanyAddress}}</p>
        </div>
    </div>
</body>
</html>',
        GETUTCDATE(),
        'System',
        1,
        '["CompanyName", "FirstName", "LastName", "Email", "LoginUrl", "CompanyAddress"]'
    );
    
    PRINT 'Welcome Email template inserted successfully.';
END
GO

-- Sample Template 2: Password Reset
IF NOT EXISTS (SELECT 1 FROM [dbo].[Templates] WHERE [Name] = 'Password Reset')
BEGIN
    INSERT INTO [dbo].[Templates] ([Name], [Description], [HtmlContent], [CreatedAt], [CreatedBy], [IsActive], [Variables])
    VALUES (
        'Password Reset',
        'Password reset email template with secure reset link',
        '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Password Reset</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f8f9fa; }
        .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #dc3545; color: white; text-decoration: none; border-radius: 5px; }
        .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Password Reset Request</h1>
        </div>
        <div class="content">
            <h2>Hello {{FirstName}},</h2>
            <p>We received a request to reset your password for your {{CompanyName}} account.</p>
            
            <div class="warning">
                <strong>Security Notice:</strong> If you did not request this password reset, please ignore this email and your password will remain unchanged.
            </div>
            
            <p>To reset your password, click the button below:</p>
            <p style="text-align: center;">
                <a href="{{ResetUrl}}" class="button">Reset Password</a>
            </p>
            
            <p>This link will expire in {{ExpirationHours}} hours for security reasons.</p>
            
            <p>If the button doesn''t work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; background-color: #e9ecef; padding: 10px; font-family: monospace;">
                {{ResetUrl}}
            </p>
        </div>
        <div class="footer">
            <p>&copy; 2025 {{CompanyName}}. All rights reserved.</p>
            <p>This is an automated message, please do not reply.</p>
        </div>
    </div>
</body>
</html>',
        GETUTCDATE(),
        'System',
        1,
        '["FirstName", "CompanyName", "ResetUrl", "ExpirationHours"]'
    );
    
    PRINT 'Password Reset template inserted successfully.';
END
GO

-- Sample Template 3: Order Confirmation
IF NOT EXISTS (SELECT 1 FROM [dbo].[Templates] WHERE [Name] = 'Order Confirmation')
BEGIN
    INSERT INTO [dbo].[Templates] ([Name], [Description], [HtmlContent], [CreatedAt], [CreatedBy], [IsActive], [Variables])
    VALUES (
        'Order Confirmation',
        'E-commerce order confirmation email template',
        '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f8f9fa; }
        .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
        .order-details { background-color: white; border: 1px solid #dee2e6; border-radius: 5px; padding: 15px; margin: 15px 0; }
        .total { font-weight: bold; font-size: 1.2em; color: #28a745; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Order Confirmed!</h1>
        </div>
        <div class="content">
            <h2>Thank you for your order, {{FirstName}}!</h2>
            <p>Your order has been confirmed and is being processed.</p>
            
            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order Number:</strong> {{OrderNumber}}</p>
                <p><strong>Order Date:</strong> {{OrderDate}}</p>
                <p><strong>Estimated Delivery:</strong> {{DeliveryDate}}</p>
                
                <h4>Shipping Address:</h4>
                <p>
                    {{ShippingName}}<br>
                    {{ShippingAddress}}<br>
                    {{ShippingCity}}, {{ShippingState}} {{ShippingZip}}
                </p>
                
                <h4>Order Summary:</h4>
                <table>
                    <thead>
                        <tr>
                            <th>Item</th>
                            <th>Quantity</th>
                            <th>Price</th>
                        </tr>
                    </thead>
                    <tbody>
                        {{OrderItems}}
                    </tbody>
                </table>
                
                <p class="total">Total: {{OrderTotal}}</p>
            </div>
            
            <p>You can track your order status by visiting your account dashboard.</p>
        </div>
        <div class="footer">
            <p>&copy; 2025 {{CompanyName}}. All rights reserved.</p>
            <p>Questions? Contact us at {{SupportEmail}}</p>
        </div>
    </div>
</body>
</html>',
        GETUTCDATE(),
        'System',
        1,
        '["FirstName", "OrderNumber", "OrderDate", "DeliveryDate", "ShippingName", "ShippingAddress", "ShippingCity", "ShippingState", "ShippingZip", "OrderItems", "OrderTotal", "CompanyName", "SupportEmail"]'
    );
    
    PRINT 'Order Confirmation template inserted successfully.';
END
GO

-- Sample Template 4: Newsletter
IF NOT EXISTS (SELECT 1 FROM [dbo].[Templates] WHERE [Name] = 'Monthly Newsletter')
BEGIN
    INSERT INTO [dbo].[Templates] ([Name], [Description], [HtmlContent], [CreatedAt], [CreatedBy], [IsActive], [Variables])
    VALUES (
        'Monthly Newsletter',
        'Monthly newsletter template for company updates and news',
        '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Monthly Newsletter</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #6f42c1; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f8f9fa; }
        .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
        .article { background-color: white; margin: 15px 0; padding: 15px; border-radius: 5px; border-left: 4px solid #6f42c1; }
        .article h3 { margin-top: 0; color: #6f42c1; }
        .cta { text-align: center; margin: 20px 0; }
        .button { display: inline-block; padding: 10px 20px; background-color: #6f42c1; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{CompanyName}} Newsletter</h1>
            <p>{{MonthYear}} Edition</p>
        </div>
        <div class="content">
            <h2>Hello {{FirstName}},</h2>
            <p>Welcome to our monthly newsletter! Here''s what''s been happening at {{CompanyName}}.</p>
            
            <div class="article">
                <h3>{{Article1Title}}</h3>
                <p>{{Article1Content}}</p>
            </div>
            
            <div class="article">
                <h3>{{Article2Title}}</h3>
                <p>{{Article2Content}}</p>
            </div>
            
            <div class="article">
                <h3>{{Article3Title}}</h3>
                <p>{{Article3Content}}</p>
            </div>
            
            <div class="cta">
                <p>Want to learn more about our latest updates?</p>
                <a href="{{WebsiteUrl}}" class="button">Visit Our Website</a>
            </div>
        </div>
        <div class="footer">
            <p>&copy; 2025 {{CompanyName}}. All rights reserved.</p>
            <p>You received this email because you subscribed to our newsletter.</p>
            <p><a href="{{UnsubscribeUrl}}">Unsubscribe</a> | <a href="{{PreferencesUrl}}">Update Preferences</a></p>
        </div>
    </div>
</body>
</html>',
        GETUTCDATE()
    );
    
    PRINT 'Monthly Newsletter template inserted successfully.';
END
GO

-- =============================================
-- Insert Sample Email Logs (for testing)
-- =============================================

-- Get template IDs for sample logs
DECLARE @WelcomeTemplateId INT = (SELECT Id FROM [dbo].[Templates] WHERE [Name] = 'Welcome Email');
DECLARE @PasswordResetTemplateId INT = (SELECT Id FROM [dbo].[Templates] WHERE [Name] = 'Password Reset');

-- Sample successful email logs
INSERT INTO [dbo].[EmailLogs] ([ToEmail], [FromEmail], [Subject], [Body], [SentAt], [IsSuccess], [TemplateId])
VALUES 
    ('john.doe@example.com', 'noreply@company.com', 'Welcome to Company, John!', 'Welcome email content...', DATEADD(DAY, -5, GETUTCDATE()), 1, @WelcomeTemplateId),
    ('jane.smith@example.com', 'noreply@company.com', 'Welcome to Company, Jane!', 'Welcome email content...', DATEADD(DAY, -4, GETUTCDATE()), 1, @WelcomeTemplateId),
    ('mike.johnson@example.com', 'noreply@company.com', 'Reset Your Password - Company', 'Password reset content...', DATEADD(DAY, -3, GETUTCDATE()), 1, @PasswordResetTemplateId),
    ('sarah.wilson@example.com', 'noreply@company.com', 'Welcome to Company, Sarah!', 'Welcome email content...', DATEADD(DAY, -2, GETUTCDATE()), 1, @WelcomeTemplateId);

-- Sample failed email log
INSERT INTO [dbo].[EmailLogs] ([ToEmail], [FromEmail], [Subject], [Body], [SentAt], [IsSuccess], [ErrorMessage], [TemplateId])
VALUES 
    ('invalid@invalid-domain.com', 'noreply@company.com', 'Welcome to Company!', 'Welcome email content...', DATEADD(DAY, -1, GETUTCDATE()), 0, 'SMTP Error: Domain not found', @WelcomeTemplateId);

PRINT 'Sample email logs inserted successfully.';

-- =============================================
-- Display Summary
-- =============================================

PRINT '';
PRINT '==============================================';
PRINT 'SAMPLE DATA INSERTION COMPLETED';
PRINT '==============================================';

SELECT 'Templates' as TableName, COUNT(*) as RecordCount FROM [dbo].[Templates]
UNION ALL
SELECT 'EmailLogs' as TableName, COUNT(*) as RecordCount FROM [dbo].[EmailLogs];

PRINT '';
PRINT 'Sample templates created:';
SELECT Id, Name, Subject, CreatedAt FROM [dbo].[Templates] ORDER BY CreatedAt;

PRINT '';
PRINT 'Sample data insertion completed successfully!';
PRINT 'You can now test the Email Template Manager with these sample templates.';
