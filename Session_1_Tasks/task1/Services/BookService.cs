using BookLibrary.Data;
using BookLibrary.Entities;

namespace BookLibrary.Services;

// TASK 1.5 — BookService.
// Concrete implementation of IBookService that operates against the
// InMemoryStore. Each method maps to a CRUD operation on the in-memory list.
public class BookService : IBookService
{
    // GetAll: return every book in the store.
    public IEnumerable<Book> GetAll()
    {
        return InMemoryStore.Books;
    }

    // GetById: return the matching book, or null if none has that Id.
    public Book? GetById(int id)
    {
        return InMemoryStore.Books.FirstOrDefault(b => b.Id == id);
    }

    // Create: assign the next available Id, link the author navigation
    // property if possible, add to the store, and return the new book.
    public Book Create(Book book)
    {
        // Generate a new Id (max existing Id + 1, or 1 if the store is empty).
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
        return book;
    }

    // Update: find the existing book and copy over its mutable fields.
    // Returns false if no book with the given Id exists.
    public bool Update(Book book)
    {
        var existing = InMemoryStore.Books.FirstOrDefault(b => b.Id == book.Id);
        if (existing is null)
            return false;

        existing.Title = book.Title;
        existing.Year = book.Year;
        existing.PageCount = book.PageCount;
        existing.AuthorId = book.AuthorId;
        return true;
    }

    // Delete: remove the book with the given Id.
    // Returns false if no such book exists.
    public bool Delete(int id)
    {
        var existing = InMemoryStore.Books.FirstOrDefault(b => b.Id == id);
        if (existing is null)
            return false;

        InMemoryStore.Books.Remove(existing);
        return true;
    }
}
