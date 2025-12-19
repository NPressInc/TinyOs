#!/bin/bash
# Build script for GrapheneOS with custom boot animation
# Uses parallel builds for 12-core/24-thread CPU

set -e

BUILD_DIR="/home/william/Documents/projects/foxPhone/graphene_3a"
DEVICE="sargo"  # Pixel 3a (non-XL) - use "bonito" for Pixel 3a XL

cd "$BUILD_DIR"

echo "=========================================="
echo "GrapheneOS Build Script"
echo "=========================================="
echo "Build directory: $BUILD_DIR"
echo "Device: $DEVICE"
echo "CPU: 12-core/24-thread (using 20 parallel jobs)"
echo ""

# Step 1: Setup build environment
echo "[1/3] Setting up build environment..."
source build/envsetup.sh

# Step 2: Select device target
echo "[2/3] Selecting device target ($DEVICE-user)..."
lunch ${DEVICE}-user

# Step 3: Build with parallel compilation
echo "[3/3] Starting build (this will take 3-6+ hours)..."
echo ""
echo "Build started at: $(date)"
echo "Using parallel compilation (20 jobs - leaving cores free for system)"
echo ""
echo "You can monitor progress or leave this running."
echo "Press Ctrl+C to cancel (build will resume from where it stopped if you restart)"
echo ""

# Use m with explicit parallel jobs (20 threads - leaving 4 cores free for system use)
# mka might not be available in script context, so using m -j20 explicitly
m -j20

echo ""
echo "=========================================="
echo "Build completed at: $(date)"
echo "=========================================="
echo ""
echo "Output images are in: $BUILD_DIR/out/target/product/$DEVICE/"
echo ""
echo "To flash to device:"
echo "  cd $BUILD_DIR/out/target/product/$DEVICE"
echo "  fastboot flash boot boot.img"
echo "  fastboot flash system system.img"
echo "  fastboot flash vendor vendor.img"
echo "  fastboot flash vbmeta vbmeta.img"
echo "  fastboot reboot"
echo ""

