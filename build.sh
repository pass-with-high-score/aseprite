#! /usr/bin/env bash
#
# This is a script to help users and developers to build Aseprite.
# Usage:
#
#   ./build.sh
#   ./build.sh --reset
#   ./build.sh --auto [--norun]
#   ./build.sh --fix-cmake [version]
#   ./build.sh --create-dmg
#   ./build.sh --init-submodules
#   ./build.sh --create-scripts
#   ./build.sh --help
#
# If you run this script without parameters, you will be able to
# follows the instructions and a configuration will be stored in a
# ".build" directory.
#
# Options:
#
#   --reset           Deletes the configuration and you can start over
#   --auto            Tries to build the default user configuration (release mode)
#   --norun           Doesn't auto-run when using --auto
#   --fix-cmake       Updates CMake minimum versions in third-party libraries
#                     Optional: Specify version like --fix-cmake 3.10
#   --create-dmg      Creates a DMG installer for macOS builds
#   --help            Displays this help message
#   --init-submodules Initializes and updates all Git submodules
#

echo "======================= BUILD ASEPRITE HELPER ========================"

# Check that we are running the script from the Aseprite clone directory.
pwd=$(pwd)
if [[ ! -f "$pwd/EULA.txt" || ! -f "$pwd/.gitmodules" ]] ; then
    echo ""
    echo "Run build script from the Aseprite directory"
    exit 1
fi

# Display help information
if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
    echo ""
    echo "Aseprite Build Script Help"
    echo "=========================="
    echo ""
    echo "Usage: ./build.sh [OPTIONS]"
    echo ""
    echo "Available options:"
    echo ""
    echo "  --auto                    Build Aseprite automatically with default settings (release mode)"
    echo "  --norun                   When used with --auto, doesn't run Aseprite after building"
    echo "  --reset                   Delete all configuration and start over"
    echo "  --fix-cmake [version]     Update CMake minimum version requirements in third-party libraries"
    echo "                            Optional: Specify version (e.g., --fix-cmake 3.12)"
    echo "  --create-dmg              Create a DMG installer for macOS builds"
    echo "  --init-submodules         Initialize and update all Git submodules"
    echo "  --help, -h                Display this help message"
    echo ""
    echo "Examples:"
    echo ""
    echo "  ./build.sh                        # Interactive build with step-by-step guidance"
    echo "  ./build.sh --auto                 # Automatic build with default settings"
    echo "  ./build.sh --auto --norun         # Automatic build without running Aseprite afterward"
    echo "  ./build.sh --fix-cmake 3.12       # Update CMake version to 3.12 in third-party libraries"
    echo "  ./build.sh --create-dmg           # Create a DMG installer for macOS (after building)"
    echo ""
    echo "Recommended workflow for new clones:"
    echo ""
    echo "  1. ./build.sh --init-submodules   # Initialize all required submodules"
    echo "  2. ./build.sh --fix-cmake         # Fix CMake version requirements"
    echo "  3. ./build.sh --auto --norun      # Build Aseprite automatically"
    echo "  4. ./build.sh --create-dmg        # (macOS only) Create DMG installer"
    echo ""
    echo "Platform-specific features:"
    echo ""
    echo "  - macOS: Automatically fixes CMake versions and creates DMG installer"
    echo "  - Windows: Automatically detects Visual Studio tools"
    echo "  - Linux: Builds with standard compilation tools"
    echo ""
    exit 0
fi

# Initialize submodules
if [ "$1" == "--init-submodules" ] ; then
    echo ""
    echo "Initializing and updating Git submodules..."
    if ! git submodule update --init --recursive ; then
        echo "Error: Failed to update submodules."
        exit 1
    fi
    echo "Submodules initialized successfully."
    exit 0
fi

# Function to create a macOS DMG
create_dmg() {
    build_dir="$1"
    version="$2"
    
    if [[ -z "$version" ]]; then
        version="1.x-dev"
    fi
    
    echo ""
    echo "Creating DMG installer for macOS..."
    
    # Create app bundle directory structure
    app_dir="$build_dir/Aseprite.app"
    dmg_temp="$build_dir/dmg_temp"
    
    echo "Setting up app bundle at $app_dir..."
    mkdir -p "$app_dir/Contents/"{MacOS,Resources}
    
    # Create Info.plist
    cat > "$app_dir/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>aseprite</string>
    <key>CFBundleIconFile</key>
    <string>Aseprite.icns</string>
    <key>CFBundleIdentifier</key>
    <string>org.aseprite.Aseprite</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Aseprite</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${version}</string>
    <key>CFBundleShortVersionString</key>
    <string>${version}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
    
    # Create PkgInfo
    echo "APPL????" > "$app_dir/Contents/PkgInfo"
    
    # Copy executable and data files
    echo "Copying executable and data files..."
    cp "$build_dir/bin/aseprite" "$app_dir/Contents/MacOS/"
    chmod +x "$app_dir/Contents/MacOS/aseprite"
    cp -R "$build_dir/bin/data" "$app_dir/Contents/Resources/"
    
    # Create app icon from existing icons
    echo "Creating app icon..."
    mkdir -p "$app_dir/Contents/Resources/Aseprite.iconset"
    
    for icon in "$build_dir/bin/data/icons/ase"{16,32,64,128,256}".png"; do
        if [[ -f "$icon" ]]; then
            size=$(basename "$icon" | sed -e 's/ase\([0-9]*\)\.png/\1/')
            cp "$icon" "$app_dir/Contents/Resources/Aseprite.iconset/icon_${size}x${size}.png"
        fi
    done
    
    # Convert iconset to icns
    iconutil -c icns -o "$app_dir/Contents/Resources/Aseprite.icns" "$app_dir/Contents/Resources/Aseprite.iconset" || echo "Warning: iconutil failed, icon may not be created"
    
    # Create DMG
    echo "Creating DMG file..."
    mkdir -p "$dmg_temp"
    cp -R "$app_dir" "$dmg_temp/"
    
    # Create symlink to Applications folder
    ln -s /Applications "$dmg_temp/Applications"
    
    # Create the DMG file
    hdiutil create -volname "Aseprite $version" -srcfolder "$dmg_temp" -ov -format UDZO "$build_dir/Aseprite-$version.dmg"
    
    # Clean up temporary files
    rm -rf "$dmg_temp" "$app_dir/Contents/Resources/Aseprite.iconset"
    
    echo "DMG created at $build_dir/Aseprite-$version.dmg"
}

