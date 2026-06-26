namespace BookLibrary.DTOs;

public record BookResponseDTO
{
    public int Id { get; init; }

    public string Title { get; init; } = "";

    public int PageCount { get; init; }

    public int AuthorId { get; init; }
}