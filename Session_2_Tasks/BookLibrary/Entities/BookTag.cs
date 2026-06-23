namespace BookLibrary.Entities;

// TASK 1.1 — BookTag join entity.
// Books and Tags have a many-to-many relationship; BookTag is the link table
// that connects one Book to one Tag. Multiple BookTag rows model the full
// many-to-many association.
public class BookTag
{
    // Foreign key to the Book side of the link.
    public int BookId { get; set; }

    // Foreign key to the Tag side of the link.
    public int TagId { get; set; }

    
   
}
