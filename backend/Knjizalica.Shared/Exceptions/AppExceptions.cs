namespace Knjizalica.Shared.Exceptions;

public abstract class AppException : Exception
{
    protected AppException(string message) : base(message)
    {
    }
}

public sealed class BusinessException : AppException
{
    public BusinessException(string message) : base(message)
    {
    }
}

public sealed class NotFoundException : AppException
{
    public NotFoundException(string message) : base(message)
    {
    }
}

public sealed class UnauthorizedAppException : AppException
{
    public UnauthorizedAppException(string message) : base(message)
    {
    }
}

public sealed class ValidationAppException : AppException
{
    public ValidationAppException(string message) : base(message)
    {
    }
}
