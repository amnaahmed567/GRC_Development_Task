namespace BookLibrary.Entities;

// TASK 1.1 — Book entity.
// Each book belongs to a single author (via AuthorId / Author nav property).
public class Book
{
    // Primary key for the book.
    public int Id { get; set; }

    // Title of the book.
    public string Title { get; set; } = string.Empty;

    // Year the book was published.
    public int Year { get; set; }

    // Number of pages in the book.
    public int PageCount { get; set; }

    // Foreign key pointing to the owning Author.
    public int AuthorId { get; set; }

    // Navigation property: the author who wrote this book.
    // Nullable because it is only populated when we explicitly link/join the data.
    public Author? Author { get; set; }

    // Navigation property: the link rows joining this book to its tags.
    // The "many" side of the Book -> BookTag relationship.
    public ICollection<BookTag> BookTags { get; set; } = new List<BookTag>();
}
