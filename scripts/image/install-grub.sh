#!/usr/bin/env bash
set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "${AETERNA_ROOT}/configs/system/aeterna.conf"

# shellcheck source=/dev/null
source "${AETERNA_ROOT}/configs/system/image.conf"

ROOT_MOUNT="${ROOT_MOUNT:-/mnt/aeterna-root}"
EFI_MOUNT="${EFI_MOUNT:-${ROOT_MOUNT}/boot/efi}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This script must run as root."
    exit 1
fi

if ! mountpoint -q "${ROOT_MOUNT}"; then
    echo "ERROR: Root filesystem is not mounted:"
    echo "${ROOT_MOUNT}"
    exit 1
fi

if ! mountpoint -q "${EFI_MOUNT}"; then
    echo "ERROR: EFI filesystem is not mounted:"
    echo "${EFI_MOUNT}"
    exit 1
fi

ROOT_DEVICES="$(findmnt -rn -o SOURCE "${ROOT_MOUNT}")"

if [[ "$(printf '%s\n' "${ROOT_DEVICES}" | sed '/^[[:space:]]*$/d' | wc -l)" -ne 1 ]]; then
    echo "ERROR: Expected exactly one root filesystem mount."
    echo "Found:"
    printf '%s\n' "${ROOT_DEVICES}"
    exit 1
fi

ROOT_DEVICE="$(printf '%s\n' "${ROOT_DEVICES}" | head -n1)"
ROOT_UUID="$(blkid -s UUID -o value "${ROOT_DEVICE}")"

if [[ -z "${ROOT_UUID}" ]]; then
    echo "ERROR: Could not determine root filesystem UUID:"
    echo "${ROOT_DEVICE}"
    exit 1
fi

KERNEL="${ROOT_MOUNT}/boot/vmlinuz-${KERNEL_VERSION}-aeterna"
INITRD="${ROOT_MOUNT}/boot/initrd.img-${KERNEL_VERSION}"

if [[ ! -f "${KERNEL}" ]]; then
    echo "ERROR: Kernel not found:"
    echo "${KERNEL}"
    exit 1
fi

if [[ ! -f "${INITRD}" ]]; then
    echo "ERROR: Initrd not found:"
    echo "${INITRD}"
    exit 1
fi

echo "=========================================="
echo "       Aeterna GRUB Installation"
echo "=========================================="
echo
echo "Root device: ${ROOT_DEVICE}"
echo "Root UUID:   ${ROOT_UUID}"
echo

echo "[1/5] Installing GRUB UEFI..."

grub-install \
    --target=x86_64-efi \
    --efi-directory="${EFI_MOUNT}" \
    --boot-directory="${ROOT_MOUNT}/boot" \
    --bootloader-id=Aeterna \
    --removable \
    --no-nvram \
    --recheck

echo
echo "[2/5] Configuring GRUB defaults..."

cat > "${ROOT_MOUNT}/etc/default/grub" <<EOF
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DEFAULT=0
GRUB_DISTRIBUTOR="Aeterna"
GRUB_CMDLINE_LINUX="root=UUID=${ROOT_UUID} rw console=ttyS0,115200"
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_LINUX_PARTUUID=true
EOF

echo
echo "[3/5] Writing deterministic GRUB configuration..."

GRUB_CFG="${ROOT_MOUNT}/boot/grub/grub.cfg"

cat > "${GRUB_CFG}" <<EOF
search --no-floppy --fs-uuid --set=root ${ROOT_UUID}

menuentry 'Aeterna Linux' {
    insmod part_gpt
    insmod ext2

    echo 'Loading Aeterna Linux ${KERNEL_VERSION}...'
    linux /boot/vmlinuz-${KERNEL_VERSION}-aeterna root=UUID=${ROOT_UUID} rw console=ttyS0,115200
    initrd /boot/initrd.img-${KERNEL_VERSION}
}
EOF

echo
echo "[4/5] Verifying GRUB configuration..."

if ! grep -Eq \
    "^[[:space:]]*linux[[:space:]]+/boot/vmlinuz-${KERNEL_VERSION}-aeterna[[:space:]].*root=UUID=${ROOT_UUID}" \
    "${GRUB_CFG}"; then
    echo "ERROR: GRUB configuration does not contain the expected kernel/root UUID."
    exit 1
fi

if ! grep -Eq \
    "^[[:space:]]*initrd[[:space:]]+/boot/initrd\\.img-${KERNEL_VERSION}[[:space:]]*$" \
    "${GRUB_CFG}"; then
    echo "ERROR: GRUB configuration does not contain the expected initrd."
    exit 1
fi

if grep -q 'root=/dev/loop' "${GRUB_CFG}"; then
    echo "ERROR: GRUB contains a loop-device root reference."
    exit 1
fi

if grep -q 'grub-mkconfig' "${GRUB_CFG}"; then
    echo "ERROR: Generated GRUB configuration contains unexpected generator content."
    exit 1
fi

echo
echo "[5/5] GRUB verification successful."
echo
echo "Kernel:"
echo "${KERNEL}"
echo
echo "Initrd:"
echo "${INITRD}"
echo
echo "GRUB configuration:"
echo "${GRUB_CFG}"
