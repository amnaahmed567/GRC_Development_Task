using BookLibrary.DTOs;

namespace BookLibrary.Services;

// TASK 3.3 — The service contract now speaks in DTOs, not Entities.
//
// Why? The controller (the HTTP layer) should never touch the raw Book entity.
// It hands the service clean DTOs in, and gets clean ResponseDTOs back. The entity
// stays an internal detail of the service.
public interface IBookService
{
    // GetAll now supports FILTERING (by author) and PAGINATION (page + pageSize),
    // so we never blindly return the whole table.
    //   - author?   -> optional filter; null means "no filter".
    //   - page      -> which page of results (1-based).
    //   - pageSize  -> how many items per page.
    Task<IEnumerable<BookResponseDTO>> GetAllAsync(string? author, int page, int pageSize);

    // Returns a single book as a ResponseDTO, or null if not found.
    Task<BookResponseDTO?> GetByIdAsync(int id);

    // Create: input is a CreateDTO, output is the saved book as a ResponseDTO.
    Task<BookResponseDTO> CreateAsync(BookCreateDTO dto);

    // Update: the id comes from the URL, the new values come from the UpdateDTO.
    // Returns true if a book was updated, false if no book had that id.
    Task<bool> UpdateAsync(int id, BookUpdateDTO dto);

    // Delete: returns true if removed, false if no book had that id.
    Task<bool> DeleteAsync(int id);
}
