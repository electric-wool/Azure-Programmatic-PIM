$SubId = "<paste sub ID>"
$Justification = "<paste justification ie. ticket number>"

$MY_ID = az ad signed-in-user show --query id -o tsv
if (-not $MY_ID) {
    throw "Couldn't get your object ID - token likely expired. Run 'az login' and try again."
}

$ROLE_DEF_ID = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
$REQUEST_ID = [guid]::NewGuid().ToString()

$body = @{
  properties = @{
    principalId = $MY_ID
    roleDefinitionId = "/subscriptions/$SubId/providers/Microsoft.Authorization/roleDefinitions/$ROLE_DEF_ID"
    requestType = "SelfActivate"
    justification = $Justification
    scheduleInfo = @{
      startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
      expiration = @{ type = "AfterDuration"; duration = "PT1H" }
    }
  }
} | ConvertTo-Json -Depth 5

$bodyFile = Join-Path $env:TEMP "pim-activate-body.json"
[System.IO.File]::WriteAllText($bodyFile, $body)

az rest --method put --uri "https://management.azure.com/subscriptions/$SubId/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/${REQUEST_ID}?api-version=2020-10-01" --body "@$bodyFile" --headers "Content-Type=application/json"

Remove-Item $bodyFile
