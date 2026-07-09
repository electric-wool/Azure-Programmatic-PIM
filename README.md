# PIM Self-Activation Scripts

Activate an eligible PIM role (Contributor) on an Azure subscription from the command line — same as clicking "Activate" in the portal, without the portal.

Three versions are included:

| Script | Backend | User ID | Best for |
|---|---|---|---|
| `AzCLI/dynamicUserID.ps1` | Azure CLI (`az rest`) | Looked up automatically (`az ad signed-in-user show`) | Most people — works for anyone who runs it |
| `AzCLI/hardcodedUserID.ps1` | Azure CLI (`az rest`) | Pasted in manually | Personal use, or when the Graph lookup fails (e.g. restricted Graph permissions) |
| `dynamicUserIDPS.ps1` | Azure PowerShell (`Invoke-AzRestMethod`) | Looked up automatically (`Get-AzADUser -SignedIn`) | Anyone already using the Az module — no Azure CLI required, no temp file |

## Prerequisites

- An **eligible** PIM assignment for Contributor on the target subscription (these scripts activate existing eligibility — they can't grant you access you don't have)
- PowerShell (works on Windows PowerShell 5.1 and PowerShell 7+)

**For the Azure CLI versions (`AzCLI/` folder):**
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed

**For the Azure PowerShell version:**
- [Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-azure-powershell) installed (`Install-Module -Name Az`)

## Usage — Azure CLI dynamic version (`AzCLI/dynamicUserID.ps1`)

1. Log in to Azure CLI:
```powershell
   az login
```

2. Open the script and set the two variables at the top:
```powershell
   $SubId = "<your subscription ID>"
   $Justification = "<reason for activation, e.g. ticket number>"
```

3. Run it:
```powershell
   .\AzCLI\dynamicUserID.ps1
```

   Or skip saving/running the file entirely — edit the two variables, then copy the whole script and paste it straight into a PowerShell window. It executes top to bottom just like running the file.

## Usage — Azure CLI hardcoded version (`AzCLI/hardcodedUserID.ps1`)

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

## Usage — Azure PowerShell version (`dynamicUserIDPS.ps1`)

1. Log in with the Az module:
```powershell
   Connect-AzAccount
```

2. Open the script and set the two variables at the top:
```powershell
   $SubId = "<your subscription ID>"
   $Justification = "<reason for activation, e.g. ticket number>"
```

3. Run it:
```powershell
   .\dynamicUserIDPS.ps1
```

   Or paste it directly: edit the two variables, copy the whole script, and paste into your PowerShell session. No file needed.

## Paste-into-PowerShell tips

All three scripts are self-contained and safe to paste directly into an interactive PowerShell window instead of running as a `.ps1` file. This is handy if your machine's execution policy blocks unsigned scripts, or you just want a one-off activation.

- Set the variables at the top (`$SubId`, `$Justification`, and `$MY_ID` for the hardcoded version) **before** pasting, or edit them in the pasted text before hitting Enter.
- In Windows Terminal / PowerShell 7, a multi-line paste runs automatically once complete. In the legacy PowerShell 5.1 console, you may need to press Enter once at the end to execute the final line.
- If pasting into PowerShell ISE, paste into the script pane and press F5.

## Success

Every version returns a JSON response with `"status": "Provisioned"`. The role is active immediately and expires automatically after 1 hour.

## Notes

- Activation duration is capped at `PT1H` (1 hour). If your organisation's PIM policy allows longer, change the `duration` value — anything above the policy max will be rejected.
- If your PIM policy requires MFA, your session must have satisfied it (a normal interactive `az login` or `Connect-AzAccount` does).
- If you get `"Request body is invalid"` in the CLI versions, your token has likely expired — run `az login` again. In the hardcoded version, also double-check `$MY_ID` isn't empty or mistyped.
- The PowerShell version doesn't throw on API errors — it checks the response status code and prints a warning with the error body on failure. If activation fails, read the returned `Content` for the reason.
- To use a role other than Contributor, swap `$ROLE_DEF_ID` for the relevant [built-in role ID](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) (e.g. Reader: `acdd72a7-3385-48ef-bd42-f606fba81ae7`).

## How it works

All versions PUT a `SelfActivate` request to the ARM `roleAssignmentScheduleRequests` endpoint — the same API the Azure portal uses for PIM activation.

- The **Azure CLI versions** write the JSON body to a temp file to avoid PowerShell 5.1 quote-mangling when passing JSON to `az rest`.
- The **Azure PowerShell version** passes the JSON body directly in memory via `Invoke-AzRestMethod -Payload`, so no temp file (or its encoding quirks) is needed.
