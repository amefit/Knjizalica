using DotNetEnv;
using Knjizalica.Shared.Configuration;
using Knjizalica.Worker.Consumers;

var builder = Host.CreateApplicationBuilder(args);

var envPath = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", "..", ".env"));
if (File.Exists(envPath))
{
    Env.Load(envPath);
}

var appSettings = AppSettingsLoader.LoadFromEnvironment();
builder.Services.AddSingleton(appSettings);
builder.Services.AddHostedService<RabbitMqConsumerService>();

var host = builder.Build();
host.Run();
