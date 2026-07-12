function Connect-M365TenantMigrationAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Source', 'Target')]
        [string] $Mode
    )

    $requiredModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Groups',
        'Microsoft.Graph.Sites',
        'Microsoft.Graph.Teams'
    )

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            throw "Required module '$module' was not found. Install Microsoft Graph with: Install-Module Microsoft.Graph -Scope CurrentUser"
        }

        Import-Module $module -ErrorAction Stop
    }

    $scopes = if ($Mode -eq 'Source') {
        @('User.Read.All', 'Group.Read.All', 'Sites.Read.All', 'Directory.Read.All')
    }
    else {
        @('User.ReadWrite.All', 'Group.ReadWrite.All', 'Sites.ReadWrite.All', 'Directory.ReadWrite.All')
    }

    Write-Host "Connecting to $Mode tenant $TenantId..." -ForegroundColor Cyan
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome
}

