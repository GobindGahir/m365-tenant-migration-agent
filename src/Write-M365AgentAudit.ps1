function Write-M365AgentAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $OutputPath,

        [Parameter(Mandatory = $true)]
        [string] $EventType,

        [Parameter(Mandatory = $true)]
        [object] $Data
    )

    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $event = [pscustomobject]@{
        EventId = [guid]::NewGuid().ToString()
        EventType = $EventType
        Timestamp = (Get-Date).ToString('s')
        Data = $Data
    }

    $event | ConvertTo-Json -Depth 8 -Compress | Add-Content -Path (Join-Path $OutputPath 'migration-agent-audit.jsonl') -Encoding UTF8
}

