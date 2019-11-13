
function GetMaxMetricResource ($rs, $starttime)
{  
    try{
        # Microsoft.Sql/servers/databases
        if($rs.ResourceType -eq "Microsoft.Sql/servers/databases"){
            $metric = Get-AzMetric -ResourceId $rs.ResourceId -TimeGrain 00:5:00 -MetricName "dtu_consumption_percent" -StartTime $starttime
        }
       
        else {
            if($rs.ResourceType -eq "Microsoft.Compute/virtualMachines")
            {
                $metric = Get-AzMetric -ResourceId $rs.ResourceId -TimeGrain 00:5:00 -MetricName "Percentage CPU" -StartTime $starttime
            }
       
            else {
                $metric = Get-AzMetric -ResourceId $rs.ResourceId -TimeGrain 00:5:00 -StartTime $starttime
            }
        }

        if($metric.Data -and $metric.Data.Count -gt 0){
            $maxMetric = 0
            foreach($value in $metric.Data){
                if($maxMetric -lt $value.Average){
                    $maxMetric = $value.Average
                }
            }
            return $maxMetric
        }
        else
        {
            return $null
        }
    }catch {
        return $null
    }
}

function GetExtraInfo{
    param ($rs)

    $ExtraInfo = ""

    # Microsoft.Sql/servers/databases
    if($rs.ResourceType -eq "Microsoft.Sql/servers/databases"){
        $ExtraInfo = $rs.Properties.serviceLevelObjective
    }

    # Microsoft.Compute/virtualMachines
    if($rs.ResourceType -eq "Microsoft.Compute/virtualMachines"){
        $ExtraInfo = $rs.Properties.hardwareProfile.vmSize
    }

    # Microsoft.DataMigration/services
    if($rs.ResourceType -eq "Microsoft.DataMigration/services"){
        $ExtraInfo = $rs.Properties.provisioningState
    }

#    # Microsoft.Compute/disks
#    if($rs.ResourceType -eq "Microsoft.Compute/disks"){
#        $ExtraInfo = $rs.Properties.diskSizeGB.ToString() + " GB"
#    }

    return $ExtraInfo
}

function GetAccessLog{
    param ($rs)

    $rsLogs = Get-AzLog -StartTime (Get-Date).AddDays(-89) -ResourceId $rs.ResourceId
    echo "Total Log: "$rsLogs.Count
       
    $firstCaller = ""
    $lastCaller = ""
    $firstCallerName = ""
    $lastCallerName = ""
    $firstTime = (Get-Date -Year 4000 -Month 1 -Day 1)
    $lastTime = (Get-Date -Year 0001 -Month 1 -Day 1)
    $listLog = New-Object System.Collections.ArrayList

    if(!$rsLogs){   # The resource doesn't have any log in past 90 days
        $firstTime = (Get-Date -Year 0001 -Month 1 -Day 1)
        $lastTime = (Get-Date -Year 0001 -Month 1 -Day 1)
    }
    else{   # The resource has log in past 90 days
        foreach($log in $rsLogs)
        {
            echo $log.Caller
            if($log.Caller.Contains("@hrblock.com")){
                $caller = $log.Caller.Replace("@hrblock.com","")   # Get the caller
            }
            else
            {           
                continue
            }

            # Get the boundary time
            # Update the first_Time
            if($firstTime -gt (get-date($log.SubmissionTimestamp)))
            {
                $firstTime = (get-date($log.SubmissionTimestamp))
                $firstCaller = $caller;
                $firstCallerName = $log.Claims.Content["name"];
            }

            # Update the last_Time
            if($lastTime -lt (get-date($log.SubmissionTimestamp)))
            {
                $lastTime = (get-date($log.SubmissionTimestamp))
                $lastCaller = $caller;
                $lastCallerName = $log.Claims.Content["name"];
            }

            $strLog = (get-date($log.SubmissionTimestamp)).ToString("u") + " | " `
                        + $log.Claims.Content["name"] + " | " `
                        + $log.OperationName.LocalizedValue 
            $listLog.Add($strLog)

        }
    }
    
    if($firstTime.Year -eq 4000)
    {
        $firstTime = (Get-Date -Year 0001 -Month 1 -Day 1)
    }

    $firstAccess =  $firstTime.ToString("g");
    $lastAccess = $lastTime.ToString("g");
    return @{ firstCaller= $firstCaller; 
              firstCallerName = $firstCallerName;
              lastCaller=$lastCaller; 
              lastCallerName = $lastCallerName;
              firstAccess = $firstAccess; 
              lastAccess = $lastAccess;
              listLog = $listLog }

}


