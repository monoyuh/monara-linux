#!/bin/bash
# Monara Linux - Build all packages (complete)
set -euo pipefail
cd "$(dirname "$0")/.."
source config
source scripts/lib.sh

check_deps wget curl tar gcc make patch

mkdir -p "$ROOTFS_DIR" "$SOURCES_DIR" "$CACHE_DIR"
build_dir="$CACHE_DIR"

build_step() {
    echo ""
    echo "=============================================="
    echo "  Building: $1"
    echo "=============================================="
}

# ============================================================
# 1. Linux Headers
# ============================================================
build_step "linux-headers"
srcdir=$(extract_source "$SOURCES_DIR/linux-$LINUX_VERSION.tar.xz" "linux-$LINUX_VERSION")
cd "$srcdir"
make mrproper
make headers_install ARCH="$ARCH" INSTALL_HDR_PATH="$ROOTFS_DIR/usr"
rm -rf "$srcdir"

# ============================================================
# 2. glibc
# ============================================================
build_step "glibc"
srcdir=$(extract_source "$SOURCES_DIR/glibc-$GLIBC_VERSION.tar.xz" "glibc-$GLIBC_VERSION")
builddir="$build_dir/glibc-build"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"
echo "libc_cv_slibdir=/usr/lib" > config.cache
CC="gcc $CFLAGS" CXX="g++ $CXXFLAGS" \
    "$srcdir/configure" \
    --prefix=/usr \
    --libdir=/usr/lib \
    --libexecdir=/usr/lib \
    --sysconfdir=/etc \
    --enable-kernel=4.15 \
    --enable-stack-protector=strong \
    --disable-werror \
    --disable-profile \
    --enable-bind-now \
    --disable-nls \
    --cache-file=config.cache
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir" "$builddir"

# ============================================================
# 3. zlib
# ============================================================
build_step "zlib"
srcdir=$(extract_source "$SOURCES_DIR/zlib-$ZLIB_VERSION.tar.gz" "zlib-$ZLIB_VERSION")
cd "$srcdir"
CFLAGS="$CFLAGS" ./configure --prefix=/usr --libdir=/usr/lib
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 4. bzip2
# ============================================================
build_step "bzip2"
srcdir=$(extract_source "$SOURCES_DIR/bzip2-$BZIP2_VERSION.tar.gz" "bzip2-$BZIP2_VERSION")
cd "$srcdir"
run_make CFLAGS="$CFLAGS -fPIC" PREFIX=/usr
run_make install PREFIX=/usr DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 5. xz
# ============================================================
build_step "xz"
srcdir=$(extract_source "$SOURCES_DIR/xz-$XZ_VERSION.tar.xz" "xz-$XZ_VERSION")
builddir="$build_dir/xz-build"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"
CC="gcc $CFLAGS" "$srcdir/configure" --prefix=/usr --libdir=/usr/lib --disable-static
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir" "$builddir"

