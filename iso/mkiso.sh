#!/bin/bash
# Monara Linux - ISO builder with Limine bootloader
set -euo pipefail
cd "$(dirname "$0")/.."
source config
source scripts/lib.sh

ISO_DIR="$MONARA_DIR/iso"
OUTPUT="$MONARA_DIR/monara-$DISTRO_VERSION.iso"

check_deps xorriso

# ============================================================
# Download/install Limine bootloader
# ============================================================
LIMINE_DIR="$CACHE_DIR/limine"
LIMINE_BIN="$LIMINE_DIR/usr/bin/limine-bios-cd.bin"

if [ ! -f "$LIMINE_BIN" ]; then
    info "Downloading Limine bootloader..."
    mkdir -p "$LIMINE_DIR"

    # Try multiple versions
    for VER in "8.0.6" "7.15.0" "7.0.0"; do
        URL="https://github.com/limine-bootloader/limine/releases/download/v${VER}/limine-${VER}-binary.tar.gz"
        TAR="$SOURCES_DIR/limine-${VER}-binary.tar.gz"

        if [ ! -f "$TAR" ]; then
            info "  Trying Limine v${VER}..."
            if wget -q --timeout=10 "$URL" -O "$TAR" 2>/dev/null || \
               curl -sL --connect-timeout 10 "$URL" -o "$TAR" 2>/dev/null; then
                info "  Downloaded Limine v${VER}"
                tar -xzf "$TAR" -C "$LIMINE_DIR" --strip-components=1 2>/dev/null || true
                break
            fi
        fi
    done

    if [ ! -f "$LIMINE_DIR/limine-bios-cd.bin" ]; then
        die "Failed to download Limine. Try: sudo apt install limine  (or check https://github.com/limine-bootloader/limine)"
    fi
fi

# ============================================================
# Prepare ISO directory
# ============================================================
info "Preparing ISO structure..."

# Create directory layout
mkdir -p "$ISO_DIR/boot" "$ISO_DIR/EFI/BOOT"

# Copy kernel and initramfs
if [ ! -f "$ISO_DIR/boot/vmlinuz-monara" ]; then
    die "Kernel not found. Run 'make build' first"
fi
if [ ! -f "$ISO_DIR/boot/initramfs.gz" ]; then
    die "Initramfs not found. Run 'make build' first"
fi

# Copy Limine files
cp "$LIMINE_DIR/limine-bios-cd.bin" "$ISO_DIR/"
cp "$LIMINE_DIR/limine-bios.sys" "$ISO_DIR/boot/"
cp "$LIMINE_DIR/limine-uefi-cd.bin" "$ISO_DIR/"
cp "$LIMINE_DIR/BOOTX64.EFI" "$ISO_DIR/EFI/BOOT/" 2>/dev/null || true

# ============================================================
# Generate Limine config
# ============================================================
info "Creating Limine config..."

cat > "$ISO_DIR/limine.cfg" << 'LIMCFG'
# Monara Linux 0.1.0 - Limine Boot Configuration

TIMEOUT=5
DEFAULT_ENTRY=0

VERBOSE_GUI=no
BAUDRATE=115200

:Monara Linux
    PROTOCOL=linux
    KERNEL_PATH=boot()/boot/vmlinuz-monara
    MODULE_PATH=boot()/boot/initramfs.gz
    CMDLINE=root=/dev/ram0 console=tty0 console=ttyS0,115200 loglevel=3 quiet

:Monara Linux (verbose)
    PROTOCOL=linux
    KERNEL_PATH=boot()/boot/vmlinuz-monara
    MODULE_PATH=boot()/boot/initramfs.gz
    CMDLINE=root=/dev/ram0 console=tty0 loglevel=7
LIMCFG

# ============================================================
# Build ISO
# ============================================================
info "Building ISO..."

xorriso -as mkisofs \
    -b limine-bios-cd.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --efi-boot limine-uefi-cd.bin \
    -efi-boot-part \
    --efi-boot-image \
    -volume-label "MONARA" \
    -iso-level 3 \
    -graft-points \
    -output "$OUTPUT" \
    "$ISO_DIR"

# Install Limine BIOS stage to the ISO
if [ -f "$LIMINE_DIR/limine-bios-install" ]; then
    "$LIMINE_DIR/limine-bios-install" "$OUTPUT"
    info "Limine BIOS stage installed"
fi

# ============================================================
# Summary
# ============================================================
info ""
info "=== Monara Linux ISO ==="
info "  File: $OUTPUT"
info "  Size: $(ls -lh "$OUTPUT" | awk '{print $5}')"
info "  Kernel: $(ls -lh "$ISO_DIR/boot/vmlinuz-monara" | awk '{print $5}')"
info "  Initramfs: $(ls -lh "$ISO_DIR/boot/initramfs.gz" | awk '{print $5}')"
info ""
info "  Run with:"
info "    qemu-system-x86_64 -cdrom $OUTPUT -m 256M -enable-kvm -serial stdio"
info ""
