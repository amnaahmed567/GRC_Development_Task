using System.ComponentModel.DataAnnotations;

namespace BookLibrary.DTOs;

// TASK 4.7 — The body the client sends to POST /auth/login.
public class LoginDTO
{
    [Required]
    public string Username { get; set; } = "";

    [Required]
    public string Password { get; set; } = "";
}
