param(
    [parameter(Mandatory = $true)]
    [string]$sha, # the sha of the deployment to track
    [parameter(Mandatory = $true)]
    [string]$repoUrl, # the url of the repository of the deployment to track
    [parameter(Mandatory = $true)]
    [string]$env, # the environment used in the deployment (pre or prod)
    [parameter(Mandatory = $false)]
    [DateTimeOffset]$deploymentDateTimeOffset # the time of the deployment
)

function Write-CloudWatchLog($currentTime, $sha, $repositoryUrl, $environment) {
    $message = @{
        Environment   = $environment
        Timestamp     = $currentTime
        HeadSha       = $sha
        RepositoryUrl = $repositoryUrl
    }

    $logEntry = New-Object -TypeName 'Amazon.CloudWatchLogs.Model.InputLogEvent'
    $logEntry.Message = ($message | ConvertTo-Json)
    $logEntry.Timestamp = (Get-Date).ToUniversalTime()

    $stream = Get-CWLLogStream -LogGroupName "DORASupportInfrastructureLogGroup" -LogStreamNamePrefix "GitHubLogStream"
    $response = Write-CWLLogEvent -SequenceToken $stream.UploadSequenceToken -LogGroupName "DORASupportInfrastructureLogGroup" -LogStreamName "GitHubLogStream" -LogEvent $logEntry
    
    Write-Host "Next Sequence Token" $response
}

Import-Module AWS.Tools.CloudWatchLogs
$dateTime;
if ($deploymentDateTimeOffset) {
    $dateTime = $deploymentDateTimeOffset
}
else {
    $dateTime = [DateTimeOffset]::Now
}

try {
    Write-Host "Logging to cloudwatch"
    $formattedDate = $dateTime.ToUniversalTime().ToString("o")
    Write-CloudWatchLog $formattedDate $sha $repoUrl $env
}
catch {
    Write-Host "Deploy Tracking Call To CloudWatch Failed"
    Write-Host $_
}
