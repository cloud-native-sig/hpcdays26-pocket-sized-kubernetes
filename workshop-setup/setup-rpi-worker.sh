#!/usr/bin/env bash
#
# Authored by Lewis and ChatGPT
#
# RPi Worker Setup Script
# Installs packages and copies k3s assets from a USB stick.
#
# Run as root:
#   sudo ./setup-rpi-worker.sh
#

set -Eeuo pipefail

# -----------------------------
# Config
# -----------------------------
USB_MOUNT="/media/usb"
K3S_DEST="/root/"
LOG_FILE="/var/log/rpi-worker-setup.log"

# Track whether this script mounted the USB
MOUNTED_BY_SCRIPT=0

# -----------------------------
# Logging
# -----------------------------
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================"
echo "RPi Worker Setup Started"
echo "Time: $(date)"
echo "======================================"

# -----------------------------
# Root check
# -----------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

# -----------------------------
# Helper functions
# -----------------------------
cleanup() {
    sync

    # Only unmount if THIS script mounted it
    if [[ "$MOUNTED_BY_SCRIPT" -eq 1 ]] && mountpoint -q "$USB_MOUNT"; then
        echo "Unmounting USB..."

        # Try normal unmount first
        if umount "$USB_MOUNT"; then
            echo "USB unmounted cleanly."
        else
            echo "WARNING: Normal unmount failed."

            if command -v lsof >/dev/null 2>&1; then
                echo "Processes using mount point:"
                lsof +f -- "$USB_MOUNT" || true
            fi

            echo "Attempting lazy unmount..."
            umount -l "$USB_MOUNT" || {
                echo "WARNING: Could not unmount $USB_MOUNT"
            }
        fi
    fi
}

error_handler() {
    echo
    echo "ERROR: Script failed at line $1"
    cleanup
    exit 1
}

trap 'error_handler $LINENO' ERR
trap cleanup EXIT

# -----------------------------
# Auto-detect USB device
# -----------------------------
echo
echo "Detecting removable USB storage..."

USB_DEVICE=""

# Prefer USB transport detection
while read -r NAME TRAN TYPE; do
    if [[ "$TRAN" == "usb" && "$TYPE" == "part" ]]; then
        USB_DEVICE="$NAME"
        break
    fi
done < <(lsblk -lnpo NAME,TRAN,TYPE)

# Fallback to removable devices if needed
if [[ -z "$USB_DEVICE" ]]; then
    while read -r NAME RM TYPE; do
        if [[ "$RM" == "1" && "$TYPE" == "part" ]]; then
            USB_DEVICE="$NAME"
            break
        fi
    done < <(lsblk -lnpo NAME,RM,TYPE)
fi

if [[ -z "$USB_DEVICE" ]]; then
    echo "ERROR: No USB storage device detected."
    echo
    echo "Available block devices:"
    lsblk -fp
    exit 1
fi

echo "Detected USB device: $USB_DEVICE"

# -----------------------------
# Mount USB
# -----------------------------
mkdir -p "$USB_MOUNT"

CURRENT_MOUNT="$(lsblk -no MOUNTPOINT "$USB_DEVICE" | head -n1)"

if [[ -n "$CURRENT_MOUNT" ]]; then
    echo "USB already mounted at: $CURRENT_MOUNT"
    USB_MOUNT="$CURRENT_MOUNT"
else
    echo "Mounting $USB_DEVICE at $USB_MOUNT..."
    mount "$USB_DEVICE" "$USB_MOUNT"
    MOUNTED_BY_SCRIPT=1
fi

# -----------------------------
# Verify expected files exist
# -----------------------------
echo
echo "Verifying USB contents..."

if ! compgen -G "$USB_MOUNT/vim/*.deb" > /dev/null; then
    echo "ERROR: No vim .deb packages found on USB."
    exit 1
fi

if [[ ! -d "$USB_MOUNT/k3s" ]]; then
    echo "ERROR: k3s directory not found on USB."
    exit 1
fi

echo "USB contents verified."

# -----------------------------
# Install packages
# -----------------------------
echo
echo "Installing .deb packages..."

dpkg --auto-deconfigure -i "$USB_MOUNT"/vim/*.deb || true

# -----------------------------
# Enable cgroup memory support
# -----------------------------
echo
echo "Configuring kernel cgroup memory support..."

CMDLINE_FILE="/boot/firmware/cmdline.txt"

grep -q 'cgroup_memory=1' "$CMDLINE_FILE" || \
    sed -i '1 s|$| cgroup_memory=1 cgroup_enable=memory|' "$CMDLINE_FILE"

echo "Kernel parameters updated."

# -----------------------------
# Copy k3s assets
# -----------------------------
echo
echo "Copying k3s assets to $K3S_DEST..."

mkdir -p "$K3S_DEST"

if command -v rsync >/dev/null 2>&1; then
    rsync -avh --delete "$USB_MOUNT/k3s/" "$K3S_DEST/k3s"
else
    cp -a "$USB_MOUNT/k3s/." "$K3S_DEST/"
fi

# -----------------------------
# Copy image .tag
# -----------------------------
echo
echo "Copying workshop images to $K3S_DEST..."

mkdir -p "$K3S_DEST"

if command -v rsync >/dev/null 2>&1; then
    rsync -avh --delete "$USB_MOUNT/workshop-images.tar" "$K3S_DEST/workshop-images.tar"
else
    cp -a "$USB_MOUNT/workshop-images.tar" "$K3S_DEST/"
fi

sync

echo
echo "======================================"
echo "RPi Worker Setup Completed Successfully"
echo "System will reboot in 10 seconds..."
echo "======================================"

sleep 10

# -----------------------------
# Reboot system
# -----------------------------
reboot
