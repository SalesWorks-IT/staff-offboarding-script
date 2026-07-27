# Auhor: Adiputra
# Date: 9/7/2026

# This script performs user offboarding based on the Status column
#
# Status = Confirm can remove
#     Hide user from GAL
#
# Status = To be deleted
#     Remove Reporting Manager
#     Remove Entra Roles
#     Block Sign-In
#     Delete User
#
# Input CSV must contain:
# Display name
# User principal name
# CountryOrRegion
# Usage location
# Licenses
# Status

# Initializers
param(
    [string]$AdminUPN,
    [switch]$Execute
)


# Default mode is Dry Run
# Execute mode must be explicitly specified

if ($Execute) {

    $DryRun = $false
    $mode = "Execute"

    Write-Host ""
    Write-Host "WARNING: EXECUTE MODE SELECTED" -ForegroundColor Red
    Write-Host "This operation will make changes to user accounts." -ForegroundColor Red
    Write-Host "Actions may include:" -ForegroundColor Red
    Write-Host " - Hide from GAL" -ForegroundColor Red
    Write-Host " - Remove Reporting Manager" -ForegroundColor Red
    Write-Host " - Remove Entra Roles" -ForegroundColor Red
    Write-Host " - Block Sign-In" -ForegroundColor Red
    Write-Host " - Delete User" -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host "Type EXECUTE to continue"

    if ($confirmation -ne "EXECUTE") {
        Write-Host "Execution cancelled." -ForegroundColor Yellow
        exit
    }
}
else {

    $DryRun = $true
    $mode = "DryRun"

    Write-Host ""
    Write-Host "DRY RUN MODE" -ForegroundColor Cyan
    Write-Host "No changes will be made." -ForegroundColor Cyan
}


function Add-LogRecord {

    param(
        [string]$DisplayName,
        [string]$UserPrincipalName,
        [string]$Status,
        [string]$Action,
        [string]$Result,
        [string]$Message
    )

    $script:logData += [PSCustomObject]@{
        Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Mode              = $mode
        AdminUser         = $AdminUPN
        DisplayName       = $DisplayName
        UserPrincipalName = $UserPrincipalName
        Status            = $Status
        Action            = $Action
        Result            = $Result
        Message           = $Message
    }
}

# Load modules
Import-Module ExchangeOnlineManagement -Force

# Create log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$adminUser = $AdminUPN.Split("@")[0]

# Create logs folder if it does not exist
$logFolder = ".\Logs"

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

$logFile = Join-Path `
    $logFolder `
    "OffboardingLog_${adminUser}_${mode}_${timestamp}.csv"

$logData = @()

# Verify input file exists
# if (-not (Test-Path $InputFile)) {
#     Write-Host "Input file not found: $InputFile" -ForegroundColor Red
#     exit 1
# }

# Verify admin account supplied for Exchange connection
if ($AdminUPN -eq $null -or $AdminUPN.Trim() -eq "") {
    Write-Host "AdminUPN is required" -ForegroundColor Red
    exit 1
}

# Connect to Exchange Online
Write-Host ""
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Write-Host "Please complete authentication if prompted." -ForegroundColor Yellow

Connect-ExchangeOnline `
    -UserPrincipalName $AdminUPN `
    -DisableWAM

Write-Host "Connected to Exchange Online" -ForegroundColor Green

# Connect to Microsoft Graph
Write-Host ""
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Write-Host "Please select your administrator account and complete sign-in if prompted." -ForegroundColor Yellow
Write-Host "Required permissions: User.ReadWrite.All, Directory.ReadWrite.All, RoleManagement.ReadWrite.Directory" -ForegroundColor Yellow

