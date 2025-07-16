using Microsoft.Extensions.Caching.Memory;
using System.Net;
using System.Text;

namespace ApiGateway.Middleware
{
    public class ResponseCachingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IMemoryCache _cache;
        private readonly ILogger<ResponseCachingMiddleware> _logger;
        private readonly ResponseCachingOptions _options;

        public ResponseCachingMiddleware(
            RequestDelegate next, 
            IMemoryCache cache, 
            ILogger<ResponseCachingMiddleware> logger,
            ResponseCachingOptions options)
        {
            _next = next;
            _cache = cache;
            _logger = logger;
            _options = options;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Only cache GET requests
            if (context.Request.Method != HttpMethods.Get)
            {
                await _next(context);
                return;
            }

            var cacheKey = GenerateCacheKey(context.Request);
            
            // Check if response is cached
            if (_cache.TryGetValue(cacheKey, out CachedResponse? cachedResponse) && cachedResponse != null)
            {
                _logger.LogInformation("Cache HIT for key: {CacheKey}", cacheKey);
                await WriteCachedResponse(context, cachedResponse);
                return;
            }

            _logger.LogInformation("Cache MISS for key: {CacheKey}", cacheKey);

            // Capture the response
            var originalBodyStream = context.Response.Body;
            using var responseBody = new MemoryStream();
            context.Response.Body = responseBody;

            await _next(context);

            // Only cache successful responses (200-299)
            if (context.Response.StatusCode >= 200 && context.Response.StatusCode < 300)
            {
                var response = new CachedResponse
                {
                    StatusCode = context.Response.StatusCode,
                    ContentType = context.Response.ContentType ?? "application/json",
                    Headers = context.Response.Headers.ToDictionary(h => h.Key, h => h.Value.ToString()),
                    Body = responseBody.ToArray(),
                    CachedAt = DateTime.UtcNow
                };

                var cacheEntryOptions = new MemoryCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_options.CacheDurationSeconds),
                    Priority = CacheItemPriority.Normal
                };

                _cache.Set(cacheKey, response, cacheEntryOptions);
                _logger.LogInformation("Cached response for key: {CacheKey} for {Duration} seconds", 
                    cacheKey, _options.CacheDurationSeconds);
            }

            // Copy the cached response back to the original stream
            context.Response.Body = originalBodyStream;
            responseBody.Seek(0, SeekOrigin.Begin);
            await responseBody.CopyToAsync(originalBodyStream);
        }

        private string GenerateCacheKey(HttpRequest request)
        {
            var keyBuilder = new StringBuilder();
            keyBuilder.Append(request.Method);
            keyBuilder.Append(":");
            keyBuilder.Append(request.Path);
            
            if (request.QueryString.HasValue)
            {
                keyBuilder.Append(request.QueryString.Value);
            }

            // Include relevant headers in cache key if needed
            if (_options.VaryByHeaders != null)
            {
                foreach (var header in _options.VaryByHeaders)
                {
                    if (request.Headers.TryGetValue(header, out var headerValue))
                    {
                        keyBuilder.Append($":{header}={headerValue}");
                    }
                }
            }

            return keyBuilder.ToString();
        }

        private async Task WriteCachedResponse(HttpContext context, CachedResponse cachedResponse)
        {
            context.Response.StatusCode = cachedResponse.StatusCode;
            context.Response.ContentType = cachedResponse.ContentType;

            // Set cache headers
            context.Response.Headers["X-Cache"] = "HIT";
            context.Response.Headers["X-Cache-Date"] = cachedResponse.CachedAt.ToString("O");

            // Add original headers (except problematic ones)
            foreach (var header in cachedResponse.Headers)
            {
                if (!IsRestrictedHeader(header.Key))
                {
                    context.Response.Headers.TryAdd(header.Key, header.Value);
                }
            }

            await context.Response.Body.WriteAsync(cachedResponse.Body, 0, cachedResponse.Body.Length);
        }

        private static bool IsRestrictedHeader(string headerName)
        {
            // Don't copy headers that ASP.NET Core manages
            var restrictedHeaders = new[]
            {
                "Content-Length",
                "Transfer-Encoding",
                "Connection",
                "Date",
                "Server"
            };

            return restrictedHeaders.Contains(headerName, StringComparer.OrdinalIgnoreCase);
        }
    }

    public class CachedResponse
    {
        public int StatusCode { get; set; }
        public string ContentType { get; set; } = string.Empty;
        public Dictionary<string, string> Headers { get; set; } = new();
        public byte[] Body { get; set; } = Array.Empty<byte>();
        public DateTime CachedAt { get; set; }
    }

    public class ResponseCachingOptions
    {
        public int CacheDurationSeconds { get; set; } = 10;
        public string[]? VaryByHeaders { get; set; }
        public long MaxCacheSizeBytes { get; set; } = 100 * 1024 * 1024; // 100MB default
    }
}