# Create DMG for macOS
if [ "$1" == "--create-dmg" ] ; then
    # Define is_macos flag
    if [[ "$(uname)" =~ "Darwin" ]] ; then
        is_macos=1
    else
        is_macos=0
    fi
    
    if [ $is_macos -ne 1 ] ; then
        echo ""
        echo "Error: --create-dmg option is only available on macOS"
        exit 1
    fi
    
    # Find build directory
    if [ -f "$pwd/.build/builds_dir" ] ; then
        builds_dir="$(cat $pwd/.build/builds_dir)"
        
        # Look for builds
        if [ -d "$builds_dir/build" ] ; then
            create_dmg "$builds_dir/build" "$2"
        elif [ -d "$builds_dir/aseprite-release" ] ; then
            create_dmg "$builds_dir/aseprite-release" "$2"
        else
            echo ""
            echo "Error: Cannot find build directory. Make sure you've built Aseprite first."
            exit 1
        fi
    else
        echo ""
        echo "Error: You need to build Aseprite first before creating a DMG."
        exit 1
    fi
    
    exit 0
fi

# Update CMake minimum versions in third-party libraries
if [ "$1" == "--fix-cmake" ] ; then
    # Check for user-specified version or use default
    cmake_version="3.10"
    if [ -n "$2" ]; then
        # Validate version number format (should be like 3.10 or 3.12.4)
        if [[ "$2" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            cmake_version="$2"
            echo "Using specified CMake version: $cmake_version"
        else
            echo "Error: Invalid CMake version format: $2"
            echo "Version should be in format like '3.10' or '3.12.4'"
            exit 1
        fi
    else
        # Try to detect system CMake version
        if command -v cmake >/dev/null 2>&1; then
            detected_version=$(cmake --version | head -n1 | sed 's/^cmake version //g' | cut -d' ' -f1 | cut -d'-' -f1)
            if [[ "$detected_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                # Extract major.minor version
                major_minor_version=$(echo "$detected_version" | cut -d'.' -f1-2)
                # Use detected version with a minimum of 3.10
                if [[ "$(echo "$major_minor_version >= 3.10" | bc -l)" -eq 1 ]]; then
                    cmake_version="$major_minor_version"
                    echo "Using detected CMake version: $cmake_version (from system CMake $detected_version)"
                else
                    echo "Detected CMake version $detected_version is too low, using minimum recommended version 3.10"
                fi
            fi
        else
            echo "CMake not found in PATH, using default version 3.10"
        fi
    fi
    
    echo ""
    echo "Checking for submodules..."
    
    # Check if third-party directories exist
    if [[ ! -d "$pwd/third_party/libpng" || ! -d "$pwd/third_party/TinyEXIF" || ! -d "$pwd/third_party/giflib" || ! -d "$pwd/third_party/cmark" || ! -d "$pwd/third_party/libarchive" ]]; then
        echo "Some submodules are missing. Updating submodules..."
        git submodule update --init --recursive
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to update submodules. Please run the following command manually:"
            echo "  git submodule update --init --recursive"
            exit 1
        fi
        echo "Submodules updated successfully."
    else
        echo "All submodules appear to be present."
    fi
    
    echo ""
    echo "Updating CMake minimum versions to $cmake_version in third-party libraries..."
    
    # Fix libpng CMakeLists.txt directly
    if [ -f "$pwd/third_party/libpng/CMakeLists.txt" ]; then
        echo "Updating third_party/libpng/CMakeLists.txt..."
        # Create a backup
        cp "$pwd/third_party/libpng/CMakeLists.txt" "$pwd/third_party/libpng/CMakeLists.txt.bak"
        
        # Use awk for more reliable file editing
        awk -v ver="$cmake_version" '{
            if ($0 ~ /cmake_minimum_required.*VERSION/) {
                print "cmake_minimum_required(VERSION " ver ")";
            } else if ($0 ~ /cmake_policy.*VERSION/) {
                print "cmake_policy(VERSION " ver ")";
            } else {
                print $0;
            }
        }' "$pwd/third_party/libpng/CMakeLists.txt.bak" > "$pwd/third_party/libpng/CMakeLists.txt"
    else
        echo "Warning: third_party/libpng/CMakeLists.txt not found, skipping."
    fi
    
    # Fix TinyEXIF CMakeLists.txt directly
    if [ -f "$pwd/third_party/TinyEXIF/CMakeLists.txt" ]; then
        echo "Updating third_party/TinyEXIF/CMakeLists.txt..."
        # Create a backup
        cp "$pwd/third_party/TinyEXIF/CMakeLists.txt" "$pwd/third_party/TinyEXIF/CMakeLists.txt.bak"
        
        # Use awk for more reliable file editing
        awk -v ver="$cmake_version" '{
            if ($0 ~ /cmake_minimum_required.*VERSION/) {
                print "cmake_minimum_required(VERSION " ver ")";
            } else if ($0 ~ /cmake_policy.*VERSION/) {
                print "cmake_policy(VERSION " ver ")";
            } else {
                print $0;
            }
        }' "$pwd/third_party/TinyEXIF/CMakeLists.txt.bak" > "$pwd/third_party/TinyEXIF/CMakeLists.txt"
    else
        echo "Warning: third_party/TinyEXIF/CMakeLists.txt not found, skipping."
    fi
    
    # Fix giflib CMakeLists.txt directly
    if [ -f "$pwd/third_party/giflib/CMakeLists.txt" ]; then
        echo "Updating third_party/giflib/CMakeLists.txt..."
        # Create a backup
        cp "$pwd/third_party/giflib/CMakeLists.txt" "$pwd/third_party/giflib/CMakeLists.txt.bak"
        
        # Use awk for more reliable file editing
        awk -v ver="$cmake_version" '{
            if ($0 ~ /cmake_minimum_required.*VERSION/) {
                print "cmake_minimum_required(VERSION " ver ")";
            } else if ($0 ~ /cmake_policy.*VERSION/) {
                print "cmake_policy(VERSION " ver ")";
            } else {
                print $0;
            }
        }' "$pwd/third_party/giflib/CMakeLists.txt.bak" > "$pwd/third_party/giflib/CMakeLists.txt"
    else
        echo "Warning: third_party/giflib/CMakeLists.txt not found, skipping."
    fi
    
    # Fix cmark CMakeLists.txt directly
    if [ -f "$pwd/third_party/cmark/CMakeLists.txt" ]; then
        echo "Updating third_party/cmark/CMakeLists.txt..."
        # Create a backup
        cp "$pwd/third_party/cmark/CMakeLists.txt" "$pwd/third_party/cmark/CMakeLists.txt.bak"
        
        # Use awk for more reliable file editing
        awk -v ver="$cmake_version" '{
            if ($0 ~ /cmake_minimum_required.*VERSION/) {
                print "cmake_minimum_required(VERSION " ver ")";
            } else if ($0 ~ /cmake_policy.*VERSION/) {
                print "cmake_policy(VERSION " ver ")";
            } else {
                print $0;
            }
        }' "$pwd/third_party/cmark/CMakeLists.txt.bak" > "$pwd/third_party/cmark/CMakeLists.txt"
    else
        echo "Warning: third_party/cmark/CMakeLists.txt not found, skipping."
    fi
    
    # Fix libarchive CMakeLists.txt directly
    if [ -f "$pwd/third_party/libarchive/CMakeLists.txt" ]; then
        echo "Updating third_party/libarchive/CMakeLists.txt..."
        # Create a backup
        cp "$pwd/third_party/libarchive/CMakeLists.txt" "$pwd/third_party/libarchive/CMakeLists.txt.bak"
        
        # Use awk for more reliable file editing
        awk -v ver="$cmake_version" '{
            if ($0 ~ /CMAKE_MINIMUM_REQUIRED.*VERSION/) {
                print "CMAKE_MINIMUM_REQUIRED(VERSION " ver " FATAL_ERROR)";
            } else if ($0 ~ /cmake_minimum_required.*VERSION/) {
                print "cmake_minimum_required(VERSION " ver ")";
            } else if ($0 ~ /cmake_policy.*VERSION/) {
                print "cmake_policy(VERSION " ver ")";
            } else {
                print $0;
            }
        }' "$pwd/third_party/libarchive/CMakeLists.txt.bak" > "$pwd/third_party/libarchive/CMakeLists.txt"
    else
        echo "Warning: third_party/libarchive/CMakeLists.txt not found, skipping."
    fi
    
    echo "CMake versions have been updated to $cmake_version. Now you can run ./build.sh to build Aseprite."
    
    # If on macOS, mark CMake as fixed to avoid redundant fixes
    if [[ "$(uname)" =~ "Darwin" ]] ; then
        mkdir -p "$pwd/.build"
        touch "$pwd/.build/cmake_fixed"
    fi
    
    exit 0
