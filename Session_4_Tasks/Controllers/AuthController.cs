using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BookLibrary.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;

namespace BookLibrary.Controllers;

// TASK 4.7 — Authentication endpoint.
// Issues a JWT when the user logs in with valid credentials.
[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;

    // IConfiguration gives us access to the "Jwt" settings in appsettings.json.
    public AuthController(IConfiguration config)
    {
        _config = config;
    }

    // POST: /auth/login
    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginDTO dto)
    {
        // Demo credentials. In a real app you'd check a Users table + hashed password.
        if (dto.Username == "admin" && dto.Password == "123")
        {
            var token = GenerateJwtToken(dto.Username);
            return Ok(new { token }); // 200 OK + the signed token
        }

        return Unauthorized(); // 401 — bad username/password
    }

    // Builds and signs the JWT.
    private string GenerateJwtToken(string username)
    {
        // 1. Claims = the data we put inside the token's payload.
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, username)
        };

        // 2. The secret key from appsettings.json signs (and later validates) the token.
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));

        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // 3. Assemble the token: issuer/audience must match what Program.cs validates.
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1), // token valid for 1 hour
            signingCredentials: creds
        );

        // 4. Serialize to the compact "header.payload.signature" string.
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
