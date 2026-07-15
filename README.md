# get-pim.ps1
 
Self-activates the Contributor role on an Azure subscription via PIM, using your existing `az login` session. No temp files, no Azure PowerShell module required — just Azure CLI + native PowerShell.
 
## Requirements
 
- Azure CLI installed and logged in (`az login`)
- PowerShell (Windows PowerShell 5.1+ or PowerShell 7+)
- PIM-eligible assignment for Contributor on the target subscription
## Usage
 
```powershell
.\get-pim.ps1 -SubId "your-sub-guid" -Justification "TRACKS-123456"
```
 
- **SubId** — the subscription GUID you want Contributor access on
- **Justification** — ticket number or reason for the activation
Role activates for 1 hour (`PT1H`). Change the `duration` value in the script if you need a different window.
 
## First-time setup
 
If scripts are blocked from running, allow them for your user account (one-time):
 
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
 
## Expected output
 
```
PIM activation request submitted.
Status: Provisioned
Expires after: 1 hour
```
 
`Provisioned` = active immediately. `PendingApproval` = role requires an approver.
 
## Troubleshooting
 
| Error | Fix |
|---|---|
| "Couldn't get your object ID" | Token expired — run `az login` |
| "Couldn't get an ARM access token" | Same — run `az login` |
| `RoleAssignmentRequestAcrsValidationFailed` | Role policy requires MFA claim — re-run `az login` to force a fresh MFA prompt |
All versions PUT a `SelfActivate` request to the ARM `roleAssignmentScheduleRequests` endpoint — the same API the Azure portal uses for PIM activation.

- The **Azure CLI versions** write the JSON body to a temp file to avoid PowerShell 5.1 quote-mangling when passing JSON to `az rest`.
- The **Azure PowerShell version** passes the JSON body directly in memory via `Invoke-AzRestMethod -Payload`, so no temp file (or its encoding quirks) is needed.
