#!/bin/bash
# Monara Linux - Hybrid build (binary packages + custom kernel)
# Fast: uses Arch binary packages for base, builds only kernel from source
set -euo pipefail
cd "$(dirname "$0")/.."
source config
source scripts/lib.sh

mkdir -p "$ROOTFS_DIR" "$CACHE_DIR" "$SOURCES_DIR" "$ISO_DIR/boot"

# ============================================================
# 1. Install binary packages via pacman (much faster than source)
# ============================================================
info "Installing base binary packages..."

PAC_PACKAGES=(
    glibc gcc-libs
    busybox
    bash pacman
    openssl libarchive curl ca-certificates
    zlib bzip2 xz zstd
    ncurses readline
    util-linux
    coreutils
    grep gawk sed gzip tar
    filesystem
    shadow
    iproute2
)

# Use pacman to download and install to rootfs
sudo pacman -Sy --noconfirm --root="$ROOTFS_DIR" --cachedir=/var/cache/pacman/pkg \
    "${PAC_PACKAGES[@]}" 2>&1 | tail -20 || {
    info "pacman install had issues, trying alternative..."
    # Fallback: create minimal structure manually
    mkdir -p "$ROOTFS_DIR"/{bin,lib,usr/{bin,lib},etc,sbin,var/lib/pacman}
}

info "Binary packages installed."

# ============================================================
# 2. Strip the rootfs to the bone
# ============================================================
info "Stripping bloat..."

# Remove ALL documentation
rm -rf "$ROOTFS_DIR"/usr/share/{doc,info,man,gtk-doc,help,locale} 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/usr/share/{icons,fonts,themes,sounds} 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/usr/share/{perl5,zoneinfo,pixmaps} 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/usr/include 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/usr/lib/{cmake,pkgconfig,*.a,*.la} 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/usr/lib/python* 2>/dev/null || true
rm -rf "$ROOTFS_DIR"/var/{cache,log,lib/pacman/sync} 2>/dev/null || true

# Remove unused binaries
rm -f "$ROOTFS_DIR"/usr/bin/{perl*,python*,cpan*,sqlite3} 2>/dev/null || true
rm -f "$ROOTFS_DIR"/usr/bin/{chfn,chsh,newgrp,wall,write} 2>/dev/null || true
rm -f "$ROOTFS_DIR"/usr/bin/{pamac,traceroute,nslookup,dig,host} 2>/dev/null || true

