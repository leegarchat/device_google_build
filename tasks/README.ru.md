# Внедрение recovery (cpio.lz4) в vendor_boot через bootsmasher и build tasks

## Что это

Каталог `device/google/build/tasks/` содержит ДВА перехвата сборки `vendor_boot.img`:

1. **Перехват образа**: штатный образ, собранный из исходников командой
   `mkbootimg`, на лету патчится бинарем `bootsmasher-host`, который заменяет
   recovery-ramdisk на готовый `cpio.lz4`-пейлоад (OrangeFox), после чего образ
   переподписывается `avbtool`. Так получается `out/…/vendor_boot.img` с Fox.
2. **Перехват target-files** (стамп `fox_vendor_boot_tf.stamp` в том же `.mk`):
   пропатченный образ вталкивается в стейджинг target-files
   (`IMAGES/vendor_boot.img`), откуда его забирают `target-files.zip` и OTA
   (`payload.bin`). Без него в payload уезжает сток — см. раздел
   «Почему нужен второй хук».

## Файлы

| Файл | Назначение |
|---|---|
| `vendor_boot_prebuilt.mk` | Активный перехват: переопределяет рецепт `$(INSTALLED_VENDOR_BOOTIMAGE_TARGET)` |
| `vendor_boot_prebuilt.mk.bak` | Бэкап старого варианта (простой `cp` пребилта). Окончание `.bak` **не** подходит под маску `*.mk`, сборщик его игнорирует |
| `bootsmasher-host` | Хост-биinary (Linux x86_64, musl-static, small-профиль: только `vboot` + `install`), бит `+x` уже выставлен |
| `OrangeFox-R12.0-test6-aio.ramdisk.lz4` | Пейлоад: готовый recovery-ramdisk в `lz4-legacy`. Имя захардкожено в `_FOX_PAYLOAD` внутри `.mk` |
| `logs.log` | Старый лог, к перехвату отношения не имеет |

## Цепочка сборки vendor_boot (shiba / zuma)

1. `device/google/shusky/device-shiba.mk` задает `TARGET_KERNEL_DIR`
   (`device/google/pixel-kernels/shiba_cp2a_005` либо `TARGET_KERNEL_DIR_EXT`),
   `device/google/zuma/common.mk:275` — `PRODUCT_BUILD_VENDOR_KERNEL_BOOT_IMAGE=true`.
2. `build/make/core/board_config.mk` выставляет `BUILDING_VENDOR_BOOT_IMAGE=true`
   (header v4, `BoardConfig-common.mk:220-221`).
3. Единственное правило сборки — `build/make/core/Makefile:1748-1767`
   («Target vendor_boot image»): `mkbootimg … --vendor_boot $@`, затем
   `assert-max-image-size`, затем `avbtool add_hash_footer --image $@
   --partition_size 0x04000000 --salt sha256(BUILD_NUMBER+BUILD_DATETIME)
   --partition_name vendor_boot … --prop com.android.build.vendor_boot.fingerprint:…`.
   Важно: отдельных `BOARD_AVB_VENDOR_BOOT_KEY_PATH/ALGORITHM` у zuma нет,
   поэтому это **hash-footer без ключа** (`INTERNAL_AVB_VENDOR_BOOT_SIGNING_ARGS`
   пуст), а дескриптор образа копируется в `vbmeta.img`
   (`--include_descriptors_from_image`).
4. Дальше пути расходятся — это ключевой момент:
   - `out/…/vendor_boot.img` (пропатченный перехватом №1) забирают `vbmeta.img`
     на этапе make (дескриптор через `images-for-partitions`) и fastboot-прошивка;
   - а `target-files.zip` / OTA / `payload.bin` собираются НЕ из него, а из
     стейджинга target-files (см. следующий раздел).

## Почему нужен второй хук (расхождение out vs payload)

Симптом, как было поймано: `out/…/vendor_boot.img` — 2 фрагмента
(platform + recovery/Fox, `RAMDISK_SZ 30702812`), а `vendor_boot` извлечённый
из `payload.bin` финального `EvolutionX-*.zip` — 1 стоковый фрагмент
(`RAMDISK_SZ 22561178`). Фантомного срабатывания нет: это два разных образа
из двух разных источников.

