# Permissions

## Source Tenant

Suggested delegated Microsoft Graph scopes:

| Scope | Purpose |
| --- | --- |
| User.Read.All | Read source users. |
| Group.Read.All | Read source groups and Teams-connected groups. |
| Sites.Read.All | Read source SharePoint site metadata. |
| Directory.Read.All | Read directory context. |

## Target Tenant

Suggested delegated Microsoft Graph scopes:

| Scope | Purpose |
| --- | --- |
| User.ReadWrite.All | Future user provisioning and license assignment workflows. |
| Group.ReadWrite.All | Create Microsoft 365 groups. |
| Sites.ReadWrite.All | Future SharePoint provisioning workflows. |
| Directory.ReadWrite.All | Directory write operations where required. |

## Security Notes

- Do not commit tenant IDs if they are considered sensitive.
- Do not commit app secrets, certificates, or access tokens.
- Use least privilege app registrations in production.
- Test with lab tenants before production.

