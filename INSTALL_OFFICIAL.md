# Installing GrapheneOS on Legacy Devices

⚠️ **IMPORTANT**: 
- **Legacy devices are end-of-life** - no longer receiving official support
- **No pre-built images available** - GrapheneOS only provides source code for legacy devices
- **You must build from source** - see `BUILD_AND_INSTALL.md` for complete instructions
- **Always verify device compatibility** - ensure you have the correct build for your specific device model

## Legacy Device Policy

For end-of-life devices, GrapheneOS:
- Provides source code via manifest files
- Does NOT provide pre-built factory images
- Requires building from source to install
- No security updates or official support

This guide covers the prerequisites and setup. For the actual build and installation process, see `BUILD_AND_INSTALL.md`.

## Prerequisites

### 1. Install ADB and Fastboot

```bash
sudo apt update
sudo apt install android-tools-adb android-tools-fastboot
```

### 2. Verify Installation

```bash
adb version
fastboot --version
```

### 3. Enable USB Debugging on Your Device

If you still have stock Android or another ROM:

1. Go to `Settings` > `About phone`
2. Tap `Build number` 7 times to enable Developer options
3. Go back to `Settings` > `Developer options`
4. Enable `USB debugging`
5. Enable `OEM unlocking` (required for bootloader unlock)

## Step 1: Download GrapheneOS Source Code

⚠️ **Note**: For legacy devices, GrapheneOS only provides source code, not pre-built images. You must build from source.

### Download Source Code Manifest

1. **Visit GrapheneOS Source**:
   - Check: https://github.com/GrapheneOS/platform_manifest
   - Find the manifest for your device's final release
   - Download the manifest file (usually `default.xml`)

2. **Download manifest**:
   ```bash
   # Create download directory
   mkdir -p ~/Downloads/grapheneos
   cd ~/Downloads/grapheneos
   
   # Download manifest from GrapheneOS repository
   # The manifest file contains references to all source repositories
   ```

**Note**: Legacy devices receive their final release and then only source code is maintained. No pre-built images are provided.

## Step 2: Unlock Bootloader

⚠️ **WARNING**: Unlocking the bootloader will **ERASE ALL DATA** on your device!

1. **Power off** your device

2. **Boot into bootloader mode**:
   - Hold **Volume Down** + **Power** buttons simultaneously (or device-specific key combination)
   - Keep holding until you see the bootloader screen (Android robot with "Start" text)

3. **Connect device to computer** via USB

4. **Verify connection**:
   ```bash
   fastboot devices
   ```
   You should see your device listed.

5. **Unlock bootloader**:
   ```bash
   fastboot flashing unlock
   ```
   
   - On your device screen, use **Volume** buttons to navigate and **Power** to confirm
   - Select **"Unlock the bootloader"** and confirm
   - Device will reboot and erase all data

6. **Wait for device to reboot** (may take a few minutes)

7. **Boot back into bootloader** (Volume Down + Power)

## Step 3: Build and Flash GrapheneOS

⚠️ **Important**: Legacy devices require building from source. There are no pre-built images.

For complete build and installation instructions, see `BUILD_AND_INSTALL.md`. The process includes:

1. **Sync source code** using the manifest file in the `graphene_3a` directory (Note: requires manual removal of dead projects like `Vanadium` and `EmergencyInfo` from `default.xml` before sync).
2. **Integrate vendor blobs** using `android-prepare-vendor` (must move blobs to `vendor/google_devices/sargo` path).
3. **Apply customizations** (network restrictions, apps, pulsing boot branding).
4. **Build the ROM** (takes several hours) - builds in the `graphene_build` directory.
5. **Flash to device** using `fastboot flashall -w`.

The build process will create factory images that you can flash to your device.

## Step 4: First Boot

1. Device will reboot automatically
2. Follow the on-screen setup wizard
3. **Do NOT connect to WiFi yet** if you want to configure network restrictions first
4. Complete initial setup

## Step 5: Customizations

⚠️ **Important**: Since you're building from source, you can customize during the build process:

1. **Network restrictions** - Add iptables rules at boot (see `MODIFICATIONS.md`)
2. **Pre-install apps** - Include your Tiny Web app in the system image (see `ADDING_APPS.md`)
3. **Custom branding** - Modify boot logo, system name, etc.
4. **Remove apps** - Strip down to minimal installation

All customizations are done during the build process in `BUILD_AND_INSTALL.md`.

## Step 6: Verify Installation

```bash
# Check device is connected
adb devices

# Check GrapheneOS version
adb shell getprop ro.build.version.release
adb shell getprop ro.grapheneos.version
```

## Troubleshooting

### Device Not Detected

1. **Check USB connection**: Try different USB cable/port
2. **Check udev rules** (if needed):
   ```bash
   # Create udev rules for Android devices
   echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0664", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. **Add user to plugdev group**:
   ```bash
   sudo usermod -aG plugdev $USER
   # Log out and back in for changes to take effect
   ```

### Bootloader Already Unlocked

If bootloader is already unlocked, skip Step 2 and go directly to Step 3.

### Flash Fails

1. Ensure device is in bootloader mode: `fastboot devices`
2. Try flashing partitions individually instead of using `flash-all.sh`
3. Verify you have the correct build for your specific device model
4. Check device codename matches your device (e.g., sargo, bonito, etc.)

### Device Stuck in Bootloop

1. Boot into bootloader (Volume Down + Power)
2. Re-flash using `flash-all.sh`
3. If still stuck, try flashing stock Android first, then GrapheneOS

## Reverting to Stock Android

If you want to go back to stock:

1. Download factory image for your device from: https://developers.google.com/android/images
2. Extract and run `flash-all.sh` from the stock image

## Next Steps

For legacy devices, you must build from source:

1. **Follow `BUILD_AND_INSTALL.md`** for complete build and installation instructions
2. **Apply customizations** during the build:
   - Network restrictions (see `MODIFICATIONS.md`)
   - Pre-install apps (see `ADDING_APPS.md`)
   - Custom branding
   - Remove unwanted apps
3. **Build the ROM** (takes several hours)
4. **Flash to device** and test

Building from source gives you full control over the installation, perfect for Tiny Web devices with network restrictions and custom apps.

## Useful Commands

```bash
# Reboot to bootloader
adb reboot bootloader

# Reboot to recovery
adb reboot recovery

# Reboot to system
fastboot reboot

# Check bootloader status
fastboot getvar unlocked

# Lock bootloader (NOT recommended - can brick if not done correctly)
# fastboot flashing lock
```

