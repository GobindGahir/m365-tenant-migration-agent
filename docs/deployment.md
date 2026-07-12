# Deployment

The agent is designed to run without an interactive admin session when app-only authentication is configured.

## Recommended Runtime Options

| Runtime | Notes |
| --- | --- |
| Azure Automation Runbook | Good fit for scheduled migration waves and certificate-based auth. |
| Azure Function | Good fit for API-triggered or queue-triggered provisioning. |
| GitHub Actions | Good for lab/demo runs; store certificate material in secrets. |
| Admin workstation | Good for development and dry-run validation. |

## App Registration Model

Use two app registrations:

| App | Tenant | Permission Model |
| --- | --- | --- |
| Source migration reader | Source tenant | Read-only Graph application permissions. |
| Target migration writer | Target tenant | Write Graph application permissions and Exchange app permissions where required. |

Use certificate credentials rather than client secrets.

## Local App-Only Run

1. Install modules:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

2. Install the certificate into the user or machine certificate store.

3. Copy config:

```powershell
Copy-Item .\config\sample.agent-config.json .\config\agent-config.json
```

4. Set:

```json
"Auth": {
  "Mode": "AppOnly"
}
```

5. Run dry-run:

```powershell
.\scripts\Invoke-M365TenantMigrationAgent.ps1 -ConfigPath .\config\agent-config.json -OutputPath .\reports\wave1
```

6. Run execute mode after review:

```powershell
.\scripts\Invoke-M365TenantMigrationAgent.ps1 -ConfigPath .\config\agent-config.json -OutputPath .\reports\wave1 -Execute
```

## Azure Automation Direction

For Azure Automation:

- Import Microsoft Graph modules.
- Import ExchangeOnlineManagement if DL/shared mailbox actions are required.
- Upload the certificate to the Automation Account.
- Store config securely or generate it from Automation variables.
- Run dry-run first and export reports to a Storage Account.
- Require manual approval before running `-Execute`.

## Security Notes

- Do not store certificate private keys in the repo.
- Do not commit real `agent-config.json`.
- Use separate source and target app registrations.
- Grant only required permissions.
- Keep `-Execute` behind change approval.
