# Adding Apps to GrapheneOS Build

Since your network-restricted build will block app store downloads, you need to pre-install apps during the build process.

## Two Approaches

### 1. System Apps (Recommended for Default Apps)
Apps installed as system apps in `/system/app/` or `/system/priv-app/` - cannot be uninstalled by users.

### 2. Prebuilt User Apps
Apps installed to `/data/app/` - can be uninstalled by users, but pre-installed during first boot.

## Method 1: Adding System Apps

### Step 1: Create App Directory Structure

In your build directory after `repo sync`, create:

```bash
mkdir -p packages/apps/YourAppName
cd packages/apps/YourAppName
```

### Step 2: Copy APK and Create Android.mk

```bash
# Copy your APK file
cp /path/to/your/app.apk YourAppName.apk

# Create Android.mk
cat > Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := YourAppName
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := YourAppName.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRIVILEGED_MODULE := true  # For priv-app, remove for regular app

include $(BUILD_PREBUILT)
EOF
```

### Step 3: Add to Device Makefile

Edit `device/google/bonito/bonito.mk` (or similar) and add:

```makefile
PRODUCT_PACKAGES += \
    YourAppName
```

## Method 2: Prebuilt User Apps (Data Partition)

### Create Prebuilt App Package

```bash
mkdir -p packages/apps/YourAppName
cd packages/apps/YourAppName
cp /path/to/your/app.apk YourAppName.apk

cat > Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := YourAppName
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := YourAppName.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_PATH := $(TARGET_OUT_DATA)/app

include $(BUILD_PREBUILT)
EOF
```

## Method 3: Using PRODUCT_COPY_FILES (Simplest)

Add directly to device makefile (`device/google/bonito/bonito.mk`):

```makefile
# Copy APK to system/priv-app (system app)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/YourApp.apk:$(TARGET_COPY_OUT_SYSTEM)/priv-app/YourApp/YourApp.apk

# Or to system/app (regular system app)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/YourApp.apk:$(TARGET_COPY_OUT_SYSTEM)/app/YourApp/YourApp.apk

# Or to data/app (user app, pre-installed)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/YourApp.apk:$(TARGET_COPY_OUT_DATA)/app/YourApp/YourApp.apk
```

Then create the directory and copy the APK:

```bash
mkdir -p device/google/bonito/prebuilt
cp /path/to/app.apk device/google/bonito/prebuilt/YourApp.apk
```

## Default GrapheneOS Apps

GrapheneOS is very minimal. After `repo sync`, you can find apps in:

- `packages/apps/` - Various system apps
- `vendor/grapheneos/` - GrapheneOS-specific apps (if present)

To see what's included by default:

```bash
cd /home/william/Documents/projects/foxPhone/graphene_3a
grep -r "PRODUCT_PACKAGES" device/google/bonito/ | grep -i app
```

## Common Default Apps in GrapheneOS

GrapheneOS is very minimal and typically includes:
- Vanilla Calculator
- Vanilla Calendar
- Vanilla Clock
- Vanilla Contacts
- Vanilla Dialer
- Vanilla Gallery
- Various minimal AOSP apps

GrapheneOS does NOT include:
- App stores (F-Droid, Play Store, etc.)
- Google services
- Firewall apps (you add network restrictions via iptables)

Check `device/google/bonito/bonito.mk` to see what's included.

## Adding Multiple Apps

Create a dedicated directory for prebuilt apps:

```bash
mkdir -p device/google/bonito/prebuilt/apps
```

Copy all APKs there, then in `sargo.mk`:

```makefile
# Prebuilt apps
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/apps/App1.apk:$(TARGET_COPY_OUT_SYSTEM)/priv-app/App1/App1.apk \
    $(LOCAL_PATH)/prebuilt/apps/App2.apk:$(TARGET_COPY_OUT_SYSTEM)/priv-app/App2/App2.apk \
    $(LOCAL_PATH)/prebuilt/apps/App3.apk:$(TARGET_COPY_OUT_DATA)/app/App3/App3.apk
```

## App Permissions and SELinux

System apps may need SELinux policies. Check:
- `device/google/bonito/sepolicy/` or `device/google/bonito-sepolicy/` for device-specific policies
- You may need to add `.te` files for new system apps

## Sideloading After Installation (Limited)

Even with network restrictions, you can sideload APKs via ADB:

```bash
adb install /path/to/app.apk
```

However, this requires:
1. USB debugging enabled
2. ADB connection
3. The app must not require network access during installation

## Recommended Workflow

1. **Before building**: Collect all APKs you want to include
2. **Create prebuilt directory**: `device/google/bonito/prebuilt/apps/`
3. **Copy APKs**: Place all APKs in the prebuilt directory
4. **Edit makefile**: Add PRODUCT_COPY_FILES entries
5. **Build**: Apps will be included in the ROM

## Example: Adding Signal Messenger

```bash
# Download your Tiny Web APK
cd device/google/bonito/prebuilt/apps
cp /path/to/tinyweb.apk TinyWeb.apk

# Add to bonito.mk
# PRODUCT_COPY_FILES += \
#     $(LOCAL_PATH)/prebuilt/apps/TinyWeb.apk:$(TARGET_COPY_OUT_DATA)/app/TinyWeb/TinyWeb.apk
```

## Important Notes

- **APK Signing**: Use `LOCAL_CERTIFICATE := PRESIGNED` for pre-signed APKs
- **Privileged Apps**: Use `priv-app` for apps needing special permissions
- **Updates**: System apps won't auto-update. User apps in `/data/app/` can be updated if network allows
- **Space**: Each app increases ROM size
- **Compatibility**: Ensure APKs are compatible with Android version (GrapheneOS Pixel 3a build uses Android 12.1)

## Verifying Apps After Build

After flashing, check installed apps:

```bash
adb shell pm list packages
adb shell ls /system/priv-app/
adb shell ls /system/app/
adb shell ls /data/app/
```

