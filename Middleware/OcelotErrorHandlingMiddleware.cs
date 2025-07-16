using Ocelot.Errors;
using System.Net;
using System.Text.Json;

namespace ApiGateway.Middleware
{
    public class OcelotErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<OcelotErrorHandlingMiddleware> _logger;

        public OcelotErrorHandlingMiddleware(RequestDelegate next, ILogger<OcelotErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            await _next(context);

            // Handle Ocelot errors after the pipeline has executed
            if (context.Items.TryGetValue("OcelotErrors", out var errorsObj) && errorsObj is List<Error> errors && errors.Any())
            {
                await HandleOcelotErrors(context, errors);
            }
        }

        private async Task HandleOcelotErrors(HttpContext context, List<Error> errors)
        {
            var primaryError = errors.First();
            
            _logger.LogError("Ocelot error occurred: {ErrorCode} - {ErrorMessage}. TraceId: {TraceId}", 
                primaryError.Code, primaryError.Message, context.TraceIdentifier);

            var response = new ErrorResponse
            {
                TraceId = context.TraceIdentifier
            };

            // Map Ocelot error codes and messages to HTTP status codes and user-friendly messages
            switch (primaryError.Code)
            {
                case OcelotErrorCode.DownstreamPathNullOrEmptyError:
                    response.StatusCode = (int)HttpStatusCode.InternalServerError;
                    response.Message = "Route configuration error";
                    response.Details = "The requested route is not properly configured";
                    break;

                case OcelotErrorCode.UnableToFindDownstreamRouteError:
                    response.StatusCode = (int)HttpStatusCode.NotFound;
                    response.Message = "Route not found";
                    response.Details = "The requested endpoint does not exist";
                    break;

                case OcelotErrorCode.RequestTimedOutError:
                    response.StatusCode = (int)HttpStatusCode.RequestTimeout;
                    response.Message = "Request timeout";
                    response.Details = "The downstream service did not respond in time";
                    break;

                case OcelotErrorCode.ConnectionToDownstreamServiceError:
                    response.StatusCode = (int)HttpStatusCode.ServiceUnavailable;
                    response.Message = "Service unavailable";
                    response.Details = "Unable to connect to the downstream service";
                    break;

                default:
                    // Handle by error message patterns for common scenarios
                    var errorMessage = primaryError.Message.ToLowerInvariant();
                    
                    if (errorMessage.Contains("authentication"))
                    {
                        response.StatusCode = (int)HttpStatusCode.Unauthorized;
                        response.Message = "Authentication failed";
                        response.Details = "Invalid or missing authentication credentials";
                    }
                    else if (errorMessage.Contains("authorization") || errorMessage.Contains("forbidden"))
                    {
                        response.StatusCode = (int)HttpStatusCode.Forbidden;
                        response.Message = "Access denied";
                        response.Details = "You don't have permission to access this resource";
                    }
                    else if (errorMessage.Contains("rate limit") || errorMessage.Contains("too many requests"))
                    {
                        response.StatusCode = (int)HttpStatusCode.TooManyRequests;
                        response.Message = "Rate limit exceeded";
                        response.Details = "Too many requests. Please try again later";
                    }
                    else if (errorMessage.Contains("timeout"))
                    {
                        response.StatusCode = (int)HttpStatusCode.RequestTimeout;
                        response.Message = "Request timeout";
                        response.Details = "The request took too long to process";
                    }
                    else if (errorMessage.Contains("not found") || errorMessage.Contains("route"))
                    {
                        response.StatusCode = (int)HttpStatusCode.NotFound;
                        response.Message = "Route not found";
                        response.Details = "The requested endpoint does not exist";
                    }
                    else if (errorMessage.Contains("service unavailable") || errorMessage.Contains("connection"))
                    {
                        response.StatusCode = (int)HttpStatusCode.ServiceUnavailable;
                        response.Message = "Service unavailable";
                        response.Details = "Unable to connect to the downstream service";
                    }
                    else
                    {
                        response.StatusCode = (int)HttpStatusCode.InternalServerError;
                        response.Message = "Gateway error";
                        response.Details = primaryError.Message;
                    }
                    break;
            }

            // Set response status and content type
            context.Response.StatusCode = response.StatusCode;
            context.Response.ContentType = "application/json";

            // Serialize and write response
            var jsonResponse = JsonSerializer.Serialize(response, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            await context.Response.WriteAsync(jsonResponse);
        }
    }
}