# ============================================================
# 6. zstd
# ============================================================
build_step "zstd"
srcdir=$(extract_source "$SOURCES_DIR/zstd-$ZSTD_VERSION.tar.gz" "zstd-$ZSTD_VERSION")
cd "$srcdir"
run_make CFLAGS="$CFLAGS" PREFIX=/usr libdir=/usr/lib
run_make install PREFIX=/usr libdir=/usr/lib DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 7. ncurses
# ============================================================
build_step "ncurses"
srcdir=$(extract_source "$SOURCES_DIR/ncurses-$NCURSES_VERSION.tar.gz" "ncurses-$NCURSES_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --with-shared \
    --without-debug \
    --without-normal \
    --enable-widec \
    --without-ada \
    --without-tests
run_make
run_make install DESTDIR="$ROOTFS_DIR"
cd "$ROOTFS_DIR/usr/lib"
for lib in ncurses form panel menu; do
    [ -f "lib${lib}w.so" ] && ln -sf "lib${lib}w.so" "lib${lib}.so" 2>/dev/null || true
done
rm -rf "$srcdir"

# ============================================================
# 8. readline
# ============================================================
build_step "readline"
srcdir=$(extract_source "$SOURCES_DIR/readline-$READLINE_VERSION.tar.gz" "readline-$READLINE_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure --prefix=/usr --libdir=/usr/lib --disable-static
run_make SHLIB_LIBS="-lncursesw"
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 9. libffi
# ============================================================
build_step "libffi"
srcdir=$(extract_source "$SOURCES_DIR/libffi-$LIBFFI_VERSION.tar.gz" "libffi-$LIBFFI_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure --prefix=/usr --libdir=/usr/lib --disable-static
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 10. OpenSSL
# ============================================================
build_step "openssl"
srcdir=$(extract_source "$SOURCES_DIR/openssl-$OPENSSL_VERSION.tar.gz" "openssl-$OPENSSL_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./Configure \
    linux-x86_64 \
    --prefix=/usr \
    --libdir=/usr/lib \
    --openssldir=/etc/ssl \
    no-ssl3 \
    no-tests \
    no-docs \
    shared
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 11. libarchive
# ============================================================
build_step "libarchive"
srcdir=$(extract_source "$SOURCES_DIR/libarchive-$LIBARCHIVE_VERSION.tar.xz" "libarchive-$LIBARCHIVE_VERSION")
builddir="$build_dir/libarchive-build"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"
CC="gcc $CFLAGS" "$srcdir/configure" \
    --prefix=/usr \
    --libdir=/usr/lib \
    --without-xml2 \
    --without-lzma \
    --without-lz4 \
    --without-zstd \
    --disable-static
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir" "$builddir"

# ============================================================
# 12. curl
# ============================================================
build_step "curl"
srcdir=$(extract_source "$SOURCES_DIR/curl-$CURL_VERSION.tar.xz" "curl-$CURL_VERSION")
builddir="$build_dir/curl-build"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"
CC="gcc $CFLAGS" "$srcdir/configure" \
    --prefix=/usr \
    --libdir=/usr/lib \
    --disable-static \
    --with-openssl \
    --without-ca-bundle \
    --without-ca-path \
    --disable-dict \
    --disable-gopher \
    --disable-imap \
    --disable-pop3 \
    --disable-smtp \
    --disable-telnet \
    --disable-tftp \
    --disable-rtsp \
    --disable-ldap
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir" "$builddir"

# ============================================================
# 13. bash
# ============================================================
build_step "bash"
srcdir=$(extract_source "$SOURCES_DIR/bash-$BASH_VERSION.tar.gz" "bash-$BASH_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --without-bash-malloc \
    --disable-nls
run_make
run_make install DESTDIR="$ROOTFS_DIR"
ln -sf bash "$ROOTFS_DIR/bin/sh"
rm -rf "$srcdir"

# ============================================================
# 14. make
# ============================================================
build_step "make"
srcdir=$(extract_source "$SOURCES_DIR/make-$MAKE_VERSION.tar.gz" "make-$MAKE_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure --prefix=/usr --libdir=/usr/lib --disable-nls
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 15. pkg-config
# ============================================================
build_step "pkg-config"
srcdir=$(extract_source "$SOURCES_DIR/pkg-config-$PKG_CONFIG_VERSION.tar.gz" "pkg-config-$PKG_CONFIG_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --disable-static \
    --with-internal-glib
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 16. busybox
# ============================================================
build_step "busybox"
srcdir=$(extract_source "$SOURCES_DIR/busybox-$BUSYBOX_VERSION.tar.bz2" "busybox-$BUSYBOX_VERSION")
cd "$srcdir"
# Use defconfig then customize
make defconfig
# Enable specific applets we need
./scripts/config --enable CONTAINER
./scripts/config --enable FEATURE_PREFER_APPLETS
./scripts/config --enable SH_IS_ASH
./scripts/config --enable ASH
./scripts/config --enable FEATURE_SH_STANDALONE
./scripts/config --enable CTTYHACK
# Networking tools
./scripts/config --enable IP
./scripts/config --enable FEATURE_IP_LINK
./scripts/config --enable FEATURE_IP_ROUTE
./scripts/config --enable PING
./scripts/config --enable WGET
./scripts/config --enable FEATURE_WGET_LONG_OPTIONS
./scripts/config --enable FEATURE_WGET_STATUSBAR
./scripts/config --enable TELNET
./scripts/config --enable NC
./scripts/config --enable IFUPDOWN
./scripts/config --enable IFUP
./scripts/config --enable IFDOWN
# Process management
./scripts/config --enable PS
./scripts/config --enable TOP
./scripts/config --enable KILL
./scripts/config --enable KILLALL
./scripts/config --enable PKILL
./scripts/config --enable GREP
./scripts/config --enable EGREP
./scripts/config --enable FGREP
./scripts/config --enable FIND
./scripts/config --enable XARGS
./scripts/config --enable SED
./scripts/config --enable AWK
./scripts/config --enable CUT
./scripts/config --enable SORT
./scripts/config --enable UNIQ
./scripts/config --enable WC
./scripts/config --enable HEAD
./scripts/config --enable TAIL
./scripts/config --enable TEE
./scripts/config --enable DIFF
./scripts/config --enable PATCH
# Compression
./scripts/config --enable GZIP
./scripts/config --enable GUNZIP
./scripts/config --enable BZIP2
./scripts/config --enable BUNZIP2
./scripts/config --enable XZ
./scripts/config --enable UNXZ
./scripts/config --enable TAR
./scripts/config --enable UNZIP
./scripts/config --enable CPIO
# Editors
./scripts/config --enable VI
# File utils
./scripts/config --enable CP
./scripts/config --enable MV
./scripts/config --enable RM
./scripts/config --enable MKDIR
./scripts/config --enable RMDIR
./scripts/config --enable LN
./scripts/config --enable LS
./scripts/config --enable CAT
./scripts/config --enable MORE
./scripts/config --enable LESS
./scripts/config --enable CHMOD
./scripts/config --enable CHOWN
./scripts/config --enable MOUNT
./scripts/config --enable UMOUNT
./scripts/config --enable DD
./scripts/config --enable DF
./scripts/config --enable DU
./scripts/config --enable STAT
./scripts/config --enable TOUCH
./scripts/config --enable MKNOD
./scripts/config --enable CHROOT
./scripts/config --enable SWITCH_ROOT
# System utils
./scripts/config --enable HOSTNAME
./scripts/config --enable DMESG
./scripts/config --enable CLEAR
./scripts/config --enable RESET
./scripts/config --enable STTY
./scripts/config --enable UPTIME
./scripts/config --enable BZERO
./scripts/config --enable MD5SUM
./scripts/config --enable SHA1SUM
./scripts/config --enable SHA256SUM
./scripts/config --enable SHA512SUM
./scripts/config --enable PRINTENV
./scripts/config --enable SETARCH
# Logins and users
./scripts/config --enable LOGIN
./scripts/config --enable PASSWD
./scripts/config --enable ADDUSER
./scripts/config --enable ADDGROUP
./scripts/config --enable SU
./scripts/config --enable GETTY
./scripts/config --enable LOGNAME
./scripts/config --enable WHOAMI
./scripts/config --enable ID
# Core utilities
./scripts/config --enable DIRNAME
./scripts/config --enable BASENAME
./scripts/config --enable ECHO
./scripts/config --enable TRUE
./scripts/config --enable FALSE
./scripts/config --enable SLEEP
./scripts/config --enable SEQ
./scripts/config --enable YES
./scripts/config --enable WHICH
./scripts/config --enable TEST
./scripts/config --enable TR
./scripts/config --enable EXPR
./scripts/config --enable CAL
./scripts/config --enable DATE
./scripts/config --enable ENV
./scripts/config --enable NOHUP
./scripts/config --enable TIMEOUT
./scripts/config --enable UNAME
./scripts/config --enable USLEEP
./scripts/config --enable FOLD
./scripts/config --enable HEXDUMP
./scripts/config --enable OD
# DHCP client for tethering
./scripts/config --enable UDHCPC
./scripts/config --enable FEATURE_UDHCPC_ARPING
./scripts/config --enable FEATURE_UDHCPC_SANITIZEOPT
# Networking tools
./scripts/config --enable IFCONFIG
./scripts/config --enable FEATURE_IFCONFIG_STATUS
./scripts/config --enable ROUTE
# USB info
./scripts/config --enable LSUSB

# Disable unused protocol support in networking
./scripts/config --disable FTPGET
./scripts/config --disable FTPPUT
./scripts/config --disable TELNETD
./scripts/config --disable HTTPD
# Build busybox
CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" run_make CC="gcc"
run_make install CONFIG_PREFIX="$ROOTFS_DIR"
# Create link for init
ln -sf /bin/busybox "$ROOTFS_DIR/sbin/init" 2>/dev/null || true
rm -rf "$srcdir"

# ============================================================
# 17. runit
# ============================================================
build_step "runit"
srcdir=$(extract_source "$SOURCES_DIR/runit-$RUNIT_VERSION.tar.gz" "runit-$RUNIT_VERSION")
cd "$srcdir/admin/runit-$RUNIT_VERSION"
CC="gcc $CFLAGS" ./package/compile
mkdir -p "$ROOTFS_DIR/usr/bin" "$ROOTFS_DIR/usr/share/man/man8"
cp command/* "$ROOTFS_DIR/usr/bin/"
cp man/*.8 "$ROOTFS_DIR/usr/share/man/man8/" 2>/dev/null || true
# Create symlink from /sbin/init to runit (the init program, not runsvdir)
mkdir -p "$ROOTFS_DIR/sbin"
ln -sf /usr/bin/runit "$ROOTFS_DIR/sbin/init" 2>/dev/null || true
rm -rf "$srcdir"

# ============================================================
# 18. pacman
# ============================================================
build_step "pacman"
srcdir=$(extract_source "$SOURCES_DIR/pacman-$PACMAN_VERSION.tar.xz" "pacman-$PACMAN_VERSION")
builddir="$build_dir/pacman-build"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"
export PKG_CONFIG_LIBDIR="$ROOTFS_DIR/usr/lib/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$ROOTFS_DIR"
export CFLAGS="$CFLAGS -I$ROOTFS_DIR/usr/include"
export LDFLAGS="$LDFLAGS -L$ROOTFS_DIR/usr/lib"
export LD_LIBRARY_PATH="$ROOTFS_DIR/usr/lib:$LD_LIBRARY_PATH"
CC="gcc $CFLAGS" "$srcdir/configure" \
    --prefix=/usr \
    --libdir=/usr/lib \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --with-libcurl \
    --disable-doc \
    --without-gpgme
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir" "$builddir"

# ============================================================
# 19. util-linux (minimal)
# ============================================================
build_step "util-linux"
srcdir=$(extract_source "$SOURCES_DIR/util-linux-$UTIL_LINUX_VERSION.tar.xz" "util-linux-$UTIL_LINUX_VERSION")
cd "$srcdir"
CC="gcc $CFLAGS" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --disable-static \
    --disable-nls \
    --without-python \
    --without-systemd \
    --disable-all-programs \
    --enable-mount \
    --enable-libmount \
    --enable-losetup
run_make
run_make install DESTDIR="$ROOTFS_DIR"
rm -rf "$srcdir"

# ============================================================
# 20. Linux Kernel
# ============================================================
build_step "linux-kernel"
srcdir=$(extract_source "$SOURCES_DIR/linux-$LINUX_VERSION.tar.xz" "linux-$LINUX_VERSION")
cd "$srcdir"
# Generate minimal config
bash "$MONARA_DIR/configs/kernel/gen-config.sh" "$srcdir" "$srcdir/.config"
# Apply Monara version
sed -i "s/^EXTRAVERSION =.*/EXTRAVERSION = -monara-$DISTRO_VERSION/" Makefile
# Build kernel (with -O3 via KCFLAGS for Clear Linux style)
run_make CC="gcc" HOSTCC="gcc" KCFLAGS="$KCFLAGS"
# Install kernel and modules
cp arch/x86/boot/bzImage "$ROOTFS_DIR/boot/vmlinuz-monara"
# Install modules only if they exist
if [ -f "modules.order" ]; then
    run_make modules_install INSTALL_MOD_PATH="$ROOTFS_DIR" 2>/dev/null || true
fi
rm -rf "$srcdir"

# ============================================================
# Finalize: create overlay, essential dirs, strip
# ============================================================
build_step "finalizing rootfs"

# Essential directories
for d in proc sys dev tmp run root home var/log var/cache/pacman/pkg var/lib/pacman mnt usr/share/monara; do
    mkdir -p "$ROOTFS_DIR/$d"
done

# Install branding
cp "$MONARA_DIR/branding/logo-wide.txt" "$ROOTFS_DIR/usr/share/monara/logo.txt"
cp "$MONARA_DIR/branding/logo-narrow.txt" "$ROOTFS_DIR/usr/share/monara/logo-narrow.txt"

# Apply overlay files
apply_overlay

# Make init scripts executable
chmod +x "$ROOTFS_DIR/etc/runit/1" "$ROOTFS_DIR/etc/runit/2" "$ROOTFS_DIR/etc/runit/3"
chmod +x "$ROOTFS_DIR/etc/runit/runsvdir/default/agetty-tty1/run"
chmod +x "$ROOTFS_DIR/etc/runit/runsvdir/default/agetty-tty2/run"
chmod +x "$ROOTFS_DIR/etc/runit/runsvdir/default/agetty-tty1/finish"

# Create initramfs init
chmod +x "$ROOTFS_DIR/init"

# Set root password (blank for now)
sed -i 's/root:.*/root::0:0:99999:7:::/' "$ROOTFS_DIR/etc/passwd" 2>/dev/null || true

# Create /etc/passwd if missing
if [ ! -f "$ROOTFS_DIR/etc/passwd" ]; then
    echo "root:x:0:0:root:/root:/bin/sh" > "$ROOTFS_DIR/etc/passwd"
    echo "root::0:0:99999:7:::" > "$ROOTFS_DIR/etc/shadow"
fi

# Create /etc/group
echo "root:x:0:root" > "$ROOTFS_DIR/etc/group"

# Strip everything
strip_rootfs

# === Build initramfs ===
build_step "building initramfs"
initramfs_dir="$build_dir/initramfs"
rm -rf "$initramfs_dir"
cp -r "$ROOTFS_DIR" "$initramfs_dir"
# Remove kernel from initramfs (keeps it smaller)
rm -f "$initramfs_dir/boot/vmlinuz-monara" 2>/dev/null || true
rm -rf "$initramfs_dir/lib/modules" 2>/dev/null || true
cd "$initramfs_dir"
find . | cpio -o -H newc -R root:root | gzip -9 > "$MONARA_DIR/iso/boot/initramfs.gz"
cd "$MONARA_DIR"
echo "Initramfs: $(ls -lh iso/boot/initramfs.gz | awk '{print $5}')"

# Copy kernel to ISO dir
cp "$ROOTFS_DIR/boot/vmlinuz-monara" "$MONARA_DIR/iso/boot/vmlinuz-monara"

info ""
info "=== Monara rootfs built ==="
info "Rootfs: $(du -sh "$ROOTFS_DIR" | cut -f1)"
info "Kernel: $(ls -lh "$MONARA_DIR/iso/boot/vmlinuz-monara" | awk '{print $5}')"
info "Initramfs: $(ls -lh "$MONARA_DIR/iso/boot/initramfs.gz" | awk '{print $5}')"
info ""
