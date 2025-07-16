using System.Net;

namespace ApiGateway.Resilience
{
    public class GatewayFailoverMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GatewayFailoverMiddleware> _logger;
        private readonly FailoverOptions _options;
        private readonly HttpClient _httpClient;

        public GatewayFailoverMiddleware(
            RequestDelegate next, 
            ILogger<GatewayFailoverMiddleware> logger,
            FailoverOptions options,
            IHttpClientFactory httpClientFactory)
        {
            _next = next;
            _logger = logger;
            _options = options;
            _httpClient = httpClientFactory.CreateClient();
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Primary gateway failed, attempting failover");
                await HandleFailover(context, ex);
            }
        }

        private async Task HandleFailover(HttpContext context, Exception originalException)
        {
            foreach (var fallbackGateway in _options.FallbackGateways)
            {
                try
                {
                    _logger.LogInformation("Attempting failover to {Gateway}", fallbackGateway);
                    
                    var fallbackUrl = $"{fallbackGateway}{context.Request.Path}{context.Request.QueryString}";
                    var response = await _httpClient.GetAsync(fallbackUrl);
                    
                    if (response.IsSuccessStatusCode)
                    {
                        context.Response.StatusCode = (int)response.StatusCode;
                        context.Response.ContentType = response.Content.Headers.ContentType?.ToString() ?? "application/json";
                        
                        var content = await response.Content.ReadAsByteArrayAsync();
                        await context.Response.Body.WriteAsync(content);
                        
                        _logger.LogInformation("Successfully failed over to {Gateway}", fallbackGateway);
                        return;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failover to {Gateway} failed", fallbackGateway);
                    continue;
                }
            }

            // All failovers failed, return error
            await HandleCompleteFailure(context, originalException);
        }

        private async Task HandleCompleteFailure(HttpContext context, Exception originalException)
        {
            context.Response.StatusCode = 503;
            context.Response.ContentType = "application/json";

            var errorResponse = new
            {
                error = "All API Gateway instances are unavailable",
                message = "The service is temporarily unavailable. Please try again later.",
                timestamp = DateTime.UtcNow,
                traceId = context.TraceIdentifier
            };

            var json = System.Text.Json.JsonSerializer.Serialize(errorResponse);
            await context.Response.WriteAsync(json);

            _logger.LogError(originalException, "All gateway instances failed");
        }
    }

    public class FailoverOptions
    {
        public List<string> FallbackGateways { get; set; } = new();
        public TimeSpan RequestTimeout { get; set; } = TimeSpan.FromSeconds(5);
    }
}
