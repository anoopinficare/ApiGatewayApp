# Email Template Manager - Database Setup Scripts

This folder contains comprehensive SQL scripts for setting up and maintaining the Email Template Manager database.

## 📁 Script Files Overview

### Core Setup Scripts (Execute in Order)
1. **`01_CreateDatabase.sql`** - Creates the main database
2. **`02_CreateTables.sql`** - Creates all tables, indexes, views, and stored procedures
3. **`03_SampleData.sql`** - Inserts sample templates and test data

### Integration Scripts
4. **`04_EFMigrationEquivalent.sql`** - Entity Framework migration equivalent for existing databases
5. **`05_MaintenanceScripts.sql`** - Database maintenance, backup, and monitoring scripts

## 🚀 Quick Setup (New Database)

For a completely new database setup:

```sql
-- Execute in order:
1. 01_CreateDatabase.sql
2. 02_CreateTables.sql
3. 03_SampleData.sql (optional - for sample data)
```

## 🔄 Integration Setup (Existing Database)

For integrating into an existing database:

```sql
-- Execute this file on your existing database:
04_EFMigrationEquivalent.sql
```

## 📊 Database Schema

### Tables Created:
- **`Templates`** - Stores email templates with HTML content
- **`EmailLogs`** - Tracks all sent emails with success/failure status

### Indexes Created:
- **Performance indexes** on frequently queried columns
- **Unique index** on template names
- **Foreign key indexes** for optimal joins

### Views Created:
- **`vw_TemplateStatistics`** - Template usage statistics
- **`vw_RecentEmailActivity`** - Recent email activity overview

### Stored Procedures:
- **`sp_GetTemplateUsageStats`** - Get detailed template usage statistics
- **`sp_CleanOldEmailLogs`** - Clean up old email logs

## 🛠 Maintenance

### Regular Maintenance Tasks:
- **Daily**: Run backup scripts
- **Weekly**: Clean up old email logs
- **Monthly**: Performance monitoring and index maintenance
- **Quarterly**: Security audit

Use `05_MaintenanceScripts.sql` for all maintenance operations.

## 📋 Sample Templates Included

The sample data script includes 4 ready-to-use templates:

1. **Welcome Email** - User onboarding template
2. **Password Reset** - Secure password reset template
3. **Order Confirmation** - E-commerce order confirmation
4. **Monthly Newsletter** - Company newsletter template

## 🔧 Configuration Requirements

### Connection String Example:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=EmailTemplateManagerDB;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

### For Existing Database:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YourServer;Database=YourExistingDB;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

## 🔐 Security Considerations

- All scripts include proper error handling
- Foreign key constraints ensure data integrity
- Indexes are optimized for performance
- Backup and maintenance scripts included
- Security audit queries provided

## 📈 Performance Features

- **Optimized indexes** for all common query patterns
- **Partitioning-ready** structure for large-scale deployments
- **Statistics and monitoring** scripts included
- **Cleanup procedures** to prevent database bloat

## 🐛 Troubleshooting

### Common Issues:

1. **Permission Errors**: Ensure SQL user has CREATE DATABASE permissions
2. **Path Issues**: Update backup paths in maintenance scripts
3. **Existing Objects**: Scripts check for existing objects before creation
4. **Migration Conflicts**: Use EF migration equivalent for existing EF databases

### Verification Queries:

```sql
-- Check if tables exist
SELECT name FROM sys.tables WHERE name IN ('Templates', 'EmailLogs');

-- Check data
SELECT COUNT(*) as TemplateCount FROM Templates;
SELECT COUNT(*) as EmailLogCount FROM EmailLogs;

-- Check indexes
SELECT name, type_desc FROM sys.indexes 
WHERE object_id IN (OBJECT_ID('Templates'), OBJECT_ID('EmailLogs'));
```

## 📞 Support

For issues or questions about the database setup:
1. Review the troubleshooting section above
2. Check script output messages for specific errors
3. Verify SQL Server version compatibility
4. Ensure proper database permissions

---

**Note**: These scripts are designed for SQL Server but can be adapted for other database systems with minor modifications to data types and syntax.