fi

# Use "./build.sh --reset" to reset all the configuration (deletes
# .build directory).
if [ "$1" == "--reset" ] ; then
    echo ""
    echo "Resetting $pwd/.build directory"
    if [ -f "$pwd/.build/builds_dir" ] ; then rm $pwd/.build/builds_dir ; fi
    if [ -f "$pwd/.build/log" ] ; then rm $pwd/.build/log ; fi
    if [ -f "$pwd/.build/main_skia_dir" ] ; then rm $pwd/.build/main_skia_dir ; fi
    if [ -f "$pwd/.build/beta_skia_dir" ] ; then rm $pwd/.build/beta_skia_dir ; fi
    if [ -f "$pwd/.build/userkind" ] ; then rm $pwd/.build/userkind ; fi
    if [ -d "$pwd/.build" ] ; then rmdir $pwd/.build ; fi
    echo "Done"
    exit 0
fi

# Use "./build.sh --auto" to build the user configuration without
# questions (downloading Skia/release mode).
auto=
if [ "$1" == "--auto" ] ; then
    shift
    auto=1
fi
norun=
if [ "$1" == "--norun" ] ; then
    shift
    norun=1
fi

# Platform.
if [[ "$(uname)" =~ "MINGW32" ]] || [[ "$(uname)" =~ "MINGW64" ]] || [[ "$(uname)" =~ "MSYS_NT-10.0" ]] ; then
    is_win=1
    cpu=x64

    if ! cl.exe >/dev/null 2>/dev/null ; then
        echo ""
        echo "MSVC compiler (cl.exe) not found in PATH"
        echo ""
        echo "  PATH=$PATH"
        echo ""
        exit 1
    fi
