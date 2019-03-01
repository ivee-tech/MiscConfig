# MiscConfig
Use source agnostic configuration with dependency injection (.NET Core)

## Introduction
This .NET Core console app shows how to use various data sources for configuration settings.
As deployment environments become more and more complex, simply storing the configuration settings in files becomes unmanageable, especially with sensitive information like account names, tenant identifiers, application secrets, etc.
A solution to make your application resilient and agnostic to the configuration data source, whether it's Xml or JSON files, environment variables, database, key vault, etc., is to use dependency injection. This way, you can decouple your code from particular configuration implementations.

## Configuration implementations
To unify the configuration, we can simply use an interface which our code will use to read the configuration settings:

``` C#
    public interface IConfigReader
    {
        string this[string name] { get; }
        string GetValue(string name);
        Task<string> GetValueAsync(string name);
    }
```

The interface <code>IConfigReader</code> (in project **Microsoft.CommonLib**) has the following properties and methods:
 - <code>this[name]</code> - indexer property for convenience;
 - <code>GetValue(string name)</code> - synchronous method to get a configuration value based on its name;
 - <code>Task<string> GetValueAsync(string name)</code> - asynchronous method to get a configuration value based on its name;

 It should be noted that we need the asynchronous method as well, because the implementers might retrieve configuration settings from databases, remote files, or even the cloud.
 If your implementation doesn't need to return the data asynchronously, you can throw a <code>NotImplementedException</code>, or even better, make the sync call async using <code>Task.Run</code>:
 ``` C#
    return await Task.Run(() => ...);
 ```

 The sample contains the following implementations (**Microsoft.ConfigReaders**):
  - <code>NetCoreSettingsConfigReader</code> - uses .NET Core out-of-the box <code>Configuration</code> class
  - <code>EnvVarsConfigReader</code> - gets the configuration settings from environment variables, requires the <code>EnvrionmentVariableTarget</code> (<code>User</code>, <code>Machine</code>, or <code>Process</code>)
  - <code>DictionaryConfigReader</code> - gets the configuration based on a simple <code>IDictionary<string, string></code> source
  - <code>KeyVaultConfigReader</code> - gets the configuration settings stored in Azure Key Vault, using default authentication callback
  - <code>CredentialsKeyVaultConfigReader</code> - gets the configuration settings stored in Azure Key Vault, using an authentication callback which requires an Azure AD registered application id and secret

  In .NET framework, a standard implementation would use <code>ConfigurationManager.AppSettings</code> to retrieve data from *.config* files.

## Configuration consumption
To inject the configuration, we can have a simple consumer class which gets a <code>IConfigReader</code> parameter in the  constructor. We use DI with our <code>Consumer</code> class as well (project **MiscConfig**):

``` C#
    public interface IConsumer
    {
        void Consume();
    }
```
The <code>Consumer</code> class implementation is loose coupled with the configuration:

``` C#
    public class ConfigConsumer : IConsumer
    {

        private IConfigReader _config;

        public ConfigConsumer(IConfigReader config)
        {
            _config = config;
        }

        public void Consume()
        {
            Console.WriteLine($"Hello, {_config["Name"]}!");
        }
    }
```

## IOC
.NET Core comes with its own IOC which makes our code even simpler and with less dependencies.
In the project **MiscConfig**, the <code>Main</code> method uses a basic setup, which creates the configuration we need:

``` C#
    var builder = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
    var configuration = builder.Build();

    IConfigReader appConfig = new NetCoreSettingsConfigReader(configuration);
    IConfigReader credKVConfig1 = new CredentialsKeyVaultConfigReader(appConfig);
    IConfigReader envConfig = new EnvVarsConfigReader(EnvironmentVariableTarget.Machine);
    IConfigReader credKVConfig2 = new CredentialsKeyVaultConfigReader(envConfig);
```

To setup DI, we add our config reader and consumer implementations as singleton and call <code>BuildServiceProvider</code>:

``` C#
    var serviceProvider = new ServiceCollection()
        // .AddSingleton<IConfigReader>(provider => appConfig)
        // .AddSingleton<IConfigReader>(provider => envConfig)
        // .AddSingleton<IConfigReader>(provider => credKVConfig1)
        .AddSingleton<IConfigReader>(provider => credKVConfig2)
        .AddSingleton<IConsumer, ConfigConsumer>()
        .BuildServiceProvider();
```
You can uncomment various <code>AddSingleton</code> lines to see how configuration is retrieved from different sources, with only a simple code change.

The consuming call is simple, we get whatever implementation was configured by DI, then call our <code>Consume</code> method:

``` C#
    var consumer = serviceProvider.GetService<IConsumer>();
    consumer.Consume();
```

## Configure Application & KeyVault in Azure

The application must be registered in Azure AD to get access to an existing Key Vault.
A script is provided to register the application and assign permissions in Key Vault

```
./scripts/create-AAD-app.ps1
```
You will need to provide the application name, and optionally App Uri, Home page Url, and reply Urls.
Additionally, you will need to specify the resource group name and the key vault name.
To execute the script, you will need to connect to Azure using

``` PowerShell
Connect-AzureRmAccount
```

and to Azure AD using

``` PowerShell
Connect-AzureAD
```

For Azure AD operations, make sure the Azure AD module is installed. If not, install it using

``` PowerShell
Install-Module AzureAD
```

Another script is used to set the Name secret in Key Vault

```
./scripts/set-keyvault-secret.ps1
```
You will need to provide the resource group name and key vault name.
To execute the script, connect to Azure first

``` PowerShell
Connect-AzureRmAccount
```

To configure the settings as environment variables, run the following script (make sure you set the corresponding values):

```
./scripts/set-env.ps1
```

If you don't have Administrator permissions, change the target to user and modify the application code to use <code>EnvironmentVariableTarget.User</code>:
``` C#
    IConfigReader envConfig = new EnvVarsConfigReader(EnvironmentVariableTarget.Machine);
```

To run the application, make sure you have .NET Core v2.2 installed and run the following command in the **MiscConfig** project folder:

```
dotnet run
```