function Get-M365SourceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $users = @()
    $sharedMailboxes = @()
    $groups = @()
    $sites = @()

    if ($Config.Discovery.IncludeUsers -eq $true) {
        if ($null -ne $Config.Scope -and -not [string]::IsNullOrWhiteSpace($Config.Scope.UserMigrationGroupId)) {
            $users = @(Get-M365MigrationGroupUsers -GroupId $Config.Scope.UserMigrationGroupId -MaxUsers $Config.Discovery.MaxUsers)
        }
        else {
            $users = @(Get-MgUser -Top $Config.Discovery.MaxUsers -Property 'id,displayName,userPrincipalName,mail,accountEnabled,userType,assignedLicenses')
        }
    }

    if ($null -ne $Config.Scope -and -not [string]::IsNullOrWhiteSpace($Config.Scope.SharedMailboxMigrationGroupId)) {
        $sharedMailboxes = @(Get-M365MigrationGroupUsers -GroupId $Config.Scope.SharedMailboxMigrationGroupId -MaxUsers $Config.Discovery.MaxUsers)
    }

    if ($Config.Discovery.IncludeGroups -eq $true) {
        $groups = @(Get-MgGroup -Top $Config.Discovery.MaxGroups -Property 'id,displayName,mail,mailNickname,groupTypes,mailEnabled,securityEnabled,visibility')
    }

    if ($Config.Discovery.IncludeSites -eq $true) {
        $sites = @(Get-MgSite -Top $Config.Discovery.MaxSites -Property 'id,displayName,name,webUrl,createdDateTime,lastModifiedDateTime,root,siteCollection')
    }

    [pscustomobject]@{
        GeneratedAt = (Get-Date).ToString('s')
        SourceTenant = $Config.SourceTenant.TenantId
        Users = $users
        SharedMailboxes = $sharedMailboxes
        Groups = $groups
        Sites = $sites
    }
}

function Get-M365MigrationGroupUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $GroupId,

        [int] $MaxUsers = 250
    )

    $members = @(Get-MgGroupMember -GroupId $GroupId -Top $MaxUsers)

    foreach ($member in $members) {
        if ($member.AdditionalProperties.'@odata.type' -ne '#microsoft.graph.user') {
            continue
        }

        Get-MgUser -UserId $member.Id -Property 'id,displayName,userPrincipalName,mail,accountEnabled,userType,assignedLicenses'
    }
}
