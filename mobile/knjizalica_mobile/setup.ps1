# Generates Flutter platform folders when the Flutter SDK is available.
$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

function Test-FlutterAvailable {
    try {
        $null = Get-Command flutter -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-FlutterAvailable)) {
    Write-Host "Flutter is not in PATH."
    Write-Host "Install Flutter and add it to PATH, then run:"
    Write-Host "  cd `"$projectRoot`""
    Write-Host "  flutter create . --org com.knjizalica --project-name knjizalica_mobile"
    Write-Host ""
    Write-Host "Dart sources under lib/ are complete; platform folders are required to run on a device."
    exit 1
}

Push-Location $projectRoot
try {
    flutter create . --org com.knjizalica --project-name knjizalica_mobile
    Write-Host "Platform scaffolding created. Run: flutter pub get"
} finally {
    Pop-Location
}
