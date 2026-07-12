function New-M365MigrationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Inventory,

        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $actions = [System.Collections.Generic.List[object]]::new()

    foreach ($user in $Inventory.Users) {
        if ($user.UserType -ne 'Member') {
            continue
        }

        $targetUpn = ConvertTo-TargetUpn -UserPrincipalName $user.UserPrincipalName -TargetDomain $Config.Mappings.UserPrincipalNameDomain

        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = 'Entra ID'
            ActionType = 'PlanUser'
            SourceObjectId = $user.Id
            SourceName = $user.UserPrincipalName
            TargetName = $targetUpn
            TargetObjectType = 'User'
            RiskLevel = if ($user.AccountEnabled -eq $false) { 'Medium' } else { 'Low' }
            ExecuteSupported = $false
            Recommendation = 'Create or match target user through approved identity lifecycle process.'
        })

        if ($Config.Provisioning.AssignLicenses -eq $true -and $null -ne $user.AssignedLicenses -and $user.AssignedLicenses.Count -gt 0) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'Licensing'
                ActionType = 'PlanLicenseAssignment'
                SourceObjectId = $user.Id
                SourceName = $user.UserPrincipalName
                TargetName = $targetUpn
                TargetObjectType = 'User'
                RiskLevel = 'Medium'
                ExecuteSupported = $false
                Recommendation = 'Map source SKU to target SKU and assign license after target user exists.'
            })
        }

        if ($Config.Provisioning.PreProvisionOneDrive -eq $true) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'OneDrive'
                ActionType = 'PlanOneDrivePreProvision'
                SourceObjectId = $user.Id
                SourceName = $user.UserPrincipalName
                TargetName = $targetUpn
                TargetObjectType = 'OneDrive'
                RiskLevel = 'Low'
                ExecuteSupported = $false
                Recommendation = 'Pre-provision OneDrive after target user and license assignment are complete.'
            })
        }
    }

    foreach ($group in $Inventory.Groups) {
        $targetName = "$($Config.Mappings.GroupPrefix)$($group.DisplayName)"
        $isUnified = $group.GroupTypes -contains 'Unified'

        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = if ($isUnified) { 'Microsoft 365 Groups' } else { 'Entra ID Groups' }
            ActionType = if ($isUnified) { 'CreateMicrosoft365Group' } else { 'PlanSecurityGroup' }
            SourceObjectId = $group.Id
            SourceName = $group.DisplayName
            TargetName = $targetName
            TargetObjectType = 'Group'
            RiskLevel = 'Low'
            ExecuteSupported = $isUnified
            Recommendation = if ($isUnified) { 'Create target Microsoft 365 group if it does not already exist.' } else { 'Review security group migration requirements and app dependencies.' }
        })

        if ($isUnified -and $Config.Provisioning.CreateTeams -eq $true) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'Teams'
                ActionType = 'PlanTeamProvisioning'
                SourceObjectId = $group.Id
                SourceName = $group.DisplayName
                TargetName = $targetName
                TargetObjectType = 'Team'
                RiskLevel = 'Medium'
                ExecuteSupported = $false
                Recommendation = 'Create Team from provisioned Microsoft 365 group and add channels from channel mapping.'
            })
        }
    }

    foreach ($site in $Inventory.Sites) {
        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = 'SharePoint Online'
            ActionType = 'PlanSharePointSite'
            SourceObjectId = $site.Id
            SourceName = $site.WebUrl
            TargetName = ConvertTo-TargetSiteUrl -SourceUrl $site.WebUrl -TargetDomain $Config.TargetTenant.PrimaryDomain
            TargetObjectType = 'Site'
            RiskLevel = if ($null -eq $site.LastModifiedDateTime) { 'Medium' } else { 'Low' }
            ExecuteSupported = $false
            Recommendation = 'Create target site through approved site provisioning process before content migration.'
        })
    }

    [pscustomobject]@{
        GeneratedAt = (Get-Date).ToString('s')
        SourceTenant = $Config.SourceTenant.TenantId
        TargetTenant = $Config.TargetTenant.TenantId
        Actions = $actions
    }
}

function ConvertTo-TargetUpn {
    param(
        [string] $UserPrincipalName,
        [string] $TargetDomain
    )

    $alias = ($UserPrincipalName -split '@')[0]
    "$alias@$TargetDomain"
}

function ConvertTo-TargetSiteUrl {
    param(
        [string] $SourceUrl,
        [string] $TargetDomain
    )

    if ([string]::IsNullOrWhiteSpace($SourceUrl)) {
        return $null
    }

    $uri = [uri] $SourceUrl
    "https://$TargetDomain$($uri.AbsolutePath)"
}

