# Injecting a recovery (cpio.lz4) into vendor_boot via bootsmasher and build tasks

## What this is

The `device/google/build/tasks/` directory contains TWO hooks into the
`vendor_boot.img` build:

1. **Image hook**: the stock image assembled from source by `mkbootimg`
   is patched on the fly by the `bootsmasher-host` binary, which swaps the
   recovery ramdisk for a ready-made `cpio.lz4` payload (OrangeFox), after which
   the image is re-signed with `avbtool`. This yields `out/…/vendor_boot.img`
   with Fox.
2. **Target-files hook** (stamp `fox_vendor_boot_tf.stamp` in the same `.mk`):
   the patched image is pushed into the target-files staging dir
   (`IMAGES/vendor_boot.img`), from where `target-files.zip` and the OTA
   (`payload.bin`) pick it up. Without it, stock ends up in the payload —
   see "Why the second hook is needed".

## Files

| File | Purpose |
|---|---|
| `vendor_boot_prebuilt.mk` | The active hook: overrides the `$(INSTALLED_VENDOR_BOOTIMAGE_TARGET)` recipe |
| `bin/bootsmasher-host` | Host binary (Linux x86_64, musl-static, small profile: `vboot` + `install` only), `+x` bit already set |
| `prebuilts/*.lz4` | Payload: ready-made recovery ramdisk in `lz4-legacy` (exactly one blob) |
| `prebuilts/config.txt` | Single line: the exact payload filename. The `.mk` reads it itself, no `.mk` edit when swapping the blob |

## vendor_boot build chain (shiba / zuma)

1. `device/google/shusky/device-shiba.mk` sets `TARGET_KERNEL_DIR`
   (`device/google/pixel-kernels/shiba_cp2a_005` or `TARGET_KERNEL_DIR_EXT`),
   `device/google/zuma/common.mk:275` sets
   `PRODUCT_BUILD_VENDOR_KERNEL_BOOT_IMAGE=true`.
2. `build/make/core/board_config.mk` raises `BUILDING_VENDOR_BOOT_IMAGE=true`
   (header v4, `BoardConfig-common.mk:220-221`).
3. The single build rule is `build/make/core/Makefile:1748-1767`
   ("Target vendor_boot image"): `mkbootimg … --vendor_boot $@`, then
   `assert-max-image-size`, then `avbtool add_hash_footer --image $@
   --partition_size 0x04000000 --salt sha256(BUILD_NUMBER+BUILD_DATETIME)
   --partition_name vendor_boot … --prop com.android.build.vendor_boot.fingerprint:…`.
   Note: zuma defines no `BOARD_AVB_VENDOR_BOOT_KEY_PATH/ALGORITHM`, so this is
   a **keyless hash-footer** (`INTERNAL_AVB_VENDOR_BOOT_SIGNING_ARGS` is empty)
   and the image descriptor is copied into `vbmeta.img`
   (`--include_descriptors_from_image`).
