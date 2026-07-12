# M365 Tenant Migration Agent

PowerShell-based Microsoft 365 tenant-to-tenant provisioning agent.

This project reads objects from a source tenant, builds a migration provisioning plan, and prepares target tenant actions for users, licenses, Microsoft 365 groups, Teams, SharePoint sites, and OneDrive. The first release is safe by default: it runs in dry-run mode unless `-Execute` is explicitly provided.

## What This Agent Does

- Connects to source tenant with read-only Graph permissions
- Connects to target tenant with read/write Graph permissions
- Discovers source users from a source migration security group
- Discovers source shared mailboxes from a separate source migration security group
- Imports Teams and SharePoint migration scope from CSV files
- Imports distribution list migration scope from CSV files
- Builds a target provisioning plan
- Detects naming and mapping risks
- Exports CSV, JSON, and HTML reports
- Writes an audit log for every planned or executed action
- Supports `-WhatIf`-style dry-run behavior by default
- Provides safe extension points for real provisioning

## What This Agent Does Not Do

This project does not migrate mailbox contents, Teams messages, SharePoint files, or OneDrive files. Data movement should be handled by a migration platform. This agent focuses on target-side preparation and provisioning orchestration.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Microsoft Graph PowerShell SDK
- Source tenant app/user permissions for read-only discovery
- Target tenant app/user permissions for provisioning

Install Microsoft Graph PowerShell SDK:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Quick Start

Copy the sample config:

```powershell
Copy-Item .\config\sample.agent-config.json .\config\agent-config.json
```

Edit tenant IDs, domains, and license mappings, then run:

```powershell
.\scripts\Invoke-M365TenantMigrationAgent.ps1 `
  -ConfigPath ".\config\agent-config.json" `
  -OutputPath ".\reports"
```

The default run is a dry run.

To execute supported target actions:

```powershell
.\scripts\Invoke-M365TenantMigrationAgent.ps1 `
  -ConfigPath ".\config\agent-config.json" `
  -OutputPath ".\reports" `
  -Execute
```

## MVP Provisioning Support

| Workload | MVP Behavior |
| --- | --- |
| Users | Reads scoped source users from a migration security group and generates target user provisioning and license assignment plans. |
| Shared Mailboxes | Reads scoped source shared mailboxes from a separate migration security group and supports target shared mailbox creation. |
| Shared Mailbox Permissions | Imports permission mappings from CSV and supports target FullAccess and SendAs assignment. |
| Licenses | Maps source SKU part numbers to target SKU IDs from config. |
| Microsoft 365 Groups | Generates group creation plan; supports safe creation when `-Execute` is used. |
| Security Groups | Generates target security group actions from Teams and SharePoint CSV scope rows. |
| Teams | Imports Teams scope from CSV and generates group/team/channel provisioning actions. |
| SharePoint | Imports SharePoint scope from CSV and generates site provisioning plan. |
| Distribution Lists | Imports DL scope from CSV and supports target distribution list creation through Exchange Online PowerShell. |
| OneDrive | Generates pre-provisioning actions for licensed users. |

## Safety Controls

- Dry-run mode by default
- Explicit `-Execute` required for writes
- Separate source and target tenant IDs
- Config-driven domain and license mappings
- Audit log for each action
- Idempotency checks before supported writes
- No secrets committed to repository

## Project Structure

```text
m365-tenant-migration-agent/
  M365TenantMigrationAgent.psd1
  M365TenantMigrationAgent.psm1
  scripts/
    Invoke-M365TenantMigrationAgent.ps1
  src/
    Connect-M365TenantMigrationAgent.ps1
    Get-M365SourceInventory.ps1
    Import-M365MigrationScope.ps1
    New-M365MigrationPlan.ps1
    Invoke-M365TargetProvisioning.ps1
    Export-M365MigrationAgentReport.ps1
    Write-M365AgentAudit.ps1
  config/
    sample.agent-config.json
    sample.teams-scope.csv
    sample.sharepoint-scope.csv
    sample.distribution-lists-scope.csv
    sample.shared-mailbox-permissions.csv
  docs/
    permissions.md
    architecture.md
    provisioning-model.md
  reports/
    .gitkeep
```

## Disclaimer

Tenant migration automation is high-impact. Test in lab tenants before using this project with production tenants.

## Scoping Model

The agent should not provision everything it discovers.

| Workload | Scope Source |
| --- | --- |
| Users | Source tenant migration security group |
| Shared mailboxes | Separate source tenant migration security group |
| Shared mailbox permissions | `config/sample.shared-mailbox-permissions.csv` |
| OneDrive | Derived from scoped users |
| Teams | `config/sample.teams-scope.csv` |
| SharePoint | `config/sample.sharepoint-scope.csv` |
| Distribution lists | `config/sample.distribution-lists-scope.csv` |
| Security groups | Created from Teams/SPO CSV rows when requested |

Example user scope:

```json
"Scope": {
  "UserMigrationGroupId": "source-security-group-object-id",
  "SharedMailboxMigrationGroupId": "source-shared-mailbox-security-group-object-id",
  "TeamsCsvPath": ".\\config\\sample.teams-scope.csv",
  "SharePointCsvPath": ".\\config\\sample.sharepoint-scope.csv",
  "DistributionListsCsvPath": ".\\config\\sample.distribution-lists-scope.csv",
  "SharedMailboxPermissionsCsvPath": ".\\config\\sample.shared-mailbox-permissions.csv"
}
```

For Teams and SharePoint, the CSV can request an associated target security group using `CreateSecurityGroup=true`.

Distribution list creation uses Exchange Online PowerShell, so connect Exchange Online in the target tenant before running with `-Execute` when DL creation is enabled.

Shared mailbox creation and shared mailbox permissions also use Exchange Online PowerShell in the target tenant.
