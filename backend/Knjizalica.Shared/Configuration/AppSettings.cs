namespace Knjizalica.Shared.Configuration;

public sealed class AppSettings
{
    public required string ConnectionString { get; init; }
    public required JwtSettings Jwt { get; init; }
    public required RabbitMqSettings RabbitMq { get; init; }
    public required SmtpSettings Smtp { get; init; }
    public required string[] CorsOrigins { get; init; }
    public int ApiPort { get; init; } = 5000;
}

public sealed class JwtSettings
{
    public required string Key { get; init; }
    public required string Issuer { get; init; }
    public required string Audience { get; init; }
    public int ExpirationMinutes { get; init; } = 60;
}

public sealed class RabbitMqSettings
{
    public required string Host { get; init; }
    public int Port { get; init; } = 5672;
    public required string Username { get; init; }
    public required string Password { get; init; }
}

public sealed class SmtpSettings
{
    public required string Host { get; init; }
    public int Port { get; init; } = 587;
    public required string Username { get; init; }
    public required string Password { get; init; }
    public bool UseSsl { get; init; } = true;
    public required string FromEmail { get; init; }
    public required string FromName { get; init; }
}

public static class AppSettingsLoader
{
    public static AppSettings LoadFromEnvironment()
    {
        return new AppSettings
        {
            ConnectionString = GetRequired("DB_CONNECTION_STRING"),
            Jwt = new JwtSettings
            {
                Key = GetRequired("JWT_KEY"),
                Issuer = GetRequired("JWT_ISSUER"),
                Audience = GetRequired("JWT_AUDIENCE"),
                ExpirationMinutes = int.Parse(GetOptional("JWT_EXPIRATION_MINUTES", "60"))
            },
            RabbitMq = new RabbitMqSettings
            {
                Host = GetRequired("RABBITMQ_HOST"),
                Port = int.Parse(GetOptional("RABBITMQ_PORT", "5672")),
                Username = GetRequired("RABBITMQ_USERNAME"),
                Password = GetRequired("RABBITMQ_PASSWORD")
            },
            Smtp = new SmtpSettings
            {
                Host = GetRequired("SMTP_HOST"),
                Port = int.Parse(GetOptional("SMTP_PORT", "587")),
                Username = GetRequired("SMTP_USERNAME"),
                Password = GetRequired("SMTP_PASSWORD"),
                UseSsl = bool.Parse(GetOptional("SMTP_USE_SSL", "true")),
                FromEmail = GetRequired("SMTP_FROM_EMAIL"),
                FromName = GetRequired("SMTP_FROM_NAME")
            },
            CorsOrigins = GetOptional("CORS_ORIGINS", "http://localhost:3000")
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries),
            ApiPort = int.Parse(GetOptional("API_PORT", "5000"))
        };
    }

    private static string GetRequired(string key)
    {
        var value = Environment.GetEnvironmentVariable(key);
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException($"Missing required environment variable: {key}");
        }

        return value;
    }

    private static string GetOptional(string key, string defaultValue)
    {
        return Environment.GetEnvironmentVariable(key) ?? defaultValue;
    }
}
