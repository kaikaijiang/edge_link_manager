@echo off
setlocal

echo === Step 1: Fetch dependencies ===
flutter pub get
IF %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Step 2: Generate plugin files ===
flutter create --platforms=windows .
IF %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Step 3: Clean old build ===
rmdir /s /q build\win32 2>nul
mkdir build\win32
cd build\win32

echo === Step 4: CMake configure (Win32) ===
cmake ../../windows -G "Visual Studio 17 2022" -A Win32 -DCMAKE_BUILD_TYPE=Release
IF %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Step 5: CMake build ===
cmake --build . --config Release
IF %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo === Searching for output .exe in known locations ===
dir .\Release
dir .\bin\Release
dir . /s /b *.exe

echo === Step 6: List output ===
dir .\Release

cd ../..
endlocal

