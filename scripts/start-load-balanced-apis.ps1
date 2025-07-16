#!/usr/bin/env pwsh
# PowerShell script to start multiple instances of APIs for load balancing demo

Write-Host "Starting Multiple API Instances for Load Balancing Demo..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Yellow

# Kill any existing processes first
Get-Process -Name "UsersApi" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "LocationsApi" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Starting Users API instances..." -ForegroundColor Cyan

# Start Users API instance 1 (port 5001)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\UsersApi'; $env:ASPNETCORE_URLS='http://localhost:5001'; dotnet run" -WindowStyle Minimized
Write-Host "  - Users API instance 1 starting on port 5001" -ForegroundColor Gray

# Start Users API instance 2 (port 5011)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\UsersApi'; $env:ASPNETCORE_URLS='http://localhost:5011'; dotnet run" -WindowStyle Minimized
Write-Host "  - Users API instance 2 starting on port 5011" -ForegroundColor Gray

# Start Users API instance 3 (port 5021)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\UsersApi'; $env:ASPNETCORE_URLS='http://localhost:5021'; dotnet run" -WindowStyle Minimized
Write-Host "  - Users API instance 3 starting on port 5021" -ForegroundColor Gray

Start-Sleep -Seconds 3

Write-Host "Starting Locations API instances..." -ForegroundColor Cyan

# Start Locations API instance 1 (port 5002)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\LocationsApi'; $env:ASPNETCORE_URLS='http://localhost:5002'; dotnet run" -WindowStyle Minimized
Write-Host "  - Locations API instance 1 starting on port 5002" -ForegroundColor Gray

# Start Locations API instance 2 (port 5012)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\LocationsApi'; $env:ASPNETCORE_URLS='http://localhost:5012'; dotnet run" -WindowStyle Minimized
Write-Host "  - Locations API instance 2 starting on port 5012" -ForegroundColor Gray

# Start Locations API instance 3 (port 5022)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\LocationsApi'; $env:ASPNETCORE_URLS='http://localhost:5022'; dotnet run" -WindowStyle Minimized
Write-Host "  - Locations API instance 3 starting on port 5022" -ForegroundColor Gray

Start-Sleep -Seconds 5

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "All API instances are starting up!" -ForegroundColor Green
Write-Host ""
Write-Host "Users API Instances:" -ForegroundColor Cyan
Write-Host "  - http://localhost:5001/api/users" -ForegroundColor White
Write-Host "  - http://localhost:5011/api/users" -ForegroundColor White
Write-Host "  - http://localhost:5021/api/users" -ForegroundColor White
Write-Host ""
Write-Host "Locations API Instances:" -ForegroundColor Cyan
Write-Host "  - http://localhost:5002/api/locations" -ForegroundColor White
Write-Host "  - http://localhost:5012/api/locations" -ForegroundColor White
Write-Host "  - http://localhost:5022/api/locations" -ForegroundColor White
Write-Host ""
Write-Host "API Gateway Routes (with Load Balancing):" -ForegroundColor Yellow
Write-Host "  - http://localhost:5000/api/user/users (Round Robin)" -ForegroundColor White
Write-Host "  - http://localhost:5000/api/location/locations (Least Connection)" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Yellow

# Wait for all services to start
Write-Host "Waiting for all services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Test connectivity to all instances
Write-Host "Testing connectivity to all instances..." -ForegroundColor Yellow

$ports = @(5001, 5011, 5021, 5002, 5012, 5022)
foreach ($port in $ports) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$port/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✓ Port $port is responding" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Port $port is not responding yet" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Load Balancing Demo is ready!" -ForegroundColor Green
Write-Host "You can now test the load balancing by making multiple requests to:" -ForegroundColor White
Write-Host "  http://localhost:5000/api/user/users" -ForegroundColor Cyan
Write-Host "  http://localhost:5000/api/location/locations" -ForegroundColor Cyan
