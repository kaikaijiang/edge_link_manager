# Building Edge Link Manager for Windows

This document provides instructions on how to build the Edge Link Manager application for Windows and run it on a Windows machine.

## Prerequisites

Before building the application, ensure you have the following installed on your Windows machine:

1. **Flutter SDK** - Install Flutter by following the [official installation guide](https://flutter.dev/docs/get-started/install/windows)
2. **Visual Studio** - Install Visual Studio 2019 or later with the "Desktop development with C++" workload
3. **Git** - Install Git for Windows from [git-scm.com](https://git-scm.com/download/win)

## Building the Application

### Option 1: Using the Build Scripts

1. Copy the entire project folder to your Windows machine
2. Navigate to the project directory
3. Choose one of the following build scripts:

#### Using Command Prompt (Batch Script)

1. Open a Command Prompt window
2. Run the batch script:
   ```
   build_windows.bat
   ```

#### Using PowerShell (PowerShell Script)

1. Open a PowerShell window
2. You may need to set the execution policy to run the script:
   ```
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```
3. Run the PowerShell script:
   ```
   .\build_windows.ps1
   ```

Both scripts will:
- Check for Flutter installation
- Enable Windows desktop support
- Get dependencies
- Build the application
- Display the location of the built executable when successful

### Option 2: Manual Build

If you prefer to build manually or if the script doesn't work for some reason, follow these steps:

1. Copy the entire project folder to your Windows machine
2. Open a Command Prompt or PowerShell window
3. Navigate to the project directory
4. Enable Windows desktop support:
   ```
   flutter config --enable-windows-desktop
   ```
5. Get dependencies:
   ```
   flutter pub get
   ```
6. Build the Windows application:
   ```
   flutter build windows --release
   ```
7. The built application will be located at:
   ```
   build\windows\runner\Release\edge_link_manager.exe
   ```

## Running the Application on a Windows Machine

To run the application on a Windows machine:

1. Copy the entire `Release` folder from `build\windows\runner\Release` to your target Windows machine
2. On the target machine, navigate to the copied `Release` folder
3. Double-click on `edge_link_manager.exe` to run the application

**Important**: The application requires all the DLL files and other resources in the `Release` folder to run properly. Make sure to copy the entire folder, not just the .exe file.

## Troubleshooting

### Missing Visual C++ Redistributable

If you encounter an error about missing DLLs when running the application, you may need to install the Visual C++ Redistributable package on the target machine:

1. Download the Visual C++ Redistributable from the [Microsoft website](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads)
2. Install the package on the target machine
3. Try running the application again

### Flutter Build Errors

If you encounter errors during the build process:

1. Make sure you have the latest Flutter SDK installed:
   ```
   flutter upgrade
   ```
2. Make sure Windows desktop support is enabled:
   ```
   flutter config --enable-windows-desktop
   ```
3. Clean the build and try again:
   ```
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

### Plugin Issues

If you encounter issues with plugins, make sure all plugins used in the project support Windows platform. You can check this in the `pubspec.yaml` file and the plugin documentation.

## Additional Resources

- [Flutter Windows Desktop Support](https://flutter.dev/desktop)
- [Flutter Windows Development Guide](https://flutter.dev/docs/development/platform-integration/windows/building)
- [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
