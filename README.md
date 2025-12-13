# Tiny Web - Custom GrapheneOS Build

This repository contains tools and documentation for building a custom GrapheneOS ROM with network restrictions and pre-installed Tiny Web app for family communication devices.

## Quick Start

1. **Download GrapheneOS source manifest** from [GrapheneOS Releases](https://grapheneos.org/releases)
2. **Follow `BUILD_AND_INSTALL.md`** for complete build and installation instructions
3. **Customize** network restrictions and apps as needed

## Project Structure

- `BUILD_AND_INSTALL.md` - Complete guide for building and installing from source
- `MODIFICATIONS.md` - How to add network restrictions
- `ADDING_APPS.md` - How to pre-install your Tiny Web app
- `restrict_network.sh` - Network restriction script (iptables rules)
- `add_apps.sh` - Helper script to add APKs to build
- `apply_modifications.sh` - Helper script to apply network restrictions

## Key Features

- **Network Restrictions**: Block all internet except Tiny Web nodes (via iptables)
- **Pre-installed Apps**: Tiny Web app included in system image
- **Minimal OS**: Based on GrapheneOS (very minimal, privacy-focused)
- **Custom Branding**: Customize boot logo, system name, etc.

## Requirements

- Linux build environment (Ubuntu/Debian recommended)
- 500GB+ disk space
- 32GB+ RAM (64GB ideal)
- 6-10 hours for first build

## Workflow

1. Sync GrapheneOS source code
2. Apply network restrictions (`MODIFICATIONS.md`)
3. Add Tiny Web app (`ADDING_APPS.md`)
4. Build ROM (`BUILD_AND_INSTALL.md`)
5. Flash to device

## Documentation

- **`BUILD_AND_INSTALL.md`** - Start here for complete build process
- **`INSTALL_OFFICIAL.md`** - General information about legacy devices
- **`NEXT_STEPS.md`** - Additional build details

## Resources

- [GrapheneOS Build Documentation](https://grapheneos.org/releases#tegu)
- [GrapheneOS Source for Phones](https://grapheneos.org/releases)

