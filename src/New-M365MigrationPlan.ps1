function New-M365MigrationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Inventory,

        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [object] $Scope
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

    foreach ($team in $Scope.Teams) {
        if ($team.Action -eq 'Skip') {
            continue
        }

        $targetName = if ([string]::IsNullOrWhiteSpace($team.TargetTeamName)) { "$($Config.Mappings.GroupPrefix)$($team.SourceTeamName)" } else { $team.TargetTeamName }
        $mailNickname = if ([string]::IsNullOrWhiteSpace($team.TargetMailNickname)) { ConvertTo-MailNickname -DisplayName $targetName } else { $team.TargetMailNickname }

        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = 'Microsoft 365 Groups'
            ActionType = 'CreateMicrosoft365Group'
            SourceObjectId = $null
            SourceName = $team.SourceTeamName
            TargetName = $targetName
            TargetObjectType = 'Group'
            RiskLevel = 'Low'
            ExecuteSupported = $true
            MailNickname = $mailNickname
            Wave = $team.Wave
            Recommendation = 'Create target Microsoft 365 group if it does not already exist.'
        })

        if ($Config.Provisioning.CreateTeams -eq $true) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'Teams'
                ActionType = 'PlanTeamProvisioning'
                SourceObjectId = $null
                SourceName = $team.SourceTeamName
                TargetName = $targetName
                TargetObjectType = 'Team'
                RiskLevel = 'Medium'
                ExecuteSupported = $false
                Channels = $team.Channels
                Wave = $team.Wave
                Recommendation = 'Create Team from provisioned Microsoft 365 group and add channels from channel mapping.'
            })
        }

        if ($Config.Provisioning.CreateSecurityGroups -eq $true -and (ConvertTo-Bool $team.CreateSecurityGroup)) {
            $securityGroupName = if ([string]::IsNullOrWhiteSpace($team.TargetSecurityGroupName)) { "$($Config.Mappings.SecurityGroupPrefix)$targetName" } else { $team.TargetSecurityGroupName }
            Add-M365SecurityGroupPlanAction -Actions $actions -SourceName $team.SourceTeamName -TargetName $securityGroupName -Wave $team.Wave -Purpose 'Teams access/security mapping'
        }
    }

    foreach ($site in $Scope.SharePointSites) {
        if ($site.Action -eq 'Skip') {
            continue
        }

        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = 'SharePoint Online'
            ActionType = 'PlanSharePointSite'
            SourceObjectId = $null
            SourceName = $site.SourceSiteUrl
            TargetName = $site.TargetSiteUrl
            TargetObjectType = 'Site'
            RiskLevel = 'Low'
            ExecuteSupported = $false
            Template = $site.Template
            Wave = $site.Wave
            Recommendation = 'Create target site through approved site provisioning process before content migration.'
        })

        if ($Config.Provisioning.CreateSecurityGroups -eq $true -and (ConvertTo-Bool $site.CreateSecurityGroup)) {
            $securityGroupName = if ([string]::IsNullOrWhiteSpace($site.TargetSecurityGroupName)) { "$($Config.Mappings.SecurityGroupPrefix)SPO-$($site.Template)-$($site.Wave)" } else { $site.TargetSecurityGroupName }
            Add-M365SecurityGroupPlanAction -Actions $actions -SourceName $site.SourceSiteUrl -TargetName $securityGroupName -Wave $site.Wave -Purpose 'SharePoint access/security mapping'
        }
    }

    foreach ($distributionList in $Scope.DistributionLists) {
        if ($distributionList.Action -eq 'Skip') {
            continue
        }

        $targetName = $distributionList.TargetDisplayName
        $targetSmtp = $distributionList.TargetPrimarySmtpAddress

        $actions.Add([pscustomobject]@{
            ActionId = [guid]::NewGuid().ToString()
            Workload = 'Exchange Online'
            ActionType = 'CreateDistributionList'
            SourceObjectId = $null
            SourceName = $distributionList.SourceDisplayName
            TargetName = $targetName
            TargetObjectType = 'DistributionList'
            RiskLevel = 'Medium'
            ExecuteSupported = $true
            PrimarySmtpAddress = $targetSmtp
            Alias = $distributionList.Alias
            Owners = $distributionList.Owners
            Members = $distributionList.Members
            RequireSenderAuthenticationEnabled = $distributionList.RequireSenderAuthenticationEnabled
            Wave = $distributionList.Wave
            Recommendation = 'Create target distribution list and validate owners, members, and mail flow.'
        })

        if (-not [string]::IsNullOrWhiteSpace($distributionList.Owners)) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'Exchange Online'
                ActionType = 'PlanDistributionListOwners'
                SourceObjectId = $null
                SourceName = $distributionList.SourceDisplayName
                TargetName = $targetName
                TargetObjectType = 'DistributionList'
                RiskLevel = 'Low'
                ExecuteSupported = $false
                Owners = $distributionList.Owners
                Wave = $distributionList.Wave
                Recommendation = 'Validate target distribution list ownership after creation.'
            })
        }

        if (-not [string]::IsNullOrWhiteSpace($distributionList.Members)) {
            $actions.Add([pscustomobject]@{
                ActionId = [guid]::NewGuid().ToString()
                Workload = 'Exchange Online'
                ActionType = 'PlanDistributionListMembers'
                SourceObjectId = $null
                SourceName = $distributionList.SourceDisplayName
                TargetName = $targetName
                TargetObjectType = 'DistributionList'
                RiskLevel = 'Low'
                ExecuteSupported = $false
                Members = $distributionList.Members
                Wave = $distributionList.Wave
                Recommendation = 'Validate target distribution list membership after creation.'
            })
        }
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

function Add-M365SecurityGroupPlanAction {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]] $Actions,

        [Parameter(Mandatory = $true)]
        [string] $SourceName,

        [Parameter(Mandatory = $true)]
        [string] $TargetName,

        [string] $Wave,

        [string] $Purpose
    )

    $Actions.Add([pscustomobject]@{
        ActionId = [guid]::NewGuid().ToString()
        Workload = 'Entra ID Groups'
        ActionType = 'CreateSecurityGroup'
        SourceObjectId = $null
        SourceName = $SourceName
        TargetName = $TargetName
        TargetObjectType = 'SecurityGroup'
        RiskLevel = 'Low'
        ExecuteSupported = $true
        MailNickname = ConvertTo-MailNickname -DisplayName $TargetName
        Wave = $Wave
        Recommendation = "Create target security group for $Purpose."
    })
}

function ConvertTo-MailNickname {
    param(
        [string] $DisplayName
    )

    $nickname = ($DisplayName -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
    if ($nickname.Length -gt 60) {
        $nickname = $nickname.Substring(0, 60)
    }

    if ([string]::IsNullOrWhiteSpace($nickname)) {
        return "mig$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    }

    $nickname
}

function ConvertTo-Bool {
    param(
        [object] $Value
    )

    if ($Value -is [bool]) {
        return $Value
    }

    @('true', 'yes', '1', 'y') -contains ([string] $Value).Trim().ToLowerInvariant()
}