elif [[ "$(uname)" == "Linux" ]] ; then
    is_linux=1
    cpu=x64
elif [[ "$(uname)" =~ "Darwin" ]] ; then
    is_macos=1
    if [[ $(uname -m) == "arm64" ]]; then
        cpu=arm64
    else
        cpu=x64
    fi
    
    # For macOS, automatically fix the CMake versions to avoid build errors
    if [ ! -f "$pwd/.build/cmake_fixed" ]; then
        echo "macOS detected: Automatically fixing CMake minimum versions in third-party libraries..."
        
        # Determine CMake version to use (prefer system version if available)
        cmake_version="3.10"
        if command -v cmake >/dev/null 2>&1; then
            detected_version=$(cmake --version | head -n1 | sed 's/^cmake version //g' | cut -d' ' -f1 | cut -d'-' -f1)
            if [[ "$detected_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                # Extract major.minor version
                major_minor_version=$(echo "$detected_version" | cut -d'.' -f1-2)
                # Use detected version with a minimum of 3.10
                if [[ "$(echo "$major_minor_version >= 3.10" | bc -l)" -eq 1 ]]; then
                    cmake_version="$major_minor_version"
                    echo "Using detected CMake version: $cmake_version (from system CMake $detected_version)"
                else
                    echo "Detected CMake version $detected_version is too low, using minimum recommended version 3.10"
                fi
            fi
        else
            echo "CMake not found in PATH, using default version 3.10"
        fi
        
        echo "Updating CMake minimum versions to $cmake_version in third-party libraries..."
        
        # Fix libpng CMakeLists.txt directly
        if [ -f "$pwd/third_party/libpng/CMakeLists.txt" ]; then
            echo "Updating third_party/libpng/CMakeLists.txt..."
            # Create a backup
            cp "$pwd/third_party/libpng/CMakeLists.txt" "$pwd/third_party/libpng/CMakeLists.txt.bak"
            
            # Use awk for more reliable file editing
            awk -v ver="$cmake_version" '{
                if ($0 ~ /cmake_minimum_required.*VERSION/) {
                    print "cmake_minimum_required(VERSION " ver ")";
                } else if ($0 ~ /cmake_policy.*VERSION/) {
                    print "cmake_policy(VERSION " ver ")";
                } else {
                    print $0;
                }
            }' "$pwd/third_party/libpng/CMakeLists.txt.bak" > "$pwd/third_party/libpng/CMakeLists.txt"
        else
            echo "Warning: third_party/libpng/CMakeLists.txt not found, skipping."
        fi
        
        # Fix TinyEXIF CMakeLists.txt directly
        if [ -f "$pwd/third_party/TinyEXIF/CMakeLists.txt" ]; then
            echo "Updating third_party/TinyEXIF/CMakeLists.txt..."
            # Create a backup
            cp "$pwd/third_party/TinyEXIF/CMakeLists.txt" "$pwd/third_party/TinyEXIF/CMakeLists.txt.bak"
            
            # Use awk for more reliable file editing
            awk -v ver="$cmake_version" '{
                if ($0 ~ /cmake_minimum_required.*VERSION/) {
                    print "cmake_minimum_required(VERSION " ver ")";
                } else if ($0 ~ /cmake_policy.*VERSION/) {
                    print "cmake_policy(VERSION " ver ")";
                } else {
                    print $0;
                }
            }' "$pwd/third_party/TinyEXIF/CMakeLists.txt.bak" > "$pwd/third_party/TinyEXIF/CMakeLists.txt"
        else
            echo "Warning: third_party/TinyEXIF/CMakeLists.txt not found, skipping."
        fi
        
        # Fix giflib CMakeLists.txt directly
        if [ -f "$pwd/third_party/giflib/CMakeLists.txt" ]; then
            echo "Updating third_party/giflib/CMakeLists.txt..."
            # Create a backup
            cp "$pwd/third_party/giflib/CMakeLists.txt" "$pwd/third_party/giflib/CMakeLists.txt.bak"
            
            # Use awk for more reliable file editing
            awk -v ver="$cmake_version" '{
                if ($0 ~ /cmake_minimum_required.*VERSION/) {
                    print "cmake_minimum_required(VERSION " ver ")";
                } else if ($0 ~ /cmake_policy.*VERSION/) {
                    print "cmake_policy(VERSION " ver ")";
                } else {
                    print $0;
                }
            }' "$pwd/third_party/giflib/CMakeLists.txt.bak" > "$pwd/third_party/giflib/CMakeLists.txt"
        else
            echo "Warning: third_party/giflib/CMakeLists.txt not found, skipping."
        fi
        
        # Fix cmark CMakeLists.txt directly
        if [ -f "$pwd/third_party/cmark/CMakeLists.txt" ]; then
            echo "Updating third_party/cmark/CMakeLists.txt..."
            # Create a backup
            cp "$pwd/third_party/cmark/CMakeLists.txt" "$pwd/third_party/cmark/CMakeLists.txt.bak"
            
            # Use awk for more reliable file editing
            awk -v ver="$cmake_version" '{
                if ($0 ~ /cmake_minimum_required.*VERSION/) {
                    print "cmake_minimum_required(VERSION " ver ")";
                } else if ($0 ~ /cmake_policy.*VERSION/) {
                    print "cmake_policy(VERSION " ver ")";
                } else {
                    print $0;
                }
            }' "$pwd/third_party/cmark/CMakeLists.txt.bak" > "$pwd/third_party/cmark/CMakeLists.txt"
        else
            echo "Warning: third_party/cmark/CMakeLists.txt not found, skipping."
        fi
        
        # Fix libarchive CMakeLists.txt directly
        if [ -f "$pwd/third_party/libarchive/CMakeLists.txt" ]; then
            echo "Updating third_party/libarchive/CMakeLists.txt..."
            # Create a backup
            cp "$pwd/third_party/libarchive/CMakeLists.txt" "$pwd/third_party/libarchive/CMakeLists.txt.bak"
            
            # Use awk for more reliable file editing
            awk -v ver="$cmake_version" '{
                if ($0 ~ /CMAKE_MINIMUM_REQUIRED.*VERSION/) {
                    print "CMAKE_MINIMUM_REQUIRED(VERSION " ver " FATAL_ERROR)";
                } else if ($0 ~ /cmake_minimum_required.*VERSION/) {
                    print "cmake_minimum_required(VERSION " ver ")";
                } else if ($0 ~ /cmake_policy.*VERSION/) {
                    print "cmake_policy(VERSION " ver ")";
                } else {
                    print $0;
                }
            }' "$pwd/third_party/libarchive/CMakeLists.txt.bak" > "$pwd/third_party/libarchive/CMakeLists.txt"
        else
            echo "Warning: third_party/libarchive/CMakeLists.txt not found, skipping."
        fi
        
        mkdir -p "$pwd/.build"
        touch "$pwd/.build/cmake_fixed"
        echo "Done updating CMake versions to $cmake_version."
    fi
