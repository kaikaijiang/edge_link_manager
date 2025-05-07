# Edge Link Manager

A Flutter application for managing remote connections to edge devices with SSH and VNC capabilities.

## Features

- SSH connection management
- VNC remote desktop viewing
- Diagnostic tools
- Hardware management utilities

## Getting Started

This project is built with Flutter and supports multiple platforms including Android, iOS, Windows, macOS, and Linux.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Development environment for your target platform

### Building and Running

#### For Windows

To build a Windows executable:

1. See the [Windows Build Instructions](WINDOWS_BUILD_INSTRUCTIONS.md) for detailed steps
2. Use the provided `build_windows.bat` script for an automated build process

#### For Other Platforms

For other platforms, follow the standard Flutter build process:

```bash
# Enable the platform you want to build for
flutter config --enable-<platform>

# Get dependencies
flutter pub get

# Build the application
flutter build <platform>
```

Replace `<platform>` with one of: `android`, `ios`, `macos`, `linux`, or `web`.

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
