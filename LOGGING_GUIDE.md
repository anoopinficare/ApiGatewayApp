# API Gateway Logging Configuration Guide

## Overview
The API Gateway has comprehensive logging enabled to help with debugging, monitoring, and troubleshooting.

## 🔍 WHERE TO CHECK LOGS

### 1. **Console/Terminal Output (Primary Location)**
The logs appear **directly in the terminal window** where you started the API Gateway:

```bash
# Start the API Gateway and watch logs in real-time
cd "d:\projects\ApiGatewayApp"
dotnet run --urls "http://localhost:5003"
```

**What you'll see:**
- Real-time log output as requests come in
- Timestamps with log levels (info, dbug, trce, warn, etc.)
- Request/response details
- Ocelot pipeline execution steps

### 2. **VS Code Terminal Tab**
If running from VS Code:
- Look at the **Terminal** tab at the bottom
- The terminal where you ran `dotnet run`
- Logs appear immediately when requests are made

### 3. **PowerShell/Command Prompt Window**
If running from external terminal:
- Check the PowerShell or Command Prompt window where you started the gateway
- Logs stream continuously as the application runs

### 4. **Log Files (NEW!)**
Logs are now also written to **text files** in addition to console output:

**📁 File Locations:**
- `bin\Debug\net9.0\logs\api-gateway-{date}.log` - All application logs
- `bin\Debug\net9.0\logs\ocelot-{date}.log` - Ocelot-specific logs only  
- `bin\Debug\net9.0\logs\requests-{date}.log` - Request/Response logs only

**📅 Daily Rotation:** New files are created each day automatically

### 5. **How to See Live Logs**
1. **Start the API Gateway:**
   ```bash
   dotnet run --urls "http://localhost:5003"
   ```
2. **Make a request to trigger logs:**
   ```bash
   Invoke-WebRequest -Uri "http://localhost:5003/api/user/users" -Method GET
   ```
3. **Watch the terminal** - logs appear instantly!

## Logging Levels Configured

### Development Environment (`appsettings.Development.json`)
- **Default**: Debug
- **Ocelot Components**: Trace (most detailed)
- **ASP.NET Core**: Information
- **HTTP Client**: Debug
- **Routing**: Debug

### Production Environment (`appsettings.json`)
- **Default**: Information
- **Ocelot Components**: Debug
- **ASP.NET Core**: Warning

## What Gets Logged

### 1. Custom Request/Response Logging
Our custom middleware logs:
- **Incoming Requests**: Method, Path, Query String, Headers
- **Outgoing Responses**: Status Code, Headers
- Request identifiers for correlation

### 2. Ocelot Pipeline Logging
- Route discovery and matching
- Downstream URL creation
- Authentication and authorization checks
- Rate limiting decisions
- Request forwarding to downstream services
- Response handling

### 3. ASP.NET Core Framework Logging
- Request start/finish times
- Pipeline middleware execution
- Error handling

## � **File Logging (NEW!)**

### **Log File Locations**
When you run the API Gateway, logs are automatically written to these files:

1. **�📋 All Logs:** `bin\Debug\net9.0\logs\api-gateway-2025-07-15.log`
   - Contains all application logs (INFO level and above)
   - Includes startup, requests, responses, and errors

2. **🔧 Ocelot Logs:** `bin\Debug\net9.0\logs\ocelot-2025-07-15.log`  
   - Contains only Ocelot routing and pipeline logs
   - Perfect for debugging routing issues

3. **🌐 Request/Response Logs:** `bin\Debug\net9.0\logs\requests-2025-07-15.log`
   - Contains only our custom request/response middleware logs
   - Clean view of incoming requests and outgoing responses

### **Sample File Contents**

**requests-2025-07-15.log:**
```
2025-07-15 06:25:15.6304 === Incoming Request ===
2025-07-15 06:25:15.6304 Method: GET
2025-07-15 06:25:15.6304 Path: /api/user/users
2025-07-15 06:25:15.6304 Headers: Host=localhost:5003, User-Agent=...
2025-07-15 06:25:15.7208 === Outgoing Response ===
2025-07-15 06:25:15.7208 StatusCode: 200
2025-07-15 06:25:15.7208 Headers: Content-Type=application/json...
```

