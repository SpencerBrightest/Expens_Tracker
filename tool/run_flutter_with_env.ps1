param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArguments
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env'

if (-not (Test-Path $envFile)) {
    throw 'The root .env file is required to read GEMINI_API_KEY.'
}

$keyLine = Get-Content $envFile |
    Where-Object { $_ -match '^\s*GEMINI_API_KEY\s*=' } |
    Select-Object -Last 1

if (-not $keyLine) {
    throw 'GEMINI_API_KEY is missing from the root .env file.'
}

$geminiApiKey = ($keyLine -replace '^\s*GEMINI_API_KEY\s*=\s*', '').Trim()
if ($geminiApiKey.Length -ge 2 -and
    (($geminiApiKey[0] -eq '"' -and $geminiApiKey[-1] -eq '"') -or
     ($geminiApiKey[0] -eq "'" -and $geminiApiKey[-1] -eq "'"))) {
    $geminiApiKey = $geminiApiKey.Substring(1, $geminiApiKey.Length - 2)
}

if ([string]::IsNullOrWhiteSpace($geminiApiKey)) {
    throw 'GEMINI_API_KEY is blank in the root .env file.'
}

Push-Location $repoRoot
try {
    & flutter @FlutterArguments "--dart-define=GEMINI_API_KEY=$geminiApiKey"
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}