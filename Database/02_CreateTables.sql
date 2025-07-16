-- =============================================
-- Email Template Manager Tables Creation Script
-- Created: July 2025
-- Description: Creates all required tables for Email Template Manager
-- =============================================

USE [EmailTemplateManagerDB];
GO

-- =============================================
-- Create Templates Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Templates' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Templates] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [HtmlContent] NVARCHAR(MAX) NOT NULL,
        [OriginalFileName] NVARCHAR(50) NULL,
        [OriginalFileSize] BIGINT NULL,
        [CreatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2(7) NULL,
        [CreatedBy] NVARCHAR(100) NOT NULL DEFAULT 'System',
        [IsActive] BIT NOT NULL DEFAULT 1,
        [Variables] NVARCHAR(MAX) NULL,
        
        CONSTRAINT [PK_Templates] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [IX_Templates_Name] UNIQUE NONCLUSTERED ([Name] ASC)
    );
    
    PRINT 'Templates table created successfully.';
END
ELSE
BEGIN
    PRINT 'Templates table already exists.';
END
GO

-- =============================================
-- Create EmailLogs Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='EmailLogs' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[EmailLogs] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ToEmail] NVARCHAR(255) NOT NULL,
        [FromEmail] NVARCHAR(255) NULL,
        [Subject] NVARCHAR(500) NOT NULL,
        [Body] NVARCHAR(MAX) NOT NULL,
        [SentAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        [IsSuccess] BIT NOT NULL DEFAULT 0,
        [ErrorMessage] NVARCHAR(MAX) NULL,
        [TemplateId] INT NULL,
        
        CONSTRAINT [PK_EmailLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EmailLogs_Templates] FOREIGN KEY ([TemplateId]) 
            REFERENCES [dbo].[Templates] ([Id]) ON DELETE SET NULL
    );
    
    PRINT 'EmailLogs table created successfully.';
END
ELSE
BEGIN
    PRINT 'EmailLogs table already exists.';
END
GO

-- =============================================
-- Create Indexes for Performance
-- =============================================

-- Index on EmailLogs.SentAt for date-based queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EmailLogs_SentAt')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_SentAt] 
    ON [dbo].[EmailLogs] ([SentAt] DESC);
    
    PRINT 'Index IX_EmailLogs_SentAt created successfully.';
END
GO

-- Index on EmailLogs.ToEmail for email-based searches
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EmailLogs_ToEmail')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_ToEmail] 
    ON [dbo].[EmailLogs] ([ToEmail]);
    
    PRINT 'Index IX_EmailLogs_ToEmail created successfully.';
END
GO

-- Index on EmailLogs.IsSuccess for filtering successful/failed emails
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EmailLogs_IsSuccess')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_IsSuccess] 
    ON [dbo].[EmailLogs] ([IsSuccess]);
    
    PRINT 'Index IX_EmailLogs_IsSuccess created successfully.';
END
GO

-- Index on Templates.IsActive for filtering active templates
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Templates_IsActive')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Templates_IsActive] 
    ON [dbo].[Templates] ([IsActive]);
    
    PRINT 'Index IX_Templates_IsActive created successfully.';
END
GO

-- Index on Templates.CreatedBy for user-based queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Templates_CreatedBy')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Templates_CreatedBy] 
    ON [dbo].[Templates] ([CreatedBy]);
    
    PRINT 'Index IX_Templates_CreatedBy created successfully.';
END
GO

-- Index on Templates.CreatedAt for date-based queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Templates_CreatedAt')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Templates_CreatedAt] 
    ON [dbo].[Templates] ([CreatedAt] DESC);
    
    PRINT 'Index IX_Templates_CreatedAt created successfully.';
END
GO

-- =============================================
-- Create Views for Common Queries
-- =============================================

-- View for Template Statistics
IF OBJECT_ID('vw_TemplateStatistics', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_TemplateStatistics];
GO

