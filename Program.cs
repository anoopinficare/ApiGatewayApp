using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using Ocelot.Provider.Polly;
using NLog.Extensions.Logging;
using ApiGateway.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add Ocelot configuration
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

// Configure detailed logging with file output
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.AddNLog(); // Add NLog for file logging

// Add services to the container
builder.Services.AddOcelot().AddPolly();

// Note: Using built-in Ocelot load balancers (RoundRobin, LeastConnection)
// Custom load balancer factory can be added here if needed

// Add HttpClient for health checks
builder.Services.AddHttpClient();

// Add Memory Cache for response caching
builder.Services.AddMemoryCache();

// Configure response caching options
builder.Services.AddSingleton(new ResponseCachingOptions
{
    CacheDurationSeconds = 10, // Cache for 10 seconds (you can change this to 5)
    VaryByHeaders = new[] { "Accept", "Accept-Language" } // Optional: vary cache by these headers
});

// Add CORS support
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var app = builder.Build();

// Add global exception handling middleware (first in pipeline)
app.UseMiddleware<GlobalExceptionHandlingMiddleware>();

// Add health check middleware
app.UseMiddleware<HealthCheckMiddleware>();

// Add request logging middleware
app.Use(async (context, next) =>
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    
    logger.LogInformation("=== Incoming Request ===");
    logger.LogInformation("Method: {Method}", context.Request.Method);
    logger.LogInformation("Path: {Path}", context.Request.Path);
    logger.LogInformation("QueryString: {QueryString}", context.Request.QueryString);
    logger.LogInformation("Headers: {Headers}", 
        string.Join(", ", context.Request.Headers.Select(h => $"{h.Key}={h.Value}")));
    
    await next();
    
    logger.LogInformation("=== Outgoing Response ===");
    logger.LogInformation("StatusCode: {StatusCode}", context.Response.StatusCode);
    logger.LogInformation("Headers: {Headers}", 
        string.Join(", ", context.Response.Headers.Select(h => $"{h.Key}={h.Value}")));
});

// Configure the HTTP request pipeline
app.UseCors("AllowAll");

// Add response caching middleware (before Ocelot)
app.UseMiddleware<ResponseCachingMiddleware>();

// Add HTTP status error handling middleware
app.UseMiddleware<HttpStatusErrorHandlingMiddleware>();

// Add Ocelot error handling middleware
app.UseMiddleware<OcelotErrorHandlingMiddleware>();

// Add Ocelot middleware (last in pipeline)
await app.UseOcelot();

app.Run();
