# Tiny Web - Custom GrapheneOS Build

This repository contains tools and documentation for building a custom GrapheneOS ROM for the Pixel 3a (sargo) with network restrictions and custom branding.

## Quick Start

1. **Setup Manifest**: Initialize the `graphene_3a` folder as a git repo and fix missing legacy links in `default.xml`.
2. **Sync Source**: Use `repo init` and `repo sync` in a separate `graphene_build` directory.
3. **Extract Vendor Blobs**: Use `android-prepare-vendor` to pull proprietary drivers from the stock Google factory image.
4. **Build**: Run `m -j$(nproc)` in the build environment.
5. **Flash**: Use `fastboot flashall -w` to install your custom OS.

Detailed instructions are in [BUILD_AND_INSTALL.md](./BUILD_AND_INSTALL.md).

## Project Structure

- `BUILD_AND_INSTALL.md` - **Start here**. Complete guide for the build process.
- `MODIFICATIONS.md` - How to add network restrictions (iptables).
- `ADDING_APPS.md` - How to pre-install your Tiny Web app.
- `imgs/` - Backup of verified, bootable images and custom boot animation.
- `icons/` - Source SVG files for branding and boot animations.

## Key Features

- **Network Restrictions**: Block all internet except Tiny Web nodes via iptables.
- **Pulsing Boot Animation**: Custom SVG-based "breathing" logo during boot.
- **Verified Boot**: Built with integrated vendor blobs for a secure, bootable experience.

## Build Requirements

- **Disk**: 500GB+ SSD
- **RAM**: 32GB+
- **OS**: Ubuntu 22.04 or 24.04
- **Time**: ~1 hour for subsequent builds; ~6 hours for first sync/build.

## Workflow Summary

1. **Modify Manifest**: Remove dead projects (`Vanadium`, `EmergencyInfo`).
2. **Sync**: `repo sync`.
3. **Patch**: Fix test lists in `platform_testing`.
4. **Vendor**: Extract and move blobs to `vendor/google_devices/sargo`.
5. **Branding**: Update `device/google/bonito/media/bootanimation.zip`.
6. **Build & Flash**: `m` and `fastboot flashall`.
