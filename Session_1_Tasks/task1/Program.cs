using BookLibrary.Entities;
using BookLibrary.Queries;
using BookLibrary.Services;

// Entry point: demonstrates the LINQ queries (Task 1.3) and then the
// CRUD operations exposed by BookService / IBookService (Tasks 1.4 & 1.5).

// 1) Run the eight LINQ queries against the seeded in-memory data.
BookQueries.RunAll();

// 2) Exercise the service layer through the IBookService interface.
IBookService service = new BookService();

Console.WriteLine("===== BOOK SERVICE (CRUD) =====\n");

// GetAll
Console.WriteLine($"GetAll -> {service.GetAll().Count()} books in store.");

// GetById
var found = service.GetById(1);
Console.WriteLine($"GetById(1) -> {found?.Title ?? "not found"}");

// Create
var created = service.Create(new Book
{
    Title = "Brave New World",
    Year = 1932,
    PageCount = 311,
    AuthorId = 1
});
Console.WriteLine($"Create -> added '{created.Title}' with new Id {created.Id}. " +
                  $"Store now has {service.GetAll().Count()} books.");

// Update
bool updated = service.Update(new Book
{
    Id = created.Id,
    Title = "Brave New World (Revised)",
    Year = 1946,
    PageCount = 320,
    AuthorId = 1
});
Console.WriteLine($"Update({created.Id}) -> success: {updated}. " +
                  $"New title: {service.GetById(created.Id)?.Title}");

// Delete
bool deleted = service.Delete(created.Id);
Console.WriteLine($"Delete({created.Id}) -> success: {deleted}. " +
                  $"Store now has {service.GetAll().Count()} books.");
