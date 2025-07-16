@echo off
echo Creating Test APIs for API Gateway...

REM Create TestApi1 on port 5001
echo Creating TestApi1...
mkdir TestApi1 2>nul
cd TestApi1
dotnet new webapi -n TestApi1 --no-https
cd TestApi1

REM Create custom launch settings for port 5001
(
echo {
echo   "$schema": "https://json.schemastore.org/launchsettings.json",
echo   "profiles": {
echo     "http": {
echo       "commandName": "Project",
echo       "dotnetRunMessages": true,
echo       "launchBrowser": false,
echo       "applicationUrl": "http://localhost:5001",
echo       "environmentVariables": {
echo         "ASPNETCORE_ENVIRONMENT": "Development"
echo       }
echo     }
echo   }
echo }
) > Properties\launchSettings.json

cd ..\..

REM Create TestApi2 on port 5002
echo Creating TestApi2...
mkdir TestApi2 2>nul
cd TestApi2
dotnet new webapi -n TestApi2 --no-https
cd TestApi2

REM Create custom launch settings for port 5002
(
echo {
echo   "$schema": "https://json.schemastore.org/launchsettings.json",
echo   "profiles": {
echo     "http": {
echo       "commandName": "Project",
echo       "dotnetRunMessages": true,
echo       "launchBrowser": false,
echo       "applicationUrl": "http://localhost:5002",
echo       "environmentVariables": {
echo         "ASPNETCORE_ENVIRONMENT": "Development"
echo       }
echo     }
echo   }
echo }
) > Properties\launchSettings.json

cd ..\..

echo.
echo Test APIs created successfully!
echo To run TestApi1: cd TestApi1\TestApi1 ^&^& dotnet run
echo To run TestApi2: cd TestApi2\TestApi2 ^&^& dotnet run
echo To run API Gateway: dotnet run
pause
