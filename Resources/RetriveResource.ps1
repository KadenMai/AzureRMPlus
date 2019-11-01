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

    $rsLogs = Get-AzLog -StartTime (Get-Date).AddDays(-90) -ResourceId $rs.ResourceId
       
    $firstCaller = ""
    $lastCaller = ""
    $firstTime = (Get-Date).AddDays(1);
    $lastTime = (Get-Date).AddDays(-90);

    if(!$rsLogs){   # The resource doesn't have any log in past 90 days
        $firstTime = (Get-Date -Year 2000 -Month 1 -Day 1)
        $lastTime = (Get-Date -Year 2000 -Month 1 -Day 1)
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
            }

            # Update the last_Time
            if($lastTime -lt (get-date($log.SubmissionTimestamp)))
            {
                $lastTime = (get-date($log.SubmissionTimestamp))
                $lastCaller = $caller;
            }
        }
    }

    $firstAccess =  $firstTime.ToString("yyyy-MM-dd");
    $lastAccess = $lastTime.ToString("yyyy-MM-dd");
    return @{ firstCaller= $firstCaller; lastCaller=$lastCaller; firstAccess = $firstAccess; lastAccess = $lastAccess }

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

    Select-AzSubscription $subscriptionName

    $startTime = (Get-Date)

    # Get list of Resource
    $listResource = Get-AzResource -ExpandProperties
    echo $listResource.Count # show the total rsource
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

        $countResource += 1

        $rsLogs = Get-AzLog -StartTime (Get-Date).AddDays(-90) -ResourceId $rs.ResourceId
       
        $firstCaller = ""
        $lastCaller = ""
        $firstTime = (Get-Date).AddDays(1);
        $lastTime = (Get-Date).AddDays(-90);

        if(!$rsLogs){   # The resource doesn't have any log in past 90 days
            $firstTime = (Get-Date -Year 1 -Month 1 -Day 1)
            $lastTime = (Get-Date -Year 1 -Month 1 -Day 1)
        }
        else{   # The resource has log in past 90 days
            foreach($log in $rsLogs)
            {
                if($log.Caller.Contains("@hrblock.com")){
                    $caller = $log.Caller.Replace("@hrblock.com","")   # Get the caller
                }
                else
                {
                    continue
                }

                # Get the boundary time
                # Update the first_Time
                if($firstTime -gt [datetime]$log.SubmissionTimestamp)
                {
                    $firstTime = ($log.SubmissionTimestamp)
                    if(![String]::IsNullOrEmpty($log.Caller)){
                        $firstCaller = $log.Caller.Replace("@hrblock.com","")   # Get the caller
                    }
                }

                # Update the last_Time
                if($lastTime -lt [datetime]$log.SubmissionTimestamp)
                {
                    $lastTime = $log.SubmissionTimestamp
                    if(![String]::IsNullOrEmpty($log.Caller)){
                        $lastCaller = $log.Caller.Replace("@hrblock.com","")   # Get the caller
                    }
                }
            }
        }

        $propertisejson = $rs.Properties | ConvertTo-Json -Depth 10
   
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
                                       "ResourceType" = $rs.ResourceType;
                                       "ResourceGroupName" = $rs.ResourceGroupName;
                                       "Location" = $rs.Location;
                                       "FirstTime" = $firstTime;
                                       "FirstCaller" = $firstCaller;
                                       "LastTime" = $lastTime;
                                       "LastCaller" = $lastCaller;
                                       "ExtraInfo" = $ExtraInfo;
                                       "Metric" = $Metric;
                                       "Propertises" = $Propertises
                                       })
    }

    $rsInfor | Export-Clixml  $path.TrimEnd("\") + "\ResourceInfo_" + $subscriptionName.Replace(" ","").ToLower() +  ".xml"

    $prepare = @{"data" = $rsInfor.Values}

    $outputPath = $path.TrimEnd("\") + "\ResourceInfo_" + $subscriptionName.Replace(" ","").ToLower() +  ".json"

    $prepare | ConvertTo-Json -Depth 10 | Out-File $outputPath



    $info = "$subscriptionName`n$startTime`n" + $countResource

    $info_file = $path.TrimEnd("\") + "\ResourceInfo_" + $subscriptionName.Replace(" ","").ToLower() +  ".info"

    $info | Out-File $info_file

}

$path = "C:\Users\X169392\Source\Repos\KadenMai\AzureRMApp.Identity\AzureRMApp.Identity\wwwroot\data"

$ignoreType = "microsoft.alertsmanagement/smartdetectoralertrules", `
            "Microsoft.Portal/dashboards", `
            "microsoft.alertsmanagement/smartdetectoralertrules", `
            "Microsoft.Compute/virtualMachines/extensions", `
            "microsoft.insights/metricAlerts", `
            "microsoft.insights/actionGroups", `
            "Microsoft.ContainerRegistry/registries", `
            "Microsoft.Web/serverfarms"
            
            

do{

GetResourceInfo_main -path $path -subscriptionName "Sandbox"
#GetResourceInfo_main -path $path -subscriptionName "Development"
}
while ($true) # infinity loop