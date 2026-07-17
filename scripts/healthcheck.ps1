$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root '.env'
$ComposeFile = Join-Path $Root 'compose/docker-compose.yml'
$OverrideFile = Join-Path $Root 'compose/docker-compose.override.local.yml'
$Url = 'http://localhost:3000'

if (-not (Test-Path $EnvFile)) {
    Write-Error "Missing .env. Create it from .env.example before running the health check."
}

function Invoke-Docker {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & docker @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Push-Location $Root
try {
    Invoke-Docker info | Out-Null

    Write-Host "Compose services:"
    Invoke-Docker compose --env-file $EnvFile -f $ComposeFile -f $OverrideFile ps

    Write-Host ""
    Write-Host "HTTP check: $Url"
    $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
    Write-Host "StatusCode: $($Response.StatusCode)"

    Write-Host ""
    Write-Host "Recent warnings/errors:"
    $Logs = Invoke-Docker compose --env-file $EnvFile -f $ComposeFile -f $OverrideFile logs --tail 120
    $Relevant = $Logs | Select-String -Pattern 'error|warn|failed|exception|refused|timeout' -CaseSensitive:$false
    if ($Relevant) {
        $Relevant | Select-Object -First 40
    }
    else {
        Write-Host "No recent warning/error patterns found in the last 120 log lines."
    }
}
catch {
    Write-Error $_
}
finally {
    Pop-Location
}