# Strip ALL binaries
find "$ROOTFS_DIR" -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true
find "$ROOTFS_DIR" -type f -name "*.so*" -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Remove sudo and suid (we don't need it - running as root)
rm -f "$ROOTFS_DIR"/usr/bin/sudo 2>/dev/null || true
rm -f "$ROOTFS_DIR"/usr/bin/su 2>/dev/null || true

info "Stripped."

# ============================================================
# 3. Build runit from source (small, fast build)
# ============================================================
info "Building runit..."

srcdir=$(extract_source "$SOURCES_DIR/runit-$RUNIT_VERSION.tar.gz" "runit-$RUNIT_VERSION")
cd "$srcdir/admin/runit-$RUNIT_VERSION"
CC="gcc $CFLAGS" ./package/compile
mkdir -p "$ROOTFS_DIR/usr/bin"
cp command/runit "$ROOTFS_DIR/usr/bin/"
cp command/runsvdir "$ROOTFS_DIR/usr/bin/"
cp command/runsv "$ROOTFS_DIR/usr/bin/"
cp command/sv "$ROOTFS_DIR/usr/bin/"
cp command/chpst "$ROOTFS_DIR/usr/bin/"
mkdir -p "$ROOTFS_DIR/sbin"
ln -sf /usr/bin/runit "$ROOTFS_DIR/sbin/init"
rm -rf "$srcdir" "$CACHE_DIR/runit-$RUNIT_VERSION"*

info "runit built."

# ============================================================
# 4. Build Linux kernel (minimal config, ~15 min)
# ============================================================
info "Building minimal Monara kernel..."

srcdir=$(extract_source "$SOURCES_DIR/linux-$LINUX_VERSION.tar.xz" "linux-$LINUX_VERSION")
cd "$srcdir"

# Generate minimal kernel config
bash "$MONARA_DIR/configs/kernel/gen-config.sh" "$srcdir" "$srcdir/.config"

# Build kernel
run_make CC="gcc" HOSTCC="gcc" KCFLAGS="$KCFLAGS"
cp arch/x86/boot/bzImage "$ISO_DIR/boot/vmlinuz-monara"
rm -rf "$srcdir"

info "Kernel built: $(ls -lh "$ISO_DIR/boot/vmlinuz-monara" | awk '{print $5}')"

# ============================================================
# 5. Create rootfs overlay
# ============================================================
info "Applying Monara overlay..."

# Create essential dirs
for d in proc sys dev tmp run root home mnt etc/runit/runsvdir/default var/log; do
    mkdir -p "$ROOTFS_DIR/$d"
done

# Copy overlay files
cp -r "$OVERLAY_DIR"/* "$ROOTFS_DIR/" 2>/dev/null || true

# Make sure init scripts are executable
chmod +x "$ROOTFS_DIR"/etc/runit/[123] 2>/dev/null || true
chmod +x "$ROOTFS_DIR"/etc/runit/runsvdir/default/agetty-tty1/run 2>/dev/null || true
chmod +x "$ROOTFS_DIR"/etc/runit/runsvdir/default/agetty-tty1/finish 2>/dev/null || true
chmod +x "$ROOTFS_DIR"/etc/runit/runsvdir/default/agetty-tty2/run 2>/dev/null || true
chmod +x "$ROOTFS_DIR"/init 2>/dev/null || true

# Install branding
mkdir -p "$ROOTFS_DIR/usr/share/monara"
cp "$MONARA_DIR/branding/logo-wide.txt" "$ROOTFS_DIR/usr/share/monara/logo.txt"
cp "$MONARA_DIR/branding/logo-narrow.txt" "$ROOTFS_DIR/usr/share/monara/logo-narrow.txt"

# Create /etc/passwd and /etc/group (minimal)
if [ ! -f "$ROOTFS_DIR/etc/passwd" ]; then
    echo "root:x:0:0:root:/root:/bin/sh" > "$ROOTFS_DIR/etc/passwd"
fi
if [ ! -f "$ROOTFS_DIR/etc/shadow" ]; then
    echo "root::0:0:99999:7:::" > "$ROOTFS_DIR/etc/shadow"
fi
if [ ! -f "$ROOTFS_DIR/etc/group" ]; then
    echo "root:x:0:root" > "$ROOTFS_DIR/etc/group"
fi

# Create /etc/inittab for busybox init fallback
echo "::sysinit:/etc/runit/1" > "$ROOTFS_DIR/etc/inittab"
echo "::wait:/etc/runit/2" >> "$ROOTFS_DIR/etc/inittab"
echo "::ctrlaltdel:/sbin/reboot" >> "$ROOTFS_DIR/etc/inittab"
echo "::shutdown:/etc/runit/3" >> "$ROOTFS_DIR/etc/inittab"

# Strip again after overlay
strip_rootfs

# ============================================================
# 6. Build initramfs
# ============================================================
info "Building initramfs..."

initramfs_dir="$CACHE_DIR/initramfs"
rm -rf "$initramfs_dir"
cp -a "$ROOTFS_DIR" "$initramfs_dir"

cd "$initramfs_dir"
find . | cpio -o -H newc | gzip -9 > "$ISO_DIR/boot/initramfs.gz"
cd "$MONARA_DIR"

info "Initramfs: $(ls -lh "$ISO_DIR/boot/initramfs.gz" | awk '{print $5}')"

# ============================================================
# 7. Create ISO
# ============================================================
info "Building ISO..."
bash "$ISO_DIR/mkiso.sh"

info ""
info "=== DONE ==="
info "ISO: monara-$DISTRO_VERSION.iso"
info ""
