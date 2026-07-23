# Auhor: Adiputra
# Date: 9/7/2026

# This script lists Entra roles assigned to users
# Input file must be users.csv
# CSV column must be UserPrincipalName

param(
    [string]$InputFile = ".\users.csv"
)

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

# Connect to Graph
Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All" -NoWelcome

# Read users
$users = Import-Csv $InputFile

foreach ($user in $users) {

    $upn = $user.UserPrincipalName

    if ($upn -eq $null -or $upn.Trim() -eq "") {
        continue
    }

    Write-Host ""
    Write-Host "User: $upn" -ForegroundColor Cyan

    try {

        $entraUser = Get-MgUser -UserId $upn

        $assignments = Get-MgRoleManagementDirectoryRoleAssignment `
            -Filter "principalId eq '$($entraUser.Id)'"

        if ($assignments.Count -eq 0) {
            Write-Host "No roles assigned" -ForegroundColor Yellow
            continue
        }

        foreach ($assignment in $assignments) {

            $role = Get-MgRoleManagementDirectoryRoleDefinition `
                -UnifiedRoleDefinitionId $assignment.RoleDefinitionId

            Write-Host "Role: $($role.DisplayName)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Completed role audit" -ForegroundColor Cyan