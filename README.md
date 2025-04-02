# Aseprite macOS Build

This repository contains a compiled version of Aseprite for macOS.

## Contents

- `Aseprite.app` - The macOS application bundle
- `Aseprite.dmg` - Disk image for easy installation

## Installation

1. Download the DMG file from the releases section
2. Mount the DMG file by double-clicking it
3. Drag the Aseprite application to your Applications folder
4. Eject the disk image
5. Launch Aseprite from your Applications folder

## Build Information

This build was created from the Aseprite repository with minor modifications to make it compatible with modern CMake.

### Changes Made to Original Source

The following CMake minimum version requirements were updated to work with modern macOS:

- `third_party/libpng/CMakeLists.txt`: Changed version from 3.5 to 3.10
- `third_party/TinyEXIF/CMakeLists.txt`: Changed version from 3.1 to 3.10
- `third_party/giflib/CMakeLists.txt`: Changed version from 3.5 to 3.10
- `third_party/cmark/CMakeLists.txt`: Changed version from 3.7 to 3.10
- `third_party/libarchive/CMakeLists.txt`: Changed version from 2.8.12 to 3.10

### Build Process

1. Clone the original Aseprite repository:
   ```
   git clone --recursive https://github.com/aseprite/aseprite.git
   ```

2. Update the CMake version requirements in the third-party libraries

3. Build using the provided script:
   ```
   ./build.sh
   ```

4. Create the macOS application bundle and DMG file

## License

Aseprite is distributed under the terms of the EULA included in the original repository and application. 