Механика (`build/make/core/Makefile`):

1. Рецепт target-files складывает в стейджинг `$(zip_root)/VENDOR_BOOT/`
   дерево исходников ramdisk (`Makefile:6838-6870`: `RAMDISK/`, `dtb`,
   `vendor_bootconfig`, `base`, `pagesize`, `vendor_cmdline`, фрагменты).
2. Тот же рецепт запускает `add_img_to_target_files.py -a … $(zip_root)`
   (`Makefile:7234-7235`), который **пересобирает** `IMAGES/vendor_boot.img`
   из этого дерева: `common.py:GetVendorBootImage` берёт готовый `IMAGES/`
   только если файл уже там, а его там нет — `BOARD_PREBUILT_VENDOR_BOOTIMAGE`
   пуст (в `pixel-kernels/` нет `vendor_boot.img`), поэтому копирование
   `INSTALLED_… → IMAGES/` (`Makefile:7041-7043`) пропускается. Туда же
   `AddVBMeta` кладёт стоковую `vbmeta.img` (дескриптор со стокового образа).
3. `ota_from_target_files` (`build-ota-package-target`, `Makefile:7317-7327`)
   читает стейджинг-каталог (`$(patsubst %.zip,%,$(BUILT_TARGET_FILES_PACKAGE))`,
   НЕ `out/…/vendor_boot.img`) и `brillo_update_payload` пакует сток в
   `payload.bin`. Финальный `EvolutionX-*.zip` — это переименованный OTA-пакет
   (`vendor/lineage/build/tasks/evolution.mk:23-24`).

Второй хук в `vendor_boot_prebuilt.mk` (стамп `_FOX_TF_STAMP` =
`$(PRODUCT_OUT)/fox_vendor_boot_tf.stamp`) чинит это после готовности стейджинга:

```make
cp <патченный vendor_boot.img> <staging>/IMAGES/vendor_boot.img  # поверх стока
rm -f <staging>/IMAGES/vbmeta.img                                # стоковый дескриптор — снести
add_img_to_target_files -a -v -p $(HOST_OUT) <staging>           # пересобрать vbmeta+digest из патченного
```

При повторном прогоне `add_img` видит готовый `IMAGES/vendor_boot.img`
(«using prebuilt») и оставляет наш, а отсутствующую `vbmeta.img` строит заново
(`BuildVBMeta`) уже с дескриптором патченного образа; `META/vbmeta_digest.txt`
перезаписывается. Care maps не затрагиваются: `vendor_boot` нет в
`PARTITIONS_WITH_CARE_MAP`. Подключение — только prereq-only строками
(`$(BUILT_TARGET_FILES_PACKAGE): $(_FOX_TF_STAMP)` и
`$(INTERNAL_OTA_PACKAGE_TARGET): $(_FOX_TF_STAMP)`), рецепты не переопределяются,
поэтому порядок гарантирован: стейджинг → стамп → zip/OTA. Пути в `.list`-файле
не меняются (те же имена), так что `target-files.zip` тоже консистентен.

## Почему нельзя штатно

- `BOARD_PREBUILT_VENDOR_BOOTIMAGE` несовместим с `vendor_kernel_boot`
  (`board_config.mk` требует `BUILDING_VENDOR_BOOT_IMAGE=true`), да и готового
  `vendor_boot.img` в `pixel-kernels/` вообще нет — образ всегда собирается.
  (Исторически здесь лежал вариант с `cp` пребилта через `wildcard`; при
  отсутствии файла `wildcard` пуст и блок **молча пропускался**, в `out/`
  ложился сток без Fox — так и было поймано.)
- `BOARD_CUSTOM_BOOTIMG_MK` покрывает только `boot`/`recovery`, не `vendor_boot`.
- Отдельных post-хуков для `vendor_boot` в Soong/Make нет.

## Как работает перехват

