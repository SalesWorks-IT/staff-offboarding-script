# Auhor: Adiputra
# Date: 6/7/2026

# This script hides users from Exchange Online Global Address List
# Input file must be users.csv
# CSV column must be UserPrincipalName

param(
    [string]$InputFile = ".\users.csv",
    [string]$AdminUPN
)

# Load Exchange Online module
Import-Module ExchangeOnlineManagement -Force

# Check if AdminUPN is provided
if ($AdminUPN -eq $null -or $AdminUPN.Trim() -eq "") {
    Write-Host "AdminUPN is required" -ForegroundColor Red
    Write-Host "Example: .\Hide-FromGAL.ps1 -InputFile .\users.csv -AdminUPN admin@domain.com"
    exit 1
}

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName $AdminUPN -DisableWAM

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
        # Check if mailbox exists
        Get-Mailbox -Identity $upn -ErrorAction Stop | Out-Null

        # Hide mailbox from GAL
        Set-Mailbox -Identity $upn -HiddenFromAddressListsEnabled $true -ErrorAction Stop

        Write-Host "Hidden from GAL: $upn" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to hide from GAL: $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Disconnect Exchange Online session
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Completed Hide from GAL process" -ForegroundColor Cyan