$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Update function ToString of Hashtable, generate long string
Update-TypeData -TypeName System.Collections.HashTable `
    -MemberType ScriptMethod `
    -MemberName ToString `
    -Value { $hashstr = "@{"; $keys = $this.keys; foreach ($key in $keys) { $v = $this[$key];
             if ($key -match "\s") { $hashstr += "`"$key`"" + "=" + "`"$v`"" + ";" }
             else { $hashstr += $key + "=" + "`"$v`"" + ";" } }; $hashstr += "}";
             return $hashstr }


function GetResourceInfo_main{
    param([string]$subscriptionName,
          [string]$path)

    echo "Subscription: $subscriptionName"
    $subs = Select-AzSubscription $subscriptionName

    $startTime = (Get-Date)

    # Get list of Resource
    $listResource = Get-AzResource -ExpandProperties
    echo "Total resources: " $listResource.Count # show the total rsource
    # Create Resource Infor
    $rsInfor = @{}

    # Travel each resource
    $countResource = 0

    foreach($rs in $listResource)
    {
        if($ignoreType.Contains($rs.ResourceType))
        {
            continue
        }

        Write-Host "Working on: " $rs.ResourceId

        $countResource += 1

        # $rsLogs = Get-AzLog -StartTime (Get-Date).AddDays(-90) -ResourceId $rs.ResourceId
        # echo "Total Log in fuction: "$rsLogs.Count

        ###################### Get list of Logs #############################
        $listActiveLog = GetAccessLog $rs
        $formatListLog = $listActiveLog.listLog

        if($listActiveLog.listLog.Count -eq 0)
        {
            $formatListLog = @(" ")
        }

        echo $listActiveLog.firstAccess
        echo $listActiveLog.firstCaller

        # $propertisejson = $rs.Properties | ConvertTo-Json -Depth 10
   
        ###################### Create and get Extra Infor #############################
   
        $ExtraInfo = GetExtraInfo $rs
   
        ##################### Convert Propertise to String ####################
        $PropertiseHT = @{}
        $rs.Properties.psobject.Properties | Foreach { $PropertiseHT[$_.Name] = $_.Value }
        $Propertises = $PropertiseHT.ToString()

        ##################### Get Metric ####################
        #$checkMetricTime = (Get-Date).AddDays(-3)
        #$Metric = GetMaxMetricResource -rs $rs -starttime $checkMetricTime
        $Metric = ""

        $rsInfor.Add($rs.ResourceId, @{
                                       "ResourceId" = $rs.ResourceId;
                                       "ResourceName" = $rs.Name;
                                       "ResourceType" = $rs.ResourceType.Replace("Microsoft.","MS.");
                                       "ResourceGroupName" = $rs.ResourceGroupName;
                                       "Location" = $rs.Location.ToUpper();
                                       "FirstTime" = $listActiveLog.firstAccess;
                                       "FirstCaller" = $listActiveLog.firstCaller;
                                       "FirstCallerName" = $listActiveLog.firstCallerName;
                                       "LastTime" = $listActiveLog.lastAccess;
                                       "LastCaller" = $listActiveLog.lastCaller;
                                       "LastCallerName" = $listActiveLog.lastCallerName;
                                       "ExtraInfo" = $ExtraInfo;
                                       "Metric" = $Metric;
                                       "Propertises" = $Propertises;
                                       "ListLogs" = $formatListLog
                                       })
    }

    #$rsInfor | Export-Clixml  $path.TrimEnd("\") + "\ResourceInfo_" + $subscriptionName.Replace(" ","").ToLower() +  ".xml"

    $prepare = @{"data" = $rsInfor.Values}

    $outputFile = "ResourceInfo_" + $subs.Subscription.Id +  ".json"

    $outputPath = $path.TrimEnd("\") + "\" + $outputFile

    $prepare | ConvertTo-Json -Depth 10 | Out-File $outputPath



    $info = "$subscriptionName`n$startTime`n$countResource`n" + $subs.Subscription.Id

    $info_file = "ResourceInfo_" + $subs.Subscription.Id +  ".info"

    $info_path = $path.TrimEnd("\") + "\" + $info_file

    $info | Out-File $info_path

    Set-AzStorageBlobContent -File $outputPath `
      -Container $containerName `
      -Blob $outputFile `
      -Context $context `
      -Force

    Set-AzStorageBlobContent -File $info_path `
      -Container $containerName `
      -Blob $info_file `
      -Context $context `
      -Force
}



$ignoreType = "microsoft.alertsmanagement/smartdetectoralertrules", `
            "Microsoft.Portal/dashboards", `
            "microsoft.alertsmanagement/smartdetectoralertrules", `
            "Microsoft.Compute/virtualMachines/extensions", `
            "microsoft.insights/metricAlerts", `
            "microsoft.insights/actionGroups", `
            "Microsoft.ContainerRegistry/registries", `
            "Microsoft.Web/serverfarms"
            
            
                     
# Login by SP
# $azureAplicationId = "c299de05-d13a-4ede-9809-4245e32dbcae"
# $azureTenantId= "3ec4eda1-a5d1-433d-90da-8dc791283d95"
# $azurePassword = ConvertTo-SecureString "35ec0012-3654-bb46-72d0-b89ed3baa72e" -AsPlainText -Force
# $psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
# Add-AzAccount -Credential $psCred -TenantId $azureTenantId  -ServicePrincipal 

# Storage
$storage = "storageaccounta3tsaac11"
$key = "nuY+GC/XM2yOYb+g7u0HV+qj3pnTbktGME+E+u4RWL8tjcTopyasrxEzzrez7kwTr7tkpQfx772T3uNdI9gdXw=="
$containerName = "azurermapp"
$context = New-AzStorageContext -StorageAccountName $storage -StorageAccountKey $key

$path = "C:\ezpath\data"


GetResourceInfo_main -path $path -subscriptionName "Sandbox"
GetResourceInfo_main -path $path -subscriptionName "Hub"
#GetResourceInfo_main -path $path -subscriptionName "Development"