using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AzureRMPlus.Models
{
    public class SubsSumaryModel
    {
        public string SubsName { get; set; }
        public string SubsTime { get; set; }
        public string SubsCount { get; set; }

        public SubsSumaryModel(string str)
        {
            string[] infos = str.Split('\n', StringSplitOptions.RemoveEmptyEntries);
            SubsName = infos[0].Trim('\r');
            SubsTime = infos[1].Trim('\r');
            SubsCount = infos[2].Trim('\r');
        }
    }
}
