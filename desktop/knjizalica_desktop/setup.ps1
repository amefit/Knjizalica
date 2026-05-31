# Setup script for Knjizalica Desktop (Flutter not assumed in PATH)
param(
    [string]$FlutterPath = ""
)

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot

function Find-Flutter {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }

    $candidates = @(
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return (Resolve-Path $path).Path
        }
    }

    $fromPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    throw "Flutter not found. Install Flutter or pass -FlutterPath 'C:\path\to\flutter\bin\flutter.bat'"
}

$flutter = Find-Flutter -ExplicitPath $FlutterPath
Write-Host "Using Flutter: $flutter"

Set-Location $ProjectDir

# Create platform folders if missing (preserves existing lib/)
if (-not (Test-Path "windows")) {
    Write-Host "Running flutter create for Windows platform..."
    & $flutter create --platforms=windows .
}

Write-Host "Fetching dependencies..."
& $flutter pub get

Write-Host ""
Write-Host "Setup complete. Run the app with:"
Write-Host "  & '$flutter' run -d windows --dart-define=API_BASE_URL=http://localhost:5000"
Write-Host ""
Write-Host "Default admin login: desktop / test"
