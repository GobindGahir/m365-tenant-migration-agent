@{
    RootModule = 'M365TenantMigrationAgent.psm1'
    ModuleVersion = '0.1.0'
    GUID = '07e1cb13-d338-4dd8-b7dd-08f6e922ec7a'
    Author = 'Gobind Gahir'
    CompanyName = 'Community'
    Copyright = '(c) 2026 Gobind Gahir. All rights reserved.'
    Description = 'Safe Microsoft 365 tenant-to-tenant provisioning and migration planning agent.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Connect-M365TenantMigrationAgent',
        'Get-M365SourceInventory',
        'Import-M365MigrationScope',
        'New-M365MigrationPlan',
        'Invoke-M365TargetProvisioning',
        'Export-M365MigrationAgentReport',
        'Write-M365AgentAudit'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Microsoft365', 'TenantMigration', 'PowerShell', 'Graph', 'Provisioning')
            ProjectUri = 'https://github.com/GobindGahir/m365-tenant-migration-agent'
            ReleaseNotes = 'Initial safe tenant migration provisioning agent MVP.'
        }
    }
}
