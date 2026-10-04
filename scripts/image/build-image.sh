#!/usr/bin/env bash

set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${AETERNA_ROOT}/configs/system/aeterna.conf"

# shellcheck disable=SC1091
source "${AETERNA_ROOT}/configs/system/image.conf"

ROOTFS="${AETERNA_ROOT}/${AETERNA_ROOTFS_DIR:-rootfs}"
IMAGE="${AETERNA_ROOT}/${IMAGE_FILE}"

MOUNT_ROOT="${ROOT_MOUNT}"
MOUNT_EFI="${EFI_MOUNT}"

LOOP_DEVICE=""

cleanup() {
    set +e

    for mountpoint in \
        "${MOUNT_ROOT}/run" \
        "${MOUNT_ROOT}/sys" \
        "${MOUNT_ROOT}/proc" \
        "${MOUNT_ROOT}/dev/pts" \
        "${MOUNT_ROOT}/dev" \
        "${MOUNT_EFI}" \
        "${MOUNT_ROOT}"
    do
        if mountpoint -q "${mountpoint}"; then
            umount "${mountpoint}"
        fi
    done

    if [[ -n "${LOOP_DEVICE}" ]]; then
        losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
    fi
}

trap cleanup EXIT

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

if [[ ! -d "${ROOTFS}" ]]; then
    echo "ERROR: Rootfs not found:"
    echo "${ROOTFS}"
    exit 1
fi

if [[ ! -f "${ROOTFS}/boot/vmlinuz-${KERNEL_VERSION}-aeterna" ]]; then
    echo "ERROR: Aeterna kernel not found."
    exit 1
fi

# Image mountpoints must be completely clean before starting.
if findmnt -rn "${MOUNT_ROOT}" >/dev/null 2>&1; then
    echo "ERROR: Root mountpoint is already in use:"
    findmnt -rn "${MOUNT_ROOT}"
    exit 1
fi

if findmnt -rn "${MOUNT_EFI}" >/dev/null 2>&1; then
    echo "ERROR: EFI mountpoint is already in use:"
    findmnt -rn "${MOUNT_EFI}"
    exit 1
fi

echo "=========================================="
echo "       Aeterna Disk Image Builder"
echo "=========================================="
echo
echo "Image:       ${IMAGE}"
echo "Size:        ${IMAGE_SIZE}"
echo "Rootfs:      ${ROOTFS}"
echo "Kernel:      ${KERNEL_VERSION}"
echo

mkdir -p "${AETERNA_ROOT}/build"

echo "[1/10] Removing previous image..."

rm -f "${IMAGE}"

echo "[2/10] Creating image..."

truncate -s "${IMAGE_SIZE}" "${IMAGE}"

echo "[3/10] Creating GPT..."

parted -s "${IMAGE}" mklabel gpt

parted -s "${IMAGE}" \
    mkpart EFI fat32 1MiB "${EFI_SIZE}"

parted -s "${IMAGE}" \
    set 1 esp on

parted -s "${IMAGE}" \
    mkpart AETERNA_ROOT ext4 "${EFI_SIZE}" 100%

echo "[4/10] Attaching image..."

LOOP_DEVICE="$(losetup --find --partscan --show "${IMAGE}")"

udevadm settle

EFI_PART="${LOOP_DEVICE}p1"
ROOT_PART="${LOOP_DEVICE}p2"

echo "Loop: ${LOOP_DEVICE}"

echo "[5/10] Formatting partitions..."

mkfs.vfat -F 32 -n "${EFI_LABEL}" "${EFI_PART}"
mkfs.ext4 -F -L "${ROOT_LABEL}" "${ROOT_PART}"

echo "[6/10] Mounting filesystems..."

mkdir -p "${MOUNT_ROOT}"

mount "${ROOT_PART}" "${MOUNT_ROOT}"

