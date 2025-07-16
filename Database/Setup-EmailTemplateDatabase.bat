@echo off
REM =============================================
REM Email Template Manager Database Setup Batch Script
REM Created: July 2025
REM Description: Batch script to setup database using SQL scripts
REM =============================================

echo ===============================================
echo Email Template Manager Database Setup Script
echo ===============================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"

REM Default settings
set "SERVER_INSTANCE=(localdb)\mssqllocaldb"
set "DATABASE_NAME=EmailTemplateManagerDB"
set "INCLUDE_SAMPLE_DATA=Y"

REM Get user input
echo Current Settings:
echo Server: %SERVER_INSTANCE%
echo Database: %DATABASE_NAME%
echo Include Sample Data: %INCLUDE_SAMPLE_DATA%
echo.

set /p "CONFIRM=Do you want to use these settings? (Y/N): "
if /i "%CONFIRM%" NEQ "Y" (
    set /p "SERVER_INSTANCE=Enter SQL Server instance (default: (localdb)\mssqllocaldb): "
    if "%SERVER_INSTANCE%"=="" set "SERVER_INSTANCE=(localdb)\mssqllocaldb"
    
    set /p "DATABASE_NAME=Enter database name (default: EmailTemplateManagerDB): "
    if "%DATABASE_NAME%"=="" set "DATABASE_NAME=EmailTemplateManagerDB"
    
    set /p "INCLUDE_SAMPLE_DATA=Include sample data? (Y/N, default: Y): "
    if "%INCLUDE_SAMPLE_DATA%"=="" set "INCLUDE_SAMPLE_DATA=Y"
)

echo.
echo Starting database setup...
echo.

REM Check if sqlcmd is available
sqlcmd -? >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: sqlcmd is not installed or not in PATH
    echo Please install SQL Server Command Line Utilities
    echo Download from: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility
    pause
    exit /b 1
)

REM Execute scripts in order
echo [1/3] Creating database...
sqlcmd -S "%SERVER_INSTANCE%" -d "master" -i "%SCRIPT_DIR%01_CreateDatabase.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create database
    pause
    exit /b 1
)
echo ✓ Database created successfully
echo.

echo [2/3] Creating tables and objects...
sqlcmd -S "%SERVER_INSTANCE%" -d "%DATABASE_NAME%" -i "%SCRIPT_DIR%02_CreateTables.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create tables
    pause
    exit /b 1
)
echo ✓ Tables created successfully
echo.

REM Include sample data if requested
if /i "%INCLUDE_SAMPLE_DATA%"=="Y" (
    echo [3/3] Inserting sample data...
    sqlcmd -S "%SERVER_INSTANCE%" -d "%DATABASE_NAME%" -i "%SCRIPT_DIR%03_SampleData.sql" -b
    if %ERRORLEVEL% NEQ 0 (
        echo WARNING: Failed to insert sample data (database is still functional)
    ) else (
        echo ✓ Sample data inserted successfully
    )
    echo.
)

echo ===============================================
echo Database setup completed successfully!
echo ===============================================
echo.
echo Database: %DATABASE_NAME%
echo Server: %SERVER_INSTANCE%
echo.
echo Connection String for appsettings.json:
echo "Server=%SERVER_INSTANCE%;Database=%DATABASE_NAME%;Trusted_Connection=true;MultipleActiveResultSets=true"
echo.
echo Next Steps:
echo 1. Update your appsettings.json with the connection string above
echo 2. Test the application with the new database
echo 3. Consider setting up regular maintenance (see 05_MaintenanceScripts.sql)
echo.

pause