Файлы `device/*/build/tasks/*.mk` инклудятся в самом конце главного Makefile
(`build/make/core/Makefile`, секция `task_makefiles`, через `sort()`), поэтому
рецепт из `vendor_boot_prebuilt.mk` **заменяет** стоковый (последний рецепт
побеждает по правилам GNU make), а пререквизиты обоих правил **сливаются**
(исходники ramdisk, dtb, фрагменты, bootconfig всё равно собираются).

Наш рецепт дословно повторяет стоковый и вставляет патч между `mkbootimg`
и проверкой размера/подписью:

```make
$(MKBOOTIMG) … --vendor_boot $@                    # 1. стоковая сборка
$(_FOX_BIN) install --file -i $@ -c $(_FOX_PAYLOAD) -o $@.fox --log …  # 2. инжект
mv $@.fox $@                                       # 3. (in==out запрещен)
assert-max-image-size                              # 4. контроль размера
avbtool add_hash_footer …                          # 5. переподпись
```

`$(_FOX_BIN)` и `$(_FOX_PAYLOAD)` добавлены в пререквизиты таргета — иначе
siso-песочница не доставит их к месту выполнения.

## Что делает bootsmasher

`bootsmasher-host install --file -i IN -c PAYLOAD.lz4 -o OUT --log …`
(чистый офлайн-режим, без fastboot/adb/`export.txt`):

1. `verify(in)` — разбор `VNDRBOOT` v3/v4: сумма таблицы = `header.ramdisk_size`,
   цепочка оффсетов, декомпрессия и проверка cpio каждого фрагмента, DTB-walk.
2. `rebuild` — новый ramdisk-набор: `platform` = только `first_stage_ramdisk/**`
   из стока + `recovery` = пейлоад Fox (минус first-stage дубли) + `dlkm` =
   оригинал как есть + carryover-остальное как есть. Свежие фрагменты —
   `marker-free LZ4-legacy`, таблица переписана, `DTB/bootconfig/flags/cmdline`
   сохранены. Хвост `vbmeta/AVB/padding` **отбрасывается** (`drop_footer=true`).
3. `verify(out)` в памяти — и только потом запись. При любой ошибке код 2
   и сборка падает громко, битого образа не будет.

Сырой `cpio` пейлоад пожмется сам, уже сжатый `lz4-legacy` (наш случай) идет
как есть. Повторный прогон на уже пропатченном образе идемпотентен по контенту.

## Почему переподпись обязательна

После шага 2 у образа нет AVB-футера. Без `add_hash_footer` с теми же
аргументами, что в стоке (размер партиции, `--salt`, `--partition_name
vendor_boot`, fingerprint-prop), `vbmeta.img` снимет неверный дескриптор,
`validate_target_files` и проверка AVB на устройстве не сойдутся. Ключ тот же,
что в стоке: для zuma/shiba — без `--key` (см. раздел 3).

## Ограничения песочницы (важно!)

Исходники под siso — **read-only**:

- никакого `chmod`/`touch`/`mv` по файлам в дереве — только чтение входов;
  запись только в `$@`, `$@.fox`, лог в `$(PRODUCT_OUT)/fox_install.log`;
- бит `+x` на `bootsmasher-host` должен быть выставлен заранее (в git
  сохраняется), рецепт его не чинит.

Нарушение роняет сборку ошибкой `Read-only file system` (уже проходили).

## Размерная политика

Партиция `BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE=0x04000000` (64 МиБ).
`assert-max-image-size` с `get-hash-image-max-size` оставляет место под
AVB-футер; сверх того держим политику on-device инсталлера — минимум ~7 МиБ
свободно (`MIN_FREE_MB` в `export.txt`). Факт для test6: выход ~29–30 МБ
при стоковом входе ~21.5 МБ ramdisk — запас ~34 МБ.

## Проверка успеха

1. В `out/target/product/shiba/` есть `fox_install.log` (`RESULT: OK`,
   `2 fragments`).
2. `bootsmasher-host vboot --verify out/…/vendor_boot.img` — 2 фрагмента,
   оба `valid=yes`.
3. Эталонный вывод `magiskboot unpack` для удачной сборки:

