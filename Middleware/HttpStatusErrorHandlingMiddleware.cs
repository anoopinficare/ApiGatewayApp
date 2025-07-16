using System.Net;
using System.Text.Json;

namespace ApiGateway.Middleware
{
    public class HttpStatusErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<HttpStatusErrorHandlingMiddleware> _logger;

        public HttpStatusErrorHandlingMiddleware(RequestDelegate next, ILogger<HttpStatusErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            await _next(context);

            // Handle error status codes that don't throw exceptions
            if (context.Response.StatusCode >= 400 && !context.Response.HasStarted)
            {
                await HandleHttpErrorAsync(context);
            }
        }

        private async Task HandleHttpErrorAsync(HttpContext context)
        {
            var statusCode = context.Response.StatusCode;
            
            _logger.LogWarning("HTTP error status code {StatusCode} returned for request {Method} {Path}. TraceId: {TraceId}", 
                statusCode, context.Request.Method, context.Request.Path, context.TraceIdentifier);

            var response = new ErrorResponse
            {
                StatusCode = statusCode,
                TraceId = context.TraceIdentifier
            };

            // Map common HTTP status codes to user-friendly messages
            switch (statusCode)
            {
                case 400:
                    response.Message = "Bad Request";
                    response.Details = "The request could not be understood by the server due to malformed syntax";
                    break;

                case 401:
                    response.Message = "Unauthorized";
                    response.Details = "Authentication is required to access this resource";
                    break;

                case 403:
                    response.Message = "Forbidden";
                    response.Details = "You don't have permission to access this resource";
                    break;

                case 404:
                    response.Message = "Not Found";
                    response.Details = "The requested resource could not be found on the server";
                    break;

                case 405:
                    response.Message = "Method Not Allowed";
                    response.Details = "The request method is not supported for this resource";
                    break;

                case 408:
                    response.Message = "Request Timeout";
                    response.Details = "The server timed out waiting for the request";
                    break;

                case 429:
                    response.Message = "Too Many Requests";
                    response.Details = "Rate limit exceeded. Please try again later";
                    break;

                case 500:
                    response.Message = "Internal Server Error";
                    response.Details = "An unexpected error occurred on the server";
                    break;

                case 501:
                    response.Message = "Not Implemented";
                    response.Details = "The server does not support the functionality required to fulfill the request";
                    break;

                case 502:
                    response.Message = "Bad Gateway";
                    response.Details = "The server received an invalid response from the upstream server";
                    break;

                case 503:
                    response.Message = "Service Unavailable";
                    response.Details = "The server is currently unable to handle the request due to temporary overloading or maintenance";
                    break;

                case 504:
                    response.Message = "Gateway Timeout";
                    response.Details = "The server did not receive a timely response from the upstream server";
                    break;

                default:
                    if (statusCode >= 400 && statusCode < 500)
                    {
                        response.Message = "Client Error";
                        response.Details = "There was an error in the request";
                    }
                    else if (statusCode >= 500)
                    {
                        response.Message = "Server Error";
                        response.Details = "There was an error on the server";
                    }
                    else
                    {
                        response.Message = "Unknown Error";
                        response.Details = "An unknown error occurred";
                    }
                    break;
            }

            // Clear the response and set the content type
            context.Response.Clear();
            context.Response.StatusCode = statusCode;
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
