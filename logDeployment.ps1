param(
    [parameter(Mandatory = $true)]
    [string]$sha,
    [parameter(Mandatory = $true)]
    [string]$repoUrl,
    [parameter(Mandatory = $true)]
    [string]$env
)

function Write-CloudWatchLog($currentTime, $hash, $repositoryUrl, $environment) {
    $message = @{
        Environment   = $environment
        Timestamp     = $currentTime
        HeadSha       = $hash
        RepositoryUrl = $repositoryUrl
    }

    $logEntry = New-Object -TypeName 'Amazon.CloudWatchLogs.Model.InputLogEvent'
    $logEntry.Message = ($message | ConvertTo-Json)
    $logEntry.Timestamp = (Get-Date).ToUniversalTime()

    $stream = Get-CWLLogStream -LogGroupName "DORASupportInfrastructureLogGroup" -LogStreamNamePrefix "OctoLogStream"
    $response = Write-CWLLogEvent -SequenceToken $stream.UploadSequenceToken -LogGroupName "DORASupportInfrastructureLogGroup" -LogStreamName "OctoLogStream" -LogEvent $logEntry
    
    Write-Host "Next Sequence Token" $response
}

function Write-LinearB($currentTimeInUnixSeconds, $hash, $repositoryUrl, $environment) {
    $uri = "https://public-api.linearb.io/api/v1/cycle-time-stages"
    $body = @{
        head_sha   = $hash
        repo_url   = $repositoryUrl
        stage_id   = $environment
        event_time = $currentTimeInUnixSeconds
    }

    $response = Invoke-RestMethod -Method Post -Uri $uri -Header @{ "x-api-key" = $LinearBAPI; "Content-Type" = "application/json" } -Body ($Body | ConvertTo-Json)

    Write-Host $response
}

$dateTime = Get-Date

try {    
    $currentTimeInUnixSeconds = ([DateTimeOffset]$dateTime).ToUnixTimeSeconds()
    $repositoryUrl = $repoUrl
    $environment = $env
    #$hash = $hash
    
    Write-LinearB $currentTimeInUnixSeconds $hash $repositoryUrl $environment    
}
catch {
    Write-Host "Deploy Tracking Call Failed"
    Write-Host $_
}

try {
    Write-Host "Logging to cloudwatch"
    $universalTime = $dateTime.ToUniversalTime()
    $formattedDate = Get-Date $universalTime -Format "o"
    Write-CloudWatchLog $formattedDate $hash $repositoryUrl $environment
}
catch {
    Write-Host "Deploy Tracking Call Failed"
    Write-Host $_
}
