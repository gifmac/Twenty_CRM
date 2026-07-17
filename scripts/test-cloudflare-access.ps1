param(
    [string]$Hostname = 'crm-test.proeduconnect.com'
)

$ErrorActionPreference = 'Stop'

$Url = "https://$Hostname"

Write-Output "Starting Cloudflare Access test for $Hostname"
Write-Output "DNS check: $Hostname"
$Dns = Resolve-DnsName -Name $Hostname -ErrorAction Stop
Write-Output ($Dns | Select-Object -First 5 Name,Type,IPAddress,NameHost | Format-Table -AutoSize | Out-String)

Write-Output ""
Write-Output "Unauthenticated request check: $Url"
$UnauthenticatedStatus = $null
try {
    $Unauthenticated = Invoke-WebRequest -Uri $Url -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15
    $UnauthenticatedStatus = $Unauthenticated.StatusCode
}
catch {
    if ($_.Exception.Response) {
        $UnauthenticatedStatus = [int]$_.Exception.Response.StatusCode
    }
    else {
        throw
    }
}

Write-Output "Unauthenticated status: $UnauthenticatedStatus"
if ($UnauthenticatedStatus -eq 200) {
    throw 'Unauthenticated request returned HTTP 200. Access protection is not blocking this hostname.'
}

if (-not $env:CF_ACCESS_CLIENT_ID -or -not $env:CF_ACCESS_CLIENT_SECRET) {
    Write-Output ''
    Write-Output 'Skipping service-token request: CF_ACCESS_CLIENT_ID and CF_ACCESS_CLIENT_SECRET are not set in this shell.'
    exit 0
}

if ($env:CF_ACCESS_CLIENT_ID -eq '<CLIENT_ID>' -or $env:CF_ACCESS_CLIENT_SECRET -eq '<CLIENT_SECRET>') {
    throw 'CF_ACCESS_CLIENT_ID and CF_ACCESS_CLIENT_SECRET still contain placeholder values. Replace them with the actual Cloudflare Access service token values for this PowerShell session.'
}

Write-Output ""
Write-Output 'Service-token request check'
Write-Output "Client ID present: length $($env:CF_ACCESS_CLIENT_ID.Length)"
Write-Output "Client Secret present: length $($env:CF_ACCESS_CLIENT_SECRET.Length)"
$Headers = @{
    'CF-Access-Client-Id' = $env:CF_ACCESS_CLIENT_ID
    'CF-Access-Client-Secret' = $env:CF_ACCESS_CLIENT_SECRET
}

$AuthenticatedStatus = $null
try {
    $Authenticated = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing -TimeoutSec 20
    $AuthenticatedStatus = $Authenticated.StatusCode
}
catch {
    if ($_.Exception.Response) {
        $AuthenticatedStatus = [int]$_.Exception.Response.StatusCode
    }
    else {
        throw
    }
}

Write-Output "Authenticated status: $AuthenticatedStatus"

if ($AuthenticatedStatus -ne 200) {
    throw "Expected HTTP 200 with service-token headers, got $AuthenticatedStatus."
}
