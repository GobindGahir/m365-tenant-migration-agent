function Get-M365SourceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $users = @()
    $groups = @()
    $sites = @()

    if ($Config.Discovery.IncludeUsers -eq $true) {
        $users = @(Get-MgUser -Top $Config.Discovery.MaxUsers -Property 'id,displayName,userPrincipalName,mail,accountEnabled,userType,assignedLicenses')
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
        Groups = $groups
        Sites = $sites
    }
}

