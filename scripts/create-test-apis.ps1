# PowerShell script to create and run test downstream APIs

# Create TestApi1 on port 5001
Write-Host "Creating TestApi1..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "TestApi1"
Set-Location "TestApi1"
dotnet new webapi -n TestApi1 --no-https
Set-Location "TestApi1"

# Create custom launch settings for port 5001
$launchSettings1 = @"
{
  "`$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://localhost:5001",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
"@

$launchSettings1 | Out-File -FilePath "Properties\launchSettings.json" -Encoding UTF8

Set-Location "..\..\"

# Create TestApi2 on port 5002
Write-Host "Creating TestApi2..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "TestApi2"
Set-Location "TestApi2"
dotnet new webapi -n TestApi2 --no-https
Set-Location "TestApi2"

# Create custom launch settings for port 5002
$launchSettings2 = @"
{
  "`$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://localhost:5002",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
"@

$launchSettings2 | Out-File -FilePath "Properties\launchSettings.json" -Encoding UTF8

Set-Location "..\..\"

Write-Host "Test APIs created successfully!" -ForegroundColor Green
Write-Host "To run TestApi1: cd TestApi1\TestApi1 && dotnet run" -ForegroundColor Yellow
Write-Host "To run TestApi2: cd TestApi2\TestApi2 && dotnet run" -ForegroundColor Yellow
Write-Host "To run API Gateway: dotnet run" -ForegroundColor Cyan
