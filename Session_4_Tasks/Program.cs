using BookLibrary.Middleware;
using BookLibrary.Services;
using BookLibrary.Data;            // TASK 4.1 — AppDbContext lives here
using Microsoft.EntityFrameworkCore; // TASK 4.1 — UseMySql / AddDbContext extensions
using Microsoft.AspNetCore.Authentication.JwtBearer; // TASK 4.7
using Microsoft.IdentityModel.Tokens;                // TASK 4.7
using Microsoft.OpenApi.Models;                       // TASK 4.7 — Swagger Bearer button
using System.Text;                                    // TASK 4.7 — Encoding

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

// TASK 4.1 — Register AppDbContext with the DI container, using Pomelo as the
// MySQL provider. ServerVersion.AutoDetect connects once and figures out which
// MySQL version the server runs, so we don't hard-code it.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// TASK 4.7 — Configure JWT Bearer authentication.
// "When a request arrives, look for an 'Authorization: Bearer <token>' header,
//  then validate the token's signature/issuer/audience using the secret key."
var jwtKey = builder.Configuration["Jwt:Key"]!;                          // read the secret signing key from appsettings.json ("!" = trust it's not null)
builder.Services                                                        // start adding services to the DI container
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)          // turn ON authentication and make "Bearer" (JWT) the default scheme
    .AddJwtBearer(options =>                                            // plug in the JWT Bearer handler ,and configure how tokens are checked
    {
        options.TokenValidationParameters = new TokenValidationParameters // the set of rules every incoming token must pass
        {
            ValidateIssuerSigningKey = true,                            // YES: verify the token's signature so it can't be forged/tampered
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)), // the exact key used to verify that signature (same key that signed it)

            ValidateIssuer = true,                                      // YES: check WHO issued the token
            ValidIssuer = builder.Configuration["Jwt:Issuer"],          // ...it must equal this issuer value from appsettings.json

            ValidateAudience = true,                                    // YES: check WHO the token was meant for
            ValidAudience = builder.Configuration["Jwt:Audience"],      // ...it must equal this audience value from appsettings.json

            ValidateLifetime = true                                     // YES: reject tokens whose "expires" time has passed
        };
    });

// enables endpoint discovery for Swagger (API documentation)
builder.Services.AddEndpointsApiExplorer();                             // lets Swagger discover all the controller endpoints

// enables Swagger generator (creates API UI + docs)
// TASK 4.7 — also add an "Authorize" button so we can paste a Bearer token in Swagger.
builder.Services.AddSwaggerGen(options =>                               // configure the Swagger doc generator
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme   // define a security scheme named "Bearer" (this creates the Authorize button)
    {
        Name = "Authorization",                                         // the HTTP header the token goes into
        Type = SecuritySchemeType.Http,                                 // it's a standard HTTP auth scheme
        Scheme = "Bearer",                                              // ...specifically the "Bearer" scheme (so Swagger adds the "Bearer " prefix for us)
        BearerFormat = "JWT",                                           // hint to humans that the token format is JWT
        In = ParameterLocation.Header,                                  // the token is sent in the request HEADER (not query/cookie)
        Description = "Paste ONLY the token here (Swagger adds the 'Bearer ' prefix)." // help text shown in the Authorize popup
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement       // say "apply that scheme to the endpoints" so the padlocks appear
    {
        {
            new OpenApiSecurityScheme                                   // reference the scheme we just defined above...
            {
                Reference = new OpenApiReference                        // ...by pointing to it by id
                {
                    Type = ReferenceType.SecurityScheme,                // the reference is to a SecurityScheme
                    Id = "Bearer"                                       // ...whose id is "Bearer" (matches AddSecurityDefinition above)
                }
            },
            Array.Empty<string>()                                       // no specific scopes required (JWT here doesn't use OAuth scopes)
        }
    });
});

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

// TASK 4.7 — Authentication MUST come before Authorization.
// UseAuthentication: reads + validates the JWT, sets "who you are".
// UseAuthorization:  enforces [Authorize] attributes, decides "are you allowed".
app.UseAuthentication();
app.UseAuthorization();

// connects controller routes like /api/books to actual controllers
app.MapControllers();

// starts the web server (keeps app running and listening for requests)
app.Run();