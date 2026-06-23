using BookLibrary.Middleware; 
using BookLibrary.Services;  

// creates web app builder (startup configuration object)
var builder = WebApplication.CreateBuilder(args);

// registers controllers so API endpoints work
builder.Services.AddControllers()
    .AddJsonOptions(options => // configure JSON serialization rules
    {
        options.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles; // avoids infinite loops in Book → Author → Book
    });

// registers BookService for dependency injection (IBookService → BookService)
builder.Services.AddScoped<IBookService, BookService>();

// enables endpoint discovery for Swagger (API documentation)
builder.Services.AddEndpointsApiExplorer();

// enables Swagger generator (creates API UI + docs)
builder.Services.AddSwaggerGen();

// builds the actual web application from configuration above
var app = builder.Build();

// adds custom middleware to log every request (method, path, time)
app.UseMiddleware<RequestLoggingMiddleware>();

// runs Swagger only in development mode
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();    // generates JSON API documentation
    app.UseSwaggerUI();  // shows interactive API testing UI
}

// redirects HTTP requests to HTTPS for security
app.UseHttpsRedirection();


// connects controller routes like /api/books to actual controllers
app.MapControllers();

// starts the web server (keeps app running and listening for requests)
app.Run();