fi

# Check utilities.
if ! cmake --version >/dev/null ; then
    echo ""
    echo "cmake utility is not available. You can get cmake from:"
    echo ""
    echo "  https://cmake.org/download/"
    echo ""
    exit 1
fi
if ! ninja --version >/dev/null ; then
    echo ""
    echo "ninja utility is not available. You can get ninja from:"
    echo ""
    echo "  https://github.com/ninja-build/ninja/releases"
    echo ""
    exit 1
fi

# Check that all submodules are checked out.
run_submodule_update=
for module in $(cat "$pwd/.gitmodules" | \
                    grep '^\[submodule' | \
                    sed -e 's/^\[.*\"\(.*\)\"\]/\1/') \
              $(cat "$pwd/laf/.gitmodules" | \
                    grep '^\[submodule' | \
                    sed -e 's/^\[.*\"\(.*\)\"\]/laf\/\1/') ; do
    if [[ ! -f "$module/CMakeLists.txt" &&
          ! -f "$module/Makefile" &&
          ! -f "$module/makefile" &&
          ! -f "$module/Makefile.am" ]] ; then
        echo ""
        echo "Module $module doesn't exist."
        if [ $auto ] ; then
            run_submodule_update=1
            break
        else
            echo "Run:"
            echo ""
            echo "  git submodule update --init --recursive"
            echo ""
            exit 1
        fi
    fi
done
if [ $run_submodule_update ] ; then
    echo "Running:"
    echo ""
    echo "  git submodule update --init --recursive"
    echo ""
    if ! git submodule update --init --recursive ; then
        echo "Failed, try again"
        exit 1
    fi
    echo "Done"
fi

# Create the directory to store the configuration.
if [ ! -d "$pwd/.build" ] ; then
    mkdir "$pwd/.build"
fi

# Kind of user (User or Developer).
# For users we simplify the process (no multiple builds), for
# developers we have more options (debug mode, etc.).
if [ ! -f "$pwd/.build/userkind" ] ; then
    if [ $auto ] ; then
        echo "user" > $pwd/.build/userkind
    else
        echo ""
        echo "Select what kind of user you are (press U or D keys):"
        echo ""
        echo "  [U]ser: give a try to Aseprite"
        echo "  [D]eveloper: develop/modify Aseprite"
        echo ""
        read -sN 1 -p "[U/D]? "
        echo ""
        if [[ "$REPLY" == "d" || "$REPLY" == "D" ]] ; then
            echo "developer" > $pwd/.build/userkind
        elif [[ "$REPLY" == "u" || "$REPLY" == "U" ]] ; then
            echo "user" > $pwd/.build/userkind
        else
            echo "Use U or D keys to select kind of user/build process"
            exit 1
        fi
    fi
