<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# API Gateway Project Instructions

This is a .NET Core API Gateway project using Ocelot middleware to route requests to multiple downstream APIs.

## Project Structure
- Uses ASP.NET Core Web API (.NET 9)
- Implements Ocelot API Gateway for request routing
- Configured to route to two different APIs on ports 5001 and 5002
- Includes CORS support for cross-origin requests

## Key Components
- `Program.cs`: Main application configuration with Ocelot setup
- `ocelot.json`: Routing configuration for the API Gateway
- Routes `/api1/*` to downstream API on port 5001
- Routes `/api2/*` to downstream API on port 5002

## Development Guidelines
- Follow RESTful API conventions
- Use dependency injection for services
- Implement proper error handling and logging
- Consider authentication and authorization for production use
- Follow .NET coding standards and best practices

## Testing
- Test gateway routing functionality
- Verify downstream API connectivity
- Test CORS configuration
- Validate error handling scenarios
