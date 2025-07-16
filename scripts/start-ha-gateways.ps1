#!/usr/bin/env pwsh
# PowerShell script to start multiple API Gateway instances for high availability

Write-Host "Starting High Availability API Gateway Setup..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Yellow

# Kill any existing gateway processes
Get-Process -Name "ApiGateway" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

Write-Host "Starting multiple API Gateway instances..." -ForegroundColor Cyan

# Start Gateway Instance 1 (Primary) - Port 5000
Write-Host "  - Starting Gateway Instance 1 (Primary) on port 5000..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd .; $env:ASPNETCORE_URLS='http://localhost:5000'; dotnet run" -WindowStyle Minimized

Start-Sleep -Seconds 3

# Start Gateway Instance 2 (Backup) - Port 5100  
Write-Host "  - Starting Gateway Instance 2 (Backup) on port 5100..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd .; $env:ASPNETCORE_URLS='http://localhost:5100'; dotnet run" -WindowStyle Minimized

Start-Sleep -Seconds 3

# Start Gateway Instance 3 (Backup) - Port 5200
Write-Host "  - Starting Gateway Instance 3 (Backup) on port 5200..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd .; $env:ASPNETCORE_URLS='http://localhost:5200'; dotnet run" -WindowStyle Minimized

Write-Host ""
Write-Host "Waiting for all gateway instances to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Test all instances
Write-Host "Testing gateway instances..." -ForegroundColor Yellow
$ports = @(5000, 5100, 5200)
foreach ($port in $ports) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$port/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✓ Gateway on port $port is healthy (Status: $($response.StatusCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Gateway on port $port is not responding" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "High Availability API Gateway Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Gateway Instances:" -ForegroundColor Cyan
Write-Host "  - Primary:  http://localhost:5000/health" -ForegroundColor White
Write-Host "  - Backup 1: http://localhost:5100/health" -ForegroundColor White  
Write-Host "  - Backup 2: http://localhost:5200/health" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure a load balancer (HAProxy/Nginx) on port 8080" -ForegroundColor White
Write-Host "  2. Point clients to http://localhost:8080 instead of individual instances" -ForegroundColor White
Write-Host "  3. Test failover by stopping one instance at a time" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Yellow
