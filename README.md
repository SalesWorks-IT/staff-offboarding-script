# Staff Offboarding Script

**Author:** Muhammad Adiputra Syafirul Hisyam  
**Email:** adiputra.syafirul@salesworksgroup.com  
**Updated since:** 09/07/2026

---

# Purpose

This script automates the staff offboarding process for Microsoft Entra ID and Exchange Online.

Actions performed are based on the **Status** column in the input CSV file.

### Confirm can remove

Performs:

- Hide user from Global Address List (GAL)

### To be deleted

Performs:

- Remove Reporting Manager
- Remove Entra Roles
- Block Sign-In
- Delete User

---

# Requirements

The following must be installed on the workstation before running the script.

### PowerShell 7

Verify version:

```powershell
$PSVersionTable.PSVersion
```

---

### Exchange Online Management Module

Install:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
```

Verify:

```powershell
Get-Module ExchangeOnlineManagement -ListAvailable
```

---

### Microsoft Graph PowerShell Module

Install:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

Verify:

```powershell
Get-Module Microsoft.Graph.Authentication -ListAvailable
```

---

# Required Permissions

The account executing the script should have appropriate permissions in:

### Exchange Online

Required for:

- Hide user from GAL

### Microsoft Entra ID

Required for:

- Remove Reporting Manager
- Remove Entra Roles
- Block Sign-In
- Delete User

Recommended roles:

```text
Global Administrator
Privileged Role Administrator
```

---

## Script Execution Policy

Some workstations may prevent PowerShell scripts from running.

Check current policy:

```powershell
Get-ExecutionPolicy
```

If the script is blocked, run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Administrator privileges are generally not required when using the CurrentUser scope.

After updating the execution policy, reopen PowerShell and execute the script again.

---

# Folder Structure

The script must be executed from the project root folder.

Example:

```text
Entra-Offboarding
│
├─ Main-Offboarding.ps1
│
├─ Inputs
│   └─ Offboarding_20260709.csv
│
└─ Logs
```

---

# Input File

Place the input CSV file inside the **Inputs** folder.

Example:

```text
Inputs
└─ Offboarding_20260709.csv
```

Notes:

- The CSV filename can be any name.
- Only one CSV file is allowed inside the Inputs folder.
- If more than one CSV file is detected, the script will stop and display an error.

---

# CSV Format

Required columns:

```text
Display name
User principal name
CountryOrRegion
Usage location
Licenses
Status
```

Example:

```csv
Display name,User principal name,CountryOrRegion,Usage location,Licenses,Status
John Doe,john.doe@company.com,MY,MY,M365 E3,Confirm can remove
Jane Doe,jane.doe@company.com,MY,MY,M365 E5,To be deleted
```

---

# Supported Status Values

### Confirm can remove

Accepted values:

```text
Confirm can remove
Confrm can remove
```

Action performed:

```text
Hide user from GAL
```

---

### To be deleted

Accepted value:

```text
To be deleted
```

Actions performed:

```text
Remove Reporting Manager
Remove Entra Roles
Block Sign-In
Delete User
```

---

# How To Run The Script

Open PowerShell 7.

Navigate to the folder containing the script.

Example:

```powershell
cd "C:\Scripts\Entra-Offboarding"
```

Ensure:

```text
Main-Offboarding.ps1
Inputs folder
CSV file
```

are present before execution.

---

# Dry Run Mode

Dry Run is the default mode.

No changes will be made.

Run:

```powershell
.\Main-Offboarding.ps1 -AdminUPN "admin@company.com"
```

Dry Run will:

- Validate the CSV
- Display planned actions
- Generate a log file
- Make no changes

---

# Execute Mode

Execute mode performs actual changes.

Run:

```powershell
.\Main-Offboarding.ps1 -AdminUPN "admin@company.com" -Execute
```

A confirmation prompt will appear:

```text
WARNING: EXECUTE MODE SELECTED

Type EXECUTE to continue
```

Enter:

```text
EXECUTE
```

to proceed.

---

# Logs

A CSV log file is generated for every run.

Location:

```text
Logs
```

Example filenames:

```text
OffboardingLog_adiputra.syafirul_DryRun_20260709_150500.csv

OffboardingLog_adiputra.syafirul_Execute_20260709_151200.csv
```

The log file includes:

```text
Timestamp
Mode
AdminUser
DisplayName
UserPrincipalName
Status
Action
Result
Message
```

---

# Validation After Execution

## Hide From GAL

Applicable Status:

```text
Confirm can remove
```

Verify in:

```text
Exchange Admin Center
→ Recipients
→ Mailboxes
→ Select User
→ General
→ Hide from Global Address List
```

Expected:

```text
Yes
```

---

## Remove Reporting Manager

Applicable Status:

```text
To be deleted
```

Verify in:

```text
Microsoft Entra Admin Center
→ Users
→ Select User
→ Properties
→ Manager
```

Expected:

```text
No manager assigned
```

---

## Remove Entra Roles

Applicable Status:

```text
To be deleted
```

Verify in:

```text
Microsoft Entra Admin Center
→ Users
→ Select User
→ Assigned Roles
```

Expected:

```text
No assigned roles
```

---

## Block Sign-In

Applicable Status:

```text
To be deleted
```

Verify in:

```text
Microsoft Entra Admin Center
→ Users
→ Select User
→ Properties
```

Expected:

```text
Block sign-in = Yes
```

---

## Delete User

Applicable Status:

```text
To be deleted
```

Verify in:

```text
Microsoft Entra Admin Center
→ Users
→ Deleted Users
```

Expected:

```text
User appears under Deleted Users
```

---

# Recommended Process

1. Place the CSV file into the Inputs folder.
2. Run Dry Run mode.
3. Review the generated log file.
4. Validate the planned actions.
5. Run Execute mode.
6. Validate changes in Exchange Online and Microsoft Entra ID.
7. Archive the generated log file for audit purposes.

---

# Tested Versions

```text
PowerShell 7.6.3
ExchangeOnlineManagement 3.10.0
Microsoft.Graph 2.38.0
```

---

# Notes

- Dry Run is the default mode.
- Execute mode requires the `-Execute` switch.
- Execute mode requires manual confirmation.
- Exactly one CSV file must exist inside the Inputs folder.
- A CSV audit log is generated for every execution.
- Review the log before proceeding with production changes.
- Test using non-production accounts before production execution.