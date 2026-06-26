using System.ComponentModel.DataAnnotations;

namespace BookLibrary.DTOs;

public class BookCreateDTO
{
    [Required]
    public string Title { get; set; } = "";

    [Range(1, 5000)]
    public int PageCount { get; set; }

    [Required]
    public int AuthorId { get; set; }
}