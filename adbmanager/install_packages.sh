#!/bin/bash

set -e  # Exit on error

# Проверка наличия подключенного устройства
if [ $(adb devices | grep -c "device$") -eq 0 ]; then
    echo "adb: no devices/emulators found"
    exit 1
fi

ADB_CMD="adb"

# Check if /tmp exists, otherwise use $HOME/.adbmanager
if [ ! -d "/tmp" ]; then
    TEMP_BASE="$HOME/.adbmanager"
else
    TEMP_BASE="/tmp"
fi

# Cleanup function on exit or interrupt (Ctrl+C)
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf $TEMP_BASE/android_install_*
}
trap cleanup EXIT

# Function to install a single APK
install_apk() {
    echo "Installing APK: $1"
    if ! "$ADB_CMD" install "$1"; then
        echo "Installation failed for APK: $1"
        exit 1  # Exit immediately if installation fails
    fi
}

# Function to install multiple APKs (split APKs)
install_multiple_apks() {
    echo "Installing multiple APKs..."
    if ! "$ADB_CMD" install-multiple "$1"/*.apk; then
        echo "Installation failed for multiple APKs in: $1"
        exit 1  # Exit immediately if installation fails
    fi
}

# Function to move OBB files if they exist
move_obb() {
    local temp_dir="$1"
    OBB_PATH=$(find "$temp_dir" -type d -name "obb" | head -n 1)
    if [ -n "$OBB_PATH" ]; then
        PKG_NAME=$("$ADB_CMD" shell pm list packages | grep -oP 'package:\K\S+' | head -n 1)
        echo "Moving OBB files to /sdcard/Android/obb/$PKG_NAME/"
        "$ADB_CMD" shell mkdir -p "/sdcard/Android/obb/$PKG_NAME/"
        "$ADB_CMD" push "$OBB_PATH" "/sdcard/Android/obb/$PKG_NAME/"
    fi
}

# Function to extract archives
extract_archive() {
    local file="$1"
    local dest="$2"

    echo "Extracting $file..."
    7z x "$file" -o"$dest" -y &>/dev/null

    # List extracted files for debugging
    echo "Extracted files:"
    find "$dest" -type f

    if [ $? -ne 0 ]; then
        echo "Failed to extract $file"
        return 1
    fi

    return 0
}

# Process each file
for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        continue
    fi

    EXT="${FILE##*.}"
    TEMP_DIR="$TEMP_BASE/android_install_$(basename "$FILE" ."$EXT")"

    # Clear temp directory before starting
    rm -rf $TEMP_BASE/android_install_*

    case "$EXT" in
        apk)
            install_apk "$FILE"
            ;;
        xapk|apks)
            if extract_archive "$FILE" "$TEMP_DIR"; then
                APK_COUNT=$(find "$TEMP_DIR" -type f -name "*.apk" | wc -l)
                if [ "$APK_COUNT" -eq 1 ]; then
                    install_apk "$TEMP_DIR"/*.apk
                else
                    install_multiple_apks "$TEMP_DIR"
                fi
                move_obb "$TEMP_DIR"
            else
                echo "Skipping $FILE due to extraction failure."
                continue
            fi
            ;;
        *)
            echo "Unsupported file format: $FILE"
            ;;
    esac

    # Remove temp files after installation, even if it failed
    if [ -d "$TEMP_DIR" ]; then
        echo "Removing temporary files..."
        rm -rf $TEMP_BASE/android_install_*
    fi
done

echo "Installation process completed."
