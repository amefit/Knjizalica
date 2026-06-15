using DotNetEnv;
using Knjizalica.Api.Data;
using Knjizalica.Api.Messaging;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Configuration;
using Knjizalica.Worker.Consumers;
using Knjizalica.Worker.Jobs;
using Microsoft.EntityFrameworkCore;

var builder = Host.CreateApplicationBuilder(args);

var envPath = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", "..", ".env"));
if (File.Exists(envPath))
{
    Env.Load(envPath);
}

var appSettings = AppSettingsLoader.LoadFromEnvironment();
builder.Services.AddSingleton(appSettings);
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(appSettings.ConnectionString));
builder.Services.AddSingleton<IMessagePublisher, RabbitMqPublisher>();
builder.Services.AddScoped<LoanDueDateMonitorService>();
builder.Services.AddHostedService<RabbitMqConsumerService>();
builder.Services.AddHostedService<LoanDueDateMonitorBackgroundService>();

var host = builder.Build();
host.Run();
