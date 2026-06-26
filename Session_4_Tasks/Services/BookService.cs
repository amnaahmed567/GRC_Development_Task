using BookLibrary.Data;
using BookLibrary.DTOs;
using BookLibrary.Mappers;
using Microsoft.EntityFrameworkCore;

namespace BookLibrary.Services;

// TASK 4.4 — BookService now talks to MySQL through AppDbContext (EF Core)
// instead of the old static InMemoryStore.
public class BookService : IBookService
{
    private readonly AppDbContext _db;

    // AppDbContext is injected by the DI container (registered in Program.cs).
    public BookService(AppDbContext db)
    {
        _db = db;
    }

    // GET ALL — filter by author + pagination (Skip/Take).
    public async Task<IEnumerable<BookResponseDTO>> GetAllAsync(
        string? author,
        int page,
        int pageSize)
    {
        // AsNoTracking: read-only query, so EF doesn't need to track changes (faster).
        // Include: load the related Author so we can filter by its Name.
        var query = _db.Books
            .AsNoTracking()
            .Include(b => b.Author)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(author))
        {
            query = query.Where(b =>
                b.Author != null &&
                b.Author.Name.Contains(author));
        }

        var skip = (page - 1) * pageSize;

        var books = await query
            .OrderBy(b => b.Id)   // stable order so paging is predictable
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync();

        return books.Select(BookMapper.ToResponse);
    }

    // GET BY ID
    public async Task<BookResponseDTO?> GetByIdAsync(int id)
    {
        var book = await _db.Books
            .AsNoTracking()
            .Include(b => b.Author)
            .FirstOrDefaultAsync(b => b.Id == id);

        return book == null ? null : BookMapper.ToResponse(book);
    }

    // CREATE
    public async Task<BookResponseDTO> CreateAsync(BookCreateDTO dto)
    {
        var book = BookMapper.ToEntity(dto);

        _db.Books.Add(book);
        await _db.SaveChangesAsync(); // EF assigns book.Id here

        return BookMapper.ToResponse(book);
    }

    // UPDATE
    public async Task<bool> UpdateAsync(int id, BookUpdateDTO dto)
    {
        var book = await _db.Books.FirstOrDefaultAsync(b => b.Id == id);

        if (book == null)
            return false;

        BookMapper.ApplyUpdate(dto, book);
        await _db.SaveChangesAsync();

        return true;
    }

    // DELETE
    public async Task<bool> DeleteAsync(int id)
    {
        var book = await _db.Books.FirstOrDefaultAsync(b => b.Id == id);

        if (book == null)
            return false;

        _db.Books.Remove(book);
        await _db.SaveChangesAsync();

        return true;
    }
}
