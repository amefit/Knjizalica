using System.Text;
using System.Text.Json;
using Knjizalica.Shared.Configuration;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Messages;
using RabbitMQ.Client;

namespace Knjizalica.Api.Messaging;

public interface IMessagePublisher
{
    Task PublishEmailAsync(SendEmailMessage message, CancellationToken cancellationToken = default);
    Task PublishNotificationAsync(SendNotificationMessage message, CancellationToken cancellationToken = default);
}

public sealed class RabbitMqPublisher : IMessagePublisher, IDisposable
{
    private readonly RabbitMqSettings _settings;
    private readonly ILogger<RabbitMqPublisher> _logger;
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    private readonly object _lock = new();
    private IConnection? _connection;
    private bool _disposed;

    public RabbitMqPublisher(AppSettings appSettings, ILogger<RabbitMqPublisher> logger)
    {
        _settings = appSettings.RabbitMq;
        _logger = logger;
    }

    public Task PublishEmailAsync(SendEmailMessage message, CancellationToken cancellationToken = default)
    {
        Publish(RabbitMqConstants.EmailQueue, message);
        return Task.CompletedTask;
    }

    public Task PublishNotificationAsync(SendNotificationMessage message, CancellationToken cancellationToken = default)
    {
        Publish(RabbitMqConstants.NotificationQueue, message);
        return Task.CompletedTask;
    }

    private void Publish<T>(string routingKey, T message)
    {
        using var channel = GetConnection().CreateModel();
        EnsureInfrastructure(channel);

        var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message, _jsonOptions));
        var properties = channel.CreateBasicProperties();
        properties.Persistent = true;
        properties.ContentType = "application/json";

        channel.BasicPublish(
            exchange: RabbitMqConstants.ExchangeName,
            routingKey: routingKey,
            basicProperties: properties,
            body: body);

        _logger.LogInformation("Published message to queue {Queue}", routingKey);
    }

    private IConnection GetConnection()
    {
        if (_connection is { IsOpen: true })
        {
            return _connection;
        }

        lock (_lock)
        {
            if (_connection is { IsOpen: true })
            {
                return _connection;
            }

            var factory = new ConnectionFactory
            {
                HostName = _settings.Host,
                Port = _settings.Port,
                UserName = _settings.Username,
                Password = _settings.Password,
                DispatchConsumersAsync = true
            };

            _connection = factory.CreateConnection();
            return _connection;
        }
    }

    private static void EnsureInfrastructure(IModel channel)
    {
        channel.ExchangeDeclare(RabbitMqConstants.ExchangeName, ExchangeType.Direct, durable: true);
        channel.QueueDeclare(RabbitMqConstants.EmailQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueDeclare(RabbitMqConstants.NotificationQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueBind(RabbitMqConstants.EmailQueue, RabbitMqConstants.ExchangeName, RabbitMqConstants.EmailQueue);
        channel.QueueBind(RabbitMqConstants.NotificationQueue, RabbitMqConstants.ExchangeName, RabbitMqConstants.NotificationQueue);
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _connection?.Dispose();
        _disposed = true;
    }
}
