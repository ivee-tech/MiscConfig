using System;
using Microsoft.CommonLib;
using Microsoft.ConfigReaders;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace MiscConfig
{
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
}
