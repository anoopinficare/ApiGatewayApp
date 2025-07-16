# API Gateway Project with Sample APIs

A complete .NET Core API Gateway implementation using Ocelot middleware that routes requests to multiple downstream APIs. This project includes two sample APIs (Users and Locations) for demonstration.

## Overview

This project demonstrates how to create an API Gateway using ASP.NET Core and Ocelot. The gateway acts as a single entry point that routes requests to different downstream APIs based on the request path.

## Features

- **API Gateway**: Routes requests to downstream APIs using Ocelot
- **Sample APIs**: Two fully functional sample APIs (Users and Locations)
- **CORS Support**: Configured for cross-origin requests
- **JSON Configuration**: Easy-to-modify routing rules via `ocelot.json`
- **Comprehensive Testing**: HTTP files for testing all endpoints
- **Automated Scripts**: PowerShell and batch scripts for easy setup

## Project Structure

```
ApiGatewayApp/
├── Program.cs                     # API Gateway configuration
├── ocelot.json                   # Ocelot routing configuration
├── ApiGateway.csproj             # Gateway project file
├── ApiGateway.http               # Gateway test requests
├── Properties/
│   └── launchSettings.json       # Gateway launch settings
├── TestApis/
│   ├── UsersApi/                 # Users API (Port 5001)
│   │   ├── Program.cs
│   │   ├── UsersApi.csproj
│   │   ├── UsersApi.http         # Users API test requests
│   │   ├── Controllers/
│   │   │   └── UsersController.cs
│   │   ├── Models/
│   │   │   └── User.cs
│   │   └── Properties/
│   │       └── launchSettings.json
│   └── LocationsApi/             # Locations API (Port 5002)
│       ├── Program.cs
│       ├── LocationsApi.csproj
│       ├── LocationsApi.http     # Locations API test requests
│       ├── Controllers/
│       │   └── LocationsController.cs
│       ├── Models/
│       │   └── Location.cs
│       └── Properties/
│           └── launchSettings.json
├── scripts/
│   ├── start-all-apis.ps1        # PowerShell startup script
│   └── start-all-apis.bat        # Batch startup script
├── .github/
│   └── copilot-instructions.md   # Copilot customization
└── README.md
```

## API Configuration

### API Gateway (Port 5000)
- **Route 1**: `/api1/{everything}` → `http://localhost:5001/api/{everything}` (Users API)
- **Route 2**: `/api2/{everything}` → `http://localhost:5002/api/{everything}` (Locations API)

### Users API (Port 5001)
Endpoints:
- `GET /api/users` - Get all users
- `GET /api/users/{id}` - Get user by ID
- `GET /api/users/active` - Get active users
- `POST /api/users` - Create new user
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user
- `GET /api/users/search?firstName=&lastName=&email=` - Search users

### Locations API (Port 5002)
Endpoints:
- `GET /api/locations` - Get all locations
- `GET /api/locations/{id}` - Get location by ID
- `GET /api/locations/active` - Get active locations
- `GET /api/locations/by-city/{city}` - Get locations by city
- `GET /api/locations/by-state/{state}` - Get locations by state
- `POST /api/locations` - Create new location
- `PUT /api/locations/{id}` - Update location
- `DELETE /api/locations/{id}` - Delete location
- `GET /api/locations/search?name=&city=&state=&country=` - Search locations
- `GET /api/locations/nearby?latitude=&longitude=&radiusKm=` - Get nearby locations

## Quick Start

### Option 1: Use the Automated Script (Recommended)

**PowerShell:**
```powershell
.\scripts\start-all-apis.ps1
```

**Command Prompt:**
```cmd
scripts\start-all-apis.bat
```

This will start all three applications in the correct order.

### Option 2: Manual Start

1. **Start Users API:**
   ```bash
   cd TestApis\UsersApi
   dotnet run --urls="http://localhost:5001"
   ```

2. **Start Locations API (in new terminal):**
   ```bash
   cd TestApis\LocationsApi
   dotnet run --urls="http://localhost:5002"
   ```

3. **Start API Gateway (in new terminal):**
   ```bash
   dotnet run --urls="http://localhost:5000"
   ```

## Testing the APIs

### Via API Gateway (Recommended)
```bash
# Get all users via gateway
curl http://localhost:5000/api1/users

# Get all locations via gateway
curl http://localhost:5000/api2/locations

# Create a new user via gateway
curl -X POST http://localhost:5000/api1/users \
  -H "Content-Type: application/json" \
  -d '{"firstName":"John","lastName":"Doe","email":"john@example.com"}'
```

### Direct API Access
```bash
# Direct Users API
curl http://localhost:5001/api/users

# Direct Locations API
curl http://localhost:5002/api/locations
```

### Using HTTP Files
Use the provided `.http` files in VS Code with the REST Client extension:
- `ApiGateway.http` - Test gateway routing
- `TestApis/UsersApi/UsersApi.http` - Test Users API directly
- `TestApis/LocationsApi/LocationsApi.http` - Test Locations API directly

## Sample Data

### Users API Sample Data
```json
[
  {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "createdDate": "2025-07-05T00:00:00",
    "isActive": true
  },
  {
    "id": 2,
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@example.com",
    "createdDate": "2025-07-10T00:00:00",
    "isActive": true
  }
]
```

### Locations API Sample Data
```json
[
  {
    "id": 1,
    "name": "Central Park",
    "address": "Central Park",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "postalCode": "10024",
    "latitude": 40.7829,
    "longitude": -73.9654,
    "createdDate": "2025-06-25T00:00:00",
    "isActive": true
  }
]
```

## Development

### Building the Projects
```bash
# Build API Gateway
dotnet build ApiGateway.csproj

# Build Users API
dotnet build TestApis/UsersApi/UsersApi.csproj

# Build Locations API
dotnet build TestApis/LocationsApi/LocationsApi.csproj
```

### Adding New Routes
To add more downstream APIs, modify the `ocelot.json` file:

```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/{everything}",
      "DownstreamScheme": "http",
      "DownstreamHostAndPorts": [
        {
          "Host": "localhost",
          "Port": 5003
        }
      ],
      "UpstreamPathTemplate": "/api3/{everything}",
      "UpstreamHttpMethod": [ "GET", "POST", "PUT", "DELETE" ],
      "Key": "new-api"
    }
  ]
}
```

## Advanced Features

The current implementation can be extended with:

- **Authentication**: Add JWT or API key authentication
- **Rate Limiting**: Implement request throttling per client
- **Load Balancing**: Multiple downstream instances
- **Request/Response Transformation**: Modify requests/responses
- **Caching**: Response caching for better performance
- **Health Checks**: Monitor downstream API health
- **Logging**: Structured logging with Serilog
- **Monitoring**: Application Insights or Prometheus metrics

## Prerequisites

- .NET 9 SDK
- Visual Studio Code or Visual Studio 2022
- REST Client extension for VS Code (optional, for .http files)

## Technologies Used

- **ASP.NET Core 9**: Web framework
- **Ocelot 24.0.0**: API Gateway middleware
- **C#**: Programming language
- **Entity Framework Core**: (Ready for database integration)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test all APIs thoroughly
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 5000, 5001, and 5002 are available
2. **Gateway returns 404**: Verify downstream APIs are running
3. **CORS errors**: Check CORS configuration if accessing from a browser
4. **Build errors**: Ensure each project builds independently

### Debugging

Enable detailed logging in `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Ocelot": "Debug"
    }
  }
}
```

## Additional Resources

- [Ocelot Documentation](https://ocelot.readthedocs.io/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core/)
- [API Gateway Pattern](https://microservices.io/patterns/apigateway.html)
