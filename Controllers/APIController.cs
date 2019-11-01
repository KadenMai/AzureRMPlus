using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using AzureRMPlus.Helper;
using AzureRMPlus.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Storage;
using Microsoft.Azure.Storage.Auth;
using Microsoft.Azure.Storage.Blob;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AzureRMPlus.Controllers
{
    public class APIController : Controller
    {
        private readonly ILogger<APIController> _logger;
        private readonly IConfiguration _Configuration;
        private StorageInfoModel _storageInfo;

        public APIController(ILogger<APIController> logger, IConfiguration config)
        {
            _logger = logger;
            _Configuration = config;

            _storageInfo = new StorageInfoModel();
            _Configuration.Bind("StorageInfo", _storageInfo);
        }

        [Authorize]
        public IActionResult SubsDetails([FromQuery(Name = "subs")] string subs)
        {
            string fileName = string.Format("ResourceInfo_{0}.json", subs);
            string content = BlobStorageHelper.GetBlobContent(
                _storageInfo.StorageName,
                _storageInfo.StorageKey,
                _storageInfo.ContainerName,
                fileName).Result;

            return Content(content);

            //return View();
        }

        [AllowAnonymous]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        // ============= Support Method ===================
        

        

    }
}