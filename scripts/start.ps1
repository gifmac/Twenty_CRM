$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root '.env'
$ComposeFile = Join-Path $Root 'compose/docker-compose.yml'
$OverrideFile = Join-Path $Root 'compose/docker-compose.override.local.yml'

if (-not (Test-Path $EnvFile)) {
    Write-Error "Missing .env. Create it with: Copy-Item .\.env.example .\.env, then replace placeholders."
}

function Invoke-Docker {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & docker @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    Invoke-Docker compose --env-file $EnvFile -f $ComposeFile -f $OverrideFile @Arguments
}

Push-Location $Root
try {
    Invoke-Docker info | Out-Null
    Invoke-Compose config | Out-Null
    Invoke-Compose up -d
    Invoke-Compose ps
}
finally {
    Pop-Location
}
