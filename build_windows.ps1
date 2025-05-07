# PowerShell script to build Edge Link Manager for Windows
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Building Edge Link Manager for Windows" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter is installed." -ForegroundColor Green
} catch {
    Write-Host "Flutter is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# Check if Flutter Windows desktop is enabled
Write-Host "`nConfiguring Flutter..." -ForegroundColor Cyan
flutter config --no-analytics
flutter config --enable-windows-desktop

# Get dependencies
Write-Host "`nGetting dependencies..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nFailed to get dependencies. Please check the error messages above." -ForegroundColor Red
    exit 1
}

# Build Windows application
Write-Host "`nBuilding Windows application..." -ForegroundColor Cyan
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}

$releasePath = Join-Path -Path $PSScriptRoot -ChildPath "build\windows\runner\Release"

Write-Host "`n===================================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "`nThe Windows executable can be found at:" -ForegroundColor Yellow
Write-Host "$releasePath\edge_link_manager.exe" -ForegroundColor Yellow
Write-Host "`nTo run the application on a Windows machine:" -ForegroundColor Yellow
Write-Host "1. Copy the entire 'Release' folder to the Windows machine" -ForegroundColor Yellow
Write-Host "2. Run edge_link_manager.exe" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Green
