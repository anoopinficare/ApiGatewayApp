#!/usr/bin/env pwsh
# PowerShell script to test API Gateway failover scenarios

Write-Host "API Gateway Failover Testing" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Yellow

# Function to test endpoint
function Test-Gateway {
    param($url, $description)
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5
        Write-Host "✓ $description - Status: $($response.StatusCode)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ $description - Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test all instances initially
Write-Host "1. Testing all gateway instances..." -ForegroundColor Cyan
$gateway1 = Test-Gateway "http://localhost:5000/health" "Gateway 1 (Primary)"
$gateway2 = Test-Gateway "http://localhost:5100/health" "Gateway 2 (Backup 1)" 
$gateway3 = Test-Gateway "http://localhost:5200/health" "Gateway 3 (Backup 2)"

if (!$gateway1 -and !$gateway2 -and !$gateway3) {
    Write-Host "ERROR: No gateway instances are running. Please start them first." -ForegroundColor Red
    Write-Host "Run: .\scripts\start-ha-gateways.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test load balancer if available
Write-Host "2. Testing load balancer..." -ForegroundColor Cyan
$loadBalancer = Test-Gateway "http://localhost:8080/health" "Load Balancer (HAProxy/Nginx)"

Write-Host ""

# Simulate primary gateway failure
Write-Host "3. Simulating primary gateway failure..." -ForegroundColor Cyan
if ($gateway1) {
    Write-Host "Stopping primary gateway (port 5000)..." -ForegroundColor Yellow
    Get-Process | Where-Object { $_.ProcessName -eq "ApiGateway" -and $_.MainWindowTitle -match "5000" } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Start-Sleep -Seconds 5
    
    Write-Host "Testing failover..." -ForegroundColor Yellow
    if ($loadBalancer) {
        Test-Gateway "http://localhost:8080/api/user/users" "Load Balancer after primary failure"
    } else {
        Test-Gateway "http://localhost:5100/api/user/users" "Direct to Backup 1"
        Test-Gateway "http://localhost:5200/api/user/users" "Direct to Backup 2"
    }
}

Write-Host ""

# Continuous testing
Write-Host "4. Continuous availability test (30 seconds)..." -ForegroundColor Cyan
Write-Host "Making requests every 2 seconds to test availability..." -ForegroundColor Gray

$successCount = 0
$totalRequests = 15

for ($i = 1; $i -le $totalRequests; $i++) {
    $testUrl = if ($loadBalancer) { "http://localhost:8080/health" } else { "http://localhost:5100/health" }
    
    Write-Host "Request $i/$totalRequests..." -ForegroundColor Gray -NoNewline
    
    if (Test-Gateway $testUrl "Test") {
        $successCount++
        Write-Host " SUCCESS" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "============================" -ForegroundColor Yellow
Write-Host "Failover Test Results:" -ForegroundColor Green
Write-Host "Success Rate: $successCount/$totalRequests ($([math]::Round(($successCount/$totalRequests)*100, 2))%)" -ForegroundColor White

if ($successCount -eq $totalRequests) {
    Write-Host "✓ EXCELLENT: 100% availability maintained during failover!" -ForegroundColor Green
} elseif ($successCount -ge ($totalRequests * 0.9)) {
    Write-Host "✓ GOOD: >90% availability maintained" -ForegroundColor Yellow
} else {
    Write-Host "✗ POOR: <90% availability - review configuration" -ForegroundColor Red
}

Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "- Use multiple gateway instances across different servers" -ForegroundColor White
Write-Host "- Implement health checks with automatic failover" -ForegroundColor White
Write-Host "- Monitor gateway performance and availability" -ForegroundColor White
Write-Host "- Use container orchestration (Kubernetes) for production" -ForegroundColor White
