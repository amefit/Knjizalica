using Knjizalica.Api.Services;

namespace Knjizalica.Worker.Jobs;

public sealed class LoanDueDateMonitorBackgroundService : BackgroundService
{
    private static readonly TimeSpan RunInterval = TimeSpan.FromHours(24);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<LoanDueDateMonitorBackgroundService> _logger;

    public LoanDueDateMonitorBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<LoanDueDateMonitorBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await RunOnceAsync(stoppingToken);

        using var timer = new PeriodicTimer(RunInterval);
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            await RunOnceAsync(stoppingToken);
        }
    }

    private async Task RunOnceAsync(CancellationToken cancellationToken)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var monitor = scope.ServiceProvider.GetRequiredService<LoanDueDateMonitorService>();
            await monitor.ProcessAsync(cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "Loan due-date monitor failed.");
        }
    }
}
