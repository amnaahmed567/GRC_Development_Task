using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BookLibrary.DTOs;
using BookLibrary.Services;

namespace BookLibrary.Controllers;

// TASK 3.6 — Full CRUD controller.
// The controller holds NO logic: it receives the HTTP request, calls the service,
// and turns the result into the right HTTP response (status code + body).
//
// TASK 4.7 — [Authorize] at the class level protects EVERY endpoint below:
// a request with no valid JWT gets 401 Unauthorized before reaching the action.
[Authorize]
[ApiController]
[Route("api/books")]
public class BooksController : ControllerBase
{
    private readonly IBookService _bookService;

    public BooksController(IBookService bookService)
    {
        _bookService = bookService;
    }

    // GET: /api/books?author=Ali&page=1&pageSize=10
    // [FromQuery] pulls the values from the URL's query string.
    [HttpGet]
    public async Task<ActionResult> GetAll(
        [FromQuery] string? author,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var books = await _bookService.GetAllAsync(author, page, pageSize);
        return Ok(books); // 200 OK
    }

    // GET: /api/books/5
    [HttpGet("{id}")]
    public async Task<ActionResult> GetById(int id)
    {
        var book = await _bookService.GetByIdAsync(id);

        if (book == null)
            return NotFound(); // 404

        return Ok(book); // 200 OK
    }

    // POST: /api/books
    [HttpPost]
    public async Task<ActionResult> Create([FromBody] BookCreateDTO dto)
    {
        var created = await _bookService.CreateAsync(dto);

        // 201 Created + a Location header pointing at GetById for the new book.
        return CreatedAtAction(
            nameof(GetById),
            new { id = created.Id },
            created
        );
    }

    // PUT: /api/books/5
    [HttpPut("{id}")]
    public async Task<ActionResult> Update(int id, [FromBody] BookUpdateDTO dto)
    {
        var result = await _bookService.UpdateAsync(id, dto);

        if (!result)
            return NotFound(); // 404

        return NoContent(); // 204
    }

    // DELETE: /api/books/5
    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(int id)
    {
        var result = await _bookService.DeleteAsync(id);

        if (!result)
            return NotFound(); // 404

        return NoContent(); // 204
    }
}
