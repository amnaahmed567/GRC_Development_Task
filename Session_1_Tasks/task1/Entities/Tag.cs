namespace BookLibrary.Entities;

// TASK 1.1 — Tag entity.
// A tag is a label (e.g. "Fiction", "Classic") that can be attached to many books.
public class Tag
{
    // Primary key for the tag.
    public int Id { get; set; }

    // Display name of the tag.
    public string Name { get; set; } = string.Empty;

    // Navigation property: the link rows joining this tag to its books.
    // The "many" side of the Tag -> BookTag relationship.
    public ICollection<BookTag> BookTags { get; set; } = new List<BookTag>();
}
