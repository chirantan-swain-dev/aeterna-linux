#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " Aeterna Linux Host Check"
echo "======================================"
echo

echo "[System]"
printf "OS:           "
grep '^PRETTY_NAME=' /etc/os-release || true

printf "Kernel:       "
uname -r

printf "Architecture: "
uname -m

echo

echo "[CPU]"
printf "CPU cores:    "
nproc

echo

echo "[Memory]"
free -h

echo

echo "[Required Tools]"

    tools=(
    gcc
    g++
    make
    ld
    as
    objcopy
    readelf
    ar
    nm
    strip
    git
    curl
    wget
    tar
    xz
    bzip2
    gzip
    patch
    bison
    flex
    bc
    perl
    python3
    qemu-system-x86_64
    xorriso
    cpio
    rsync
    file
    gawk
    zstd
    pkg-config
)

missing=0

for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  [OK]   %s\n" "$tool"
    else
        printf "  [MISS] %s\n" "$tool"
        missing=1
    fi
if ! dpkg-query -W -f='${Status}' libelf-dev 2>/dev/null | grep -q 'install ok installed'; then
    echo "ERROR: Required package not installed: libelf-dev"
    exit 1
fi
done

echo

if [ "$missing" -ne 0 ]; then
    echo "Host validation FAILED."
    echo "Install the missing dependencies before continuing."
    exit 1
fi

echo "Host validation PASSED."
