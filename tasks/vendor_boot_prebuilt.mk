# vendor_boot_prebuilt.mk — stock vendor_boot build + runtime OrangeFox inject.
#
# NOTE: there is NO vendor_boot.img prebuilt in the kernel dir
# (device/google/pixel-kernels/*/ has no vendor_boot.img); the image is
# always built from source by build/make/core/Makefile ("Target vendor_boot
# image" rule with mkbootimg + avbtool add_hash_footer).
#
# AOSP constraint: BUILDING_VENDOR_BOOT_IMAGE must be true when
# PRODUCT_BUILD_VENDOR_KERNEL_BOOT_IMAGE is true (board_config.mk:537).
# This makes BOARD_PREBUILT_VENDOR_BOOTIMAGE incompatible with vendor_kernel_boot.
#
# Solution: override the vendor_boot BUILD RECIPE itself.  Task files are
# included after the main Makefile, so this recipe replaces the original
# mkbootimg recipe.  Prerequisites from the original rule are still merged
# (and built), but the recipe body becomes: stock mkbootimg build ->
# bootsmasher OrangeFox patch -> avbtool add_hash_footer. The patched
# $(INSTALLED_VENDOR_BOOTIMAGE_TARGET) (out/.../vendor_boot.img) feeds
# vbmeta.img and fastboot flashing, BUT the OTA payload needs the second
# hook at the bottom of this file (_FOX_TF_STAMP): ota_from_target_files
# does NOT read out/.../vendor_boot.img, it rebuilds vendor_boot from the
# VENDOR_BOOT/ source tree inside the target-files staging dir.
#
# Layout:
#   bin/bootsmasher-host     — host x86_64 musl binary (install --file mode)
#   prebuilts/*.lz4          — recovery cpio payload (exactly one blob)
#   prebuilts/config.txt     — single line: the exact payload filename.
#     Swapping the OrangeFox blob is a data-only change, this mk is untouched.
#   touch/<codename>.lgz     — per-device touch archives, injected into the
#     recovery payload root (--inject-lgz). Missing file for the build
#     device = install without touch archive (stock touch path covers it).
#
# Included via: -include $(sort $(wildcard device/*/build/tasks/*.mk))
$(info INSTALLED_VENDOR_BOOTIMAGE_TARGET=$(INSTALLED_VENDOR_BOOTIMAGE_TARGET))

ifdef INSTALLED_VENDOR_BOOTIMAGE_TARGET

# Fox tools live under this file's dir (top-relative paths).
# The payload filename is read from prebuilts/config.txt (one line, exact
# name, no wildcard), so replacing the OrangeFox blob never edits this mk.
_FOX_DIR := device/google/build/tasks
_FOX_BIN := $(_FOX_DIR)/bin/bootsmasher-host
_FOX_LZ4_NAME := $(strip $(shell cat $(_FOX_DIR)/prebuilts/config.txt))
_FOX_PAYLOAD := $(_FOX_DIR)/prebuilts/$(_FOX_LZ4_NAME)

# Device codename for --device + touch archive lookup. lineage_*.mk sets
# DEVICE_CODENAME; fall back to parsing TARGET_PRODUCT (lineage_<dev>[-...]).
_FOX_DEVICE := $(strip $(DEVICE_CODENAME))
ifeq ($(_FOX_DEVICE),)
_FOX_DEVICE := $(strip $(firstword $(subst -, ,$(word 2,$(subst _, ,$(TARGET_PRODUCT))))))
endif
_FOX_LGZ := $(_FOX_DIR)/touch/$(_FOX_DEVICE).lgz
# --device only when we know the codename; --inject-lgz only when the
# archive exists (wildcard is empty otherwise, keeping stock touch path).
_FOX_DEV_ARGS := $(if $(_FOX_DEVICE),--device $(_FOX_DEVICE))
_FOX_LGZ_ARGS := $(if $(wildcard $(_FOX_LGZ)),--inject-lgz $(_FOX_LGZ))

