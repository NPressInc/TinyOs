# Building and Installing GrapheneOS from Source

Complete guide for building GrapheneOS from source for legacy devices with custom network restrictions and pre-installed apps.

## Overview

This guide covers:
- Setting up the build environment
- Syncing GrapheneOS source code (with fixes for legacy repos)
- Integrating proprietary vendor blobs
- Adding network restrictions and custom boot animations
- Building the ROM
- Flashing to device

## Prerequisites

### System Requirements

- **OS**: Linux (Ubuntu 22.04/24.04 recommended)
- **Disk Space**: 500GB+ free space
- **RAM**: 32GB+ recommended (64GB ideal)
- **CPU**: Multi-core processor (8+ cores recommended)
- **Time**: Initial sync ~1-2 hours, build ~1-4 hours

### Install Build Tools

```bash
sudo apt update && sudo apt install -y \
    bc curl default-jdk-headless default-jre-headless git git-lfs \
    libncurses-dev libssl-dev lz4 m4 python3-lxml \
    python3-protobuf python3-yaml python-is-python3 rsync zip \
    protobuf-compiler adb fastboot inkscape imagemagick libarchive-tools
```

### Install Repo Tool

```bash
mkdir -p ~/bin
export PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod +x ~/bin/repo
```

## Phase 1: Download Source Code

### Step 1: Initialize Manifest Repository

The manifest folder (`graphene_3a`) must be a git repository for `repo` to work.

```bash
cd /home/william/Documents/projects/foxPhone/graphene_3a
git init
git add default.xml GLOBAL-PREUPLOAD.cfg
git commit -m "Initial manifest"
```

### Step 2: Fix Legacy Repositories (CRITICAL)

GrapheneOS has removed some legacy repositories (Vanadium, EmergencyInfo) from their servers. You must remove them from `default.xml` before syncing:

1. Open `graphene_3a/default.xml`.
2. Delete the lines for `platform_external_vanadium` and `platform_packages_apps_EmergencyInfo`.
3. Commit the change:
   ```bash
   git add default.xml
   git commit -m "Remove missing legacy repositories"
   ```

### Step 3: Initialize and Sync

Create a separate build directory for the actual source code.

```bash
cd /home/william/Documents/projects/foxPhone
mkdir -p graphene_build
cd graphene_build

# Initialize repo using your local manifest
repo init -u file:///home/william/Documents/projects/foxPhone/graphene_3a -m default.xml

# Start the sync
repo sync -c -j$(nproc) --force-sync
```

## Phase 2: Patch the Build Tree

Because we removed projects in Phase 1, we must patch the build tree to avoid "module not found" errors.

### Step 1: Remove EmergencyInfo References

1. **Remove from test list**: Edit `platform_testing/build/tasks/tests/instrumentation_test_list.mk` and remove the line for `EmergencyInfoUnitTests`.
2. **Remove from product list**: Edit `build/make/target/product/telephony_system_ext.mk` and remove the line for `EmergencyInfo`.

## Phase 3: Get Proprietary Files

### Step 1: Extract from Factory Image

You need the stock Google factory image zip in your Downloads folder.

```bash
cd /home/william/Documents/projects/foxPhone/graphene_build
./vendor/android-prepare-vendor/execute-all.sh -d sargo -b SP2A.220505.006 -i ~/Downloads/sargo-sp2a.220505.006-factory-978959e1.zip -o vendor
```

### Step 2: Move Blobs to Expected Path

Move the extracted files to the location GrapheneOS expects:

```bash
mkdir -p vendor/google_devices
cp -r vendor/sargo/sp2a.220505.006/vendor/google_devices/* vendor/google_devices/
```

## Phase 4: Apply Customizations

### Step 1: Custom Pulsing Boot Animation

To use a pulsing SVG logo:
1. Create a `bootanimation.zip` containing a sequence of PNG frames (scaling from 0.8 to 1.0).
2. Place it in `device/google/bonito/media/bootanimation.zip`.
3. Add this line to `device/google/bonito/device-sargo.mk`:
   ```makefile
   PRODUCT_COPY_FILES += \
       device/google/bonito/media/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip
   ```

## Phase 5: Build

```bash
source build/envsetup.sh
lunch sargo-user
m -j$(nproc)
```

## Phase 6: Flash to Device

1. Boot device to bootloader (Power + Vol Down).
2. Flash all images:
   ```bash
   cd out/target/product/sargo
   fastboot flashall -w
   ```

## Troubleshooting

- **Stuck on Google Logo**: Usually means a mismatch between `system.img` and `vendor.img`. Ensure you integrated vendor blobs in Phase 3.
- **Bootloader Loop**: Check slot status: `fastboot getvar all`. Ensure `vbmeta` was flashed correctly.
