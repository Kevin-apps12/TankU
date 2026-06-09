# Runs the app with Supabase config from env.ps1.
# Usage:
#   ./run.ps1            # default device
#   ./run.ps1 chrome     # web
#   ./run.ps1 windows    # desktop (if enabled)
param([string]$Device = "")

$envFile = Join-Path $PSScriptRoot "env.ps1"
if (Test-Path $envFile) {
    . $envFile
} else {
    Write-Host "No env.ps1 found. Copy env.example.ps1 to env.ps1 and fill it in." -ForegroundColor Yellow
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
    Write-Host "SUPABASE_URL / SUPABASE_ANON_KEY are not set." -ForegroundColor Red
    exit 1
}

$args = @(
    "run",
    "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)",
    "--dart-define=SUPABASE_ANON_KEY=$($env:SUPABASE_ANON_KEY)"
)
if ($Device) { $args += @("-d", $Device) }

& flutter @args
