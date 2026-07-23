# Auhor: Adiputra
# Date: 9/7/2026

# This script deletes users from Entra ID
# Deleted users are moved to Deleted Users and can be restored within retention period
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
# User.ReadWrite.All is required to delete users
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

        # Verify user exists before deletion
        $entraUser = Get-MgUser -UserId $upn -ErrorAction Stop

        Write-Host "User found: $($entraUser.DisplayName)" -ForegroundColor Yellow

        # Delete user
        Remove-MgUser `
            -UserId $upn `
            -ErrorAction Stop

        Write-Host "User deleted successfully" -ForegroundColor Green

        # Verify user no longer exists in active users
        try {
            Get-MgUser -UserId $upn -ErrorAction Stop | Out-Null
            Write-Host "Verification failed - user still exists" -ForegroundColor Red
        }
        catch {
            Write-Host "Verification successful - user removed from active users" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed processing user: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Delete user process completed" -ForegroundColor Cyan