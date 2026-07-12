# Provisioning Model

## MVP

The MVP generates a migration plan for users, licenses, OneDrive, Microsoft 365 groups, Teams, and SharePoint sites.

Microsoft 365 group, security group, distribution list, shared mailbox, and shared mailbox permission actions have supported write paths in version `0.1.0`.

- `-Execute` is used
- `Provisioning.CreateGroups` is `true`
- the planned action is `CreateMicrosoft365Group`
- an existing group with the target display name is not found

Security group creation also requires:

- `Provisioning.CreateSecurityGroups` is `true`
- the planned action is `CreateSecurityGroup`
- an existing group with the target display name is not found

Distribution list creation requires:

- `Provisioning.CreateDistributionLists` is `true`
- the planned action is `CreateDistributionList`
- Exchange Online PowerShell is connected in the target tenant
- an existing distribution list with the target SMTP address is not found

Shared mailbox creation and permission assignment require:

- `Provisioning.CreateSharedMailboxes` is `true`
- `Provisioning.ApplySharedMailboxPermissions` is `true`
- Exchange Online PowerShell is connected in the target tenant
- target shared mailbox exists before permissions are applied

## Plan-Only Actions

These actions are intentionally plan-only in the MVP:

- User creation
- License assignment
- OneDrive pre-provisioning
- Team creation
- Channel creation
- SharePoint site creation
- Distribution list owner/member validation actions

This keeps the first version safe while documenting the full orchestration model.

## Future Enhancements

- App-only authentication support
- Channel mapping input file
- User mapping input file
- License SKU lookup and validation
- SharePoint site template mapping
- Teams owner/member provisioning
- Rollback and cleanup report
