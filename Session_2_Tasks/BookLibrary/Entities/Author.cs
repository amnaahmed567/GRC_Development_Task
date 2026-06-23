namespace BookLibrary.Entities;

// TASK 1.1 — Author entity.
// An author can have many books (one-to-many relationship).
public class Author
{
    // Primary key for the author.
    public int Id { get; set; }

    // Author's full name.
    public string Name { get; set; } = string.Empty;

    // Navigation property: the collection of books written by this author.
    // ICollection<Book> models the "many" side of the Author -> Books relationship.
    public ICollection<Book> Books { get; set; } = new List<Book>();
}
