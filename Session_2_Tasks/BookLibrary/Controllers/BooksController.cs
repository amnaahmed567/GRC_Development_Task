using Microsoft.AspNetCore.Mvc;
using BookLibrary.Entities;
using BookLibrary.Services;

namespace BookLibrary.Controllers;

[ApiController]
[Route("api/books")]   // simplified route (no placeholder)

public class BooksController : ControllerBase
{
    private readonly IBookService _bookService;

    public BooksController(IBookService bookService)
    {
        _bookService = bookService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Book>>> GetAll()
    {
        var books = await _bookService.GetAllAsync();
        return Ok(books);
    }
}