fi

userkind=$(echo -n $(cat $pwd/.build/userkind))
if [ "$userkind" == "developer" ] ; then
    echo "======================= BUILDING FOR DEVELOPER ======================="
else
    echo "========================= BUILDING FOR USER =========================="
fi

# Get the builds_dir location.
if [ ! -f "$pwd/.build/builds_dir" ] ; then
    if [ "$userkind" == "developer" ] ; then
        # The "builds" folder is a place where all possible combination/builds
        # will be stored. If the ASEPRITE_BUILD environment variable is
        # defined, that's the directory, in other case for a regular "user"
        # the folder will be this same directory where Aseprite was cloned.
        if [[ "$ASEPRITE_BUILD" != "" ]] ; then
            if [ $is_win ] ; then
                builds_dir=$(cygpath "$ASEPRITE_BUILD")
            else
                builds_dir="$ASEPRITE_BUILD"
            fi

            if [ -d "$builds_dir" ] ; then
                echo ""
                echo "Using ASEPRITE_BUILD environment variable for builds directory."
            else
                if ! mkdir "$builds_dir" ; then
                    echo ""
                    echo "The ASEPRITE_BUILD is defined but we weren't able to create the directory:"
                    echo ""
                    echo "  ASEPRITE_BUILD=$builds_dir"
                    echo ""
                    echo "To solve this issue delete the ASEPRITE_BUILD variable or point it to a valid path."
                    exit 1
                fi
            fi
        else
            # Default location for developers
            builds_dir=$HOME/builds

            echo ""
            echo "Select a folder where to leave all builds:"
            echo "  builds_dir/"
            echo "    release-x64/..."
            echo "    debug-x64/..."
            echo ""
            echo "builds_dir [$builds_dir]? "
            read builds_dir_read
            if [ "$builds_dir_read" != "" ] ; then
                builds_dir="$builds_dir_read"
            fi
        fi
    else
        # Default location for users
        builds_dir="$pwd"

        echo ""
        echo "We'll build Aseprite in $builds_dir/build directory"
    fi
    echo "$builds_dir" > "$pwd/.build/builds_dir"
fi
# Overwrite $builds_dir variable from the config content.
builds_dir="$(echo -n $(cat $pwd/.build/builds_dir))"

