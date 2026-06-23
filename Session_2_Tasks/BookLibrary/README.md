# BookLibrary

A small .NET 8 console app demonstrating entity classes, an in-memory data
store, LINQ queries, and a CRUD service layer.

## Project structure

```
BookLibrary.csproj
Program.cs                  # Entry point — runs the queries and CRUD demo
Entities/
  Author.cs                 # TASK 1.1 — Author (Id, Name, ICollection<Book>)
  Book.cs                   # TASK 1.1 — Book (Id, Title, Year, PageCount, AuthorId, Author nav)
  Tag.cs                    # TASK 1.1 — Tag (Id, Name)
  BookTag.cs                # TASK 1.1 — BookTag join entity (BookId, TagId)
Data/
  InMemoryStore.cs          # TASK 1.2 — Static store seeded with 3 authors, 8 books, 4 tags, 6 links
Queries/
  BookQueries.cs            # TASK 1.3 — Eight LINQ queries
Services/
  IBookService.cs           # TASK 1.4 — CRUD interface (GetAll, GetById, Create, Update, Delete)
  BookService.cs            # TASK 1.5 — Implementation against InMemoryStore
```

## The 8 LINQ queries (Task 1.3)

1. Filter books by author (`Where`)
2. Select titles, sorted A–Z (`OrderBy` + `Select`)
3. Group books by author with counts (`GroupBy`)
4. Average page count (`Average`)
5. Any book over 500 pages (`Any`)
6. Find a book by Id (`FirstOrDefault`)
7. Join books with authors (`Join`)
8. Top 3 longest books (`OrderByDescending` + `Take`)

## How to run

You need the [.NET 8 SDK](https://dotnet.microsoft.com/download) installed
(verify with `dotnet --version`).

From the project folder:

```bash
dotnet run
```

That single command restores, builds, and runs the app. You'll see the output
of all eight LINQ queries followed by a CRUD demonstration of `BookService`.

### Optional

```bash
dotnet build      # compile only, without running
dotnet clean      # remove build artifacts (bin/ and obj/)
```
