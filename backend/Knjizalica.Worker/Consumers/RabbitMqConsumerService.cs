using System.Net;
using System.Text;
using System.Text.Json;
using Knjizalica.Shared.Configuration;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Messages;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace Knjizalica.Worker.Consumers;

public sealed class RabbitMqConsumerService : BackgroundService
{
    private readonly AppSettings _appSettings;
    private readonly ILogger<RabbitMqConsumerService> _logger;
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    private IConnection? _connection;
    private IModel? _channel;

    public RabbitMqConsumerService(AppSettings appSettings, ILogger<RabbitMqConsumerService> logger)
    {
        _appSettings = appSettings;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        stoppingToken.Register(() =>
        {
            _logger.LogInformation("RabbitMQ consumer stopping.");
            _channel?.Close();
            _connection?.Close();
        });

        await ConnectWithRetryAsync(stoppingToken);
        StartEmailConsumer();
        StartNotificationConsumer();

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }

    private async Task ConnectWithRetryAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = _appSettings.RabbitMq.Host,
            Port = _appSettings.RabbitMq.Port,
            UserName = _appSettings.RabbitMq.Username,
            Password = _appSettings.RabbitMq.Password,
            DispatchConsumersAsync = true,
            AutomaticRecoveryEnabled = true
        };

        var delay = TimeSpan.FromSeconds(1);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();
                EnsureInfrastructure(_channel);
                _logger.LogInformation("Connected to RabbitMQ at {Host}:{Port}", _appSettings.RabbitMq.Host, _appSettings.RabbitMq.Port);
                return;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to connect to RabbitMQ. Retrying in {DelaySeconds}s", delay.TotalSeconds);
                await Task.Delay(delay, stoppingToken);
                delay = TimeSpan.FromSeconds(Math.Min(delay.TotalSeconds * 2, 30));
            }
        }
    }

    private void StartEmailConsumer()
    {
        if (_channel == null)
        {
            return;
        }

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.Received += async (_, args) =>
        {
            var retryCount = 0;
            while (retryCount < 4)
            {
                try
                {
                    var json = Encoding.UTF8.GetString(args.Body.ToArray());
                    var message = JsonSerializer.Deserialize<SendEmailMessage>(json, _jsonOptions)
                        ?? throw new InvalidOperationException("Email message payload is invalid.");

                    await SendEmailAsync(message);
                    _channel.BasicAck(args.DeliveryTag, false);
                    return;
                }
                catch (Exception ex)
                {
                    retryCount++;
                    _logger.LogError(ex, "Failed to process email message. Attempt {Attempt}/4", retryCount);
                    if (retryCount >= 4)
                    {
                        _channel.BasicNack(args.DeliveryTag, false, false);
                        return;
                    }

                    await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, retryCount - 1)));
                }
            }
        };

        _channel.BasicConsume(RabbitMqConstants.EmailQueue, autoAck: false, consumer);
        _logger.LogInformation("Listening on queue {Queue}", RabbitMqConstants.EmailQueue);
    }

    private void StartNotificationConsumer()
    {
        if (_channel == null)
        {
            return;
        }

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.Received += async (_, args) =>
        {
            try
            {
                var json = Encoding.UTF8.GetString(args.Body.ToArray());
                var message = JsonSerializer.Deserialize<SendNotificationMessage>(json, _jsonOptions)
                    ?? throw new InvalidOperationException("Notification message payload is invalid.");

                _logger.LogInformation(
                    "Notification queued for user {UserId}: {Title}",
                    message.UserId,
                    message.Title);

                _channel.BasicAck(args.DeliveryTag, false);
                await Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process notification message.");
                _channel.BasicNack(args.DeliveryTag, false, false);
            }
        };

        _channel.BasicConsume(RabbitMqConstants.NotificationQueue, autoAck: false, consumer);
        _logger.LogInformation("Listening on queue {Queue}", RabbitMqConstants.NotificationQueue);
    }

    private async Task SendEmailAsync(SendEmailMessage message)
    {
        var email = new MimeMessage();
        email.From.Add(new MailboxAddress(_appSettings.Smtp.FromName, _appSettings.Smtp.FromEmail));
        email.To.Add(MailboxAddress.Parse(message.ToEmail));
        email.Subject = message.Subject;
        email.Body = new TextPart("plain") { Text = message.Body };

        using var client = new SmtpClient();
        await client.ConnectAsync(
            _appSettings.Smtp.Host,
            _appSettings.Smtp.Port,
            _appSettings.Smtp.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);

        if (!string.IsNullOrWhiteSpace(_appSettings.Smtp.Username))
        {
            await client.AuthenticateAsync(_appSettings.Smtp.Username, _appSettings.Smtp.Password);
        }

        await client.SendAsync(email);
        await client.DisconnectAsync(true);

        _logger.LogInformation("Email sent to {Email}", message.ToEmail);
    }

    private static void EnsureInfrastructure(IModel channel)
    {
        channel.ExchangeDeclare(RabbitMqConstants.ExchangeName, ExchangeType.Direct, durable: true);
        channel.QueueDeclare(RabbitMqConstants.EmailQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueDeclare(RabbitMqConstants.NotificationQueue, durable: true, exclusive: false, autoDelete: false);
        channel.QueueBind(RabbitMqConstants.EmailQueue, RabbitMqConstants.ExchangeName, RabbitMqConstants.EmailQueue);
        channel.QueueBind(RabbitMqConstants.NotificationQueue, RabbitMqConstants.ExchangeName, RabbitMqConstants.NotificationQueue);
    }

    public override void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
        base.Dispose();
    }
}
