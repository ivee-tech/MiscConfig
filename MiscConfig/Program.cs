using System;
using Microsoft.CommonLib;
using Microsoft.ConfigReaders;
using Microsoft.Extensions.Configuration;
using System.IO;
using Microsoft.Extensions.DependencyInjection;

namespace MiscConfig
{
    class Program
    {
        static void Main(string[] args)
        {
            var builder = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
            var configuration = builder.Build();

            IConfigReader appConfig = new NetCoreSettingsConfigReader(configuration);
            IConfigReader credKVConfig1 = new CredentialsKeyVaultConfigReader(appConfig);
            IConfigReader envConfig = new EnvVarsConfigReader(EnvironmentVariableTarget.Machine);
            IConfigReader credKVConfig2 = new CredentialsKeyVaultConfigReader(envConfig);

            var serviceProvider = new ServiceCollection()
                // .AddSingleton<IConfigReader>(provider => appConfig)
                // .AddSingleton<IConfigReader>(provider => envConfig)
                // .AddSingleton<IConfigReader>(provider => credKVConfig1)
                .AddSingleton<IConfigReader>(provider => credKVConfig2)
                .AddSingleton<IConsumer, ConfigConsumer>()
                .BuildServiceProvider();

            var consumer = serviceProvider.GetService<IConsumer>();
            consumer.Consume();

        }
    }
}
