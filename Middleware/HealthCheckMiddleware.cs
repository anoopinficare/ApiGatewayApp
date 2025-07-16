using System.Text.Json;

namespace ApiGateway.Middleware
{
    public class HealthCheckMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<HealthCheckMiddleware> _logger;
        private readonly HttpClient _httpClient;

        public HealthCheckMiddleware(RequestDelegate next, ILogger<HealthCheckMiddleware> logger, IHttpClientFactory httpClientFactory)
        {
            _next = next;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(5); // Short timeout for health checks
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.Request.Path.StartsWithSegments("/health"))
            {
                await HandleHealthCheck(context);
                return;
            }

            await _next(context);
        }

        private async Task HandleHealthCheck(HttpContext context)
        {
            var healthStatus = new HealthCheckResponse
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Services = new List<ServiceHealth>()
            };

            // Check Users API instances
            var usersApiInstances = new[]
            {
                ("Users API Instance 1", "http://localhost:5001/api/users"),
                ("Users API Instance 2", "http://localhost:5011/api/users"),
                ("Users API Instance 3", "http://localhost:5021/api/users")
            };

            foreach (var (name, endpoint) in usersApiInstances)
            {
                var health = await CheckServiceHealth(name, endpoint);
                healthStatus.Services.Add(health);
            }

            // Check Locations API instances
            var locationsApiInstances = new[]
            {
                ("Locations API Instance 1", "http://localhost:5002/api/locations"),
                ("Locations API Instance 2", "http://localhost:5012/api/locations"),
                ("Locations API Instance 3", "http://localhost:5022/api/locations")
            };

            foreach (var (name, endpoint) in locationsApiInstances)
            {
                var health = await CheckServiceHealth(name, endpoint);
                healthStatus.Services.Add(health);
            }

            // Determine overall status
            if (healthStatus.Services.Any(s => s.Status == "Unhealthy"))
            {
                healthStatus.Status = "Degraded";
                context.Response.StatusCode = 503; // Service Unavailable
            }
            else if (healthStatus.Services.All(s => s.Status == "Unhealthy"))
            {
                healthStatus.Status = "Unhealthy";
                context.Response.StatusCode = 503;
            }
            else
            {
                context.Response.StatusCode = 200;
            }

            context.Response.ContentType = "application/json";
            
            var json = JsonSerializer.Serialize(healthStatus, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            await context.Response.WriteAsync(json);
        }

        private async Task<ServiceHealth> CheckServiceHealth(string serviceName, string healthEndpoint)
        {
            var serviceHealth = new ServiceHealth
            {
                ServiceName = serviceName,
                Endpoint = healthEndpoint
            };

            try
            {
                var response = await _httpClient.GetAsync(healthEndpoint);
                serviceHealth.Status = response.IsSuccessStatusCode ? "Healthy" : "Unhealthy";
                serviceHealth.ResponseTime = DateTimeOffset.UtcNow;
                
                if (!response.IsSuccessStatusCode)
                {
                    serviceHealth.Error = $"HTTP {(int)response.StatusCode} {response.StatusCode}";
                }
            }
            catch (HttpRequestException ex)
            {
                serviceHealth.Status = "Unhealthy";
                serviceHealth.Error = $"Connection failed: {ex.Message}";
                serviceHealth.ResponseTime = DateTimeOffset.UtcNow;
                
                _logger.LogWarning("Health check failed for {ServiceName}: {Error}", serviceName, ex.Message);
            }
            catch (TaskCanceledException)
            {
                serviceHealth.Status = "Unhealthy";
                serviceHealth.Error = "Request timeout";
                serviceHealth.ResponseTime = DateTimeOffset.UtcNow;
                
                _logger.LogWarning("Health check timeout for {ServiceName}", serviceName);
            }

            return serviceHealth;
        }
    }

    public class HealthCheckResponse
    {
        public string Status { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
        public List<ServiceHealth> Services { get; set; } = new();
    }

    public class ServiceHealth
    {
        public string ServiceName { get; set; } = string.Empty;
        public string Endpoint { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? Error { get; set; }
        public DateTimeOffset ResponseTime { get; set; }
    }
}
