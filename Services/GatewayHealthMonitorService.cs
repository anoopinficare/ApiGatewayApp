using Microsoft.Extensions.Hosting;

namespace ApiGateway.Services
{
    public class GatewayHealthMonitorService : BackgroundService
    {
        private readonly ILogger<GatewayHealthMonitorService> _logger;
        private readonly HttpClient _httpClient;
        private readonly HealthMonitorOptions _options;

        public GatewayHealthMonitorService(
            ILogger<GatewayHealthMonitorService> logger,
            IHttpClientFactory httpClientFactory,
            HealthMonitorOptions options)
        {
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _options = options;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                await MonitorGatewayHealth();
                await Task.Delay(_options.CheckInterval, stoppingToken);
            }
        }

        private async Task MonitorGatewayHealth()
        {
            var healthReport = new GatewayHealthReport
            {
                Timestamp = DateTime.UtcNow,
                Instances = new List<GatewayInstanceHealth>()
            };

            // Check primary gateway
            var primaryHealth = await CheckGatewayInstance("Primary", _options.PrimaryGatewayUrl);
            healthReport.Instances.Add(primaryHealth);

            // Check backup gateways
            foreach (var backupUrl in _options.BackupGatewayUrls)
            {
                var backupHealth = await CheckGatewayInstance("Backup", backupUrl);
                healthReport.Instances.Add(backupHealth);
            }

            // Log health status
            var healthyCount = healthReport.Instances.Count(i => i.IsHealthy);
            var totalCount = healthReport.Instances.Count;

            _logger.LogInformation("Gateway Health: {Healthy}/{Total} instances healthy", 
                healthyCount, totalCount);

            // Alert if all instances are down
            if (healthyCount == 0)
            {
                _logger.LogCritical("CRITICAL: All API Gateway instances are down!");
                await TriggerAlert(healthReport);
            }
            else if (healthyCount < totalCount)
            {
                _logger.LogWarning("WARNING: {Count} gateway instances are unhealthy", 
                    totalCount - healthyCount);
            }
        }

        private async Task<GatewayInstanceHealth> CheckGatewayInstance(string type, string url)
        {
            var health = new GatewayInstanceHealth
            {
                Type = type,
                Url = url,
                CheckTime = DateTime.UtcNow
            };

            try
            {
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var response = await _httpClient.GetAsync($"{url}/health");
                stopwatch.Stop();

                health.IsHealthy = response.IsSuccessStatusCode;
                health.ResponseTime = stopwatch.ElapsedMilliseconds;
                health.StatusCode = (int)response.StatusCode;

                if (!response.IsSuccessStatusCode)
                {
                    health.Error = $"HTTP {response.StatusCode}";
                }
            }
            catch (Exception ex)
            {
                health.IsHealthy = false;
                health.Error = ex.Message;
                health.ResponseTime = _options.TimeoutMs;
            }

            return health;
        }

        private async Task TriggerAlert(GatewayHealthReport healthReport)
        {
            // Implement alerting logic here
            // Examples: Send email, Slack notification, PagerDuty alert, etc.
            
            var alertMessage = $"""
                🚨 CRITICAL ALERT: All API Gateway Instances Down
                
                Time: {healthReport.Timestamp:yyyy-MM-dd HH:mm:ss UTC}
                
                Failed Instances:
                {string.Join("\n", healthReport.Instances.Select(i => $"- {i.Type}: {i.Url} - {i.Error}"))}
                
                Immediate action required!
                """;

            _logger.LogCritical("ALERT: {AlertMessage}", alertMessage);
            
            // Here you would integrate with your alerting system
            // await _alertingService.SendCriticalAlert(alertMessage);
        }
    }

    public class HealthMonitorOptions
    {
        public string PrimaryGatewayUrl { get; set; } = "http://localhost:5000";
        public List<string> BackupGatewayUrls { get; set; } = new() 
        { 
            "http://localhost:5100", 
            "http://localhost:5200" 
        };
        public TimeSpan CheckInterval { get; set; } = TimeSpan.FromSeconds(30);
        public int TimeoutMs { get; set; } = 5000;
    }

    public class GatewayHealthReport
    {
        public DateTime Timestamp { get; set; }
        public List<GatewayInstanceHealth> Instances { get; set; } = new();
    }

    public class GatewayInstanceHealth
    {
        public string Type { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
        public bool IsHealthy { get; set; }
        public long ResponseTime { get; set; }
        public int StatusCode { get; set; }
        public string? Error { get; set; }
        public DateTime CheckTime { get; set; }
    }
}
