$functionFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'src') -Filter '*.ps1' -ErrorAction Stop

foreach ($functionFile in $functionFiles) {
    . $functionFile.FullName
}

Export-ModuleMember -Function @(
    'Connect-M365TenantMigrationAgent',
    'Get-M365SourceInventory',
    'New-M365MigrationPlan',
    'Invoke-M365TargetProvisioning',
    'Export-M365MigrationAgentReport',
    'Write-M365AgentAudit'
)