Connect-MgGraph `
    -Scopes `
    "User.ReadWrite.All",
    "Directory.ReadWrite.All",
    "RoleManagement.ReadWrite.Directory" `
    -NoWelcome | Out-Null

Write-Host "Connected to Microsoft Graph" -ForegroundColor Green

# Read users from CSV
$csvFiles = Get-ChildItem ".\Inputs" -Filter "*.csv"

if ($csvFiles.Count -eq 0) {
    Write-Host "No CSV file found in Inputs folder." -ForegroundColor Red
    exit 1
}

if ($csvFiles.Count -gt 1) {
    Write-Host "Multiple CSV files found in Inputs folder." -ForegroundColor Red
    Write-Host "Please keep only one CSV file before running the script." -ForegroundColor Red

    $csvFiles | Select-Object Name

    exit 1
}

$InputFile = $csvFiles[0].FullName

Write-Host "Input file detected: $($csvFiles[0].Name)" -ForegroundColor Green

# Import CSV
$users = Import-Csv $InputFile

# Validate required columns
$requiredColumns = @(
    "Display name",
    "User principal name",
    "CountryOrRegion",
    "Usage location",
    "Licenses",
    "Status"
)

$csvColumns = $users[0].PSObject.Properties.Name

$missingColumns = $requiredColumns | Where-Object {
    $_ -notin $csvColumns
}

if ($missingColumns.Count -gt 0) {

    Write-Host "Missing required column(s):" -ForegroundColor Red

    foreach ($column in $missingColumns) {
        Write-Host " - $column" -ForegroundColor Red
    }

    Write-Host "Exiting. Please check the CSV input file." -ForegroundColor Red
    exit 1
}

Write-Host "CSV validation passed" -ForegroundColor Green
Write-Host "Loaded $($users.Count) user(s)" -ForegroundColor Green

# Process each user
foreach ($user in $users) {

    $displayName = $user.'Display name'
    $upn = $user.'User principal name'
    $status = $user.Status

    if ($upn -eq $null -or $upn.Trim() -eq "") {
        continue
    }

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "User    : $displayName"
    Write-Host "UPN     : $upn"
    Write-Host "Status  : $status"
    Write-Host "=========================================" -ForegroundColor Cyan

    # Confirm can remove
    if ($status -eq "Confirm can remove" -or $status -eq "Confrm can remove") {
        
        if ($DryRun) {

            Write-Host "[DRY RUN] Would hide user from GAL" -ForegroundColor Yellow

            Add-LogRecord `
                -DisplayName $displayName `
                -UserPrincipalName $upn `
                -Status $status `
                -Action "Hide From GAL" `
                -Result "Planned" `
                -Message "Would hide user from GAL"

            continue
        }
        else {

            try {

                Write-Host "Action: Hide from GAL" -ForegroundColor Yellow

                Set-Mailbox `
                    -Identity $upn `
                    -HiddenFromAddressListsEnabled $true `
                    -ErrorAction Stop

                Write-Host "Hide from GAL completed" -ForegroundColor Green
                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Hide From GAL" `
                    -Result "Success" `
                    -Message "User hidden from GAL"

            }
            catch {

                Write-Host "Hide from GAL failed" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red

                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Hide From GAL" `
                    -Result "Failed" `
                    -Message $_.Exception.Message

            }

            continue
        }
    }

    # To be deleted
    if ($status -eq "To be deleted") {

        if ($DryRun) {

            # Show current manager
            try {

                $managerRef = Get-MgUserManager `
                    -UserId $upn `
                    -ErrorAction Stop

                $manager = Get-MgUser `
                    -UserId $managerRef.Id

                Write-Host "[DRY RUN] Would remove manager: $($manager.DisplayName) ($($manager.UserPrincipalName))" -ForegroundColor Yellow

                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Manager" `
                    -Result "Planned" `
                    -Message "Would remove manager: $($manager.DisplayName)"

            }
            catch {

                Write-Host "[DRY RUN] No manager assigned" -ForegroundColor Yellow
                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Manager" `
                    -Result "Skipped" `
                    -Message "No manager assigned"

            }

            # Show current roles
            try {

                $entraUser = Get-MgUser -UserId $upn

                $assignments = Get-MgRoleManagementDirectoryRoleAssignment `
                    -Filter "principalId eq '$($entraUser.Id)'"

                # if no roles assigned
                if ($assignments.Count -eq 0) {

                    Write-Host "[DRY RUN] No Entra roles assigned" -ForegroundColor Yellow

                    Add-LogRecord `
                        -DisplayName $displayName `
                        -UserPrincipalName $upn `
                        -Status $status `
                        -Action "Remove Role" `
                        -Result "Skipped" `
                        -Message "No Entra roles assigned"
                }
                else {

                    Write-Host "[DRY RUN] Found $($assignments.Count) role(s)" -ForegroundColor Yellow

                    foreach ($assignment in $assignments) {

                        $role = Get-MgRoleManagementDirectoryRoleDefinition `
                            -UnifiedRoleDefinitionId $assignment.RoleDefinitionId

                        Write-Host "[DRY RUN] Would remove role: $($role.DisplayName)" -ForegroundColor Yellow

                        
                        Add-LogRecord `
                            -DisplayName $displayName `
                            -UserPrincipalName $upn `
                            -Status $status `
                            -Action "Remove Role" `
                            -Result "Planned" `
                            -Message $role.DisplayName

                    }
                }
            }
            catch {

                Write-Host "[DRY RUN] Failed to retrieve roles" -ForegroundColor Red
                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Role" `
                    -Result "Failed" `
                    -Message $_.Exception.Message

            }

            # block sign in
            Write-Host "[DRY RUN] Would block sign-in" -ForegroundColor Yellow
            
            Add-LogRecord `
                -DisplayName $displayName `
                -UserPrincipalName $upn `
                -Status $status `
                -Action "Block Sign-In" `
                -Result "Planned" `
                -Message "Would block sign-in"

            # delete user
            Write-Host "[DRY RUN] Would delete user" -ForegroundColor Yellow

            Add-LogRecord `
                -DisplayName $displayName `
                -UserPrincipalName $upn `
                -Status $status `
                -Action "Delete User" `
                -Result "Planned" `
                -Message "Would delete user"
        }
        else {

            # Remove Reporting Manager
            try {

                $managerRef = Get-MgUserManager `
                    -UserId $upn `
                    -ErrorAction Stop

                $manager = Get-MgUser `
                    -UserId $managerRef.Id

                Write-Host "Manager Found : $($manager.DisplayName)" -ForegroundColor Yellow

                Remove-MgUserManagerByRef `
                    -UserId $upn `
                    -ErrorAction Stop

                Write-Host "Manager removed" -ForegroundColor Green

                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Manager" `
                    -Result "Success" `
                    -Message "Manager removed"

            }
            catch {

                Write-Host "No manager found or manager removal failed" -ForegroundColor Yellow
                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Manager" `
                    -Result "Skipped" `
                    -Message $_.Exception.Message

            }

            # Remove Entra Roles
            try {

                $entraUser = Get-MgUser -UserId $upn

                $assignments = Get-MgRoleManagementDirectoryRoleAssignment `
                    -Filter "principalId eq '$($entraUser.Id)'"

                Write-Host "Found $($assignments.Count) role(s)" -ForegroundColor Yellow

                foreach ($assignment in $assignments) {

                    $role = Get-MgRoleManagementDirectoryRoleDefinition `
                        -UnifiedRoleDefinitionId $assignment.RoleDefinitionId

                    Write-Host "Removing role: $($role.DisplayName)" -ForegroundColor Yellow

                    Remove-MgRoleManagementDirectoryRoleAssignment `
                        -UnifiedRoleAssignmentId $assignment.Id `
                        -ErrorAction Stop

                    Write-Host "Removed role: $($role.DisplayName)" -ForegroundColor Green

                    Add-LogRecord `
                        -DisplayName $displayName `
                        -UserPrincipalName $upn `
                        -Status $status `
                        -Action "Remove Role" `
                        -Result "Success" `
                        -Message $role.DisplayName
                }

                if ($assignments.Count -eq 0) {
                    Write-Host "No Entra roles assigned" -ForegroundColor Yellow
                    
                    Add-LogRecord `
                        -DisplayName $displayName `
                        -UserPrincipalName $upn `
                        -Status $status `
                        -Action "Remove Role" `
                        -Result "Skipped" `
                        -Message "No Entra roles assigned"
                }
            }
            catch {

                Write-Host "Role removal failed" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red

                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Remove Role" `
                    -Result "Failed" `
                    -Message $_.Exception.Message
            }

            # Block Sign-In
            try {

                Update-MgUser `
                    -UserId $upn `
                    -AccountEnabled:$false

                Write-Host "Sign-in blocked" -ForegroundColor Green

                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Block Sign-In" `
                    -Result "Success" `
                    -Message "Sign-in blocked"
            }
            catch {

                Write-Host "Failed to block sign-in" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red

                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Block Sign-In" `
                    -Result "Failed" `
                    -Message $_.Exception.Message
                `
            }

            # Delete User
            try {

                # Remove-MgUser `
                #     -UserId $upn `
                #     -ErrorAction Stop

                Write-Host "Delete user skipped for testing" -ForegroundColor Yellow
                #Write-Host "User deleted" -ForegroundColor Green

                # Add-LogRecord `
                #     -DisplayName $displayName `
                #     -UserPrincipalName $upn `
                #     -Status $status `
                #     -Action "Delete User" `
                #     -Result "Success" `
                #     -Message "User deleted"
                
                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Delete User" `
                    -Result "Skipped" `
                    -Message "Delete user skipped for testing"

            }
            catch {

                Write-Host "User deletion failed" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red

                Add-LogRecord `
                    -DisplayName $displayName `
                    -UserPrincipalName $upn `
                    -Status $status `
                    -Action "Delete User" `
                    -Result "Failed" `
                    -Message $_.Exception.Message
            }
        }

        continue
    }

    Write-Host "Status not recognised. User skipped." -ForegroundColor Yellow
}

# Write-Host "DEBUG - About to disconnect sessions"

# Disconnect sessions
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph | Out-Null

# Export to CSV
$logData | Export-Csv -Path $logFile -NoTypeInformation

Write-Host ""
Write-Host "Log file created: $logFile" -ForegroundColor Green
Write-Host "Offboarding process completed" -ForegroundColor Cyan