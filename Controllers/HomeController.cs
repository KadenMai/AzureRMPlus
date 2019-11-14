using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using AzureRMPlus.Models;
using AzureRMPlus.Helper;
using Microsoft.Extensions.Configuration;

namespace AzureRMPlus.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IConfiguration _Configuration;
        private StorageInfoModel _storageInfo;

        public HomeController(ILogger<HomeController> logger, IConfiguration config)
        {
            _logger = logger;
            _Configuration = config;

            _storageInfo = new StorageInfoModel();
            _Configuration.Bind("StorageInfo", _storageInfo);
        }

        [AllowAnonymous]
        public IActionResult Index()
        {
            return View();
        }

        [AllowAnonymous]
        public IActionResult Subs()
        {
            return View();
        }

        [Authorize]
        public IActionResult Subscriptions()
        {
            List<SubsSumaryModel> lss = new List<SubsSumaryModel>();
            List<string> fileNames = BlobStorageHelper.GetListBlobFile(
                _storageInfo.StorageName,
                _storageInfo.StorageKey,
                _storageInfo.ContainerName,
                ".info").Result;

            foreach(string name in fileNames)
            {
                try
                {
                    lss.Add(GetSubsSumary(name).Result);
                }
                catch
                { // skip the error
                }
            }

            List<SubsSumaryModel> sortedlss = lss.OrderByDescending(o => o.SubsCount).ToList();

            ViewData["lsubs"] = sortedlss;

            return View();
        }

        [AllowAnonymous]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        //=========== Method ================
        private async Task<SubsSumaryModel> GetSubsSumary(string subsname)
        {
            string fileName = string.Format("ResourceInfo_{0}.info", subsname);
            string content = await BlobStorageHelper.GetBlobContent(
                _storageInfo.StorageName,
                _storageInfo.StorageKey,
                _storageInfo.ContainerName,
                subsname);
            SubsSumaryModel ss = new SubsSumaryModel(content);

            return ss;
        }
    }
}
