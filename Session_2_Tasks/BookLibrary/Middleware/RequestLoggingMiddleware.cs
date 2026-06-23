using System.Diagnostics;

namespace BookLibrary.Middleware;

public class RequestLoggingMiddleware
{    private readonly RequestDelegate _next;

    
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    // This runs for EVERY request.
    public async Task InvokeAsync(HttpContext context)
    {
        // Start a stopwatch so we can measure how long the request takes.
        var stopwatch = Stopwatch.StartNew();

        // Grab the method (GET, POST, ...) and the path (/api/books) up front.
        var method = context.Request.Method;
        var path = context.Request.Path;

        await _next(context);

        stopwatch.Stop();


        var statusCode = context.Response.StatusCode;
        var elapsedMs = stopwatch.ElapsedMilliseconds;

        _logger.LogInformation(
            "HTTP {Method} {Path} responded {StatusCode} in {ElapsedMs} ms",
            method, path, statusCode, elapsedMs);
    }
}
