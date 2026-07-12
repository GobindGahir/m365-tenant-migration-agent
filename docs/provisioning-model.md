# Provisioning Model

## MVP

The MVP generates a migration plan for users, licenses, OneDrive, Microsoft 365 groups, Teams, and SharePoint sites.

Microsoft 365 group and security group creation have supported write paths in version `0.1.0`, and only when:

- `-Execute` is used
- `Provisioning.CreateGroups` is `true`
- the planned action is `CreateMicrosoft365Group`
- an existing group with the target display name is not found

Security group creation also requires:

- `Provisioning.CreateSecurityGroups` is `true`
- the planned action is `CreateSecurityGroup`
- an existing group with the target display name is not found

## Plan-Only Actions

These actions are intentionally plan-only in the MVP:

- User creation
- License assignment
- OneDrive pre-provisioning
- Team creation
- Channel creation
- SharePoint site creation

This keeps the first version safe while documenting the full orchestration model.

## Future Enhancements

- App-only authentication support
- Channel mapping input file
- User mapping input file
- License SKU lookup and validation
- SharePoint site template mapping
- Teams owner/member provisioning
- Rollback and cleanup report
