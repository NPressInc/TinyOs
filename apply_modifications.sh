#!/bin/bash
# Helper script to apply network restriction modifications to GrapheneOS source
# Run this from your GrapheneOS build directory after repo sync completes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${1:-$SCRIPT_DIR/graphene_3a}"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    echo "Usage: $0 [build_directory]"
    echo "Example: $0 ./graphene_3a"
    exit 1
fi

cd "$BUILD_DIR"

echo "Applying network restriction modifications..."
echo "Build directory: $BUILD_DIR"

# Check if source is synced
if [ ! -d "device/google" ]; then
    echo "Error: Source code not synced. Run 'repo sync' first."
    exit 1
fi

# Determine device tree location (bonito for Pixel 3a XL, shares code with sargo)
DEVICE_TREE="device/google/bonito"
if [ ! -d "$DEVICE_TREE" ]; then
    echo "Warning: $DEVICE_TREE not found. Searching for device tree..."
    # Try alternative locations
    if [ -d "device/google/sargo" ]; then
        DEVICE_TREE="device/google/sargo"
        echo "Using: $DEVICE_TREE"
    else
        echo "Error: Could not find device tree. Please specify manually."
        exit 1
    fi
fi

# Copy restriction script
echo "Copying restrict_network.sh to device tree..."
mkdir -p "$DEVICE_TREE"
cp "$SCRIPT_DIR/restrict_network.sh" "$DEVICE_TREE/restrict_network.sh"
chmod +x "$DEVICE_TREE/restrict_network.sh"

# Try to find and update init file
INIT_FILE=$(find "$DEVICE_TREE" -name "init.*.rc" -o -name "*.rc" | head -1)
if [ -n "$INIT_FILE" ]; then
    echo "Found init file: $INIT_FILE"
    if ! grep -q "restrict_network.sh" "$INIT_FILE"; then
        echo "Adding network restriction to init file..."
        cat >> "$INIT_FILE" << 'EOF'

# Network restriction (added by apply_modifications.sh)
on post-fs-data
    exec u:r:kernel:s0 /vendor/bin/restrict_network.sh
EOF
        echo "Added init trigger to $INIT_FILE"
    else
        echo "Init file already contains network restriction trigger"
    fi
else
    echo "Warning: Could not find init.rc file. You'll need to add it manually."
    echo "Look for init files in: $DEVICE_TREE"
fi

# Try to find and update device makefile
MK_FILE=$(find "$DEVICE_TREE" -name "*.mk" | head -1)
if [ -n "$MK_FILE" ]; then
    echo "Found makefile: $MK_FILE"
    if ! grep -q "restrict_network.sh" "$MK_FILE"; then
        echo "Adding PRODUCT_COPY_FILES entry..."
        # Add before the last line or at the end
        cat >> "$MK_FILE" << 'EOF'

# Network restriction script
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/restrict_network.sh:$(TARGET_COPY_OUT_VENDOR)/bin/restrict_network.sh
EOF
        echo "Added to $MK_FILE"
    else
        echo "Makefile already contains network restriction entry"
    fi
else
    echo "Warning: Could not find device makefile. You'll need to add PRODUCT_COPY_FILES manually."
fi

echo ""
echo "Modifications applied!"
echo ""
echo "Next steps:"
echo "1. Edit $DEVICE_TREE/restrict_network.sh to set your allowed IPs/domains"
echo "2. Review $INIT_FILE to ensure the init trigger is correct"
echo "3. Review $MK_FILE to ensure PRODUCT_COPY_FILES is correct"
echo "4. Proceed with build: source build/envsetup.sh && lunch bonito-user && m"
echo ""
echo "See MODIFICATIONS.md for detailed instructions and troubleshooting."

