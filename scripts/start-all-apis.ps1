# PowerShell script to start all APIs and the Gateway

Write-Host "Starting Users API, Locations API, and API Gateway..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Yellow

# Start Users API in the background
Write-Host "Starting Users API on port 5001..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\UsersApi'; dotnet run --urls='http://localhost:5001'" -WindowStyle Minimized

# Wait a moment for the first API to start
Start-Sleep -Seconds 3

# Start Locations API in the background
Write-Host "Starting Locations API on port 5002..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'TestApis\LocationsApi'; dotnet run --urls='http://localhost:5002'" -WindowStyle Minimized

# Wait a moment for the second API to start
Start-Sleep -Seconds 3

# Start API Gateway
Write-Host "Starting API Gateway on port 5000..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "All services starting up!" -ForegroundColor Green
Write-Host "Users API: http://localhost:5001/api/users" -ForegroundColor Yellow
Write-Host "Locations API: http://localhost:5002/api/locations" -ForegroundColor Yellow
Write-Host "API Gateway: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Gateway Users Route: http://localhost:5000/api1/users" -ForegroundColor Magenta
Write-Host "Gateway Locations Route: http://localhost:5000/api2/locations" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Yellow

# Start the API Gateway (this will run in the current window)
dotnet run --urls="http://localhost:5000"
