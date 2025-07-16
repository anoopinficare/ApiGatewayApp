# Docker Commands for API Gateway with Load Balancing
# Run this script to build and start the full load-balanced API Gateway setup

Write-Host "API Gateway Load Balanced Docker Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Function to wait for Docker to be ready
function Wait-ForDocker {
    Write-Host "Waiting for Docker to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    
    do {
        try {
            docker version | Out-Null
            Write-Host "Docker is ready!" -ForegroundColor Green
            return $true
        }
        catch {
            $attempt++
            if ($attempt -ge $maxAttempts) {
                Write-Host "Docker failed to start after $maxAttempts attempts" -ForegroundColor Red
                return $false
            }
            Write-Host "Attempt $attempt/$maxAttempts - Docker not ready yet..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    } while ($true)
}

# Wait for Docker to be ready
if (!(Wait-ForDocker)) {
    Write-Host "Please start Docker Desktop and run this script again" -ForegroundColor Red
    exit 1
}

# Set location to the project directory
Set-Location "d:\projects\ApiGatewayApp"

Write-Host "`nStep 1: Cleaning up existing containers..." -ForegroundColor Cyan
docker-compose down --remove-orphans

Write-Host "`nStep 2: Building Docker images..." -ForegroundColor Cyan
docker-compose build --no-cache

Write-Host "`nStep 3: Starting load-balanced services..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "`nStep 4: Waiting for services to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

Write-Host "`nStep 5: Checking service status..." -ForegroundColor Cyan
docker-compose ps

Write-Host "`nStep 6: Showing logs..." -ForegroundColor Cyan
docker-compose logs --tail=10

Write-Host "`nLoad Balanced API Gateway is now running!" -ForegroundColor Green
Write-Host "Services running:" -ForegroundColor Yellow
Write-Host "  - API Gateway: http://localhost:8080" -ForegroundColor White
Write-Host "  - Users API (primary): http://localhost:5001" -ForegroundColor White  
Write-Host "  - Locations API (primary): http://localhost:5002" -ForegroundColor White
Write-Host "  - Load balanced instances running internally" -ForegroundColor White
Write-Host "`nTest endpoints through gateway:" -ForegroundColor Yellow
Write-Host "  - Health Check: http://localhost:8080/health" -ForegroundColor White
Write-Host "  - Users API: http://localhost:8080/api/user/users" -ForegroundColor White
Write-Host "  - Locations API: http://localhost:8080/api/location/locations" -ForegroundColor White
Write-Host "`nTo stop all services, run:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor White
