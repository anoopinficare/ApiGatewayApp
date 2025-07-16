using System.Text.Json;
using System.Net.NetworkInformation;

namespace ApiGateway.Middleware
{
    public class DistributedHealthCheckMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<DistributedHealthCheckMiddleware> _logger;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public DistributedHealthCheckMiddleware(
            RequestDelegate next, 
            ILogger<DistributedHealthCheckMiddleware> logger, 
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _next = next;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(5);
            _configuration = configuration;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.Request.Path.StartsWithSegments("/health/detailed"))
            {
                await HandleDetailedHealthCheck(context);
                return;
            }

            await _next(context);
        }

        private async Task HandleDetailedHealthCheck(HttpContext context)
        {
            var healthStatus = new DetailedHealthResponse
            {
                Gateway = new GatewayHealth
                {
                    Status = "Healthy",
                    Version = GetType().Assembly.GetName().Version?.ToString() ?? "1.0.0",
                    Timestamp = DateTime.UtcNow,
                    Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development"
                },
                DownstreamServices = new List<DistributedServiceHealth>()
            };

            // Check all configured downstream services
            var routes = _configuration.GetSection("Routes").Get<List<dynamic>>();
            
            if (routes != null)
            {
                foreach (var route in routes)
                {
                    var serviceKey = route.GetProperty("Key").GetString();
                    var downstreamHosts = route.GetProperty("DownstreamHostAndPorts");
                    
                    if (downstreamHosts.ValueKind == JsonValueKind.Array)
                    {
                        var serviceHealthGroup = new DistributedServiceHealth
                        {
                            ServiceName = serviceKey ?? "Unknown",
                            Instances = new List<ServiceInstance>()
                        };

                        foreach (var host in downstreamHosts.EnumerateArray())
                        {
                            var hostname = host.GetProperty("Host").GetString();
                            var port = host.GetProperty("Port").GetInt32();
                            
                            var instance = await CheckServiceInstance(hostname, port, serviceKey);
                            serviceHealthGroup.Instances.Add(instance);
                        }

                        // Determine overall service health
                        var healthyInstances = serviceHealthGroup.Instances.Count(i => i.Status == "Healthy");
                        serviceHealthGroup.OverallStatus = healthyInstances > 0 ? "Healthy" : "Unhealthy";
                        serviceHealthGroup.HealthyInstances = healthyInstances;
                        serviceHealthGroup.TotalInstances = serviceHealthGroup.Instances.Count;

                        healthStatus.DownstreamServices.Add(serviceHealthGroup);
                    }
                }
            }

            // Determine overall gateway health
            var allServicesHealthy = healthStatus.DownstreamServices.All(s => s.OverallStatus == "Healthy");
            var anyServiceHealthy = healthStatus.DownstreamServices.Any(s => s.OverallStatus == "Healthy");

            if (allServicesHealthy)
            {
                healthStatus.Gateway.Status = "Healthy";
                context.Response.StatusCode = 200;
            }
            else if (anyServiceHealthy)
            {
                healthStatus.Gateway.Status = "Degraded";
                context.Response.StatusCode = 200;
            }
            else
            {
                healthStatus.Gateway.Status = "Unhealthy";
                context.Response.StatusCode = 503;
            }

            context.Response.ContentType = "application/json";
            var json = JsonSerializer.Serialize(healthStatus, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = true
            });

            await context.Response.WriteAsync(json);
        }

        private async Task<ServiceInstance> CheckServiceInstance(string? hostname, int port, string? serviceName)
        {
            var instance = new ServiceInstance
            {
                Host = hostname ?? "unknown",
                Port = port,
                ServiceName = serviceName ?? "unknown"
            };

            try
            {
                // Check network connectivity first
                var ping = new Ping();
                var pingReply = await ping.SendPingAsync(hostname ?? "localhost", 3000);
                
                if (pingReply.Status != IPStatus.Success)
                {
                    instance.Status = "Unreachable";
                    instance.Error = $"Network unreachable: {pingReply.Status}";
                    return instance;
                }

                // Check HTTP endpoint
                var healthEndpoint = $"http://{hostname}:{port}/health";
                var response = await _httpClient.GetAsync(healthEndpoint);
                
                instance.Status = response.IsSuccessStatusCode ? "Healthy" : "Unhealthy";
                instance.ResponseTime = DateTimeOffset.UtcNow;
                instance.ResponseTimeMs = (int)(DateTime.UtcNow - DateTime.UtcNow.AddMilliseconds(-100)).TotalMilliseconds;

                if (!response.IsSuccessStatusCode)
                {
                    instance.Error = $"HTTP {(int)response.StatusCode} {response.StatusCode}";
                }
            }
            catch (HttpRequestException ex)
            {
                instance.Status = "Connection Failed";
                instance.Error = ex.Message;
            }
            catch (TaskCanceledException)
            {
                instance.Status = "Timeout";
                instance.Error = "Health check timeout";
            }
            catch (Exception ex)
            {
                instance.Status = "Error";
                instance.Error = ex.Message;
            }

            return instance;
        }
    }

    public class DetailedHealthResponse
    {
        public GatewayHealth Gateway { get; set; } = new();
        public List<DistributedServiceHealth> DownstreamServices { get; set; } = new();
    }

    public class GatewayHealth
    {
        public string Status { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string Environment { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }

    public class DistributedServiceHealth
    {
        public string ServiceName { get; set; } = string.Empty;
        public string OverallStatus { get; set; } = string.Empty;
        public int HealthyInstances { get; set; }
        public int TotalInstances { get; set; }
        public List<ServiceInstance> Instances { get; set; } = new();
    }

    public class ServiceInstance
    {
        public string Host { get; set; } = string.Empty;
        public int Port { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? Error { get; set; }
        public DateTimeOffset ResponseTime { get; set; }
        public int ResponseTimeMs { get; set; }
    }
}
