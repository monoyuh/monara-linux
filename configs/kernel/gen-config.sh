#!/bin/bash
# Monara Linux - Generate minimal kernel config
# Starts from allnoconfig, enables only what's needed
set -euo pipefail

KERNEL_DIR="$1"
OUTPUT="$2"

cd "$KERNEL_DIR"

# Start with allnoconfig (everything disabled)
make allnoconfig

# ============================================================
# Architecture & Base
# ============================================================
./scripts/config --enable CONFIG_64BIT
./scripts/config --enable CONFIG_X86_64
./scripts/config --enable CONFIG_X86
./scripts/config --enable CONFIG_GENERIC_CPU
./scripts/config --enable CONFIG_SMP
./scripts/config --enable CONFIG_EMBEDDED
./scripts/config --enable CONFIG_EXPERT

# ============================================================
# Memory optimization
# ============================================================
./scripts/config --enable CONFIG_NO_HZ_IDLE
./scripts/config --enable CONFIG_HIGH_RES_TIMERS
./scripts/config --set-val CONFIG_HZ 100
./scripts/config --enable CONFIG_PREEMPT_VOLUNTARY
./scripts/config --disable CONFIG_CGROUPS
./scripts/config --disable CONFIG_NAMESPACES
./scripts/config --enable CONFIG_DEVTMPFS_MOUNT
./scripts/config --enable CONFIG_TMPFS

# ============================================================
# Enable Boot devices (SATA, NVMe, virtio)
# ============================================================
./scripts/config --enable CONFIG_PCI
./scripts/config --enable CONFIG_PCI_MSI
./scripts/config --enable CONFIG_ATA
./scripts/config --enable CONFIG_ATA_PIIX
./scripts/config --enable CONFIG_ATA_GENERIC
./scripts/config --enable CONFIG_PATA_AMD
./scripts/config --enable CONFIG_PATA_ATIIXP
./scripts/config --enable CONFIG_PATA_OLDPIIX
./scripts/config --enable CONFIG_PATA_SCH
./scripts/config --enable CONFIG_BLK_DEV_SD
./scripts/config --enable CONFIG_BLK_DEV_SR
./scripts/config --enable CONFIG_NVME_CORE
./scripts/config --enable CONFIG_BLK_DEV_NVME

# virtio (for QEMU)
./scripts/config --enable CONFIG_VIRTIO
./scripts/config --enable CONFIG_VIRTIO_PCI
./scripts/config --enable CONFIG_VIRTIO_BLK
./scripts/config --enable CONFIG_VIRTIO_NET
./scripts/config --enable CONFIG_VIRTIO_CONSOLE
./scripts/config --enable CONFIG_VIRTIO_BALLOON
./scripts/config --enable CONFIG_VIRTIO_MMIO

# ============================================================
# Filesystems
# ============================================================
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_EXT4_USE_FOR_EXT2
./scripts/config --enable CONFIG_MSDOS_FS
./scripts/config --enable CONFIG_VFAT_FS
./scripts/config --enable CONFIG_PROC_FS
./scripts/config --enable CONFIG_SYSFS
./scripts/config --enable CONFIG_TMPFS
./scripts/config --enable CONFIG_DEV_TMPFS
./scripts/config --enable CONFIG_ISO9660_FS

# ============================================================
# Networking (minimal - for pacman)
# ============================================================
./scripts/config --enable CONFIG_NET
./scripts/config --enable CONFIG_PACKET
./scripts/config --enable CONFIG_UNIX
./scripts/config --enable CONFIG_INET
./scripts/config --enable CONFIG_IPV6
./scripts/config --enable CONFIG_NETDEVICES
./scripts/config --enable CONFIG_NET_CORE
./scripts/config --enable CONFIG_E1000
./scripts/config --enable CONFIG_E1000E
./scripts/config --enable CONFIG_R8169
./scripts/config --enable CONFIG_TULIP
./scripts/config --enable CONFIG_NE2K_PCI
./scripts/config --enable CONFIG_8139TOO
./scripts/config --disable CONFIG_WIRELESS

# ============================================================
# Security (minimal)
# ============================================================
./scripts/config --disable CONFIG_SECURITY
./scripts/config --disable CONFIG_SECURITY_NETWORK
./scripts/config --disable CONFIG_SECURITY_PATH
./scripts/config --disable CONFIG_LSM_MMAP_MIN_ADDR
./scripts/config --disable CONFIG_SECURITY_SELINUX
./scripts/config --disable CONFIG_SECURITY_APPARMOR
./scripts/config --disable CONFIG_SECURITY_YAMA
./scripts/config --disable CONFIG_SECURITY_LOADPIN

# ============================================================
# Disable bloat (keep essentials: BUG, PRINTK)
# ============================================================
./scripts/config --disable CONFIG_FTRACE
./scripts/config --disable CONFIG_TRACING
./scripts/config --disable CONFIG_DEBUG_KERNEL
./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --disable CONFIG_KALLSYMS
./scripts/config --enable CONFIG_BUG
./scripts/config --enable CONFIG_PRINTK
./scripts/config --enable CONFIG_PRINTK_SAFE_LOG_BUF_SHIFT 12
./scripts/config --disable CONFIG_MAGIC_SYSRQ
./scripts/config --enable CONFIG_NLS
./scripts/config --disable CONFIG_CRYPTO_MANAGER_DISABLE_TESTS

# ============================================================
# EFI support (for direct boot)
# ============================================================
./scripts/config --enable CONFIG_EFI
./scripts/config --enable CONFIG_EFI_STUB
./scripts/config --enable CONFIG_EFI_MIXED
./scripts/config --enable CONFIG_EFI_PARTITION

# ============================================================
# Module support (disabled - build everything in)
# ============================================================
./scripts/config --disable CONFIG_MODULES
./scripts/config --disable CONFIG_MODULE_SIG

# ============================================================
# Built-in initramfs
# ============================================================
./scripts/config --enable CONFIG_BLK_DEV_INITRD
./scripts/config --enable CONFIG_RD_GZIP
./scripts/config --disable CONFIG_RD_BZIP2
./scripts/config --disable CONFIG_RD_LZMA
./scripts/config --disable CONFIG_RD_XZ
./scripts/config --disable CONFIG_RD_LZO
./scripts/config --disable CONFIG_RD_LZ4
./scripts/config --disable CONFIG_RD_ZSTD

# ============================================================
# Console support
# ============================================================
./scripts/config --enable CONFIG_VT
./scripts/config --enable CONFIG_VT_CONSOLE
./scripts/config --enable CONFIG_HW_CONSOLE
./scripts/config --enable CONFIG_SERIAL_8250
./scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
./scripts/config --enable CONFIG_SERIAL_CORE
./scripts/config --enable CONFIG_SERIAL_CORE_CONSOLE

# ============================================================
# Compression & optimization
# ============================================================
./scripts/config --enable CONFIG_KERNEL_GZIP
./scripts/config --enable CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE

# Finalize
make olddefconfig
cp .config "$OUTPUT"

echo "Kernel config generated: $OUTPUT"
wc -l "$OUTPUT"
