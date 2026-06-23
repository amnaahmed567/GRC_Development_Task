using BookLibrary.Data;
using BookLibrary.Entities;

namespace BookLibrary.Queries;

// TASK 1.3 — Eight LINQ queries over the InMemoryStore data.
// Each method demonstrates a different LINQ operator/pattern and prints
// its result so you can see the output when the program runs.
public static class BookQueries
{
    // Runs every query in order.
    public static void RunAll()
    {
        Console.WriteLine("===== LINQ QUERIES =====\n");
        Query1_FilterByAuthor(authorId: 1);
        Query2_TitlesSorted();
        Query3_GroupByAuthor();
        Query4_AveragePages();
        Query5_AnyOver500Pages();
        Query6_FirstOrDefaultById(id: 4);
        Query7_JoinBooksAndAuthors();
        Query8_TopThreeLongest();
    }

    // 1) Filter: all books written by a given author.
    public static void Query1_FilterByAuthor(int authorId)
    {
        var books = InMemoryStore.Books
            .Where(b => b.AuthorId == authorId)
            .ToList();

        Console.WriteLine($"1) Books by author #{authorId}:");
        foreach (var b in books)
            Console.WriteLine($"   - {b.Title}");
        Console.WriteLine();
    }

    // 2) Select + OrderBy: just the titles, alphabetically sorted.
    public static void Query2_TitlesSorted()
    {
        var titles = InMemoryStore.Books
            .OrderBy(b => b.Title)
            .Select(b => b.Title)
            .ToList();

        Console.WriteLine("2) All titles sorted A-Z:");
        foreach (var t in titles)
            Console.WriteLine($"   - {t}");
        Console.WriteLine();
    }

    // 3) GroupBy: count of books per author.
    public static void Query3_GroupByAuthor()
    {
        var groups = InMemoryStore.Books
            .GroupBy(b => b.AuthorId)
            .Select(g => new
            {
                AuthorId = g.Key,
                Count = g.Count()
            });

        Console.WriteLine("3) Book count grouped by author:");
        foreach (var g in groups)
            Console.WriteLine($"   - Author #{g.AuthorId}: {g.Count} book(s)");
        Console.WriteLine();
    }

    // 4) Average: the average page count across all books.
    public static void Query4_AveragePages()
    {
        double avg = InMemoryStore.Books.Average(b => b.PageCount);
        Console.WriteLine($"4) Average page count: {avg:F1}\n");
    }

    // 5) Any: is there at least one book longer than 500 pages?
    public static void Query5_AnyOver500Pages()
    {
        bool hasLong = InMemoryStore.Books.Any(b => b.PageCount > 500);
        Console.WriteLine($"5) Any book over 500 pages? {hasLong}\n");
    }

    // 6) FirstOrDefault: find a single book by its Id (null if not found).
    public static void Query6_FirstOrDefaultById(int id)
    {
        Book? book = InMemoryStore.Books.FirstOrDefault(b => b.Id == id);
        Console.WriteLine(book is null
            ? $"6) No book found with Id {id}.\n"
            : $"6) Book with Id {id}: {book.Title}\n");
    }

    // 7) Join: combine books with their authors to show "Title by Author".
    public static void Query7_JoinBooksAndAuthors()
    {
        var joined = InMemoryStore.Books
            .Join(
                InMemoryStore.Authors,
                book => book.AuthorId,   // key on the Book side
                author => author.Id,     // key on the Author side
                (book, author) => new { book.Title, AuthorName = author.Name })
            .ToList();

        Console.WriteLine("7) Books joined with authors:");
        foreach (var row in joined)
            Console.WriteLine($"   - {row.Title} by {row.AuthorName}");
        Console.WriteLine();
    }

    // 8) OrderByDescending + Take: the three longest books.
    public static void Query8_TopThreeLongest()
    {
        var longest = InMemoryStore.Books
            .OrderByDescending(b => b.PageCount)
            .Take(3)
            .ToList();

        Console.WriteLine("8) Top 3 longest books:");
        foreach (var b in longest)
            Console.WriteLine($"   - {b.Title} ({b.PageCount} pages)");
        Console.WriteLine();
    }
}
