using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AzureRMPlus.Models
{
    public class StorageInfoModel
    {
        public string StorageName { get; set; }
        public string StorageKey { get; set; }
        public string ContainerName { get; set; }
    }
}
