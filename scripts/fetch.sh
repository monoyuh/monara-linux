#!/bin/bash
# Monara Linux - Fetch all source tarballs
set -euo pipefail
cd "$(dirname "$0")/.."
source config
source scripts/lib.sh

mkdir -p "$SOURCES_DIR"

info "Fetching source packages..."

fetch_source "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$LINUX_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz"
fetch_source "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"
fetch_source "http://smarden.org/runit/runit-$RUNIT_VERSION.tar.gz"
fetch_source "https://github.com/facebook/zstd/releases/download/v$ZSTD_VERSION/zstd-$ZSTD_VERSION.tar.gz"
fetch_source "https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz"
fetch_source "https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VERSION.tar.gz"
fetch_source "https://tukaani.org/xz/xz-$XZ_VERSION.tar.gz"
fetch_source "https://libarchive.org/downloads/libarchive-$LIBARCHIVE_VERSION.tar.xz"
fetch_source "https://openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
fetch_source "https://curl.se/download/curl-$CURL_VERSION.tar.xz"
fetch_source "https://sources.archlinux.org/other/pacman/pacman-$PACMAN_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/make/make-$MAKE_VERSION.tar.gz"
fetch_source "https://ftp.gnu.org/gnu/bash/bash-$BASH_VERSION.tar.gz"
fetch_source "https://www.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION%.*}/util-linux-$UTIL_LINUX_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/gmp/gmp-$GMP_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/mpfr/mpfr-$MPFR_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/mpc/mpc-$MPC_VERSION.tar.gz"
fetch_source "https://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz"
fetch_source "https://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz"
fetch_source "https://pkg-config.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz"
fetch_source "https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz"
fetch_source "https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.xz"
fetch_source "https://ftp.gnu.org/gnu/texinfo/texinfo-$TEXINFO_VERSION.tar.xz"

info "All sources fetched to $SOURCES_DIR"
