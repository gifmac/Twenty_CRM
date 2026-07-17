param(
    [string]$Hostname = 'crm-test.proeduconnect.com'
)

$ErrorActionPreference = 'Stop'

$Cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $Cloudflared) {
    $KnownPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
    if (Test-Path $KnownPath) {
        $CloudflaredPath = $KnownPath
    }
    else {
        Write-Error 'cloudflared was not found on PATH or at the expected Windows install path.'
    }
}
else {
    $CloudflaredPath = $Cloudflared.Source
}

Write-Host "cloudflared: $CloudflaredPath"
& $CloudflaredPath version
if ($LASTEXITCODE -ne 0) {
    throw 'cloudflared version check failed.'
}

Write-Host ''
Write-Host 'Windows service:'
$Service = Get-Service -Name Cloudflared -ErrorAction SilentlyContinue
if ($Service) {
    $ServiceSummary = $Service | Select-Object Name,DisplayName,Status,StartType
    Write-Host ($ServiceSummary | Format-Table -AutoSize | Out-String)

    $RawConfig = & sc.exe qc Cloudflared 2>&1
    $RawConfig | ForEach-Object {
        $_ -replace '(?i)(--token\s+)[^\s"]+', '$1<REDACTED>' `
           -replace '(?i)(token=)[^\s"]+', '$1<REDACTED>' `
           -replace 'eyJ[A-Za-z0-9_\.-]+', '<REDACTED_JWT>'
    }
}
else {
    Write-Host 'No Cloudflared Windows service found.'
}

Write-Host ''
Write-Host "DNS check: $Hostname"
try {
    Resolve-DnsName -Name $Hostname -ErrorAction Stop | Select-Object Name,Type,IPAddress,NameHost
}
catch {
    Write-Host "DNS not resolved: $($_.Exception.Message)"
}

Write-Host ''
Write-Host "HTTPS check: https://$Hostname"
try {
    $Response = Invoke-WebRequest -Uri "https://$Hostname" -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15
    Write-Host "StatusCode: $($Response.StatusCode)"
}
catch {
    if ($_.Exception.Response) {
        Write-Host "StatusCode: $([int]$_.Exception.Response.StatusCode)"
        Write-Host "StatusDescription: $($_.Exception.Response.StatusDescription)"
    }
    else {
        Write-Host "Request failed: $($_.Exception.Message)"
    }
}
