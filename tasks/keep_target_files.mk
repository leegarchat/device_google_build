# keep_target_files.mk — persist *-target_files-*.zip after every build.
#
# WHY: `m evolution` builds the OTA package from the target-files staging
# dir ($(BUILT_TARGET_FILES_DIR)) but the `evolution` recipe itself ends
# with `rm -rf $(intermediates-dir-for,PACKAGING,target_files)`
# (vendor/lineage/build/tasks/evolution.mk), so the archive never survives.
# Offline OTA repacks (variant A: copy archive -> swap IMAGES/*.img ->
# ota_from_target_files -k releasekey) need that archive.
#
# FIX (two parts):
#  1. Force the archive to build on every OTA build (prerequisite only,
#     no recipe is overridden).
#  2. Copy it out of the intermediates dir BEFORE the `evolution` recipe
#     wipes it. The backup target is a prerequisite of the OTA package,
#     so make builds: zip -> backup copy -> OTA recipe (which then
#     deletes only the intermediates, not our copy).
#
# Result (only when _KEEP_TF_ENABLED=true):
# $(PRODUCT_OUT)/target_files_backup/<name>-target_files-*.zip (~7 GB)
# survives the build. Copy it out of out/ if you need a master archive
# (make clean / -c wipes the whole product dir).
#
# Manual gate: set to true to enable the backup, false keeps the build
# stock (no target_files archive is kept). Edit by hand when needed.
_KEEP_TF_ENABLED := false

# Included via: build/make/core/Makefile wildcard
#   $(sort $(wildcard device/*/build/tasks/*.mk))
$(info KEEP_TARGET_FILES_PACKAGE=$(BUILT_TARGET_FILES_PACKAGE) enabled=$(_KEEP_TF_ENABLED))

ifeq ($(_KEEP_TF_ENABLED),true)
ifdef INTERNAL_OTA_PACKAGE_TARGET
$(INTERNAL_OTA_PACKAGE_TARGET): $(BUILT_TARGET_FILES_PACKAGE)

_KEEP_TF_BACKUP_DIR := $(PRODUCT_OUT)/target_files_backup
_KEEP_TF_BACKUP := $(PRODUCT_OUT)/keep_target_files.stamp

$(_KEEP_TF_BACKUP): $(BUILT_TARGET_FILES_PACKAGE)
	$(call pretty,"Backing up target-files archive: $(notdir $(BUILT_TARGET_FILES_PACKAGE))")
	$(hide) mkdir -p $(_KEEP_TF_BACKUP_DIR)
	$(hide) cp $(BUILT_TARGET_FILES_PACKAGE) $(_KEEP_TF_BACKUP_DIR)/
	$(hide) touch $@

$(INTERNAL_OTA_PACKAGE_TARGET): $(_KEEP_TF_BACKUP)
endif # INTERNAL_OTA_PACKAGE_TARGET
endif # _KEEP_TF_ENABLED
