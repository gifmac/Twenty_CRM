$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
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

Push-Location $Root
try {
    .\scripts\status.ps1

    $Response = Invoke-WebRequest -Uri 'http://localhost:3000' -UseBasicParsing -TimeoutSec 10
    if ($Response.StatusCode -ne 200) {
        throw "Expected HTTP 200 from local Twenty, got $($Response.StatusCode)."
    }

    Write-Host 'Local Twenty origin: HTTP 200'
}
finally {
    Pop-Location
}

