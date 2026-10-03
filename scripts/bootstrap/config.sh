#!/usr/bin/env bash

set -euo pipefail

AETERNA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CONFIG_FILE="${AETERNA_ROOT}/configs/system/aeterna.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Aeterna configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

export AETERNA_ROOT
export AETERNA_NAME
export AETERNA_VERSION
export TARGET_ARCH
export TARGET_TRIPLET
export KERNEL_VERSION
export LIBC
export COMPILER
export PACKAGE_MANAGER
export PACKAGE_FORMAT
export BOOT_MODE
export BOOTLOADER
export ROOT_FILESYSTEM
export DEVELOPMENT_REPOSITORY
export BUILD_JOBS
