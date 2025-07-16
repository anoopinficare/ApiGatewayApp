-- =============================================
-- Email Template Manager - Database Maintenance Scripts
-- Created: July 2025
-- Description: Maintenance and utility scripts for Email Template Manager
-- =============================================

-- =============================================
-- 1. BACKUP SCRIPT
-- =============================================

-- Create backup of the database
DECLARE @BackupPath NVARCHAR(500) = 'C:\Backups\EmailTemplateManagerDB_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';

BACKUP DATABASE [EmailTemplateManagerDB] 
TO DISK = @BackupPath
WITH FORMAT, 
     COMPRESSION,
     CHECKSUM,
     DESCRIPTION = 'Email Template Manager Database Backup';

PRINT 'Database backup created at: ' + @BackupPath;
GO

-- =============================================
-- 2. CLEANUP SCRIPTS
-- =============================================

-- Clean up old email logs (older than 90 days)
DECLARE @CleanupDate DATETIME2 = DATEADD(DAY, -90, GETUTCDATE());
DECLARE @DeletedCount INT;

DELETE FROM [dbo].[EmailLogs] 
WHERE [SentAt] < @CleanupDate;

SET @DeletedCount = @@ROWCOUNT;
PRINT 'Cleaned up ' + CAST(@DeletedCount AS VARCHAR(10)) + ' old email log records.';
GO

-- =============================================
-- 3. PERFORMANCE MONITORING SCRIPTS
-- =============================================

-- Check database size
SELECT 
    DB_NAME() as DatabaseName,
    (SELECT SUM(size * 8.0 / 1024) FROM sys.master_files WHERE type = 0 AND database_id = DB_ID()) as 'Data Size (MB)',
    (SELECT SUM(size * 8.0 / 1024) FROM sys.master_files WHERE type = 1 AND database_id = DB_ID()) as 'Log Size (MB)';

-- Check table sizes
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME IN ('Templates', 'EmailLogs')
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC;

-- =============================================
-- 4. INDEX MAINTENANCE
-- =============================================

-- Rebuild indexes if fragmentation is high
DECLARE @IndexMaintenanceSQL NVARCHAR(MAX) = '';

SELECT @IndexMaintenanceSQL = @IndexMaintenanceSQL + 
    CASE 
        WHEN avg_fragmentation_in_percent > 30 THEN
            'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(i.object_id) + '].[' + OBJECT_NAME(i.object_id) + '] REBUILD;' + CHAR(13)
        WHEN avg_fragmentation_in_percent > 10 THEN
            'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(i.object_id) + '].[' + OBJECT_NAME(i.object_id) + '] REORGANIZE;' + CHAR(13)
        ELSE ''
    END
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Templates', 'EmailLogs')
  AND i.name IS NOT NULL;

IF LEN(@IndexMaintenanceSQL) > 0
BEGIN
    PRINT 'Executing index maintenance:';
    PRINT @IndexMaintenanceSQL;
    EXEC sp_executesql @IndexMaintenanceSQL;
END
ELSE
BEGIN
    PRINT 'No index maintenance required.';
END
GO

-- =============================================
-- 5. UPDATE STATISTICS
-- =============================================

UPDATE STATISTICS [dbo].[Templates];
UPDATE STATISTICS [dbo].[EmailLogs];

PRINT 'Statistics updated for all tables.';
GO

-- =============================================
-- 6. DATA VALIDATION SCRIPTS
-- =============================================

-- Check for orphaned email logs (emails without valid template references)
SELECT COUNT(*) as OrphanedEmailLogs
FROM [dbo].[EmailLogs] el
LEFT JOIN [dbo].[Templates] t ON el.TemplateId = t.Id
WHERE el.TemplateId IS NOT NULL AND t.Id IS NULL;

-- Check for templates without any usage
SELECT t.Id, t.Name, t.CreatedAt
FROM [dbo].[Templates] t
LEFT JOIN [dbo].[EmailLogs] el ON t.Id = el.TemplateId
WHERE el.Id IS NULL
ORDER BY t.CreatedAt DESC;

-- Check email success rate by template
SELECT 
    t.Name as TemplateName,
    COUNT(*) as TotalEmails,
    SUM(CASE WHEN el.IsSuccess = 1 THEN 1 ELSE 0 END) as SuccessfulEmails,
    SUM(CASE WHEN el.IsSuccess = 0 THEN 1 ELSE 0 END) as FailedEmails,
    CAST(
        (SUM(CASE WHEN el.IsSuccess = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) 
        AS DECIMAL(5,2)
    ) as SuccessRate
FROM [dbo].[Templates] t
INNER JOIN [dbo].[EmailLogs] el ON t.Id = el.TemplateId
GROUP BY t.Id, t.Name
ORDER BY SuccessRate DESC;

-- =============================================
-- 7. SECURITY AUDIT
-- =============================================

-- Check database permissions
SELECT 
    dp.state_desc,
    dp.permission_name,
    s.name AS principal_name,
    dp.class_desc,
    o.name AS object_name
FROM sys.database_permissions dp
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
LEFT JOIN sys.database_principals s ON dp.grantee_principal_id = s.principal_id
WHERE o.name IN ('Templates', 'EmailLogs') OR o.name IS NULL
ORDER BY s.name, dp.permission_name;

PRINT 'Database maintenance scripts completed.';

-- =============================================
-- 8. SCHEDULED MAINTENANCE RECOMMENDATIONS
-- =============================================

PRINT '';
PRINT '==============================================';
PRINT 'SCHEDULED MAINTENANCE RECOMMENDATIONS:';
PRINT '==============================================';
PRINT '1. Run backup script daily';
PRINT '2. Run cleanup script weekly to remove old email logs';
PRINT '3. Run performance monitoring monthly';
PRINT '4. Run index maintenance monthly or when fragmentation > 10%';
PRINT '5. Update statistics weekly';
PRINT '6. Review data validation results monthly';
PRINT '7. Review security audit quarterly';
PRINT '==============================================';
