@echo off
setlocal

echo === Cleaning previous Win32 build ===
rmdir /s /q build\win32 2>nul
mkdir build\win32
cd build\win32

echo === Generating CMake build system for 32-bit (Win32) ===
cmake ../../windows -G "Visual Studio 17 2022" -A Win32 -DCMAKE_BUILD_TYPE=Release
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ CMake generation failed!
    exit /b %ERRORLEVEL%
)

echo === Building project in Release mode ===
cmake --build . --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed!
    exit /b %ERRORLEVEL%
)

cd ../..
echo ✅ Build succeeded! Executable is in build\win32\Release\
endlocal

