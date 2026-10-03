#!/usr/bin/env bash

set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${AETERNA_ROOT}/configs/system/aeterna.conf"

ROOTFS="${AETERNA_ROOT}/${AETERNA_ROOTFS_DIR:-rootfs}"
BOOTSTRAP_MIRROR="http://http.kali.org/kali"

echo "=========================================="
echo "      Aeterna Rootfs Bootstrap"
echo "=========================================="
echo
echo "Distribution:   ${DEVELOPMENT_REPOSITORY}"
echo "Architecture:   ${TARGET_ARCH}"
echo "Rootfs:         ${ROOTFS}"
echo "Mirror:         ${BOOTSTRAP_MIRROR}"
echo

if [ "${TARGET_ARCH}" != "x86_64" ]; then
    echo "ERROR: This bootstrap currently supports x86_64 only."
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script with sudo."
    echo
    echo "Example:"
    echo "  sudo ./scripts/bootstrap/bootstrap-rootfs.sh"
    exit 1
fi

if [ -d "${ROOTFS}" ] && [ -n "$(find "${ROOTFS}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    echo "ERROR: Rootfs is not empty:"
    echo "${ROOTFS}"
    echo
    echo "Remove the existing generated rootfs before bootstrapping again."
    exit 1
fi

mkdir -p "${ROOTFS}"

echo "[1/3] Bootstrapping Kali Rolling..."
debootstrap \
    --arch=amd64 \
    --variant=minbase \
    kali-rolling \
    "${ROOTFS}" \
    "${BOOTSTRAP_MIRROR}"

echo
echo "[2/3] Verifying target userspace..."

CHROOT_ARCH="$(chroot "${ROOTFS}" dpkg --print-architecture)"
# shellcheck disable=SC2016
DPKG_VERSION="$(chroot "${ROOTFS}" dpkg-query -W -f='${Version}' dpkg)"
APT_VERSION="$(chroot "${ROOTFS}" apt-cache --version | head -1)"

if [ "${CHROOT_ARCH}" != "amd64" ]; then
    echo "ERROR: Unexpected target architecture: ${CHROOT_ARCH}"
    exit 1
fi

echo "Architecture: ${CHROOT_ARCH}"
echo "dpkg:         ${DPKG_VERSION}"
echo "APT:          ${APT_VERSION}"

echo
echo "[3/4] Applying Aeterna system identity..."

cat > "${ROOTFS}/etc/os-release" <<EOF
NAME="${AETERNA_NAME} Linux"
PRETTY_NAME="${AETERNA_NAME} Linux ${AETERNA_VERSION}"
ID=aeterna
ID_LIKE=debian
VERSION_ID="${AETERNA_VERSION}"
VERSION="${AETERNA_VERSION}"
VERSION_CODENAME=aeterna
HOME_URL="https://github.com/chirantan-swain-dev/aeterna-linux"
EOF

echo "aeterna" > "${ROOTFS}/etc/hostname"

echo
echo "[4/4] Configuring APT..."

cat > "${ROOTFS}/etc/apt/sources.list" <<EOF
deb ${BOOTSTRAP_MIRROR} kali-rolling main contrib non-free non-free-firmware
EOF

echo
echo "Bootstrap completed successfully."
echo
echo "Architecture: ${CHROOT_ARCH}"
echo "dpkg:         ${DPKG_VERSION}"
echo "APT:          ${APT_VERSION}"
echo "Rootfs:"
du -sh "${ROOTFS}"
echo
echo
echo "Rootfs:"
du -sh "${ROOTFS}"
echo
