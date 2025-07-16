-- =============================================
-- Email Template Manager - Entity Framework Migration Script
-- Created: July 2025
-- Description: SQL script equivalent to Entity Framework migrations
-- Use this if you prefer to run SQL scripts instead of EF migrations
-- =============================================

USE [YourExistingDatabase];  -- Replace with your actual database name
GO

-- =============================================
-- Migration: AddEmailTemplates
-- =============================================

-- Check if migration has already been applied
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '__EFMigrationsHistory')
BEGIN
    -- Create EF Migrations History table if it doesn't exist
    CREATE TABLE [dbo].[__EFMigrationsHistory] (
        [MigrationId] NVARCHAR(150) NOT NULL,
        [ProductVersion] NVARCHAR(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
    
    PRINT '__EFMigrationsHistory table created.';
END
GO

-- Check if this specific migration has been applied
IF NOT EXISTS (SELECT 1 FROM [dbo].[__EFMigrationsHistory] WHERE [MigrationId] = '20250716000001_AddEmailTemplates')
BEGIN
    PRINT 'Applying migration: AddEmailTemplates';
    
    -- =============================================
    -- Create Templates Table
    -- =============================================
    CREATE TABLE [dbo].[Templates] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        [Description] nvarchar(500) NULL,
        [HtmlContent] nvarchar(max) NOT NULL,
        [OriginalFileName] nvarchar(50) NULL,
        [OriginalFileSize] bigint NULL,
        [CreatedAt] datetime2 NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [CreatedBy] nvarchar(100) NOT NULL DEFAULT 'System',
        [IsActive] bit NOT NULL DEFAULT 1,
        [Variables] nvarchar(max) NULL,
        CONSTRAINT [PK_Templates] PRIMARY KEY ([Id])
    );
    
    -- =============================================
    -- Create EmailLogs Table
    -- =============================================
    CREATE TABLE [dbo].[EmailLogs] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [ToEmail] nvarchar(255) NOT NULL,
        [FromEmail] nvarchar(255) NULL,
        [Subject] nvarchar(500) NOT NULL,
        [Body] nvarchar(max) NOT NULL,
        [SentAt] datetime2 NOT NULL,
        [IsSuccess] bit NOT NULL,
        [ErrorMessage] nvarchar(max) NULL,
        [TemplateId] int NULL,
        CONSTRAINT [PK_EmailLogs] PRIMARY KEY ([Id])
    );
    
    -- =============================================
    -- Create Indexes
    -- =============================================
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Templates_Name] ON [dbo].[Templates] ([Name]);
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_TemplateId] ON [dbo].[EmailLogs] ([TemplateId]);
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_SentAt] ON [dbo].[EmailLogs] ([SentAt]);
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_ToEmail] ON [dbo].[EmailLogs] ([ToEmail]);
    CREATE NONCLUSTERED INDEX [IX_EmailLogs_IsSuccess] ON [dbo].[EmailLogs] ([IsSuccess]);
    CREATE NONCLUSTERED INDEX [IX_Templates_CreatedAt] ON [dbo].[Templates] ([CreatedAt]);
    CREATE NONCLUSTERED INDEX [IX_Templates_IsActive] ON [dbo].[Templates] ([IsActive]);
    CREATE NONCLUSTERED INDEX [IX_Templates_CreatedBy] ON [dbo].[Templates] ([CreatedBy]);
    
    -- =============================================
    -- Create Foreign Key Constraints
    -- =============================================
    ALTER TABLE [dbo].[EmailLogs] 
    ADD CONSTRAINT [FK_EmailLogs_Templates_TemplateId] 
    FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[Templates] ([Id]) ON DELETE SET NULL;
    
    -- Record the migration
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20250716000001_AddEmailTemplates', N'8.0.8');
    
    PRINT 'Migration AddEmailTemplates applied successfully.';
END
ELSE
BEGIN
    PRINT 'Migration AddEmailTemplates has already been applied.';
END
GO

-- =============================================
-- Verify Migration Results
-- =============================================
PRINT '';
PRINT 'Verifying migration results...';

-- Check if tables exist
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Templates')
    PRINT '✓ Templates table exists';
ELSE
    PRINT '✗ Templates table missing';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EmailLogs')
    PRINT '✓ EmailLogs table exists';
ELSE
    PRINT '✗ EmailLogs table missing';

-- Check if indexes exist
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Templates_Name')
    PRINT '✓ IX_Templates_Name index exists';

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EmailLogs_TemplateId')
    PRINT '✓ IX_EmailLogs_TemplateId index exists';

-- Check if foreign key exists
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EmailLogs_Templates_TemplateId')
    PRINT '✓ Foreign key constraint exists';

PRINT '';
PRINT 'Migration verification completed.';

-- =============================================
-- Display Table Schemas
-- =============================================
PRINT '';
PRINT 'Templates table schema:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Templates'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'EmailLogs table schema:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'EmailLogs'
ORDER BY ORDINAL_POSITION;
