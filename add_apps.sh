#!/bin/bash
# Helper script to add APK files to GrapheneOS build
# Usage: ./add_apps.sh [build_directory] [app_type] [apk_path...]
# Example: ./add_apps.sh ~/grapheneos system /path/to/app.apk

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${1:-$SCRIPT_DIR/graphene_3a}"
APP_TYPE="${2:-data}"  # system, priv-app, or data
shift 2 2>/dev/null || shift 1 2>/dev/null || true

if [ $# -eq 0 ]; then
    echo "Usage: $0 [build_directory] [app_type] [apk_path...]"
    echo ""
    echo "Arguments:"
    echo "  build_directory  Path to GrapheneOS build directory (default: ./graphene_3a)"
    echo "  app_type         Type: 'system', 'priv-app', or 'data' (default: data)"
    echo "  apk_path         One or more paths to APK files"
    echo ""
    echo "Examples:"
    echo "  $0 ./graphene_3a system /path/to/app.apk"
    echo "  $0 ./graphene_3a priv-app app1.apk app2.apk"
    echo "  $0 ./graphene_3a data *.apk"
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    exit 1
fi

cd "$BUILD_DIR"

# Check if source is synced
if [ ! -d "device/google" ]; then
    echo "Error: Source code not synced. Run 'repo sync' first."
    exit 1
fi

# Determine device tree location
DEVICE_TREE="device/google/bonito"
if [ ! -d "$DEVICE_TREE" ]; then
    if [ -d "device/google/sargo" ]; then
        DEVICE_TREE="device/google/sargo"
    else
        echo "Error: Could not find device tree. Please sync source first."
        exit 1
    fi
fi

# Create prebuilt directory
PREBUILT_DIR="$DEVICE_TREE/prebuilt/apps"
mkdir -p "$PREBUILT_DIR"

# Find or create device makefile
MK_FILE=$(find "$DEVICE_TREE" -maxdepth 1 -name "*.mk" | head -1)
if [ -z "$MK_FILE" ]; then
    echo "Warning: Could not find device makefile. You'll need to add entries manually."
    MK_FILE="$DEVICE_TREE/bonito.mk"
fi

echo "Build directory: $BUILD_DIR"
echo "Device tree: $DEVICE_TREE"
echo "App type: $APP_TYPE"
echo "Makefile: $MK_FILE"
echo ""

# Process each APK
for APK_PATH in "$@"; do
    if [ ! -f "$APK_PATH" ]; then
        echo "Warning: APK not found: $APK_PATH (skipping)"
        continue
    fi

    APK_NAME=$(basename "$APK_PATH" .apk)
    APK_BASENAME=$(basename "$APK_PATH")
    
    # Copy APK to prebuilt directory
    echo "Copying $APK_BASENAME..."
    cp "$APK_PATH" "$PREBUILT_DIR/$APK_BASENAME"
    
    # Determine target path based on app type
    case "$APP_TYPE" in
        system)
            TARGET_PATH="\$(TARGET_COPY_OUT_SYSTEM)/app/$APK_NAME/$APK_BASENAME"
            ;;
        priv-app)
            TARGET_PATH="\$(TARGET_COPY_OUT_SYSTEM)/priv-app/$APK_NAME/$APK_BASENAME"
            ;;
        data)
            TARGET_PATH="\$(TARGET_COPY_OUT_DATA)/app/$APK_NAME/$APK_BASENAME"
            ;;
        *)
            echo "Error: Invalid app type: $APP_TYPE (must be: system, priv-app, or data)"
            exit 1
            ;;
    esac
    
    # Check if entry already exists
    if grep -q "$APK_BASENAME" "$MK_FILE" 2>/dev/null; then
        echo "  Entry already exists in makefile for $APK_BASENAME"
    else
        # Add entry to makefile
        echo "  Adding to makefile..."
        
        # Check if PRODUCT_COPY_FILES section exists
        if ! grep -q "PRODUCT_COPY_FILES.*prebuilt/apps" "$MK_FILE" 2>/dev/null; then
            # Add new section
            cat >> "$MK_FILE" << EOF

# Prebuilt apps (added by add_apps.sh)
PRODUCT_COPY_FILES += \\
    \$(LOCAL_PATH)/prebuilt/apps/$APK_BASENAME:$TARGET_PATH
EOF
        else
            # Append to existing section
            # Remove the last backslash and add new entry
            sed -i '/prebuilt\/apps.*\\$/s/\\$//' "$MK_FILE"
            sed -i "/prebuilt\/apps/a\\    \$(LOCAL_PATH)/prebuilt/apps/$APK_BASENAME:$TARGET_PATH \\\\" "$MK_FILE"
        fi
        echo "  Added: $APK_BASENAME -> $TARGET_PATH"
    fi
done

echo ""
echo "Apps added successfully!"
echo ""
echo "Next steps:"
echo "1. Review $MK_FILE to verify entries"
echo "2. Edit APK names/paths if needed"
echo "3. Build: source build/envsetup.sh && lunch bonito-user && m"
echo ""
echo "Note: System/priv-app apps require proper directory structure."
echo "You may need to create Android.mk files for complex apps."
echo "See ADDING_APPS.md for detailed instructions."

