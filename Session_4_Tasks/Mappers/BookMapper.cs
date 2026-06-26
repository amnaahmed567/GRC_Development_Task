using BookLibrary.DTOs;
using BookLibrary.Entities;

namespace BookLibrary.Mappers;

// TASK 3.2 — Manual mapper (no AutoMapper).
//
// A "mapper" is just a bridge that converts between the two worlds:
//   DTO  (clean data the API talks in)  <->  Book entity (the real model the service stores)
//
// It is a STATIC class so we never create an instance of it — we just call its
// helper methods directly, e.g.  BookMapper.ToResponse(book).
public static class BookMapper
{
    // CreateDTO -> new Entity.
    // Used when CREATING a book. We do NOT copy an Id here — the service assigns it.
    public static Book ToEntity(BookCreateDTO dto)
    {
        return new Book
        {
            Title = dto.Title,
            PageCount = dto.PageCount,
            AuthorId = dto.AuthorId
        };
    }

    // UpdateDTO -> EXISTING Entity.
    // Used when UPDATING. We mutate the book we already have instead of creating a
    // new one, so its Id (and anything else not in the DTO) is preserved.
    public static void ApplyUpdate(BookUpdateDTO dto, Book book)
    {
        book.Title = dto.Title;
        book.PageCount = dto.PageCount;
        book.AuthorId = dto.AuthorId;
    }

    // Entity -> ResponseDTO.
    // Used when sending data BACK to the client, so we never leak internal entity
    // details (navigation properties, etc.) — only the clean fields we choose.
    public static BookResponseDTO ToResponse(Book book)
    {
        return new BookResponseDTO
        {
            Id = book.Id,
            Title = book.Title,
            PageCount = book.PageCount,
            AuthorId = book.AuthorId
        };
    }
}
