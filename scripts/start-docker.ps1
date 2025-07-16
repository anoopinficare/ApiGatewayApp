# Docker Commands for API Gateway
# Run this script to build and start the API Gateway in Docker

Write-Host "API Gateway Docker Setup" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

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
docker-compose -f docker-compose.simple.yml down --remove-orphans

Write-Host "`nStep 2: Building Docker images..." -ForegroundColor Cyan
docker-compose -f docker-compose.simple.yml build --no-cache

Write-Host "`nStep 3: Starting services..." -ForegroundColor Cyan
docker-compose -f docker-compose.simple.yml up -d

Write-Host "`nStep 4: Checking service status..." -ForegroundColor Cyan
Start-Sleep -Seconds 10
docker-compose -f docker-compose.simple.yml ps

Write-Host "`nStep 5: Showing logs..." -ForegroundColor Cyan
docker-compose -f docker-compose.simple.yml logs --tail=20

Write-Host "`nAPI Gateway is now running!" -ForegroundColor Green
Write-Host "Access the API Gateway at: http://localhost:8080" -ForegroundColor Yellow
Write-Host "Test endpoints:" -ForegroundColor Yellow
Write-Host "  - Health Check: http://localhost:8080/health" -ForegroundColor White
Write-Host "  - Users API: http://localhost:8080/api/user/users" -ForegroundColor White
Write-Host "  - Locations API: http://localhost:8080/api/location/locations" -ForegroundColor White
Write-Host "`nTo stop the services, run:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.simple.yml down" -ForegroundColor White