**ocelot-2025-07-15.log:**
```
2025-07-15 06:25:15.6445 DEBUG Upstream URL path: /api/user/users
2025-07-15 06:25:15.6598 DEBUG Downstream templates: /api/{everything}
2025-07-15 06:25:15.6731 DEBUG Downstream URL: http://localhost:5001/api/users
2025-07-15 06:25:15.7147 INFO 200 OK status code of request URI: http://localhost:5001/api/users
```

### **File Benefits**
- ✅ **Persistent** - Logs survive application restarts
- ✅ **Daily rotation** - New files created automatically each day
- ✅ **Separated by concern** - Different files for different log types
- ✅ **Easy analysis** - Can use text editors, log analyzers, or scripts
- ✅ **Production ready** - Suitable for monitoring and troubleshooting

### **How to View Files**
```bash
# View all logs
notepad "bin\Debug\net9.0\logs\api-gateway-2025-07-15.log"

# View only Ocelot routing logs  
notepad "bin\Debug\net9.0\logs\ocelot-2025-07-15.log"

# View only request/response logs
notepad "bin\Debug\net9.0\logs\requests-2025-07-15.log"

# Monitor logs in real-time (PowerShell)
Get-Content "bin\Debug\net9.0\logs\requests-2025-07-15.log" -Wait
```

When you make a request to `GET http://localhost:5003/api/user/users`, you'll see logs like this in your **terminal/console**:

```
2025-07-15 06:20:04.750 info: Program[0]
      === Incoming Request ===
2025-07-15 06:20:04.750 info: Program[0]
      Method: GET
2025-07-15 06:20:04.750 info: Program[0]
      Path: /api/user/users
2025-07-15 06:20:04.750 info: Program[0]
      Headers: Host=localhost:5003, User-Agent=...

2025-07-15 06:20:04.753 dbug: Ocelot.DownstreamRouteFinder.Middleware
      Upstream URL path: /api/user/users
2025-07-15 06:20:04.758 dbug: Ocelot.DownstreamRouteFinder.Middleware
      Downstream templates: /api/{everything}
2025-07-15 06:20:04.760 dbug: Ocelot.DownstreamUrlCreator.Middleware
      Downstream URL: http://localhost:5001/api/users
2025-07-15 06:20:04.771 info: Ocelot.Requester.Middleware.HttpRequesterMiddleware
      200 OK status code of request URI: http://localhost:5001/api/users

2025-07-15 06:20:04.783 info: Program[0]
      === Outgoing Response ===
2025-07-15 06:20:04.783 info: Program[0]
      StatusCode: 200
2025-07-15 06:20:04.783 info: Program[0]
      Headers: Content-Type=application/json; charset=utf-8, ...
```

## 💡 Quick Tips for Reading Logs

### **Look for these key patterns:**
- `=== Incoming Request ===` - Start of a new request
- `Upstream URL path:` - The path that came into the gateway
- `Downstream URL:` - Where the gateway forwarded the request
- `200 OK status code` - Successful request
- `404 Not Found status code` - Failed request
- `=== Outgoing Response ===` - End of request processing

## Key Log Messages to Watch

### Successful Routing
- `Upstream URL path: /api/user/users`
- `Downstream URL: http://localhost:5001/api/users`
- `200 OK status code of request URI: ...`

### Route Not Found
- `404 Not Found status code of request URI: ...`
- Check if upstream path matches your ocelot.json configuration

### Authentication/Authorization
- `No authentication needed for path: ...`
- `No authorization needed for upstream path: ...`

### Rate Limiting
- `EnableEndpointEndpointRateLimiting is not enabled for downstream path: ...`

## Configuration Files

### **File Logging Configuration**
The file logging is configured using **NLog** with the following setup:

