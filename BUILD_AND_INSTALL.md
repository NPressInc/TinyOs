# Building and Installing GrapheneOS from Source

Complete guide for building GrapheneOS from source for legacy devices with custom network restrictions and pre-installed apps.

## Overview

This guide covers:
- Setting up the build environment
- Syncing GrapheneOS source code
- Adding network restrictions
- Pre-installing your Tiny Web app
- Building the ROM
- Flashing to device

## Prerequisites

### System Requirements

- **OS**: Linux (Ubuntu/Debian recommended)
- **Disk Space**: 500GB+ free space
- **RAM**: 32GB+ recommended (64GB ideal)
- **CPU**: Multi-core processor (8+ cores recommended)
- **Time**: Initial sync ~1-2 hours, build ~3-6 hours

### Install Build Tools

```bash
sudo apt update && sudo apt install -y \
    bc curl default-jdk-headless default-jre-headless git git-lfs \
    libncurses-dev libssl-dev lz4 m4 python3-lxml \
    python3-protobuf python3-yaml python-is-python3 rsync zip \
    protobuf-compiler adb fastboot
```

**Note**: Package names may vary by Ubuntu/Debian version:
- `libncurses5-dev` → `libncurses-dev` (newer versions)
- `android-tools-adb` → `adb` (newer versions)
- `android-tools-fastboot` → `fastboot` (newer versions)

If you get package errors, try installing individually or check your distribution's package names.

### Install Repo Tool

```bash
mkdir -p ~/bin
export PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod +x ~/bin/repo
```

### System Configuration

```bash
sudo sysctl -w kernel.unprivileged_userns_clone=1
```

## Phase 1: Download Source Code

### Step 1: Create Build Directory

```bash
# Navigate to your project directory
cd /home/william/Documents/projects/foxPhone/graphene_3a
```

The build will happen in the `graphene_3a` directory, alongside the manifest folder.

### Step 2: Initialize Manifest as Git Repository

⚠️ **Important**: The manifest folder must be a git repository for `repo` to work. If it's not already, initialize it:

```bash
# Navigate to manifest folder
cd /home/william/Documents/projects/foxPhone/graphene_3a/platform_manifest-SP2A.220505.006.2022081800

# Initialize as git repository (if not already done)
git init
git config user.email "build@local"
git config user.name "Build User"
git add default.xml GLOBAL-PREUPLOAD.cfg
git commit -m "Initial manifest commit"

# Go back to build directory
cd /home/william/Documents/projects/foxPhone/graphene_3a
```

### Step 3: Initialize Repo with Manifest

⚠️ **Important**: Run this command from your build directory (`graphene_3a`), not from inside the manifest folder!

```bash
# Make sure you're in the build directory
cd /home/william/Documents/projects/foxPhone/graphene_3a

# Clean up any partial initialization (if needed)
rm -rf .repo

# Using local manifest folder - relative path (since manifest is in same directory)
repo init -u file://$(pwd)/platform_manifest-SP2A.220505.006.2022081800

# Or using absolute path:
# repo init -u file:///home/william/Documents/projects/foxPhone/graphene_3a/platform_manifest-SP2A.220505.006.2022081800

# Or using remote manifest (if available)
# repo init -u https://github.com/GrapheneOS/platform_manifest -b SP2A.220505.006.2022081800
```

**Important Notes**:
- Manifest folder must be a **git repository** (initialize it first if needed)
- Must use `file://` protocol for local paths
- Run from your **build directory** (`graphene_3a`), not from inside the manifest folder
- Point to the **folder** containing `default.xml`, not the file itself

### Step 4: Sync Source Code

```bash
repo sync -j8
```

This downloads ~100GB of source code. Takes 1-2 hours depending on connection speed.

## Phase 2: Apply Customizations

### Step 1: Add Network Restrictions

Use the helper script or manual method:

```bash
# From your project directory
./apply_modifications.sh ~/grapheneos
```

Or manually (see `MODIFICATIONS.md` for details):
1. Copy `restrict_network.sh` to device tree
2. Modify device makefile to include script
3. Add init script trigger

**Edit `restrict_network.sh`** to set your allowed IPs/domains:
```bash
ALLOWED_IPS="192.0.2.1 198.51.100.1"  # Your Tiny Web node IPs
ALLOWED_DOMAINS=""  # Optional: domain names
ALLOWED_PORTS="443 80"  # Optional: restrict to specific ports
```

### Step 2: Pre-install Your Tiny Web App

Use the helper script:

```bash
# From your project directory
./add_apps.sh ~/grapheneos system /path/to/tinyweb.apk
```

Or manually (see `ADDING_APPS.md` for details):
1. Copy APK to device tree prebuilt directory
2. Modify device makefile to include app
3. Choose system app (cannot be uninstalled) or user app

### Step 3: Custom Branding (Optional)

