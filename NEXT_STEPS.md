# GrapheneOS Network-Restricted Build - Next Steps

## Overview
Build GrapheneOS for Pixel 3a (sargo/bonito) with network restrictions allowing only specific servers. This guide covers building from source with custom network restrictions and pre-installing your Tiny Web app.

## Phase 1: Environment Setup

### 1.1 Install Prerequisites
```bash
sudo apt update && sudo apt install -y \
    bc curl default-jdk-headless default-jre-headless git git-lfs \
    libncurses-dev libssl-dev lz4 m4 python3-lxml \
    python3-protobuf python3-yaml python-is-python3 rsync zip \
    protobuf-compiler adb fastboot
```

**Note**: Package names may vary:
- `libncurses5-dev` → `libncurses-dev` (newer Ubuntu/Debian)
- `android-tools-adb` → `adb` (newer versions)
- `android-tools-fastboot` → `fastboot` (newer versions)

### 1.2 Install Repo Tool
```bash
mkdir -p ~/bin
export PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

### 1.3 System Configuration
```bash
sudo sysctl -w kernel.unprivileged_userns_clone=1
```

## Phase 2: Source Code Sync

### 2.1 Create Build Directory
```bash
# Navigate to your project directory
cd /home/william/Documents/projects/foxPhone/graphene_3a
```

The build will happen in the `graphene_3a` directory, alongside the manifest folder.

### 2.2 Initialize Repo
```bash
# Make sure you're in the build directory
cd /home/william/Documents/projects/foxPhone/graphene_3a

# Using local manifest folder - relative path (since manifest is in same directory)
repo init -u file://$(pwd)/platform_manifest-SP2A.220505.006.2022081800

# Or using absolute path:
# repo init -u file:///home/william/Documents/projects/foxPhone/graphene_3a/platform_manifest-SP2A.220505.006.2022081800

# Or using remote manifest (if available):
# repo init -u https://github.com/GrapheneOS/platform_manifest -b SP2A.220505.006.2022081800
```

**Note**: Point to the **folder** containing `default.xml`, not the file itself. Run from the build directory (`graphene_3a`).

### 2.3 Sync Sources (this will take time, ~100GB download)
```bash
repo sync -j8
```

## Phase 3: Apply Network Restrictions

After syncing completes, apply the modifications in this directory:

1. Copy `restrict_network.sh` to the device tree
2. Modify the init script to call it on boot
3. See `MODIFICATIONS.md` for detailed instructions

## Phase 4: Build

### 4.1 Get Proprietary Files
```bash
# GrapheneOS proprietary files
# For Pixel 3a (sargo), you may need to extract from device or use prebuilt
# Check GrapheneOS documentation for device-specific instructions
./vendor/android-prepare-vendor/execute-all.sh -d sargo -b SP2A.220505.006 -o vendor
```

### 4.2 Setup Build Environment
```bash
source build/envsetup.sh
lunch bonito-user  # or sargo-user for Pixel 3a (bonito is Pixel 3a XL, shares code with sargo)
```

### 4.3 Build (takes several hours)
```bash
m
```

## Phase 5: Flash to Device

### 5.1 Boot into Bootloader
- Power off device
- Hold Volume Down + Power until bootloader appears

### 5.2 Unlock Bootloader (if needed)
```bash
fastboot flashing unlock
```
⚠️ **Warning**: This erases all data!

### 5.3 Flash GrapheneOS
From the build directory:
```bash
# Flash the built ROM (replace bonito with sargo if building for Pixel 3a)
fastboot flash boot out/target/product/bonito/boot.img
fastboot flash system out/target/product/bonito/system.img
fastboot flash vendor out/target/product/bonito/vendor.img
fastboot flash vbmeta out/target/product/bonito/vbmeta.img
fastboot reboot
```

## Important Notes

- **Disk Space**: Ensure 500GB+ free space
- **RAM**: 32GB+ recommended (64GB ideal)
- **Time**: Initial sync ~1-2 hours, build ~3-6 hours depending on hardware
- **Testing**: Test network restrictions in a VM or spare device first
- **DNS**: You may need to allow DNS servers (8.8.8.8) if using domain names
- **Network Restrictions**: Network restrictions are applied via iptables at boot. Edit `restrict_network.sh` to customize allowed IPs/domains.

## Customization

Edit `restrict_network.sh` to modify:
- Allowed server IPs/domains
- Allowed ports
- IPv6 support (if needed)

