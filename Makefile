.PHONY: all fetch build iso clean distclean run help

# Monara Linux Build System
# Run targets from the monara/ directory

all: fetch build iso

fetch:
	@./scripts/fetch.sh

build:
	@./scripts/build-all.sh

iso:
	@./iso/mkiso.sh

hybrid:
	@./build-hybrid.sh

quick: all

clean:
	rm -rf cache rootfs iso/boot iso/limine.cfg
	rm -f monara-*.iso

distclean: clean
	rm -rf sources

run: monara-*.iso
	@echo "==> Booting Monara in QEMU..."
	@ISO=$$(ls monara-*.iso 2>/dev/null | head -1); \
	if [ -n "$$ISO" ]; then \
		qemu-system-x86_64 -cdrom "$$ISO" -m 256M -enable-kvm -smp 2 -serial stdio; \
	else \
		echo "No ISO found. Run 'make all' first."; \
	fi

run-nokvm: monara-*.iso
	@echo "==> Booting Monara in QEMU (no KVM)..."
	@ISO=$$(ls monara-*.iso 2>/dev/null | head -1); \
	if [ -n "$$ISO" ]; then \
		qemu-system-x86_64 -cdrom "$$ISO" -m 256M -smp 2 -serial stdio; \
	else \
		echo "No ISO found. Run 'make all' first."; \
	fi

help:
	@echo "Monara Linux Build System"
	@echo "  make fetch   - Download all source tarballs"
	@echo "  make build   - Build packages, kernel, initramfs"
	@echo "  make iso     - Create bootable ISO"
	@echo "  make run     - Boot in QEMU (with KVM)"
	@echo "  make clean   - Remove build artifacts"
	@echo ""
	@echo "CPU baseline: edit CPU_BASELINE in 'config'"
	@echo "  native      = your exact CPU (default)"
	@echo "  x86-64-v3   = Haswell+ (Clear Linux target)"
	@echo "  x86-64-v4   = Skylake-X+ (AVX-512)"
