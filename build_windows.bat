@echo off
echo ===================================================
echo Building Edge Link Manager for Windows
echo ===================================================

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Flutter is not installed or not in PATH.
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    exit /b 1
)

REM Check if Flutter Windows desktop is enabled
flutter config --no-analytics
flutter config --enable-windows-desktop

REM Navigate to the project directory
cd %~dp0

REM Get dependencies
echo.
echo Getting dependencies...
flutter pub get

REM Build Windows application
echo.
echo Building Windows application...
flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed. Please check the error messages above.
    exit /b 1
)

echo.
echo ===================================================
echo Build completed successfully!
echo.
echo The Windows executable can be found at:
echo %~dp0build\windows\runner\Release\edge_link_manager.exe
echo.
echo To run the application on a Windows machine:
echo 1. Copy the entire 'Release' folder to the Windows machine
echo 2. Run edge_link_manager.exe
echo ===================================================