# List all builds.
builds_list="$(mktemp)"
n=1
for file in $(ls $builds_dir/*/CMakeCache.txt 2>/dev/null | sort) ; do
    if cat "$file" | grep -q "CMAKE_PROJECT_NAME:STATIC=aseprite" ; then
        if [ $n -eq 1 ] ; then
            echo "-- AVAILABLE BUILDS --"
        fi
        echo "$file" >> $builds_list
        echo "$n. $file"
        n=$(($n+1))
    fi
done

# New build configuration.
build_type=RelWithDebInfo

# No builds, so this is the first build.
if [[ $n -eq 1 ]] ; then
    echo "-- FIRST BUILD --"
    if [ "$userkind" == "developer" ] ; then
        active_build_dir="$builds_dir/aseprite-release"
    else
        active_build_dir="$builds_dir/build"
    fi
    echo "First build directory: $active_build_dir"
    
    # If in auto mode, create directory if it doesn't exist
    if [ $auto ] ; then
        if [ ! -d "$active_build_dir" ] ; then
            mkdir -p "$active_build_dir"
        fi
    fi
else
    if [ ! $auto ] ; then
        echo "N. New build (N key)"
        echo "U. Update Visual Studio/Windows Kit/macOS SDK version (U key)"
        read -p "Select an option or number to build? " build_n
    else
        # In auto mode, always choose option 1 if there's a build
        build_n=1
    fi

    # New build
    if [[ "$build_n" == "n" || "$build_n" == "N" ]] ; then
        if [ ! $auto ] ; then
            read -p "Select build type [RELEASE/debug]? "
            # Convert REPLY to lowercase using a portable method
            REPLY_LC=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$REPLY_LC" == "debug" ]] ; then
                build_type=Debug
                new_build_name=aseprite-debug
            else
                build_type=RelWithDebInfo
                new_build_name=aseprite-release
            fi

            read -p "Select a name [$new_build_name]? "
            if [[ "$REPLY" != "" ]] ; then
                new_build_name=$REPLY
            fi
        else
            # For auto mode, use default release settings
            build_type=RelWithDebInfo
            new_build_name=aseprite-release
        fi
        active_build_dir="$builds_dir/$new_build_name"
        
        # In auto mode, create directory if it doesn't exist
        if [ $auto ] && [ ! -d "$active_build_dir" ] ; then
            mkdir -p "$active_build_dir"
        fi
    
    # Update SDK
    elif [[ "$build_n" == "u" || "$build_n" == "U" ]] ; then
        echo "Update SDK dirs..."
        if [ $is_win ] ; then
            newclver=$(echo $VCToolsInstallDir | sed -e 's_^.*\\\([0-9\.]*\)\\$_\1_')

            function update_file {
                file=$1
                echo "--- Updating $file ---" | tee -a "$pwd/.build/log"
                mv "$file" "$file-old"
                cat "$file-old" | sed -e 's_^\(.*/VC/Tools/MSVC/\)\([0-9\.]*\)\(.*$\)_\1'$newclver'\3_' > "$file"
                diff -w -u3 "$file-old" "$file" >> "$pwd/.build/log"
                echo "--- End $file ---" >> "$pwd/.build/log"
            }

            echo "New VC version: $newclver"
            for file in $(cat $builds_list) ; do
                build_dir=$(dirname $file)
                echo "--- Updating $build_dir ---"
                update_file "$file"
                for other_file in "$build_dir/CMakeFiles/rules.ninja" \
                                  "$build_dir"/CMakeFiles/*/*.cmake \
                                  "$build_dir/third_party/libpng/scripts/genout.cmake" ; do
                    update_file "$other_file"
                done
            done
        fi
        echo "Done"
        exit

    else # Build the selected dir
        n=1
        for file in $(cat $builds_list) ; do
            if [ "$n" == "$build_n" ] ; then
                active_build_dir=$(dirname $file)
                build_type=$(cat $active_build_dir/CMakeCache.txt | grep CMAKE_BUILD_TYPE | cut -d "=" -f2)
                break
            fi
            n=$(($n+1))
        done
    fi
fi

if [ "$active_build_dir" == "" ] ; then
    echo "No build selected"
    exit 1
fi

if [ -f "$active_build_dir/CMakeCache.txt" ] ; then
    source_dir=$(cat $active_build_dir/CMakeCache.txt | grep aseprite_SOURCE_DIR | cut -d "=" -f2)
else
    source_dir="$pwd"
fi
branch_name=$(git --git-dir="$source_dir/.git" rev-parse --abbrev-ref HEAD)

if [[ "$branch_name" == "main" || "$branch_name" == "beta" ]] ; then
    base_branch_name="$branch_name"
else
    # Get the origin (or first remote) name
    remote=$(git --git-dir="$source_dir/.git" remote | grep origin)
    if [ "$remote" == "" ] ; then
        remote=$(git --git-dir="$source_dir/.git" remote | head -n1)
    fi

    if git --git-dir="$source_dir/.git" branch --contains "$remote/beta" | grep -q "^\* $branch_name\$" ; then
        base_branch_name=beta
    elif git --git-dir="$source_dir/.git" branch --contains "$remote/main" | grep -q "^\* $branch_name\$" ; then
        base_branch_name=main
    else
        echo ""
        echo "Error: Branch $branch_name looks like doesn't belong to main or beta"
        echo ""
        exit 1
    fi
fi

echo "=========================== CONFIGURATION ============================"
echo "Build type: $build_type"
echo "Build dir: \"$active_build_dir\""
echo "Source dir: \"$source_dir\""
if [ "$branch_name" != "$base_branch_name" ] ; then
    echo "Branch name: $base_branch_name > $branch_name"
else
    echo "Branch name: $base_branch_name"
fi

# Required Skia for the base branch.
if [ "$base_branch_name" == "beta" ] ; then
    skia_tag=m124-08a5439a6b
    file_skia_dir=beta_skia_dir
    possible_skia_dir_name=skia-m124
else
    skia_tag=m102-861e4743af
    file_skia_dir=main_skia_dir
    possible_skia_dir_name=skia
fi

# Check Skia dependency.
if [ ! -f "$pwd/.build/$file_skia_dir" ] ; then
    # Try "C:/deps/skia" or "$HOME/deps/skia"
    if [[ $is_win ]] ; then
        skia_dir="C:/deps/$possible_skia_dir_name"
    else
        skia_dir="$HOME/deps/$possible_skia_dir_name"
    fi

    if [ ! -d "$skia_dir" ] ; then
        echo ""
        echo "Skia directory wasn't found."
        echo ""

        echo "Select Skia directory to create [$skia_dir]? "
        if [ ! $auto ] ; then
            read skia_dir_read
            if [ "$skia_dir_read" != "" ] ; then
                skia_dir="$skia_dir_read"
            fi
        fi
        mkdir -p $skia_dir || exit 1
    fi
    echo $skia_dir > "$pwd/.build/$file_skia_dir"
fi
skia_dir=$(echo -n $(cat $pwd/.build/$file_skia_dir))
if [ ! -d "$skia_dir" ] ; then
    mkdir "$skia_dir"
fi

# Only on Windows we need the Debug version of Skia to compile the
# Debug version of Aseprite.
if [[ $is_win && "$build_type" == "Debug" ]] ; then
    skia_library_dir="$skia_dir/out/Debug-x64"
else
    skia_library_dir="$skia_dir/out/Release-$cpu"
fi

# If the library directory is not available, we can try to download
# the pre-built package.
if [ ! -d "$skia_library_dir" ] ; then
    echo ""
    echo "Skia library wasn't found."
    echo ""
    if [ ! $auto ] ; then
        read -sN 1 -p "Download pre-compiled Skia automatically [Y/n]? "
    fi
    if [[ $auto || "$REPLY" == "" || "$REPLY" == "y" || "$REPLY" == "Y" ]] ; then
        if [[ $is_win && "$build_type" == "Debug" ]] ; then
            skia_build=Debug
        else
            skia_build=Release
        fi

        if [ $is_win ] ; then
            skia_file=Skia-Windows-$skia_build-$cpu.zip
        elif [ $is_macos ] ; then
            skia_file=Skia-macOS-$skia_build-$cpu.zip
        else
            skia_file=Skia-Linux-$skia_build-$cpu-libstdc++.zip
        fi
        skia_url=https://github.com/aseprite/skia/releases/download/$skia_tag/$skia_file
        echo "Downloading Skia from $skia_url"
        if [ ! -f "$skia_dir/$skia_file" ] ; then
            curl -L -o "$skia_dir/$skia_file" "$skia_url"
        fi
        if [ ! -d "$skia_library_dir" ] ; then
            unzip -n -d "$skia_dir" "$skia_dir/$skia_file"
        fi
    else
        echo "Please follow these instructions to compile Skia manually:"
        echo ""
        echo "  https://github.com/aseprite/skia?tab=readme-ov-file#skia-for-aseprite-and-laf"
        echo ""
        exit 1
    fi
fi
echo "================================ SKIA ================================"
echo "Skia directory: \"$skia_dir\""
echo "Skia library directory: \"$skia_library_dir\""
if [ ! -d "$skia_library_dir" ] ; then
    echo "  But the Skia library directory wasn't found."
    exit 1
fi

# Building
echo "=============================== CMAKE ================================"
if [ ! -f "$active_build_dir/ninja.build" ] ; then
    echo ""
    echo "We are going to run cmake and then build the project."
    echo "This will take some minutes."
    echo ""
    if [ ! $auto ] ; then
        read -sN 1 -p "Press any key to continue. "
    fi

    if [ $is_macos ] ; then
        osx_deployment_target="-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"
    else
        osx_deployment_target=
    fi

    echo "Configuring Aseprite..."
    if ! cmake -B "$active_build_dir" -S "$source_dir" -G Ninja \
         -DCMAKE_BUILD_TYPE=$build_type \
         $osx_deployment_target \
         -DLAF_BACKEND=skia \
         -DSKIA_DIR="$skia_dir" \
         -DSKIA_LIBRARY_DIR="$skia_library_dir" | \
            tee -a "$pwd/.build/log" ; then
        echo "Error running cmake."
        exit 1
    fi
fi
echo "============================== BUILDING =============================="
if ! cmake --build "$active_build_dir" -- aseprite | tee -a "$pwd/.build/log" ; then
    echo "Error building Aseprite."
    exit 1
fi

echo "================================ DONE ================================"
if [ $is_win ] ; then exe=.exe ; else exe= ; fi
echo "Run Aseprite with the following command:"
echo ""
echo "  $active_build_dir/bin/aseprite$exe"
echo ""

# On macOS, automatically create DMG
if [[ $is_macos && -f "$active_build_dir/bin/aseprite" && ! -f "$active_build_dir/Aseprite-1.x-dev.dmg" ]]; then
    echo "macOS build detected: Creating DMG installer..."
    create_dmg "$active_build_dir" "1.x-dev"
    echo ""
    echo "You can distribute Aseprite using the DMG file at:"
    echo "  $active_build_dir/Aseprite-1.x-dev.dmg"
    echo ""
fi

# Run Aseprite in --auto mode
if [[ $auto && ! $norun ]] ; then
    $active_build_dir/bin/aseprite$exe
fi

# Function to create run scripts for different platforms
create_run_scripts() {
    build_dir="$1"
    
    echo ""
    echo "Creating platform-specific run scripts..."
    
    # Create Windows batch file (run_aseprite.bat)
    echo "Creating Windows batch file..."
    cat > "$build_dir/run_aseprite.bat" << EOF
@echo off
rem Run Aseprite from the build directory
echo Running Aseprite...
cd "%~dp0"
bin\\aseprite.exe %*
EOF
    chmod +x "$build_dir/run_aseprite.bat"
    
    # Create Linux shell script (run_aseprite.sh)
    echo "Creating Linux shell script..."
    cat > "$build_dir/run_aseprite.sh" << EOF
#!/bin/bash
# Run Aseprite from the build directory
echo "Running Aseprite..."
cd "\$(dirname "\$0")"
./bin/aseprite "\$@"
EOF
    chmod +x "$build_dir/run_aseprite.sh"
    
    # Create macOS shell script (run_aseprite_mac.sh)
    echo "Creating macOS shell script..."
    cat > "$build_dir/run_aseprite_mac.sh" << EOF
#!/bin/bash
# Run Aseprite from the build directory on macOS
echo "Running Aseprite..."
cd "\$(dirname "\$0")"
./bin/aseprite "\$@"
EOF
    chmod +x "$build_dir/run_aseprite_mac.sh"
    
    echo "Run scripts created in $build_dir"
    echo " - Windows: run_aseprite.bat"
    echo " - Linux:   run_aseprite.sh"
    echo " - macOS:   run_aseprite_mac.sh"
}

# Create run scripts manually
if [ "$1" == "--create-scripts" ] ; then
    # Find build directory
    if [ -f "$pwd/.build/builds_dir" ] ; then
        builds_dir="$(cat $pwd/.build/builds_dir)"
        
        # Look for builds
        if [ -d "$builds_dir/build" ] ; then
            create_run_scripts "$builds_dir/build"
        elif [ -d "$builds_dir/aseprite-release" ] ; then
            create_run_scripts "$builds_dir/aseprite-release"
        else
            echo ""
            echo "Error: Cannot find build directory. Make sure you've built Aseprite first."
            exit 1
        fi
    else
        echo ""
        echo "Error: You need to build Aseprite first before creating run scripts."
        exit 1
    fi
    
    exit 0
fi
