@echo off
setlocal

echo === Step 1: Ensure Flutter dependencies are fetched ===
flutter pub get
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ flutter pub get failed!
    exit /b %ERRORLEVEL%
)

echo === Step 2: Generate ephemeral files for Windows desktop ===
REM This generates the CMake config and plugin registrant
flutter create --platforms=windows .
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ flutter create --platforms=windows . failed!
    exit /b %ERRORLEVEL%
)

echo === Step 3: Clean previous Win32 build ===
rmdir /s /q build\win32 2>nul
mkdir build\win32
cd build\win32

echo === Step 4: Generate 32-bit CMake project ===
cmake ../../windows -G "Visual Studio 17 2022" -A Win32 -DCMAKE_BUILD_TYPE=Release
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ CMake generation failed!
    exit /b %ERRORLEVEL%
)

echo === Step 5: Build app in Release mode (Win32) ===
cmake --build . --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed!
    exit /b %ERRORLEVEL%
)

cd ../..
echo ✅ Build succeeded! Executable is in build\win32\Release\
endlocal

