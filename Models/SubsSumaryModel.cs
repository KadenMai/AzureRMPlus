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
        public int SubsCount { get; set; }
        public string SubsId { get; set; }

        public SubsSumaryModel(string str)
        {
            string[] infos = str.Split('\n', StringSplitOptions.RemoveEmptyEntries);
            SubsName = infos[0].Trim('\r');
            SubsTime = infos[1].Trim('\r');
            SubsCount = Convert.ToInt32(infos[2].Trim('\r'));
            SubsId = infos[3].Trim('\r');
        }
    }
}
