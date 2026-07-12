function Export-M365MigrationAgentReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Inventory,

        [Parameter(Mandatory = $true)]
        [object] $Plan,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]] $Results,

        [Parameter(Mandatory = $true)]
        [string] $OutputPath
    )

    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $Plan.Actions | Export-Csv -Path (Join-Path $OutputPath "migration-plan-$timestamp.csv") -NoTypeInformation -Encoding UTF8
    $Results | Export-Csv -Path (Join-Path $OutputPath "provisioning-results-$timestamp.csv") -NoTypeInformation -Encoding UTF8

    @{
        GeneratedAt = (Get-Date).ToString('s')
        InventorySummary = @{
            Users = $Inventory.Users.Count
            Groups = $Inventory.Groups.Count
            Sites = $Inventory.Sites.Count
        }
        Plan = $Plan
        Results = $Results
    } | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $OutputPath "migration-agent-report-$timestamp.json") -Encoding UTF8

    $html = New-M365MigrationAgentHtmlReport -Inventory $Inventory -Plan $Plan -Results $Results
    Set-Content -Path (Join-Path $OutputPath "migration-agent-report-$timestamp.html") -Value $html -Encoding UTF8
}

function New-M365MigrationAgentHtmlReport {
    param(
        [object] $Inventory,
        [object] $Plan,
        [object[]] $Results
    )

    $rows = foreach ($action in $Plan.Actions) {
        $workload = [System.Net.WebUtility]::HtmlEncode($action.Workload)
        $type = [System.Net.WebUtility]::HtmlEncode($action.ActionType)
        $source = [System.Net.WebUtility]::HtmlEncode($action.SourceName)
        $target = [System.Net.WebUtility]::HtmlEncode($action.TargetName)
        $risk = [System.Net.WebUtility]::HtmlEncode($action.RiskLevel)
        $recommendation = [System.Net.WebUtility]::HtmlEncode($action.Recommendation)
        "<tr><td>$workload</td><td>$type</td><td>$source</td><td>$target</td><td>$risk</td><td>$recommendation</td></tr>"
    }

    @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>M365 Tenant Migration Agent Report</title>
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #172033; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #d7dee8; padding: 8px; text-align: left; vertical-align: top; }
th { background: #f3f6fa; }
.summary { display: flex; gap: 12px; margin: 20px 0; }
.metric { border: 1px solid #d7dee8; border-radius: 6px; padding: 12px; min-width: 150px; }
.metric strong { display: block; font-size: 26px; }
</style>
</head>
<body>
<h1>M365 Tenant Migration Agent Report</h1>
<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<section class="summary">
<div class="metric"><strong>$($Inventory.Users.Count)</strong>Users</div>
<div class="metric"><strong>$($Inventory.Groups.Count)</strong>Groups</div>
<div class="metric"><strong>$($Inventory.Sites.Count)</strong>Sites</div>
<div class="metric"><strong>$($Plan.Actions.Count)</strong>Actions</div>
<div class="metric"><strong>$($Results.Count)</strong>Results</div>
</section>
<table>
<thead><tr><th>Workload</th><th>Action</th><th>Source</th><th>Target</th><th>Risk</th><th>Recommendation</th></tr></thead>
<tbody>$($rows -join "`n")</tbody>
</table>
</body>
</html>
"@
}

