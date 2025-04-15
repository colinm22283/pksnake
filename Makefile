export ASM=/opt/cross/bin/i686-elf-as
export ASMFLAGS=

export LD=/opt/cross/bin/i686-elf-ld
export LDFLAGS=-T$(SOURCE_DIR)/linker.ld

export INCLUDE_DIRS=$(SOURCE_DIR)/include

export BUILD_DIR=$(CURDIR)/build
export BIN_DIR=$(BUILD_DIR)/bin
export OBJ_DIR=$(BUILD_DIR)/obj
export SOURCE_DIR=$(CURDIR)/firmware
export MAKE_DIR=$(CURDIR)/make

export MAKE_SCRIPTS=$(MAKE_DIR)/targets.mk

.PHONY: $(BIN_DIR)/pksnake
$(BIN_DIR)/pksnake:
	cd firmware && $(MAKE) $(BIN_DIR)/pksnake

$(BUILD_DIR)/pksnake.img: $(BIN_DIR)/pksnake
	cat $(BIN_DIR)/pksnake > $(BUILD_DIR)/pksnake.img

.PHONY: emulate
emulate: $(BUILD_DIR)/pksnake.img
	cd $(BUILD_DIR) && qemu-system-x86_64 -no-reboot -drive file=pksnake.img,format=raw -vga std -d int -m 6G

.PHONY: emulate-debug
emulate-debug: $(BUILD_DIR)/pksnake.img
	cd $(BUILD_DIR) && qemu-system-x86_64 -no-reboot -s -S -drive file=pksnake.img,format=raw -vga std -d int -m 6G


.DEFAULT: all
.PHONY: all
all: $(BUILD_DIR)/pksnake.img

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