if ! mountpoint -q "${MOUNT_ROOT}"; then
    echo "ERROR: Root filesystem failed to mount:"
    echo "${MOUNT_ROOT}"
    exit 1
fi

mkdir -p "${MOUNT_ROOT}/boot/efi"

mount "${EFI_PART}" "${MOUNT_ROOT}/boot/efi"

if ! mountpoint -q "${MOUNT_ROOT}/boot/efi"; then
    echo "ERROR: EFI filesystem failed to mount:"
    echo "${MOUNT_ROOT}/boot/efi"
    exit 1
fi

echo "[7/10] Copying rootfs..."

rsync -aHAX --numeric-ids \
    --exclude='/proc/***' \
    --exclude='/sys/***' \
    --exclude='/dev/***' \
    --exclude='/run/***' \
    --exclude='/tmp/***' \
    "${ROOTFS}/" \
    "${MOUNT_ROOT}/"

mkdir -p \
    "${MOUNT_ROOT}/proc" \
    "${MOUNT_ROOT}/sys" \
    "${MOUNT_ROOT}/dev" \
    "${MOUNT_ROOT}/dev/pts" \
    "${MOUNT_ROOT}/run" \
    "${MOUNT_ROOT}/tmp"

chmod 1777 "${MOUNT_ROOT}/tmp"

echo "[8/10] Mounting runtime filesystems..."

mount --bind /dev "${MOUNT_ROOT}/dev"
mount --bind /dev/pts "${MOUNT_ROOT}/dev/pts"
mount -t proc proc "${MOUNT_ROOT}/proc"
mount -t sysfs sysfs "${MOUNT_ROOT}/sys"
mount --bind /run "${MOUNT_ROOT}/run"

echo "[9/10] Installing GRUB..."


"${AETERNA_ROOT}/scripts/image/install-grub.sh"

echo "[10/10] Verifying image..."

GRUB_CFG="${MOUNT_ROOT}/boot/grub/grub.cfg"

if [[ ! -f "${MOUNT_ROOT}/boot/vmlinuz-${KERNEL_VERSION}-aeterna" ]]; then
    echo "ERROR: Kernel missing from final image."
    exit 1
fi

if [[ ! -f "${MOUNT_ROOT}/boot/initrd.img-${KERNEL_VERSION}" ]]; then
    echo "ERROR: Initrd missing from final image."
    exit 1
fi

if [[ ! -f "${GRUB_CFG}" ]]; then
    echo "ERROR: GRUB configuration was not created:"
    echo "${GRUB_CFG}"
    exit 1
fi

if [[ ! -f "${MOUNT_EFI}/EFI/BOOT/BOOTX64.EFI" ]]; then
    echo "ERROR: EFI fallback bootloader was not created."
    exit 1
fi

if ! grep -Eq \
    "^[[:space:]]*linux[[:space:]]+/boot/vmlinuz-${KERNEL_VERSION}-aeterna[[:space:]].*root=UUID=" \
    "${GRUB_CFG}"; then
    echo "ERROR: GRUB kernel entry is missing."
    exit 1
fi

if ! grep -Eq \
    "^[[:space:]]*initrd[[:space:]]+/boot/initrd\\.img-${KERNEL_VERSION}[[:space:]]*$" \
    "${GRUB_CFG}"; then
    echo "ERROR: GRUB initrd entry is missing."
    exit 1
fi

if grep -q 'root=/dev/loop' "${GRUB_CFG}"; then
    echo "ERROR: GRUB contains a loop-device root reference."
    exit 1
fi

if ! grep -q '^ID=aeterna$' "${MOUNT_ROOT}/etc/os-release"; then
    echo "ERROR: Aeterna identity missing from final image."
    exit 1
fi

echo
echo "GRUB configuration:"
cat "${GRUB_CFG}"

echo
echo "=========================================="
echo "Aeterna image created successfully."
echo "=========================================="
echo
echo "Image:"
echo "${IMAGE}"
echo
du -h "${IMAGE}"
