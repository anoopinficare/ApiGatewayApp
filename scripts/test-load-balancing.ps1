#!/usr/bin/env pwsh
# PowerShell script to test load balancing

Write-Host "Testing Load Balancing..." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow

# Test Users API (Round Robin)
Write-Host "Testing Users API Load Balancing (Round Robin):" -ForegroundColor Cyan
for ($i = 1; $i -le 6; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/user/users" -Method GET -TimeoutSec 10
        $serverHeader = $response.Headers['Server']
        $dateHeader = $response.Headers['Date']
        Write-Host "  Request $i - Status: $($response.StatusCode), Server: $serverHeader" -ForegroundColor White
        
        # Small delay to see load balancing in action
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Host "  Request $i - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test Locations API (Least Connection)
Write-Host "Testing Locations API Load Balancing (Least Connection):" -ForegroundColor Cyan
for ($i = 1; $i -le 6; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/location/locations" -Method GET -TimeoutSec 10
        $serverHeader = $response.Headers['Server']
        $dateHeader = $response.Headers['Date']
        Write-Host "  Request $i - Status: $($response.StatusCode), Server: $serverHeader" -ForegroundColor White
        
        # Small delay to see load balancing in action
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Host "  Request $i - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Load Balancing Test Complete!" -ForegroundColor Green
Write-Host "Check the API Gateway logs to see which downstream instances were called." -ForegroundColor Yellow