CREATE VIEW [dbo].[vw_TemplateStatistics]
AS
SELECT 
    t.Id,
    t.Name,
    t.CreatedAt,
    t.UpdatedAt,
    t.CreatedBy,
    t.IsActive,
    COUNT(el.Id) as EmailsSent,
    SUM(CASE WHEN el.IsSuccess = 1 THEN 1 ELSE 0 END) as SuccessfulEmails,
    SUM(CASE WHEN el.IsSuccess = 0 THEN 1 ELSE 0 END) as FailedEmails,
    MAX(el.SentAt) as LastUsed
FROM [dbo].[Templates] t
LEFT JOIN [dbo].[EmailLogs] el ON t.Id = el.TemplateId
GROUP BY t.Id, t.Name, t.CreatedAt, t.UpdatedAt, t.CreatedBy, t.IsActive;
GO

PRINT 'View vw_TemplateStatistics created successfully.';

-- View for Recent Email Activity
IF OBJECT_ID('vw_RecentEmailActivity', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_RecentEmailActivity];
GO

CREATE VIEW [dbo].[vw_RecentEmailActivity]
AS
SELECT TOP 100
    el.Id,
    el.ToEmail,
    el.Subject,
    el.SentAt,
    el.IsSuccess,
    t.Name as TemplateName
FROM [dbo].[EmailLogs] el
LEFT JOIN [dbo].[Templates] t ON el.TemplateId = t.Id
ORDER BY el.SentAt DESC;
GO

PRINT 'View vw_RecentEmailActivity created successfully.';

-- =============================================
-- Create Stored Procedures for Common Operations
-- =============================================

-- Stored Procedure: Get Template Usage Statistics
IF OBJECT_ID('sp_GetTemplateUsageStats', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_GetTemplateUsageStats];
GO

CREATE PROCEDURE [dbo].[sp_GetTemplateUsageStats]
    @TemplateId INT = NULL,
    @DateFrom DATETIME2 = NULL,
    @DateTo DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.Id,
        t.Name,
        COUNT(el.Id) as TotalEmails,
        SUM(CASE WHEN el.IsSuccess = 1 THEN 1 ELSE 0 END) as SuccessfulEmails,
        SUM(CASE WHEN el.IsSuccess = 0 THEN 1 ELSE 0 END) as FailedEmails,
        MIN(el.SentAt) as FirstUsed,
        MAX(el.SentAt) as LastUsed
    FROM [dbo].[Templates] t
    LEFT JOIN [dbo].[EmailLogs] el ON t.Id = el.TemplateId
        AND (@DateFrom IS NULL OR el.SentAt >= @DateFrom)
        AND (@DateTo IS NULL OR el.SentAt <= @DateTo)
    WHERE (@TemplateId IS NULL OR t.Id = @TemplateId)
    GROUP BY t.Id, t.Name
    ORDER BY TotalEmails DESC;
END
GO

PRINT 'Stored Procedure sp_GetTemplateUsageStats created successfully.';

-- Stored Procedure: Clean Old Email Logs
IF OBJECT_ID('sp_CleanOldEmailLogs', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_CleanOldEmailLogs];
GO

CREATE PROCEDURE [dbo].[sp_CleanOldEmailLogs]
    @DaysToKeep INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@DaysToKeep, GETUTCDATE());
    DECLARE @DeletedRows INT;
    
    DELETE FROM [dbo].[EmailLogs] 
    WHERE SentAt < @CutoffDate;
    
    SET @DeletedRows = @@ROWCOUNT;
    
    PRINT CONCAT('Deleted ', @DeletedRows, ' email log records older than ', @DaysToKeep, ' days.');
    
    SELECT @DeletedRows as DeletedRecords;
END
GO

PRINT 'Stored Procedure sp_CleanOldEmailLogs created successfully.';

PRINT 'All database objects created successfully.';
PRINT 'Database setup is complete!';
