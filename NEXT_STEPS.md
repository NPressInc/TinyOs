# GrapheneOS Build - Next Steps & Automation

Now that you have a working build, here is how to maintain and automate your custom OS.

## 1. Quick Rebuilds

You don't need to rebuild everything to change the UI or apps.

### Updating Boot Animation
1. Replace `device/google/bonito/media/bootanimation.zip`.
2. Run:
   ```bash
   m systemimage
   ```
3. Flash:
   ```bash
   fastboot flash system out/target/product/sargo/system.img
   ```

### Updating Pre-installed Apps
1. Update your APK in the `vendor/` or `packages/apps/` path you chose.
2. Run `m systemimage`.
3. Flash `system.img`.

## 2. Automation Script (`build.sh`)

You can create a script in the root directory to handle the boilerplate environment setup:

```bash
#!/bin/bash
# Save as build_sargo.sh
cd /home/william/Documents/projects/foxPhone/graphene_build
source build/envsetup.sh
lunch sargo-user
m -j$(nproc) "$@"
```

Usage: `./build_sargo.sh` or `./build_sargo.sh systemimage`.

## 3. Backups

Keep the contents of your `imgs/` folder safe. These are your "known good" recovery images.
- `boot.img`: Kernel and recovery.
- `system.img`: The main OS and your apps.
- `vendor.img`: Proprietary drivers (synced to this build).
- `vbmeta.img`: Verified Boot signatures.

## 4. Troubleshooting Boot Issues

If the phone fails to boot after a change:
1. **Check the Slot**: `fastboot getvar current-slot`.
2. **Force Active Slot**: `fastboot --set-active=a`.
3. **Disable Verification**: If you are testing experimental kernels:
   ```bash
   fastboot flash --disable-verity --disable-verification vbmeta vbmeta.img
   ```

## 5. Network Restrictions

See `MODIFICATIONS.md` for details on how to update the `restrict_network.sh` script inside the build tree. Any changes there require a `m systemimage` to take effect.
