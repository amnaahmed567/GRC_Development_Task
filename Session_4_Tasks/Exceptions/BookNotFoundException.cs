namespace BookLibrary.Exceptions;

public class BookNotFoundException : Exception
{

    public BookNotFoundException(int id)
        : base($"Book with Id {id} was not found.")
    {
    }
}
