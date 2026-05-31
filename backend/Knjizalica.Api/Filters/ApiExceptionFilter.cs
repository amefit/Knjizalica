using Knjizalica.Shared.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Knjizalica.Api.Filters;

public sealed class ApiExceptionFilter : IExceptionFilter
{
    private readonly ILogger<ApiExceptionFilter> _logger;
    private readonly IHostEnvironment _environment;

    public ApiExceptionFilter(ILogger<ApiExceptionFilter> logger, IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    public void OnException(ExceptionContext context)
    {
        var (statusCode, message) = context.Exception switch
        {
            ValidationAppException ex => (StatusCodes.Status400BadRequest, ex.Message),
            BusinessException ex => (StatusCodes.Status400BadRequest, ex.Message),
            NotFoundException ex => (StatusCodes.Status404NotFound, ex.Message),
            UnauthorizedAppException ex => (StatusCodes.Status401Unauthorized, ex.Message),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.")
        };

        if (statusCode >= StatusCodes.Status500InternalServerError)
        {
            _logger.LogError(context.Exception, "Unhandled exception at {Path}", context.HttpContext.Request.Path);
        }
        else
        {
            _logger.LogWarning(context.Exception, "Handled exception at {Path}", context.HttpContext.Request.Path);
        }

        var response = new ErrorResponse
        {
            Message = message
        };

        if (_environment.IsDevelopment() && statusCode >= StatusCodes.Status500InternalServerError)
        {
            response.Details = context.Exception.Message;
        }

        context.Result = new ObjectResult(response) { StatusCode = statusCode };
        context.ExceptionHandled = true;
    }
}

public sealed class ErrorResponse
{
    public required string Message { get; init; }
    public string? Details { get; set; }
}