**nlog.config:**
```xml
<?xml version="1.0" encoding="utf-8" ?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd">
  <targets>
    <!-- All logs file -->
    <target xsi:type="File" 
            name="allfile" 
            fileName="logs/api-gateway-${shortdate}.log"
            layout="${longdate} ${uppercase:${level}} ${logger} ${message}" />
    
    <!-- Ocelot-specific logs -->
    <target xsi:type="File" 
            name="ocelotfile" 
            fileName="logs/ocelot-${shortdate}.log" />
    
    <!-- Request/response logs -->
    <target xsi:type="File" 
            name="requestfile" 
            fileName="logs/requests-${shortdate}.log" />
  </targets>
  
  <rules>
    <logger name="*" minlevel="Information" writeTo="allfile" />
    <logger name="Ocelot*" minlevel="Debug" writeTo="ocelotfile" />
    <logger name="Program" minlevel="Information" writeTo="requestfile" />
  </rules>
</nlog>
```

**Program.cs changes:**
```csharp
using NLog.Extensions.Logging;

// Configure detailed logging with file output
builder.Logging.ClearProviders();
builder.Logging.AddConsole();      // Keep console output
builder.Logging.AddDebug();
builder.Logging.AddNLog();         // Add file logging
```

### **Logging Configuration (appsettings.json)**
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Ocelot": "Debug",
      "Ocelot.Requester": "Debug",
      "Ocelot.DownstreamRouteFinder": "Debug"
    }
  }
}
```

### `/appsettings.Development.json`
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Ocelot": "Trace",
      "Ocelot.Requester": "Trace"
    }
  }
}
```

### Custom Middleware in `Program.cs`
```csharp
app.Use(async (context, next) =>
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    
    logger.LogInformation("=== Incoming Request ===");
    logger.LogInformation("Method: {Method}", context.Request.Method);
    logger.LogInformation("Path: {Path}", context.Request.Path);
    // ... more logging
    
    await next();
    
    logger.LogInformation("=== Outgoing Response ===");
    logger.LogInformation("StatusCode: {StatusCode}", context.Response.StatusCode);
    // ... more logging
});
```

## Troubleshooting with Logs

### Problem: 404 Not Found
**Look for**: 
- `Upstream URL path: /your/path`
- `Downstream templates: /api/{everything}`
- Check if your request path matches the `UpstreamPathTemplate` in ocelot.json

### Problem: Downstream Service Not Responding
**Look for**:
- `Downstream URL: http://localhost:5001/...`
- Connection errors or timeouts
- Verify downstream service is running on the correct port

### Problem: Route Not Matching
**Look for**:
- Route discovery messages
- Template matching information
- Check your ocelot.json configuration

## Log Levels Reference

- **Trace**: Most detailed, includes step-by-step execution
- **Debug**: Detailed information for debugging
- **Information**: General information about application flow
- **Warning**: Potentially harmful situations
- **Error**: Error events that might still allow the application to continue
- **Critical**: Very serious error events

### **🚀 Quick Log Monitoring Script**
Use our PowerShell script to monitor logs in real-time:

```bash
# Monitor request/response logs
.\scripts\monitor-logs.ps1

# Monitor Ocelot routing logs  
.\scripts\monitor-logs.ps1 -LogType ocelot

# Monitor all logs
.\scripts\monitor-logs.ps1 -LogType all
```

## 🚫 **Current Limitations & Notes**

### **Console vs Files**
- **Console**: Shows real-time logs with full detail (including TRACE level)
- **Files**: Shows INFO level and above, formatted for easy reading

### **File Location**
- Log files are created in `bin\Debug\net9.0\logs\` (output directory)
- **Not** in the project root `logs\` folder

### **Daily Rotation**
- New files created automatically each day: `api-gateway-2025-07-15.log`
- Previous days' logs are preserved

### **Production Considerations**
- In production, consider log retention policies
- Monitor disk space usage for log files
- Consider using log aggregation tools for multiple instances

## ✅ **Summary**

Your API Gateway now has **comprehensive logging**:

1. **✅ Console Output** - Real-time logs while developing
2. **✅ File Logging** - Persistent logs separated by concern
3. **✅ Daily Rotation** - Automatic file management  
4. **✅ Multiple Formats** - Choose the right log for your needs
5. **✅ Production Ready** - Suitable for monitoring and troubleshooting

**Log Files Created:**
- 📋 `api-gateway-{date}.log` - All logs
- 🔧 `ocelot-{date}.log` - Routing logs only
- 🌐 `requests-{date}.log` - Request/response logs only

Perfect for debugging routing issues, monitoring performance, and troubleshooting problems!
