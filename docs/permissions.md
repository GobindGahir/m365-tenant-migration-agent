# Permissions

## Source Tenant

Suggested Microsoft Graph application permissions for app-only discovery:

| Scope | Purpose |
| --- | --- |
| User.Read.All | Read source users. |
| Group.Read.All | Read source groups and Teams-connected groups. |
| Sites.Read.All | Read source SharePoint site metadata. |
| Directory.Read.All | Read directory context. |

## Target Tenant

Suggested Microsoft Graph application permissions for app-only provisioning:

| Scope | Purpose |
| --- | --- |
| User.ReadWrite.All | Future user provisioning and license assignment workflows. |
| Group.ReadWrite.All | Create Microsoft 365 groups. |
| Sites.ReadWrite.All | Future SharePoint provisioning workflows. |
| Directory.ReadWrite.All | Directory write operations where required. |

## Exchange Online

Distribution list provisioning uses Exchange Online PowerShell.

Suggested role:

| Role | Purpose |
| --- | --- |
| Exchange Administrator | Create and manage distribution groups during migration provisioning. |

The same Exchange role is required to create target shared mailboxes and apply FullAccess or SendAs permissions.

Before using `-Execute` for DL creation, connect to the target tenant with:

```powershell
Connect-ExchangeOnline -UserPrincipalName admin@target.contoso.com
```

For app-only Exchange Online auth, use config:

```json
"Target": {
  "ClientId": "target-app-client-id",
  "CertificateThumbprint": "target-certificate-thumbprint",
  "ExchangeOrganization": "targettenant.onmicrosoft.com",
  "ConnectExchangeOnline": true
}
```

The agent will call:

```powershell
Connect-ExchangeOnline -AppId "<client-id>" -CertificateThumbprint "<thumbprint>" -Organization "<tenant>.onmicrosoft.com"
```

## Security Notes

- Do not commit tenant IDs if they are considered sensitive.
- Do not commit app secrets, certificates, or access tokens.
- Use least privilege app registrations in production.
- Test with lab tenants before production.
