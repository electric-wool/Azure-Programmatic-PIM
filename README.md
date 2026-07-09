# PIM Self-Activation Scripts
 
Activate an eligible PIM role (Contributor) on an Azure subscription from the command line — same as clicking "Activate" in the portal, without the portal.
 
Two versions are included:
 
| Script | User ID | Best for |
|---|---|---|
| `dynamicUserID.ps1` | Looked up automatically (`az ad signed-in-user show`) | Most people — works for anyone who runs it |
| `hardcodedUserID.ps1` | Pasted in manually | Personal use, or when the Graph lookup fails (e.g. restricted Graph permissions) |
 
## Prerequisites
 
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- An **eligible** PIM assignment for Contributor on the target subscription (these scripts activate existing eligibility — they can't grant you access you don't have)
- PowerShell (works on Windows PowerShell 5.1 and PowerShell 7+)
## Usage — dynamic version (`dynamicUserID.ps1`)
 
1. Log in to Azure CLI:
```powershell
   az login
```
 
2. Open the script and set the two variables at the top:
```powershell
   $SubId = "<your subscription ID>"
   $Justification = "<reason for activation, e.g. ticket number>"
```
 
3. Run it (or paste the whole thing into a PowerShell window):
```powershell
   .\dynamicUserID.ps1
```
 
## Usage — hardcoded version (`hardcodedUserID.ps1`)
 
Same as above, but also set your own user object ID:
 
```powershell
$SUB_ID = "<your subscription ID>"
$MY_ID = "<your user object ID>"
```
 
To find your object ID:
 
```powershell
az ad signed-in-user show --query id -o tsv
```
 
(Or in the portal: Microsoft Entra ID → Users → your account → Object ID.)
 
## Success
 
Either version returns a JSON response with `"status": "Provisioned"`. The role is active immediately and expires automatically after 1 hour.
 
## Notes
 
- Activation duration is capped at `PT1H` (1 hour). If your organisation's PIM policy allows longer, change the `duration` value — anything above the policy max will be rejected.
- If your PIM policy requires MFA, your `az login` session must have satisfied it (a normal interactive login does).
- If you get `"Request body is invalid"`, your token has likely expired — run `az login` again. In the hardcoded version, also double-check `$MY_ID` isn't empty or mistyped.
- To use a role other than Contributor, swap `$ROLE_DEF_ID` for the relevant [built-in role ID](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) (e.g. Reader: `acdd72a7-3385-48ef-bd42-f606fba81ae7`).
## How it works
 
Both scripts PUT a `SelfActivate` request to the ARM `roleAssignmentScheduleRequests` endpoint — the same API the Azure portal uses for PIM activation. The JSON body is written to a temp file to avoid PowerShell 5.1 quote-mangling when passing JSON to `az rest`.
