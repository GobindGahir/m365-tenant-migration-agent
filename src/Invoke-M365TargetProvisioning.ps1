function Invoke-M365TargetProvisioning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Plan,

        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $OutputPath,

        [switch] $Execute
    )

    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $results = [System.Collections.Generic.List[object]]::new()
    $mode = if ($Execute) { 'Execute' } else { 'DryRun' }

    foreach ($action in $Plan.Actions) {
        $status = 'Planned'
        $message = 'Dry run only. No target tenant changes were made.'

        if ($Execute -and $action.ExecuteSupported -eq $true -and $action.ActionType -eq 'CreateMicrosoft365Group' -and $Config.Provisioning.CreateGroups -eq $true) {
            $existing = @(Get-MgGroup -Filter "displayName eq '$($action.TargetName.Replace("'", "''"))'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue)

            if ($existing.Count -gt 0) {
                $status = 'Skipped'
                $message = 'Target group already exists.'
            }
            else {
                $mailNickname = if ([string]::IsNullOrWhiteSpace($action.MailNickname)) { ConvertTo-MailNickname -DisplayName $action.TargetName } else { $action.MailNickname }
                New-MgGroup -DisplayName $action.TargetName -MailEnabled:$true -MailNickname $mailNickname -SecurityEnabled:$false -GroupTypes @('Unified') | Out-Null
                $status = 'Created'
                $message = 'Microsoft 365 group created in target tenant.'
            }
        }
        elseif ($Execute -and $action.ExecuteSupported -eq $true -and $action.ActionType -eq 'CreateSecurityGroup' -and $Config.Provisioning.CreateSecurityGroups -eq $true) {
            $existing = @(Get-MgGroup -Filter "displayName eq '$($action.TargetName.Replace("'", "''"))'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue)

            if ($existing.Count -gt 0) {
                $status = 'Skipped'
                $message = 'Target security group already exists.'
            }
            else {
                $mailNickname = if ([string]::IsNullOrWhiteSpace($action.MailNickname)) { ConvertTo-MailNickname -DisplayName $action.TargetName } else { $action.MailNickname }
                New-MgGroup -DisplayName $action.TargetName -MailEnabled:$false -MailNickname $mailNickname -SecurityEnabled:$true | Out-Null
                $status = 'Created'
                $message = 'Security group created in target tenant.'
            }
        }
        elseif ($Execute -and $action.ExecuteSupported -ne $true) {
            $status = 'NotSupported'
            $message = 'This action is intentionally plan-only in the MVP.'
        }

        $result = [pscustomobject]@{
            Timestamp = (Get-Date).ToString('s')
            Mode = $mode
            ActionId = $action.ActionId
            Workload = $action.Workload
            ActionType = $action.ActionType
            SourceName = $action.SourceName
            TargetName = $action.TargetName
            Status = $status
            Message = $message
        }

        $results.Add($result)
        Write-M365AgentAudit -OutputPath $OutputPath -EventType 'ProvisioningAction' -Data $result
    }

    $results
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
