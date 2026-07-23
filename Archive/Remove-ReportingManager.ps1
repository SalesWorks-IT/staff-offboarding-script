# Auhor: Adiputra
# Date: 9/7/2026

# This script removes managers from users in Entra ID
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

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All" -NoWelcome

# Read users from CSV
$users = Import-Csv $InputFile

# Process each user
foreach ($user in $users) {

    $upn = $user.UserPrincipalName

    # Skip empty user
    if ($upn -eq $null -or $upn.Trim() -eq "") {
        Write-Host "Skipped empty UserPrincipalName" -ForegroundColor Yellow
        continue
    }

    try {

        # Get manager details
        $managerRef = Get-MgUserManager -UserId $upn -ErrorAction Stop
        $manager = Get-MgUser -UserId $managerRef.Id

        Write-Host "User: $upn" -ForegroundColor Cyan
        Write-Host "Manager: $($manager.DisplayName) ($($manager.UserPrincipalName))" -ForegroundColor Cyan

        # Remove manager
        Remove-MgUserManagerByRef -UserId $upn -ErrorAction Stop

        Write-Host "Manager removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "No manager found or failed: $upn" -ForegroundColor Yellow
    }

    Write-Host ""
}

Write-Host "Completed Remove Reporting Manager process" -ForegroundColor Cyan