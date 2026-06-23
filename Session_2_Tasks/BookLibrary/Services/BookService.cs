using BookLibrary.Data;
using BookLibrary.Entities;
using BookLibrary.Exceptions;

namespace BookLibrary.Services;


public class BookService : IBookService
{
    // GetAll: return every book in the store.
    public Task<IEnumerable<Book>> GetAllAsync()
    {
        return Task.FromResult<IEnumerable<Book>>(InMemoryStore.Books);
    }


    public Task<Book?> GetByIdAsync(int id)
    {
        var book = InMemoryStore.Books.FirstOrDefault(b => b.Id == id);
        if (book is null)
            throw new BookNotFoundException(id);

        return Task.FromResult(book);
    }

    public Task<Book> CreateAsync(Book book)
    {
        
        book.Id = InMemoryStore.Books.Count == 0
            ? 1
            : InMemoryStore.Books.Max(b => b.Id) + 1;

        // Keep navigation data consistent if the author exists.
        var author = InMemoryStore.Authors.FirstOrDefault(a => a.Id == book.AuthorId);
        if (author is not null)
        {
            book.Author = author;
            author.Books.Add(book);
        }

        InMemoryStore.Books.Add(book);
        return Task.FromResult(book);
    }

  
    public Task<bool> UpdateAsync(Book book)
    {
        var existing = InMemoryStore.Books.FirstOrDefault(b => b.Id == book.Id);
        if (existing is null)
            return Task.FromResult(false);

        existing.Title = book.Title;
        existing.Year = book.Year;
        existing.PageCount = book.PageCount;
        existing.AuthorId = book.AuthorId;
        return Task.FromResult(true);
    }

    public Task<bool> DeleteAsync(int id)
    {
        var existing = InMemoryStore.Books.FirstOrDefault(b => b.Id == id);
        if (existing is null)
            return Task.FromResult(false);

        InMemoryStore.Books.Remove(existing);
        return Task.FromResult(true);
    }
}
