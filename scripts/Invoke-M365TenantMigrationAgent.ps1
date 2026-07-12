[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ConfigPath,

    [string] $OutputPath = (Join-Path $PSScriptRoot '..\reports'),

    [switch] $Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '..\M365TenantMigrationAgent.psd1'
Import-Module $modulePath -Force

if (-not (Test-Path -Path $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

Connect-M365TenantMigrationAgent -TenantId $config.SourceTenant.TenantId -Mode Source
$inventory = Get-M365SourceInventory -Config $config

$plan = New-M365MigrationPlan -Inventory $inventory -Config $config

Connect-M365TenantMigrationAgent -TenantId $config.TargetTenant.TenantId -Mode Target
$results = Invoke-M365TargetProvisioning -Plan $plan -Config $config -OutputPath $OutputPath -Execute:$Execute

Export-M365MigrationAgentReport -Inventory $inventory -Plan $plan -Results $results -OutputPath $OutputPath

Write-Host "Source users discovered: $($inventory.Users.Count)" -ForegroundColor Green
Write-Host "Source groups discovered: $($inventory.Groups.Count)" -ForegroundColor Green
Write-Host "Source sites discovered: $($inventory.Sites.Count)" -ForegroundColor Green
Write-Host "Plan actions: $($plan.Actions.Count)" -ForegroundColor Green
Write-Host "Mode: $(if ($Execute) { 'Execute' } else { 'DryRun' })" -ForegroundColor Green
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green

