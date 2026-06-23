using BookLibrary.Entities;

namespace BookLibrary.Services;

// TASK 1.4 — IBookService interface.
// Defines the CRUD contract for working with books. Keeping this as an
// interface lets us swap the underlying data source (in-memory, database, etc.)
// without changing the code that depends on it.
public interface IBookService
{
    // Return every book.
    IEnumerable<Book> GetAll();

    // Return a single book by Id, or null if it does not exist.
    Book? GetById(int id);

    // Add a new book and return the created entity (with its assigned Id).
    Book Create(Book book);

    // Update an existing book; returns true if a matching book was updated.
    bool Update(Book book);

    // Delete a book by Id; returns true if a book was removed.
    bool Delete(int id);
}
