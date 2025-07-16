# Database Setup Scripts for Email Template Manager

## PowerShell Scripts for Automated Database Setup

### Setup-EmailTemplateDatabase.ps1
# PowerShell script to automatically execute all database setup scripts

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerInstance = "(localdb)\mssqllocaldb",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "EmailTemplateManagerDB",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSampleData = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseExistingDatabase = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ExistingDatabaseName = ""
)

Write-Host "===============================================" -ForegroundColor Green
Write-Host "Email Template Manager Database Setup Script" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to execute SQL script
function Execute-SqlScript {
    param(
        [string]$ScriptPath,
        [string]$Server,
        [string]$Database = "master"
    )
    
    try {
        Write-Host "Executing: $([System.IO.Path]::GetFileName($ScriptPath))" -ForegroundColor Yellow
        
        if (Get-Command "sqlcmd" -ErrorAction SilentlyContinue) {
            # Use sqlcmd if available
            sqlcmd -S $Server -d $Database -i $ScriptPath -b
        } else {
            # Use Invoke-Sqlcmd if SqlServer module is available
            Import-Module SqlServer -ErrorAction Stop
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -InputFile $ScriptPath
        }
        
        Write-Host "✓ Completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution logic
try {
    if ($UseExistingDatabase) {
        # Use existing database
        if ([string]::IsNullOrEmpty($ExistingDatabaseName)) {
            $ExistingDatabaseName = Read-Host "Enter existing database name"
        }
        
        Write-Host "Setting up Email Template Manager in existing database: $ExistingDatabaseName" -ForegroundColor Cyan
        
        # Execute EF Migration equivalent script
        $success = Execute-SqlScript -ScriptPath "$ScriptDir\04_EFMigrationEquivalent.sql" -Server $ServerInstance -Database $ExistingDatabaseName
        
        if ($success -and $IncludeSampleData) {
            # Update sample data script to use existing database
            $sampleDataScript = Get-Content "$ScriptDir\03_SampleData.sql" -Raw
            $sampleDataScript = $sampleDataScript -replace "USE \[EmailTemplateManagerDB\];", "USE [$ExistingDatabaseName];"
            $tempScript = "$env:TEMP\SampleData_Modified.sql"
            $sampleDataScript | Out-File -FilePath $tempScript -Encoding UTF8
            
            Execute-SqlScript -ScriptPath $tempScript -Server $ServerInstance -Database $ExistingDatabaseName
            Remove-Item $tempScript -Force
        }
    } else {
        # Create new database
        Write-Host "Creating new database: $DatabaseName" -ForegroundColor Cyan
        
        # Execute scripts in order
        $scripts = @(
            "$ScriptDir\01_CreateDatabase.sql",
            "$ScriptDir\02_CreateTables.sql"
        )
        
        if ($IncludeSampleData) {
            $scripts += "$ScriptDir\03_SampleData.sql"
        }
        
        foreach ($script in $scripts) {
            if (Test-Path $script) {
                $dbToUse = if ($script -like "*01_CreateDatabase.sql") { "master" } else { $DatabaseName }
                $success = Execute-SqlScript -ScriptPath $script -Server $ServerInstance -Database $dbToUse
                
                if (-not $success) {
                    throw "Failed to execute $script"
                }
            } else {
                Write-Warning "Script not found: $script"
            }
        }
    }
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "Database setup completed successfully!" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    
    if ($UseExistingDatabase) {
        Write-Host "Database: $ExistingDatabaseName" -ForegroundColor Cyan
    } else {
        Write-Host "Database: $DatabaseName" -ForegroundColor Cyan
    }
    Write-Host "Server: $ServerInstance" -ForegroundColor Cyan
    
    # Display next steps
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Update your appsettings.json with the connection string" -ForegroundColor White
    Write-Host "2. Test the application with the new database" -ForegroundColor White
    Write-Host "3. Consider setting up regular maintenance (see 05_MaintenanceScripts.sql)" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Red
    Write-Host "Database setup failed!" -ForegroundColor Red
    Write-Host "===============================================" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure SQL Server is running" -ForegroundColor White
    Write-Host "2. Verify connection string and permissions" -ForegroundColor White
    Write-Host "3. Check if sqlcmd or SqlServer PowerShell module is installed" -ForegroundColor White
    Write-Host "4. Run scripts manually if needed" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
