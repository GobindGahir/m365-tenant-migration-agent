function Import-M365MigrationScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $teams = @()
    $sharePointSites = @()
    $distributionLists = @()

    if ($null -ne $Config.Scope -and -not [string]::IsNullOrWhiteSpace($Config.Scope.TeamsCsvPath)) {
        $teamsPath = Resolve-M365AgentPath -Path $Config.Scope.TeamsCsvPath
        if (Test-Path -Path $teamsPath) {
            $teams = @(Import-Csv -Path $teamsPath | Where-Object { ConvertTo-Bool $_.Enabled })
        }
    }

    if ($null -ne $Config.Scope -and -not [string]::IsNullOrWhiteSpace($Config.Scope.SharePointCsvPath)) {
        $sharePointPath = Resolve-M365AgentPath -Path $Config.Scope.SharePointCsvPath
        if (Test-Path -Path $sharePointPath) {
            $sharePointSites = @(Import-Csv -Path $sharePointPath | Where-Object { ConvertTo-Bool $_.Enabled })
        }
    }

    if ($null -ne $Config.Scope -and -not [string]::IsNullOrWhiteSpace($Config.Scope.DistributionListsCsvPath)) {
        $distributionListsPath = Resolve-M365AgentPath -Path $Config.Scope.DistributionListsCsvPath
        if (Test-Path -Path $distributionListsPath) {
            $distributionLists = @(Import-Csv -Path $distributionListsPath | Where-Object { ConvertTo-Bool $_.Enabled })
        }
    }

    [pscustomobject]@{
        Teams = $teams
        SharePointSites = $sharePointSites
        DistributionLists = $distributionLists
    }
}

function Resolve-M365AgentPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    Join-Path (Get-Location) $Path
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
