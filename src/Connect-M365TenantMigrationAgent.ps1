function Connect-M365TenantMigrationAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

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

    $tenantId = if ($Mode -eq 'Source') { $Config.SourceTenant.TenantId } else { $Config.TargetTenant.TenantId }
    $authMode = if ($null -ne $Config.Auth -and -not [string]::IsNullOrWhiteSpace($Config.Auth.Mode)) {
        $Config.Auth.Mode
    }
    else {
        'Delegated'
    }

    $scopes = if ($Mode -eq 'Source') {
        @('User.Read.All', 'Group.Read.All', 'Sites.Read.All', 'Directory.Read.All')
    }
    else {
        @('User.ReadWrite.All', 'Group.ReadWrite.All', 'Sites.ReadWrite.All', 'Directory.ReadWrite.All')
    }

    Write-Host "Connecting to $Mode tenant $tenantId using $authMode auth..." -ForegroundColor Cyan

    if ($authMode -eq 'AppOnly') {
        $appAuth = if ($Mode -eq 'Source') { $Config.Auth.Source } else { $Config.Auth.Target }

        if ($null -eq $appAuth -or [string]::IsNullOrWhiteSpace($appAuth.ClientId) -or [string]::IsNullOrWhiteSpace($appAuth.CertificateThumbprint)) {
            throw "$Mode app-only authentication requires ClientId and CertificateThumbprint in config."
        }

        Connect-MgGraph -TenantId $tenantId -ClientId $appAuth.ClientId -CertificateThumbprint $appAuth.CertificateThumbprint -NoWelcome

        if ($Mode -eq 'Target' -and $appAuth.ConnectExchangeOnline -eq $true) {
            Connect-M365AgentExchangeOnline -TargetAuth $appAuth
        }

        return
    }

    Connect-MgGraph -TenantId $tenantId -Scopes $scopes -NoWelcome
}

function Connect-M365AgentExchangeOnline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $TargetAuth
    )

    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module is required for app-only Exchange connection. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    }

    if ([string]::IsNullOrWhiteSpace($TargetAuth.ExchangeOrganization)) {
        throw "Target Auth ExchangeOrganization is required for app-only Exchange Online connection."
    }

    Import-Module ExchangeOnlineManagement -ErrorAction Stop

    Connect-ExchangeOnline `
        -AppId $TargetAuth.ClientId `
        -CertificateThumbprint $TargetAuth.CertificateThumbprint `
        -Organization $TargetAuth.ExchangeOrganization `
        -ShowBanner:$false
}
