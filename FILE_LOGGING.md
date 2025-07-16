# 📁 File Logging Feature

## Overview
The API Gateway now supports **both console and file logging** for comprehensive monitoring and debugging.

## Log Files Created
When you run the API Gateway, three types of log files are automatically created in `bin\Debug\net9.0\logs\`:

### 📋 All Application Logs
**File:** `api-gateway-{date}.log`
- Contains all application logs (INFO level and above)
- Includes startup, requests, responses, Ocelot routing, and errors
- Perfect for comprehensive troubleshooting

### 🔧 Ocelot Routing Logs  
**File:** `ocelot-{date}.log`
- Contains only Ocelot-specific routing and pipeline logs
- Shows route discovery, URL transformation, authentication checks
- Ideal for debugging routing issues

### 🌐 Request/Response Logs
**File:** `requests-{date}.log`
- Contains only custom request/response middleware logs
- Clean view of incoming requests and outgoing responses
- Great for API monitoring and performance analysis

## Quick Start

1. **Start the API Gateway:**
   ```bash
   dotnet run --urls "http://localhost:5003"
   ```

2. **Make some requests to generate logs:**
   ```bash
   Invoke-WebRequest -Uri "http://localhost:5003/api/user/users" -Method GET
   ```

3. **Check the log files:**
   ```bash
   # View request/response logs
   notepad "bin\Debug\net9.0\logs\requests-2025-07-15.log"
   
   # View Ocelot routing logs
   notepad "bin\Debug\net9.0\logs\ocelot-2025-07-15.log"
   
   # View all logs
   notepad "bin\Debug\net9.0\logs\api-gateway-2025-07-15.log"
   ```

## Live Monitoring

Use our PowerShell script to monitor logs in real-time:

```bash
# Monitor request/response logs (default)
.\scripts\monitor-logs.ps1

# Monitor Ocelot routing logs  
.\scripts\monitor-logs.ps1 -LogType ocelot

# Monitor all logs
.\scripts\monitor-logs.ps1 -LogType all
```

## Sample Log Contents

### requests-{date}.log
```
2025-07-15 06:25:15.6304 === Incoming Request ===
2025-07-15 06:25:15.6304 Method: GET
2025-07-15 06:25:15.6304 Path: /api/user/users
2025-07-15 06:25:15.6304 Headers: Host=localhost:5003, User-Agent=...
2025-07-15 06:25:15.7208 === Outgoing Response ===
2025-07-15 06:25:15.7208 StatusCode: 200
2025-07-15 06:25:15.7208 Headers: Content-Type=application/json...
```

### ocelot-{date}.log
```
2025-07-15 06:25:15.6445 DEBUG Upstream URL path: /api/user/users
2025-07-15 06:25:15.6598 DEBUG Downstream templates: /api/{everything}
2025-07-15 06:25:15.6731 DEBUG Downstream URL: http://localhost:5001/api/users
2025-07-15 06:25:15.7147 INFO 200 OK status code of request URI: http://localhost:5001/api/users
```

## Benefits

- ✅ **Persistent** - Logs survive application restarts
- ✅ **Daily Rotation** - New files created automatically each day  
- ✅ **Separated by Concern** - Different files for different log types
- ✅ **Easy Analysis** - Use text editors, log analyzers, or scripts
- ✅ **Production Ready** - Suitable for monitoring and troubleshooting
- ✅ **Console + Files** - Best of both worlds for development and production

## Technical Details

- **Framework:** NLog with ASP.NET Core logging
- **Rotation:** Daily rotation with `{shortdate}` pattern
- **Format:** Structured logging with timestamps and log levels
- **Configuration:** `nlog.config` file with multiple targets and rules

For complete logging documentation, see [LOGGING_GUIDE.md](LOGGING_GUIDE.md).
