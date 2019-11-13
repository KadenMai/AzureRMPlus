using Microsoft.Azure.Storage;
using Microsoft.Azure.Storage.Auth;
using Microsoft.Azure.Storage.Blob;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace AzureRMPlus.Helper
{
    public static class BlobStorageHelper
    {
        static public async Task<string> GetBlobContent(string StorageName, string StorageKey, string ContainerName, string blobName)
        {
            var storageCredentials = new StorageCredentials(StorageName, StorageKey);
            var cloudStorageAccount = new CloudStorageAccount(storageCredentials, true);

            var blobClient = cloudStorageAccount.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(ContainerName);

            CloudBlockBlob blob = container.GetBlockBlobReference(blobName);

            Stream target = new MemoryStream();
            await blob.DownloadToStreamAsync(target);
            target.Position = 0;

            StreamReader r = new StreamReader(target);

            return r.ReadToEnd();
        }

        static public async Task<List<string>> GetListBlobFile(string StorageName, string StorageKey, string ContainerName, string blogExt)
        {
            var storageCredentials = new StorageCredentials(StorageName, StorageKey);
            var cloudStorageAccount = new CloudStorageAccount(storageCredentials, true);

            var blobClient = cloudStorageAccount.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(ContainerName);

            List<string> fileNames = new List<string>();

            foreach (IListBlobItem item in container.ListBlobs(null, false))
            {
                if (item.GetType() == typeof(CloudBlockBlob))
                {
                    CloudBlockBlob Bblob = (CloudBlockBlob)item;
                    if (Bblob.Name.EndsWith(blogExt, StringComparison.CurrentCultureIgnoreCase))
                        fileNames.Add(Bblob.Name);
                }
            }

            return fileNames;
        }
    }
}
