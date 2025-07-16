-- =============================================
-- Email Template Manager Database Creation Script
-- Created: July 2025
-- Description: Creates the main database for Email Template Manager
-- =============================================

-- Check if database exists and create if not
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'EmailTemplateManagerDB')
BEGIN
    CREATE DATABASE [EmailTemplateManagerDB]
    COLLATE SQL_Latin1_General_CP1_CI_AS;
    
    PRINT 'Database EmailTemplateManagerDB created successfully.';
END
ELSE
BEGIN
    PRINT 'Database EmailTemplateManagerDB already exists.';
END
GO

-- Use the created database
USE [EmailTemplateManagerDB];
GO

-- Set database options for better performance and compatibility
ALTER DATABASE [EmailTemplateManagerDB] 
SET RECOVERY SIMPLE,
    PAGE_VERIFY CHECKSUM,
    READ_COMMITTED_SNAPSHOT ON;
GO

PRINT 'Database configuration completed.';
