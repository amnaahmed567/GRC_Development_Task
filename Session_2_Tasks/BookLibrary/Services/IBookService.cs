using BookLibrary.Entities;

namespace BookLibrary.Services;

public interface IBookService
{

    Task<IEnumerable<Book>> GetAllAsync();

    Task<Book?> GetByIdAsync(int id);

    Task<Book> CreateAsync(Book book);

    Task<bool> UpdateAsync(Book book);

    Task<bool> DeleteAsync(int id);
}
