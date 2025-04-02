# Aseprite macOS Build v1.0.0

This is the first release of the macOS build of Aseprite.

## What's included

- Complete Aseprite application for macOS
- DMG installer with drag-and-drop installation
- Support for macOS (tested on macOS Ventura/Sonoma)

## Installation

1. Download the Aseprite.dmg file attached to this release
2. Mount the DMG file by double-clicking it
3. Drag the Aseprite application to your Applications folder
4. Eject the disk image
5. Launch Aseprite from your Applications folder

## Build Information

This build was created from the official Aseprite repository with minor modifications to make it compatible with modern macOS.

### Changes Made to Original Source

The following CMake minimum version requirements were updated:
- `third_party/libpng/CMakeLists.txt`: 3.5 → 3.10
- `third_party/TinyEXIF/CMakeLists.txt`: 3.1 → 3.10
- `third_party/giflib/CMakeLists.txt`: 3.5 → 3.10
- `third_party/cmark/CMakeLists.txt`: 3.7 → 3.10
- `third_party/libarchive/CMakeLists.txt`: 2.8.12 → 3.10

## Known Issues

- None reported yet. If you encounter any issues, please report them in the Issues section.

## License

Aseprite is distributed under the terms of the EULA included in the original repository and application. 