```
RAMDISK_SZ      [30702812]
VND_RAMDISK     name=[] type=[platform] size=[3861505] fmt=[lz4_legacy]
VND_RAMDISK     name=[recovery] type=[recovery] size=[26841307] fmt=[lz4_legacy]
VBMETA
```

4. После распаковки рядом лежат `vendor_ramdisk/ramdisk.cpio` (platform)
   и `vendor_ramdisk/recovery.cpio` (Fox; внутри `lgz_cluster.lgz`).
   `find | grep twrp` по корню platform-фрагмента ничего не даст — и не должен:
   Fox живет в отдельном `recovery`-фрагменте.
5. **Обязательно: проверка payload.** Извлечь `vendor_boot` из финального
   `EvolutionX-*.zip` (`payload-dumper-go -p vendor_boot …`) и прогнать
   `magiskboot unpack`: должны быть те же 2 фрагмента, `RAMDISK_SZ 30702812`.
   Если там 1 фрагмент / `RAMDISK_SZ ~22561178` — в payload ушёл сток
   (см. раздел «Почему нужен второй хук»): проверить, что стамп
   `out/…/fox_vendor_boot_tf.stamp` создался и OTA зависит от него.
6. Консистентность AVB: `avbtool verify_image --image IMAGES/vbmeta.img`
   из стейджинга (или `validate_target_files.py`) — дескриптор `vendor_boot`
   должен соответствовать пропатченному образу.
5. **Обязательно: проверка payload.** Извлечь `vendor_boot` из финального
   `EvolutionX-*.zip` (`payload-dumper-go -p vendor_boot …`) и прогнать
   `magiskboot unpack`: должны быть те же 2 фрагмента, `RAMDISK_SZ 30702812`.
   Если там 1 фрагмент / `RAMDISK_SZ ~22561178` — сработал стейджинг
   без второго хука (см. раздел «Почему нужен второй хук»): проверить, что
   стамп `out/…/fox_vendor_boot_tf.stamp` создался и OTA зависит от него.
6. Консистентность AVB: `avbtool verify_image --image IMAGES/vbmeta.img`
   из стейджинга (или `validate_target_files.py`) — дескриптор `vendor_boot`
   должен соответствовать пропатченному образу.

## Обслуживание

- **Новый пейлоад**: положить `*.lz4` рядом, обновить `_FOX_PAYLOAD` в `.mk`.
  Имя точное, без `wildcard` — опечатка остановит сборку на этапе kati
  (`no rule to make target`), а не даст тихий сток.
- **Новый бинарь**: заменить `bootsmasher-host` (`dist/bootsmasher-small-linux-x86_64`),
  сохранить `+x`.
- **Сток поменялся** (новые флаги `mkbootimg` в AOSP): сверить рецепт с
  `build/make/core/Makefile` («Target vendor_boot image»).
- **Откат**: удалить/переименовать `.mk` (маска `*.mk` его не найдет) —
  соберется чистый сток. `.bak` — это бэкап еще более старого `cp`-варианта.
- Стамп `fox_vendor_boot_tf.stamp` пересоздаётся автоматически при изменении
  образа или стейджинга (зависимости make); удалять вручную не нужно.

## К чему приводит

- Каждая сборка `shiba` (и любой продукт с этим tasks-каталогом) из коробки
  содержит OrangeFox в обоих слотах `vendor_boot`: и `out/…/vendor_boot.img`
  (перехват №1), и `payload.bin` (перехват №2 в стейджинге target-files)
  несут один и тот же пропатченный образ — отдельный шаг прошивки рекавери
  не нужен.
- AVB-цепочка консистентна: футер пересоздан, дескриптор в `vbmeta` снят уже
  с пропатченного образа, fingerprint-prop актуальный. Специальной
  переподписи `target-files`/`sign_target_files_apks` для `vendor_boot`
  не требуется.
- Плата: +~8 МБ к ramdisk, зависимость сборки от двух бинарных файлов в дереве
  (нужно коммитить), при сломанном пейлоаде сборка падает (это намеренно —
  лучше громко, чем тихий сток без рекавери).
