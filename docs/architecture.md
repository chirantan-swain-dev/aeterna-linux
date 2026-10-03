# Aeterna Linux Architecture

## Project

Aeterna Linux is an independent Linux distribution being developed
from source.

## Year 1 Objective

During the first year, Aeterna is intended for private/internal use
by the Aeterna development team and friends.

The Year 1 system will use the Kali Rolling repository through APT.

The public release infrastructure will be developed separately
when Aeterna is prepared for public release.

## Target Architecture

- CPU architecture: x86_64
- Firmware: UEFI
- Partitioning: GPT
- Bootloader: GRUB
- Kernel: Linux 7.2.8
- C library: glibc
- Compiler: GCC
- Binary utilities: GNU binutils
- Package format: Debian .deb
- Package database: dpkg
- Package manager: APT
- Year 1 repository: Kali Rolling
- Initial filesystem: ext4
- Virtualization/testing: QEMU

## Package Management

Aeterna will use APT and dpkg.

Aeterna will not create a custom native package manager.

## Year 1 Repository

The primary package source during Year 1 is Kali Rolling.

Aeterna-specific packages may be created where necessary.

## Future Public Release

Before public release, Aeterna will transition from the
Kali package repository to an Aeterna-controlled package repository.

The package management interface will remain APT/dpkg.

## Development Principles

1. Source and build configuration are version controlled.
2. Builds should become reproducible.
3. Generated build artifacts are not committed to Git.
4. Secrets are never committed.
5. Major architectural decisions are documented.
6. Aeterna should remain rebuildable from the repository.
7. Changes should be tested in QEMU before physical deployment
   whenever practical.
