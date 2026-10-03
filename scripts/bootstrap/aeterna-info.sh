#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/config.sh"

echo "=========================================="
echo "           AETERNA LINUX"
echo "=========================================="
echo
echo "Name:              ${AETERNA_NAME}"
echo "Version:           ${AETERNA_VERSION}"
echo "Architecture:      ${TARGET_ARCH}"
echo "Target:            ${TARGET_TRIPLET}"
echo "Kernel:            ${KERNEL_VERSION}"
echo "Libc:              ${LIBC}"
echo "Compiler:          ${COMPILER}"
echo "Package manager:   ${PACKAGE_MANAGER}"
echo "Package format:    ${PACKAGE_FORMAT}"
echo "Boot mode:         ${BOOT_MODE}"
echo "Bootloader:        ${BOOTLOADER}"
echo "Root filesystem:   ${ROOT_FILESYSTEM}"
echo "Dev repository:    ${DEVELOPMENT_REPOSITORY}"
echo "Build jobs:        ${BUILD_JOBS}"
echo
echo "Source root:       ${AETERNA_ROOT}"
echo "=========================================="
