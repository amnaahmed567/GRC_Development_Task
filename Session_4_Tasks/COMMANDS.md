# Session 4 — Commands Reference

Simple list of the terminal commands run in each task.

---

## Task 4.1 — AppDbContext + Pomelo

Install EF Core + the MySQL provider (Pomelo) and the migration tooling:

```bash
dotnet add package Pomelo.EntityFrameworkCore.MySql --version 8.0.2
dotnet add package Microsoft.EntityFrameworkCore.Design --version 8.0.6
```

Build to confirm it compiles:

```bash
dotnet build
```

---

## Task 4.2 — First migration + create tables

Install the EF command-line tool (only needed once per machine):

```bash
dotnet tool install --global dotnet-ef
```

Create the first migration and apply it to MySQL:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

Verify the tables were created:

```bash
# inside MySQL
SHOW TABLES;
DESCRIBE Books;
DESCRIBE BookTags;
```

---

## Task 4.3 — Seed data

Seed rows were added with `HasData(...)` in AppDbContext, then turned into a migration and applied:

```bash
dotnet ef migrations add SeedData
dotnet ef database update
```

Verify the rows:

```sql
SELECT COUNT(*) FROM Authors;   -- 3
SELECT COUNT(*) FROM Books;     -- 8
SELECT COUNT(*) FROM Tags;      -- 4
SELECT COUNT(*) FROM BookTags;  -- 6
```

---

## Task 4.4 — Use AppDbContext in BookService

No EF commands here — just code changes (deleted InMemoryStore.cs, rewrote BookService).
Build and run to test:

```bash
dotnet build
dotnet run
```

Test the endpoints (in another terminal):

```bash
curl "http://localhost:5000/api/books?page=1&pageSize=3"
curl "http://localhost:5000/api/books?author=Orwell"
curl "http://localhost:5000/api/books/6"
```

---

## Task 4.5 — Verify controller unchanged

No code changes. Just ran the app and tested every endpoint:

```bash
dotnet run
```

```bash
# GET all + paging
curl "http://localhost:5000/api/books?page=1&pageSize=2"

# GET by id
curl "http://localhost:5000/api/books/1"

# POST (create)
curl -X POST "http://localhost:5000/api/books" \
     -H "Content-Type: application/json" \
     -d '{"title":"Test Book","pageCount":123,"authorId":2}'

# PUT (update)
curl -X PUT "http://localhost:5000/api/books/9" \
     -H "Content-Type: application/json" \
     -d '{"title":"Test Book UPDATED","pageCount":200,"authorId":2}'

# DELETE
curl -X DELETE "http://localhost:5000/api/books/9"
```

---

## Task 4.6 — Add Isbn column (migrate, revert, re-apply)

After adding `Isbn` to Book.cs:

```bash
# 1. create the migration
dotnet ef migrations add AddIsbnToBook

# 2. apply it (adds the Isbn column)
dotnet ef database update

# 3. revert it (drops the Isbn column, keeps seed data)
dotnet ef database update SeedData

# 4. re-apply it (adds the Isbn column back)
dotnet ef database update
```

Verify the column:

```sql
SHOW COLUMNS FROM Books;   -- should list: Isbn
```

---

## Handy EF commands cheat-sheet

```bash
dotnet ef migrations add <Name>      # create a new migration
dotnet ef database update            # apply all pending migrations
dotnet ef database update <Name>     # roll forward/back to a specific migration
dotnet ef database update 0          # roll back ALL migrations (drops everything)
dotnet ef migrations list            # list migrations + which are applied/pending
dotnet ef migrations remove          # delete the last (unapplied) migration file
```

## Connecting to MySQL from the terminal

```bash
mysql -h 127.0.0.1 -P 3307 -u root -p BookLibraryDB
# (then type the password when prompted)
```
