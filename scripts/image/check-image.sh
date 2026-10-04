#!/usr/bin/env bash

set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${AETERNA_ROOT}/configs/system/aeterna.conf"
source "${AETERNA_ROOT}/configs/system/image.conf"

IMAGE="${AETERNA_ROOT}/${IMAGE_FILE}"

echo "=========================================="
echo "       Aeterna Image Verification"
echo "=========================================="
echo

if [ ! -f "${IMAGE}" ]; then
    echo "ERROR: Image not found:"
    echo "${IMAGE}"
    exit 1
fi

echo "Image:"
echo "${IMAGE}"
echo

echo "[1/5] Checking image size..."
du -h "${IMAGE}"

echo
echo "[2/5] Checking kernel..."
if [ ! -f "${AETERNA_ROOT}/sources/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage" ]; then
    echo "ERROR: Kernel build artifact not found."
    exit 1
fi
echo "Linux ${KERNEL_VERSION}: OK"

echo
echo "[3/5] Checking rootfs kernel artifacts..."

ROOTFS="${AETERNA_ROOT}/rootfs"

test -f "${ROOTFS}/boot/vmlinuz-${KERNEL_VERSION}-aeterna"
test -f "${ROOTFS}/boot/initrd.img-${KERNEL_VERSION}"
test -f "${ROOTFS}/boot/config-${KERNEL_VERSION}"

echo "Kernel:     OK"
echo "Initramfs:  OK"
echo "Config:     OK"

echo
echo "[4/5] Checking Aeterna identity..."

grep -q '^ID=aeterna$' "${ROOTFS}/etc/os-release"
grep -q "^PRETTY_NAME=\"${AETERNA_NAME} Linux ${AETERNA_VERSION}\"$" \
    "${ROOTFS}/etc/os-release"

echo "Aeterna identity: OK"

echo
echo "[5/5] Checking package system..."

chroot "${ROOTFS}" dpkg --audit

echo "dpkg audit: OK"

echo
echo "=========================================="
echo "Image prerequisites verified successfully."
echo "=========================================="
