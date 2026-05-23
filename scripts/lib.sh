#!/bin/bash
# Monara Linux - Shared build functions

die() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo "==> $*" >&2
}

fetch_source() {
    local url="$1"
    local dest="$SOURCES_DIR/$(basename "$url")"
    if [ ! -f "$dest" ]; then
        info "Fetching $url"
        wget -q --show-progress "$url" -O "$dest" || curl -L -o "$dest" "$url" || die "Failed to fetch $url"
    fi
}

extract_source() {
    local archive="$1"
    local dirname="$2"
    local dest="$CACHE_DIR/$dirname"
    if [ -d "$dest" ]; then
        rm -rf "$dest"
    fi
    mkdir -p "$dest"
    info "Extracting $archive"
    case "$archive" in
        *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" --strip-components=1 ;;
        *.tar.xz)       tar -xJf "$archive" -C "$dest" --strip-components=1 ;;
        *.tar.bz2)      tar -xjf "$archive" -C "$dest" --strip-components=1 ;;
        *.tar.zst)      tar -I zstd -xf "$archive" -C "$dest" --strip-components=1 ;;
        *)              die "Unknown archive format: $archive" ;;
    esac
    echo "$dest"
}

prepare_build() {
    local pkgname="$1"
    local builddir="$CACHE_DIR/$pkgname-build"
    rm -rf "$builddir"
    mkdir -p "$builddir"
    echo "$builddir"
}

run_make() {
    make "$MAKEFLAGS" "$@" || die "make failed"
}

run_configure() {
    ./configure "$@" || die "configure failed"
}

apply_overlay() {
    if [ -d "$OVERLAY_DIR" ]; then
        cp -r "$OVERLAY_DIR"/* "$ROOTFS_DIR/" 2>/dev/null || true
    fi
}

strip_rootfs() {
    info "Stripping binaries..."
    find "$ROOTFS_DIR" -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true
    find "$ROOTFS_DIR" -type f -name "*.so*" -exec strip --strip-unneeded {} \; 2>/dev/null || true
}

check_deps() {
    local missing=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Missing dependency: $cmd"
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then
        die "Install missing dependencies and try again"
    fi
}
