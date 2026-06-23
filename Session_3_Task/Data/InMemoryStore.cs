using BookLibrary.Entities;

namespace BookLibrary.Data;

// TASK 1.2 — InMemoryStore.
// A static, in-memory data source that stands in for a database.
// It exposes lists of Authors, Books, Tags and BookTag links, all seeded
// with sample data in the static constructor.
public static class InMemoryStore
{
    // In-memory tables.
    public static List<Author> Authors { get; } = new();
    public static List<Book> Books { get; } = new();
    public static List<Tag> Tags { get; } = new();
    public static List<BookTag> BookTags { get; } = new();

    // The static constructor runs once, the first time the class is used,
    // and fills the lists with seed data.
    static InMemoryStore()
    {
        Seed();
    }

    private static void Seed()
    {
        // --- 3 authors ---
        Authors.AddRange(new[]
        {
            new Author { Id = 1, Name = "George Orwell" },
            new Author { Id = 2, Name = "J.R.R. Tolkien" },
            new Author { Id = 3, Name = "Jane Austen" },
        });

        // --- 8 books (linked to authors via AuthorId) ---
        Books.AddRange(new[]
        {
            new Book { Id = 1, Title = "1984",                  Year = 1949, PageCount = 328, AuthorId = 1 },
            new Book { Id = 2, Title = "Animal Farm",           Year = 1945, PageCount = 112, AuthorId = 1 },
            new Book { Id = 3, Title = "Homage to Catalonia",   Year = 1938, PageCount = 232, AuthorId = 1 },
            new Book { Id = 4, Title = "The Hobbit",            Year = 1937, PageCount = 310, AuthorId = 2 },
            new Book { Id = 5, Title = "The Fellowship of the Ring", Year = 1954, PageCount = 423, AuthorId = 2 },
            new Book { Id = 6, Title = "The Return of the King",     Year = 1955, PageCount = 416, AuthorId = 2 },
            new Book { Id = 7, Title = "Pride and Prejudice",   Year = 1813, PageCount = 279, AuthorId = 3 },
            new Book { Id = 8, Title = "Emma",                  Year = 1815, PageCount = 544, AuthorId = 3 },
        });

        // Wire up the navigation properties so Book.Author and Author.Books
        // are populated (mimics what an ORM would do for us).
        foreach (var book in Books)
        {
            var author = Authors.First(a => a.Id == book.AuthorId);
            book.Author = author;
            author.Books.Add(book);
        }

        // --- 4 tags ---
        Tags.AddRange(new[]
        {
            new Tag { Id = 1, Name = "Classic" },
            new Tag { Id = 2, Name = "Fantasy" },
            new Tag { Id = 3, Name = "Dystopian" },
            new Tag { Id = 4, Name = "Romance" },
        });

        // --- 6 BookTag links (many-to-many between books and tags) ---
        BookTags.AddRange(new[]
        {
            new BookTag { BookId = 1, TagId = 3 }, // 1984 -> Dystopian
            new BookTag { BookId = 1, TagId = 1 }, // 1984 -> Classic
            new BookTag { BookId = 4, TagId = 2 }, // The Hobbit -> Fantasy
            new BookTag { BookId = 5, TagId = 2 }, // Fellowship -> Fantasy
            new BookTag { BookId = 7, TagId = 4 }, // Pride and Prejudice -> Romance
            new BookTag { BookId = 7, TagId = 1 }, // Pride and Prejudice -> Classic
        });
    }
}