Modify branding files in:
- `vendor/branding/` - Boot logo, system name, etc.
- Device-specific branding in device tree

## Phase 3: Get Proprietary Files

GrapheneOS needs proprietary vendor files. For legacy devices:

```bash
# Extract from device (if you have one running stock Android)
./vendor/android-prepare-vendor/execute-all.sh -d <device_codename> -b <build_number> -o vendor

# Or use prebuilt proprietary files if available
# Check GrapheneOS documentation for your specific device
```

**Device codenames**:
- Pixel 3a: `sargo`
- Pixel 3a XL: `bonito`
- Pixel 3: `blueline`
- Pixel 3 XL: `crosshatch`

## Phase 4: Build

### Step 1: Setup Build Environment

```bash
cd /home/william/Documents/projects/foxPhone/graphene_3a
source build/envsetup.sh
```

### Step 2: Select Device Target

```bash
# For Pixel 3a XL (bonito) - shares code with sargo
lunch bonito-user

# Or for Pixel 3a (sargo) if available
# lunch sargo-user
```

### Step 3: Build

```bash
# Full build (takes 3-6+ hours)
m

# Or parallel build (faster if you have many cores)
mka
```

The build output will be in `out/target/product/<device>/`

## Phase 5: Flash to Device

### Step 1: Unlock Bootloader (if not already unlocked)

⚠️ **WARNING**: This erases all data!

1. Enable Developer Options on device
2. Enable "OEM unlocking" and "USB debugging"
3. Boot into bootloader:
   ```bash
   adb reboot bootloader
   # Or: Power off, hold Volume Down + Power
   ```
4. Unlock:
   ```bash
   fastboot flashing unlock
   ```
   - Confirm on device screen
   - Wait for reboot

### Step 2: Boot into Bootloader

```bash
fastboot reboot bootloader
# Or: Power off, hold Volume Down + Power
```

### Step 3: Flash Built ROM

From the build directory:

```bash
cd /home/william/Documents/projects/foxPhone/graphene_3a/out/target/product/bonito

# Flash all partitions
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot flash vbmeta vbmeta.img
fastboot flash dtbo dtbo.img  # If available

# Reboot
fastboot reboot
```

### Step 4: First Boot

- First boot takes 10-15 minutes
- Your Tiny Web app should be pre-installed
- Network restrictions are active at boot
- Test connectivity to your Tiny Web nodes

## Verification

```bash
# Check device connection
adb devices

# Check GrapheneOS version
adb shell getprop ro.build.version.release
adb shell getprop ro.grapheneos.version

# Check network restrictions
adb shell iptables -L OUTPUT -n -v

# Check installed apps
adb shell pm list packages | grep -i tinyweb
```

## Troubleshooting

### Build Fails

- **Out of memory**: Increase swap space or reduce parallel jobs (`repo sync -j4`)
- **Missing dependencies**: Install all prerequisites listed above
- **Proprietary files missing**: Extract from device or find prebuilt files

### Flash Fails

- **Device not detected**: Check USB cable, try different port
- **Wrong device**: Verify device codename matches your device
- **Partition errors**: Try flashing partitions individually

### Network Restrictions Not Working

- **Check script location**: Verify `restrict_network.sh` is in `/vendor/bin/`
- **Check init trigger**: Verify script is called in init file
- **Check SELinux**: May need to add SELinux policies
- **Check logs**: `adb shell dmesg | grep restrict_network`

### App Not Installed

- **Check makefile**: Verify app is in `PRODUCT_COPY_FILES` or `PRODUCT_PACKAGES`
- **Check build output**: Look for app in `out/target/product/<device>/system/app/` or `/data/app/`
- **Check installation**: `adb shell pm list packages | grep <app_name>`

## Customization Tips

### Make It More Minimal

Edit device makefile to remove unwanted apps:
```makefile
# Remove apps from PRODUCT_PACKAGES
```

### Adjust Network Restrictions

Edit `restrict_network.sh`:
- Add/remove allowed IPs
- Configure allowed ports
- Enable/disable IPv6
- Add DNS servers

### Update Apps

To update your Tiny Web app:
1. Replace APK in prebuilt directory
2. Rebuild ROM
3. Flash updated system partition

## Time Estimates

- **Initial setup**: 30 minutes
- **Source sync**: 1-2 hours
- **Customizations**: 30 minutes - 2 hours
- **Build**: 3-6 hours
- **Flash**: 5-10 minutes
- **First boot**: 10-15 minutes

**Total**: ~6-10 hours for first build

## Next Steps

After successful installation:

1. Test all functionality
2. Verify network restrictions work
3. Test Tiny Web app connectivity
4. Customize further as needed
5. Create backup of working build

For detailed customization guides, see:
- `MODIFICATIONS.md` - Network restrictions
- `ADDING_APPS.md` - Adding apps
- `NEXT_STEPS.md` - Additional build details

