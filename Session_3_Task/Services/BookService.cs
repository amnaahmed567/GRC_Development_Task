using BookLibrary.Data;
using BookLibrary.DTOs;
using BookLibrary.Mappers;

namespace BookLibrary.Services;

// TASK 3.4 — Service now works in DTOs and uses BookMapper to convert.
// GetAll gains filtering (by author) and pagination (Skip/Take).
public class BookService : IBookService
{
    // GET ALL with filter + pagination
    public Task<IEnumerable<BookResponseDTO>> GetAllAsync(
        string? author,
        int page,
        int pageSize)
    {
        // 1. Start with all books
        var query = InMemoryStore.Books.AsQueryable();

        // 2. Filter by author (if provided)
        if (!string.IsNullOrWhiteSpace(author))
        {
            query = query.Where(b =>
                b.Author != null &&
                b.Author.Name.Contains(author));
        }

        // 3. Pagination (Skip + Take)
        var skip = (page - 1) * pageSize;

        var books = query
            .Skip(skip)
            .Take(pageSize)
            .ToList();

        // 4. Convert Entity -> DTO using mapper
        var result = books
            .Select(BookMapper.ToResponse);

        return Task.FromResult(result);
    }

    // GET BY ID
    public Task<BookResponseDTO?> GetByIdAsync(int id)
    {
        var book = InMemoryStore.Books
            .FirstOrDefault(b => b.Id == id);

        if (book == null)
            return Task.FromResult<BookResponseDTO?>(null);

        return Task.FromResult<BookResponseDTO?>(BookMapper.ToResponse(book));
    }

    // CREATE
    public Task<BookResponseDTO> CreateAsync(BookCreateDTO dto)
    {
        var book = BookMapper.ToEntity(dto);

        book.Id = InMemoryStore.Books.Count == 0
            ? 1
            : InMemoryStore.Books.Max(b => b.Id) + 1;

        // Keep navigation data consistent so author-filtering works for new books too.
        var author = InMemoryStore.Authors.FirstOrDefault(a => a.Id == book.AuthorId);
        if (author is not null)
        {
            book.Author = author;
            author.Books.Add(book);
        }

        InMemoryStore.Books.Add(book);

        return Task.FromResult(BookMapper.ToResponse(book));
    }

    // UPDATE
    public Task<bool> UpdateAsync(int id, BookUpdateDTO dto)
    {
        var book = InMemoryStore.Books
            .FirstOrDefault(b => b.Id == id);

        if (book == null)
            return Task.FromResult(false);

        BookMapper.ApplyUpdate(dto, book);

        return Task.FromResult(true);
    }

    // DELETE
    public Task<bool> DeleteAsync(int id)
    {
        var book = InMemoryStore.Books
            .FirstOrDefault(b => b.Id == id);

        if (book == null)
            return Task.FromResult(false);

        InMemoryStore.Books.Remove(book);

        return Task.FromResult(true);
    }
}
