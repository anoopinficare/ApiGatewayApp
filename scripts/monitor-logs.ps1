# API Gateway Log Monitor Script
# This script helps you monitor the API Gateway logs in real-time

param(
    [string]$LogType = "requests"  # Options: "requests", "ocelot", "all"
)

$today = Get-Date -Format "yyyy-MM-dd"
$logPath = "bin\Debug\net9.0\logs"

switch ($LogType.ToLower()) {
    "requests" {
        $fileName = "$logPath\requests-$today.log"
        Write-Host "📋 Monitoring Request/Response logs..." -ForegroundColor Green
    }
    "ocelot" {
        $fileName = "$logPath\ocelot-$today.log"
        Write-Host "🔧 Monitoring Ocelot routing logs..." -ForegroundColor Yellow
    }
    "all" {
        $fileName = "$logPath\api-gateway-$today.log"
        Write-Host "📊 Monitoring All application logs..." -ForegroundColor Blue
    }
    default {
        $fileName = "$logPath\requests-$today.log"
        Write-Host "📋 Monitoring Request/Response logs..." -ForegroundColor Green
    }
}

if (-not (Test-Path $fileName)) {
    Write-Host "❌ Log file not found: $fileName" -ForegroundColor Red
    Write-Host "💡 Make sure the API Gateway is running and has processed some requests." -ForegroundColor Yellow
    exit 1
}

Write-Host "👁️  Watching: $fileName" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring`n" -ForegroundColor Gray

try {
    Get-Content $fileName -Wait -Tail 10
}
catch {
    Write-Host "❌ Error monitoring logs: $_" -ForegroundColor Red
}
