#!/usr/bin/env bash

set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${AETERNA_ROOT}/configs/system/aeterna.conf"

ROOTFS="${AETERNA_ROOT}/${AETERNA_ROOTFS_DIR:-rootfs}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

if [ ! -d "${ROOTFS}" ]; then
    echo "ERROR: Rootfs not found:"
    echo "${ROOTFS}"
    exit 1
fi

echo "Applying Aeterna system identity..."

cat > "${ROOTFS}/etc/os-release" <<EOF_OS
NAME="${AETERNA_NAME} Linux"
PRETTY_NAME="${AETERNA_NAME} Linux ${AETERNA_VERSION}"
ID=aeterna
ID_LIKE=debian
VERSION_ID="${AETERNA_VERSION}"
VERSION="${AETERNA_VERSION}"
VERSION_CODENAME=aeterna
HOME_URL="https://github.com/chirantan-swain-dev/aeterna-linux"
EOF_OS

printf '%s\n' "${AETERNA_NAME,,}" > "${ROOTFS}/etc/hostname"

echo
echo "Identity:"
cat "${ROOTFS}/etc/os-release"

echo
echo "Hostname:"
cat "${ROOTFS}/etc/hostname"

echo
echo "Aeterna identity applied successfully."