# Override vendor_boot recipe: stock mkbootimg build first (same command as
# build/make/core/Makefile "Target vendor_boot image" rule), then inject
# OrangeFox recovery ramdisk via bootsmasher, then re-sign with avbtool
# (bootsmasher drops the AVB footer, so add_hash_footer must run AFTER the
# patch, with the same args as the stock rule).
# NOTE: stock prerequisites (mkbootimg inputs, dtb, ramdisk fragments,
# bootconfig, AVBTOOL) are merged from the original rule automatically;
# only the Fox tools are added here. Do NOT touch the source tree here
# (siso sandbox is read-only): read inputs, write only $@ / $@.fox / log.
ifeq ($(BOARD_AVB_ENABLE),true)
$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(_FOX_BIN) $(_FOX_PAYLOAD)
	$(call pretty,"Target vendor_boot image (OrangeFox): $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_VENDOR_BOOTIMAGE_ARGS) $(BOARD_MKBOOTIMG_ARGS) --vendor_ramdisk $(INTERNAL_VENDOR_RAMDISK_TARGET) $(INTERNAL_VENDOR_RAMDISK_FRAGMENT_ARGS) --vendor_boot $@
	$(hide) $(_FOX_BIN) install --file -i $@ -c $(_FOX_PAYLOAD) -o $@.fox --log $(PRODUCT_OUT)/fox_install.log $(_FOX_DEV_ARGS) $(_FOX_LGZ_ARGS)
	$(hide) mv $@.fox $@
	$(hide) $(call assert-max-image-size,$@,$(call get-hash-image-max-size,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE)))
	$(hide) $(AVBTOOL) add_hash_footer --image $@ \
	   $(call get-partition-size-argument,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE)) \
	   --salt $$(sha256sum $(BUILD_NUMBER_FILE) $(BUILD_DATETIME_FILE) | cut -d " " -f 1 | tr -d '\n') \
	   --partition_name vendor_boot $(INTERNAL_AVB_VENDOR_BOOT_SIGNING_ARGS) \
	   $(BOARD_AVB_VENDOR_BOOT_ADD_HASH_FOOTER_ARGS)
else
$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(_FOX_BIN) $(_FOX_PAYLOAD)
	$(call pretty,"Target vendor_boot image (OrangeFox, no AVB): $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_VENDOR_BOOTIMAGE_ARGS) $(BOARD_MKBOOTIMG_ARGS) --vendor_ramdisk $(INTERNAL_VENDOR_RAMDISK_TARGET) $(INTERNAL_VENDOR_RAMDISK_FRAGMENT_ARGS) --vendor_boot $@
	$(hide) $(_FOX_BIN) install --file -i $@ -c $(_FOX_PAYLOAD) -o $@.fox --log $(PRODUCT_OUT)/fox_install.log $(_FOX_DEV_ARGS) $(_FOX_LGZ_ARGS)
	$(hide) mv $@.fox $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE))
endif

# --- Fox target-files hook: push the patched vendor_boot into the OTA source ---
#
# WHY: out/.../vendor_boot.img (patched above) never reaches payload.bin on
# its own. The target-files recipe copies ramdisk SOURCES into
# <staging>/VENDOR_BOOT/ (build/make/core/Makefile:6838-6870) and then runs
# add_img_to_target_files (Makefile:7234-7235), which REBUILDS
# <staging>/IMAGES/vendor_boot.img from that tree: common.py GetVendorBootImage
# reuses IMAGES/ only if the file is already there, and it is NOT there
# because BOARD_PREBUILT_VENDOR_BOOTIMAGE is empty (no vendor_boot.img in
# pixel-kernels/), so the IMAGES copy at Makefile:7041-7043 is skipped.
# ota_from_target_files (via brillo_update_payload) then packs the rebuilt
# STOCK image into payload.bin, and the stock-based IMAGES/vbmeta.img with it.
# Symptom: out/.../vendor_boot.img has 2 fragments (platform+recovery/Fox),
# payload's vendor_boot has 1 stock platform fragment.
#
# FIX: after the target-files staging dir is complete, overwrite staging
# IMAGES/vendor_boot.img with the patched image, delete the stock-based
# IMAGES/vbmeta.img, and re-run add_img_to_target_files so vbmeta.img +
# META/vbmeta_digest.txt are regenerated from the patched image (care maps
# are unaffected: vendor_boot is not in PARTITIONS_WITH_CARE_MAP). Both OTA
# and target-files.zip consume the staging dir AFTER this stamp (prereq-only
# wiring below — no recipe is overridden here, prerequisites just merge).
_FOX_TF_STAGING := $(patsubst %.zip,%,$(BUILT_TARGET_FILES_PACKAGE))
_FOX_TF_STAMP := $(PRODUCT_OUT)/fox_vendor_boot_tf.stamp

$(_FOX_TF_STAMP): $(INSTALLED_VENDOR_BOOTIMAGE_TARGET) $(BUILT_TARGET_FILES_DIR)
	$(call pretty,"OrangeFox target-files inject: $(notdir $(_FOX_TF_STAGING))/IMAGES/vendor_boot.img")
	$(hide) cp $(INSTALLED_VENDOR_BOOTIMAGE_TARGET) $(_FOX_TF_STAGING)/IMAGES/vendor_boot.img
	$(hide) rm -f $(_FOX_TF_STAGING)/IMAGES/vbmeta.img
	$(hide) PATH=$(INTERNAL_USERIMAGES_BINARY_PATHS):$$PATH MKBOOTIMG=$(MKBOOTIMG) \
	    $(ADD_IMG_TO_TARGET_FILES) -a -v -p $(HOST_OUT) $(_FOX_TF_STAGING)
	$(hide) touch $@

$(BUILT_TARGET_FILES_PACKAGE): $(_FOX_TF_STAMP)
ifdef INTERNAL_OTA_PACKAGE_TARGET
$(INTERNAL_OTA_PACKAGE_TARGET): $(_FOX_TF_STAMP)
endif

endif # INSTALLED_VENDOR_BOOTIMAGE_TARGET
