# Applying Network Restrictions to GrapheneOS Build

This guide explains how to integrate the network restriction script into your GrapheneOS build.

## File Locations

After syncing the GrapheneOS source, you'll need to modify files in the device tree. For Pixel 3a (sargo/bonito), the relevant paths are typically:

- Device tree: `device/google/bonito/` (Pixel 3a XL, shares code with sargo) or `device/google/sargo/`
- Init scripts: `device/google/bonito/init.bonito.rc` or similar
- Vendor scripts: `vendor/grapheneos/scripts/` (if it exists)

## Step-by-Step Integration

### Step 1: Copy the Restriction Script

After `repo sync` completes, copy the script to the device tree:

```bash
# From your build directory (graphene_3a)
cd /home/william/Documents/projects/foxPhone/graphene_3a
cp /home/william/Documents/projects/foxPhone/restrict_network.sh \
   device/google/bonito/restrict_network.sh
```

Or create it in a vendor directory if that structure exists:

```bash
mkdir -p vendor/grapheneos/scripts
cp /home/william/Documents/projects/foxPhone/restrict_network.sh \
   vendor/grapheneos/scripts/restrict_network.sh
```

### Step 2: Make Script Executable in Build

You need to ensure the script is marked as executable in the build system. Look for a `device/google/bonito/bonito.mk` or similar makefile and add:

```makefile
# Copy network restriction script
PRODUCT_COPY_FILES += \
    device/google/bonito/restrict_network.sh:$(TARGET_COPY_OUT_VENDOR)/bin/restrict_network.sh

# Make it executable
PRODUCT_PACKAGES += restrict_network.sh
```

Or if using the vendor directory:

```makefile
PRODUCT_COPY_FILES += \
    vendor/grapheneos/scripts/restrict_network.sh:$(TARGET_COPY_OUT_VENDOR)/bin/restrict_network.sh
```

### Step 3: Integrate into Init Process

Find the device's init file (usually `device/google/bonito/init.bonito.rc` or `device/google/bonito/init.bonito.early.rc`) and add:

```init
# Network restriction
on post-fs-data
    exec u:r:kernel:s0 /vendor/bin/restrict_network.sh

# Or if you need it earlier in the boot process:
on early-init
    exec u:r:kernel:s0 /vendor/bin/restrict_network.sh
```

**Note**: The SELinux context `u:r:kernel:s0` may need adjustment. Check existing exec statements in the init file for the correct context.

### Step 4: Configure Allowed Servers

Before building, edit `restrict_network.sh` and set:

```bash
ALLOWED_IPS="192.0.2.1 198.51.100.1"  # Your server IPs
ALLOWED_DOMAINS=""  # Optional: domain names
ALLOWED_PORTS="443 80"  # Optional: restrict to specific ports
```

### Step 5: SELinux Policy (if needed)

If SELinux blocks the script, you may need to add a policy. Look for SELinux policy files in:
- `device/google/bonito/sepolicy/` or
- `device/google/bonito-sepolicy/`

Create or modify a `.te` file to allow the script execution.

## Alternative: Late-Init Approach

If early-init doesn't work, you can trigger the script via a property:

In init file:
```init
on property:sys.boot_completed=1
    exec u:r:kernel:s0 /vendor/bin/restrict_network.sh
```

## Custom Pulsing Boot Animation

You can replace the default GrapheneOS boot animation with a custom pulsing logo based on an SVG file.

### Step 1: Generate the Animation
Use a script to render your SVG at multiple scales and package them into a `bootanimation.zip`:

1. Render SVG frames (e.g., scale 0.8 to 1.0).
2. Create `desc.txt` with resolution (1080 2220 for Pixel 3a).
3. Zip with **zero compression** (`zip -0r`).

### Step 2: Integrate into Build
1. Place `bootanimation.zip` in `device/google/bonito/media/`.
2. Edit `device/google/bonito/device-sargo.mk` and add:
   ```makefile
   PRODUCT_COPY_FILES += \
       device/google/bonito/media/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip
   ```

### Step 3: Rebuild
```bash
m systemimage
```

## Testing

After building and flashing:

1. Boot the device
2. Connect via ADB: `adb shell`
3. Check iptables rules: `iptables -L OUTPUT -n -v`
4. Test connectivity: `ping <allowed-ip>` should work, `ping 8.8.8.8` should fail (unless it's in your whitelist)

## Troubleshooting

- **Script not running**: Check `dmesg | grep restrict_network` for log messages
- **SELinux denials**: Check `adb shell dmesg | grep avc` for SELinux errors
- **DNS not working**: Ensure DNS servers are in `DNS_SERVERS` variable
- **Rules not persisting**: May need to add to `on property:net.dns1=*` trigger

## Important Warnings

- This will break most apps and system services
- Time sync (NTP) will fail unless you whitelist time servers
- System updates won't work
- Most apps requiring internet will fail
- Test thoroughly before using on a primary device

