# Auhor: Adiputra
# Date: 9/7/2026

# This script blocks sign-in for users in Entra ID
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
# User.ReadWrite.All is required to update user accounts
Connect-MgGraph `
    -Scopes "User.ReadWrite.All","Directory.ReadWrite.All" `
    -NoWelcome

# Read all users from CSV
$users = Import-Csv $InputFile

# Process each user
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

        # Get current account status before making changes
        $currentUser = Get-MgUser `
            -UserId $upn `
            -Property AccountEnabled

        Write-Host "Current AccountEnabled: $($currentUser.AccountEnabled)" -ForegroundColor Yellow

        # Block sign-in
        Update-MgUser `
            -UserId $upn `
            -AccountEnabled:$false

        # Verify account status after update
        $updatedUser = Get-MgUser `
            -UserId $upn `
            -Property AccountEnabled

        Write-Host "Updated AccountEnabled: $($updatedUser.AccountEnabled)" -ForegroundColor Green
        Write-Host "Sign-in blocked successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed processing user: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Block sign-in process completed" -ForegroundColor Cyan