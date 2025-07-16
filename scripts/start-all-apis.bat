@echo off
echo Starting Users API, Locations API, and API Gateway...
echo =============================================

REM Start Users API in a new window
echo Starting Users API on port 5001...
start "Users API" cmd /k "cd TestApis\UsersApi && dotnet run --urls=http://localhost:5001"

REM Wait for Users API to start
timeout /t 3 /nobreak >nul

REM Start Locations API in a new window
echo Starting Locations API on port 5002...
start "Locations API" cmd /k "cd TestApis\LocationsApi && dotnet run --urls=http://localhost:5002"

REM Wait for Locations API to start
timeout /t 3 /nobreak >nul

REM Display information
echo =============================================
echo All services are starting up!
echo Users API: http://localhost:5001/api/users
echo Locations API: http://localhost:5002/api/locations
echo API Gateway: http://localhost:5000
echo Gateway Users Route: http://localhost:5000/api1/users
echo Gateway Locations Route: http://localhost:5000/api2/locations
echo =============================================

REM Start API Gateway in current window
echo Starting API Gateway on port 5000...
dotnet run --urls="http://localhost:5000"
