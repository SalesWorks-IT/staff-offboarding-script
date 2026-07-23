# Auhor: Adiputra
# Date: 9/7/2026

# This script removes direct Entra ID role assignments from users
# Input file must be users.csv
# CSV column must be UserPrincipalName
# Example:
# UserPrincipalName
# user1@company.com
# user2@company.com

param(
    [string]$InputFile = ".\users.csv"
)

# Stop script if CSV file does not exist
if (-not (Test-Path $InputFile)) {
    Write-Host "Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

# Connect to Microsoft Graph
# RoleManagement.ReadWrite.Directory is required to remove role assignments
Connect-MgGraph `
    -Scopes "User.ReadWrite.All","Directory.ReadWrite.All","RoleManagement.ReadWrite.Directory" `
    -NoWelcome

# Read all users from CSV
$users = Import-Csv $InputFile

# Process each user one by one
foreach ($user in $users) {

    $upn = $user.UserPrincipalName

    # Skip blank rows
    if ($upn -eq $null -or $upn.Trim() -eq "") {
        Write-Host "Skipped empty UserPrincipalName" -ForegroundColor Yellow
        continue
    }

    Write-Host ""
    Write-Host "Processing user: $upn" -ForegroundColor Cyan

    try {

        # Get the Entra ID user object
        $entraUser = Get-MgUser -UserId $upn

        # Get all direct role assignments for the user
        $assignments = Get-MgRoleManagementDirectoryRoleAssignment `
            -Filter "principalId eq '$($entraUser.Id)'"

        # If user has no roles, move to next user
        if ($assignments.Count -eq 0) {
            Write-Host "No Entra roles assigned" -ForegroundColor Yellow
            continue
        }

        Write-Host "Found $($assignments.Count) role(s) for $upn"

        # Remove each role assignment found
        foreach ($assignment in $assignments) {

            # Get friendly role name
            $role = Get-MgRoleManagementDirectoryRoleDefinition `
                -UnifiedRoleDefinitionId $assignment.RoleDefinitionId

            Write-Host "Role found: $($role.DisplayName)" -ForegroundColor Yellow

            # Remove role assignment
            Remove-MgRoleManagementDirectoryRoleAssignment `
                -UnifiedRoleAssignmentId $assignment.Id `
                -ErrorAction Stop

            Write-Host "Removed role: $($role.DisplayName)" -ForegroundColor Green
        }
    }
    catch {

        # Continue processing other users if one user fails
        Write-Host "Failed processing user: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Role removal process completed" -ForegroundColor Cyan