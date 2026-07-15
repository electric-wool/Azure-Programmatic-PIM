<#
.SYNOPSIS
    Self-activates the Contributor role on a subscription via PIM.
.EXAMPLE
    .\Activate-PIM.ps1 -SubId "xxxx-xxxx-xxxx" -Justification "TRACKS-123456"
#>
param(
    [Parameter(Mandatory)][string]$SubId,
    [Parameter(Mandatory)][string]$Justification
)
 
$MY_ID = az ad signed-in-user show --query id -o tsv
if (-not $MY_ID) {
    throw "Couldn't get your object ID - token likely expired. Run 'az login' and try again."
}
 
$token = az account get-access-token --resource https://management.azure.com --query accessToken -o tsv
if (-not $token) {
    throw "Couldn't get an ARM access token. Run 'az login' and try again."
}
 
$ROLE_DEF_ID = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
$REQUEST_ID  = [guid]::NewGuid().ToString()
 
$body = @{
    properties = @{
        principalId      = $MY_ID
        roleDefinitionId = "/subscriptions/$SubId/providers/Microsoft.Authorization/roleDefinitions/$ROLE_DEF_ID"
        requestType      = "SelfActivate"
        justification    = $Justification
        scheduleInfo     = @{
            startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            expiration    = @{ type = "AfterDuration"; duration = "PT1H" }
        }
    }
} | ConvertTo-Json -Depth 5
 
$uri = "https://management.azure.com/subscriptions/$SubId/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/${REQUEST_ID}?api-version=2020-10-01"
 
$response = Invoke-RestMethod -Method Put -Uri $uri `
    -Headers @{ Authorization = "Bearer $token" } `
    -ContentType 'application/json' `
    -Body $body
 
Write-Host "PIM activation request submitted." -ForegroundColor Green
Write-Host "Status: $($response.properties.status)"
Write-Host "Expires after: 1 hour"