4. From here the paths diverge — this is the key point:
   - `out/…/vendor_boot.img` (patched by hook #1) feeds `vbmeta.img` at make
     time (descriptor via `images-for-partitions`) and fastboot flashing;
   - but `target-files.zip` / OTA / `payload.bin` are NOT built from it —
     they are built from the target-files staging dir (see next section).

## Why the second hook is needed (out vs payload divergence)

The symptom as caught: `out/…/vendor_boot.img` has 2 fragments
(platform + recovery/Fox, `RAMDISK_SZ 30702812`), while the `vendor_boot`
extracted from the final `EvolutionX-*.zip`'s `payload.bin` has 1 stock
fragment (`RAMDISK_SZ 22561178`). No phantom — these are two different images
from two different sources.

Mechanics (`build/make/core/Makefile`):

1. The target-files recipe copies ramdisk SOURCES into the staging
   `$(zip_root)/VENDOR_BOOT/` tree (`Makefile:6838-6870`: `RAMDISK/`, `dtb`,
   `vendor_bootconfig`, `base`, `pagesize`, `vendor_cmdline`, fragments).
2. The same recipe runs `add_img_to_target_files.py -a … $(zip_root)`
   (`Makefile:7234-7235`), which **rebuilds** `IMAGES/vendor_boot.img` from
   that tree: `common.py:GetVendorBootImage` reuses `IMAGES/` only if the file
   is already there, and it is NOT there — `BOARD_PREBUILT_VENDOR_BOOTIMAGE`
   is empty (no `vendor_boot.img` in `pixel-kernels/`), so the `INSTALLED_… →
   IMAGES/` copy (`Makefile:7041-7043`) is skipped. `AddVBMeta` likewise drops
   a stock-based `vbmeta.img` (descriptor of the stock image) next to it.
3. `ota_from_target_files` (`build-ota-package-target`, `Makefile:7317-7327`)
   reads the staging directory (`$(patsubst %.zip,%,$(BUILT_TARGET_FILES_PACKAGE))`,
   NOT `out/…/vendor_boot.img`) and `brillo_update_payload` packs the stock
   image into `payload.bin`. The final `EvolutionX-*.zip` is just the renamed
   OTA package (`vendor/lineage/build/tasks/evolution.mk:23-24`).

The second hook in `vendor_boot_prebuilt.mk` (stamp `_FOX_TF_STAMP` =
`$(PRODUCT_OUT)/fox_vendor_boot_tf.stamp`) fixes this once staging is complete:

```make
cp <patched vendor_boot.img> <staging>/IMAGES/vendor_boot.img  # over stock
rm -f <staging>/IMAGES/vbmeta.img                               # drop stock descriptor
add_img_to_target_files -a -v -p $(HOST_OUT) <staging>          # regen vbmeta+digest from patched
```

On re-run, `add_img` sees the ready `IMAGES/vendor_boot.img` ("using prebuilt")
and keeps ours, while the missing `vbmeta.img` is rebuilt (`BuildVBMeta`) with
the patched image's descriptor; `META/vbmeta_digest.txt` is rewritten. Care
maps are untouched: `vendor_boot` is not in `PARTITIONS_WITH_CARE_MAP`.
Wiring is prerequisite-only (`$(BUILT_TARGET_FILES_PACKAGE): $(_FOX_TF_STAMP)`
and `$(INTERNAL_OTA_PACKAGE_TARGET): $(_FOX_TF_STAMP)`) — no recipe is
overridden, so ordering is guaranteed: staging → stamp → zip/OTA. Paths in the
`.list` file don't change (same names), so `target-files.zip` stays consistent
too.

## Why the stock hooks don't work

- `BOARD_PREBUILT_VENDOR_BOOTIMAGE` is incompatible with `vendor_kernel_boot`
  (`board_config.mk` requires `BUILDING_VENDOR_BOOT_IMAGE=true`), and there is
  no ready-made `vendor_boot.img` in `pixel-kernels/` anyway — the image is
  always built from source. (Historically a plain-`cp`-prebuilt variant lived
  here behind a `wildcard`; with no file present the `wildcard` is empty and the
  block was **silently skipped**, so `out/` got a stock image with no Fox —
  exactly how it was caught.)
- `BOARD_CUSTOM_BOOTIMG_MK` covers only `boot`/`recovery`, not `vendor_boot`.
- There are no dedicated post-hooks for `vendor_boot` in Soong/Make.

## How the override works

`device/*/build/tasks/*.mk` files are included at the very end of the main
Makefile (`build/make/core/Makefile`, `task_makefiles` section, via `sort()`),
so the recipe in `vendor_boot_prebuilt.mk` **replaces** the stock one (last
recipe wins under GNU make rules), while the prerequisites of both rules are
**merged** (ramdisk sources, dtb, fragments, bootconfig are still built).

Our recipe repeats the stock one verbatim and inserts the patch between
`mkbootimg` and the size check / signing:

```make
$(MKBOOTIMG) … --vendor_boot $@                    # 1. stock build
$(_FOX_BIN) install --file -i $@ -c $(_FOX_PAYLOAD) -o $@.fox --log …  # 2. inject
mv $@.fox $@                                       # 3. (in==out is forbidden)
assert-max-image-size                              # 4. size check
avbtool add_hash_footer …                          # 5. re-sign
```

`$(_FOX_BIN)` and `$(_FOX_PAYLOAD)` are added as target prerequisites —
otherwise the siso sandbox would not stage them at the execution site.

## What bootsmasher does

`bootsmasher-host install --file -i IN -c PAYLOAD.lz4 -o OUT --log …`
(pure offline mode, no fastboot/adb/`export.txt`):

1. `verify(in)` — parses the `VNDRBOOT` v3/v4: table sum vs
   `header.ramdisk_size`, offset chain, decompress + cpio check of every
   fragment, DTB walk.
2. `rebuild` — a new ramdisk set: `platform` = only `first_stage_ramdisk/**`
   from stock + `recovery` = the Fox payload (minus first-stage duplicates) +
   `dlkm` = original verbatim + the rest carried over verbatim. Fresh fragments
   are `marker-free LZ4-legacy`, the table is rewritten, `DTB/bootconfig/flags/
   cmdline` are preserved. The `vbmeta/AVB/padding` tail is **dropped**
   (`drop_footer=true`).
3. `verify(out)` in memory — only then is anything written. Any error exits
   with code 2 and fails the build loudly; no broken image is produced.

A raw `cpio` payload gets compressed automatically; an already compressed
`lz4-legacy` payload (our case) passes through verbatim. Re-running on an
already patched image is content-idempotent.

## Why re-signing is mandatory

After step 2 the image has no AVB footer. Without `add_hash_footer` using the
same arguments as stock (partition size, `--salt`, `--partition_name
vendor_boot`, fingerprint prop), `vbmeta.img` would capture a wrong descriptor
and `validate_target_files` plus on-device AVB verification would disagree.
Same key as stock: for zuma/shiba that means no `--key` (see section 3).

## Sandbox constraints (important!)

Sources under siso are **read-only**:

- no `chmod`/`touch`/`mv` on anything in the tree — inputs are read-only;
  only `$@`, `$@.fox` and the `$(PRODUCT_OUT)/fox_install.log` log may be written;
- the `+x` bit on `bootsmasher-host` must be set in advance (git preserves it);
  the recipe does not fix it up.

Violations fail the build with `Read-only file system` (already seen once).

## Size policy

Partition `BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE=0x04000000` (64 MiB).
`assert-max-image-size` with `get-hash-image-max-size` reserves room for the
AVB footer; on top of that we keep the on-device installer's policy of ~7 MiB
free minimum (`MIN_FREE_MB` in `export.txt`). Data point for test6: ~29–30 MB
out for ~21.5 MB of stock input ramdisk — about 34 MB headroom.

## Verifying success

1. `out/target/product/shiba/` contains `fox_install.log` (`RESULT: OK`,
   `2 fragments`).
2. `bootsmasher-host vboot --verify out/…/vendor_boot.img` — 2 fragments,
   both `valid=yes`.
3. Reference `magiskboot unpack` output of a good build:

```
RAMDISK_SZ      [30702812]
VND_RAMDISK     name=[] type=[platform] size=[3861505] fmt=[lz4_legacy]
VND_RAMDISK     name=[recovery] type=[recovery] size=[26841307] fmt=[lz4_legacy]
VBMETA
```

4. After unpacking, `vendor_ramdisk/ramdisk.cpio` (platform) sits next to
   `vendor_ramdisk/recovery.cpio` (Fox; contains `lgz_cluster.lgz`).
   `find | grep twrp` at the platform fragment root finds nothing — and should
   not: Fox lives in the separate `recovery` fragment.
5. **Mandatory: verify the payload.** Extract `vendor_boot` from the final
   `EvolutionX-*.zip` (`payload-dumper-go -p vendor_boot …`) and run
   `magiskboot unpack`: expect the same 2 fragments, `RAMDISK_SZ 30702812`.
   One fragment / `RAMDISK_SZ ~22561178` means stock went into the payload
   (see "Why the second hook is needed"): check that
   `out/…/fox_vendor_boot_tf.stamp` was created and OTA depends on it.
6. AVB consistency: `avbtool verify_image --image IMAGES/vbmeta.img`
   from staging (or `validate_target_files.py`) — the `vendor_boot`
   descriptor must match the patched image.

## Maintenance

- **New payload**: drop the `*.lz4` into `prebuilts/` (remove the old one, there
  must be exactly one blob) and write its exact name into
  `prebuilts/config.txt`. The name is exact, no `wildcard` — a typo stops
  the build at kati stage (`no rule to make target`) instead of silently
  producing stock. The `.mk` stays untouched.
- **New binary**: replace `bin/bootsmasher-host`
  (`dist/bootsmasher-small-linux-x86_64`), keep `+x`.
- **Stock changed** (new `mkbootimg` flags upstream): diff the recipe against
  `build/make/core/Makefile` ("Target vendor_boot image").
- **Rollback**: delete/rename the `.mk` (the `*.mk` glob will miss it) — a
  clean stock image builds.
- The `fox_vendor_boot_tf.stamp` is recreated automatically when the image or
  staging changes (make dependencies); no manual cleanup needed.

## Consequences

- Every build of `shiba` (or any product sharing this tasks directory) ships
  OrangeFox in both `vendor_boot` slots out of the box: both `out/…/vendor_boot.img`
  (hook #1) and `payload.bin` (hook #2 in the target-files staging) carry the
  same patched image — no separate recovery flashing step needed.
- The AVB chain stays consistent: footer re-created, the `vbmeta` descriptor
  captured from the already-patched image, fingerprint prop current. No extra
  `target-files`/`sign_target_files_apks` re-signing for `vendor_boot` needed.
- Cost: ~8 MB extra ramdisk, a build dependency on two binary files in the
  tree (must be committed), and a loud build failure on a broken payload
  (deliberate — loud beats a silent stock image with no recovery).
