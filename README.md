# Project Zomboid Build 42.20.2 — Personal Mod Repository

Актуальное состояние пользовательских модов и патчей после рабочего прохода **15.08.2026**.

## Текущие версии

- **Guns of Marz Attachment Rebalance — 2.0.0** — утверждённый stock-based ребаланс поколений I–VII/U + редкость.
- **Weapon Attachment Tooltip Cleaner — 2.7.2 TEST** — компактная синяя совместимость + PartType fallback.
- **Russian Translation Collection for Mods — 4.4.3** — zoom hotfix, PartType Guns of Marz, названия поколений.
- **Homemade Suppressors for Guns of Marz — 3.16 TEST**.
- **Guns of Marz Core Fixes — 1.1** — FNC stock + M24 integrated bipod permanent-part fixes.
- **Inspect Weapon - Guns of Marz Compatibility — 0.3.0 TEST / Fix 2** — стабильный штатный рендер, корректный tooltip магазина, fallback установленных GoM-деталей.
- **Realistic Combat — 3.8 TEST**, технический ID `RealisticCombat`.
- Smoking Universal Patch — без изменений этого прохода.

## Что сделано 15.08.2026

### Inspect Weapon - Guns of Marz Compatibility 0.3.0 TEST / Fix 2

- Оригинальный Inspect Weapon остаётся отдельной Workshop-зависимостью (`RiskyInspectWeapon`); его файлы в репозиторий не копируются.
- После теста Fix 1 подтверждено: старый Stage 1 renderer override и `getCandidateCategories()` больше не используются, лавина ошибок при открытом окне устранена.
- Fix 2 сохраняет штатный рендер автора и добавляет только узкие compatibility-hook'и.
- Tooltip временного объекта магазина синхронизируется с реальным `CurrentAmmoCount` оружия: контрольный случай M92FS — иконка `7`, tooltip должен показывать `7 / 15`, а не `0 / 15`.
- Если штатный `getWeaponPart("Scope")`/другой обычный слот вернул nil, уже установленная runtime-деталь восстанавливается через `getAllWeaponParts()` без сканирования script items.
- Уже установленные нестандартные PartType Guns of Marz (планки, underbarrel, рукояти, лазеры/фонари, адаптеры, Booster, патронташ, сошки и integrated state-детали) показываются отдельными read-only строками.
- Служебные анимационные PartType (`Slide`, `Pump`, `Bolt`, `Lever`, `Barrel`, `Animated1..9`) скрыты; `Clip` не дублируется.
- Generic-снятие несъёмных деталей через Inspect Weapon блокируется через Gunworks `PreventRemovals` плюс fallback для integrated stock/bipod/bayonet систем.
- Для следующей проверки добавлена одна компактная диагностическая строка только при изменении набора установленных частей — без тяжёлого per-frame candidate scan.
- Состояние/история ремонта оружия не меняются. Характеристики оружия/обвесов также не меняются; отдельная сводка эффективных статов остаётся следующим этапом после подтверждения стабильного осмотра.

### Guns of Marz Core Fixes 1.1

- Помимо уже исправленного FNC, обнаружены и закрыты две пропущенные stock-записи `M24_Integrated_Bipod_Folded/Deployed`.
- После v1.1 все 39 найденных integrated/state attachment-item Guns of Marz имеют защиту от generic removal с учётом Core Fixes.
- Для уже затронутого M24 добавлено штатное восстановление через `FoldingBipod`.

### Guns of Marz Attachment Rebalance 2.0.0

Основа — **только STOCK Guns of Marz**. Самодельные глушители, наши другие патчи и встроенные части оружия в систему поколений не смешиваются.

Поколения применены к лазерам, пистолетной оптике, компактной/коллиматорной оптике, увеличительной оптике и передним рукояткам. `U` — уникальный предмет вне линейного тира. PRL-1, Booster и сошки сохраняют STOCK-механику/цифры/редкость.

Редкость:

`I ×1.60 → II ×1.35 → III ×1.10 → IV ×0.90 → V ×0.70 → VI ×0.50 → VII ×0.35`, `U ×1.00`.

- установленный на оружии обвес: масштабируется исходный процентный ролл конкретной пушки;
- отдельный лут: масштабируется исходный относительный вес в уже существующих контейнерах;
- новые точки спавна не создаются;
- required-обвесы не превращаются в случайные.

Утверждённые таблицы лежат в `Planning/`.

### UI / tooltip

- WATC не использует `setMountOn(nil)`;
- список совместимости остаётся синим, короткими моделями через ` / `;
- `Можно прикрепить на:` оставлено;
- `Tooltip_Weapon_LaserRifle` и родственные кастомные PartType имеют русский fallback;
- Show Weapon Stats Plus должен сохранять свои статы.

### Локализация

- `IGUI_BackButton_Zoom = "Приближение %1%%"`, без артефакта `250$s$%`;
- tiered-названия синхронизированы с префиксами `I–VII/U`;
- игровые ID предметов не менялись.

## Что не менялось финальным ребаланс-проходом

- Realistic Combat 3.8;
- Homemade Suppressors 3.16;
- Guns of Marz Core Fixes 1.1;
- WATC 2.7.2 gameplay/UI-код;
- заводские и самодельные глушители;
- MountOn / совместимость установки.

## Inspect Weapon - Guns of Marz Compatibility 0.4.0 / Fix 3

- сохранён стабильный нативный renderer RiskyInspectWeapon и Fix 2 live-magazine sync;
- установка GoM-обвеса адаптирована под текущую сигнатуру Gunworks без legacy-аргумента `50`;
- обычные GoM WeaponPart, UniversalAttachment-планки и съёмные штыки получили отдельные безопасные install/remove пути;
- снятие учитывает зависимый обвес и permanent/integrated-защиту;
- отсутствие отвёртки больше не выглядит как «меню ничего не делает»: кандидат показывается недоступным с причиной;
- raw `RailUp`, `BayonetKnife`, `UI_GOMIW_*` закрыты fallback-подписями;
- глобальный `getAllItems()`/candidate database scan не возвращён.

## Рекомендуемый порядок загрузки

1. Hot Brass / Gunworks framework dependencies
2. Guns of Marz (`SWMG`, `MarzGuns`)
3. Guns of Marz Core Fixes 1.1
4. MarzGuns Sound Overhaul
5. Guns of Marz Attachment Rebalance 2.0.0
6. Homemade Suppressors for Guns of Marz 3.16 TEST
7. Inspect Weapon (`RiskyInspectWeapon`)
8. Inspect Weapon - Guns of Marz Compatibility 0.4.0 TEST / Fix 3
9. CleanUI / Armor Makes Sense / Equipment UI / Open All Containers / Reorder Containers / Picking Meister / Show Weapon Stats Plus
10. Russian Translation Collection 4.4.3 (`loadLast=on`)
11. Weapon Attachment Tooltip Cleaner 2.7.2 TEST (`loadLast=on`, после переводчика)
12. Fancy Handwork / compatibility patch
13. Realistic Combat 3.8 TEST

## Что проверить в игре

- Inspect Weapon Fix 3: проверить обратимый цикл «снять → поставить обратно» для PL-4/JS14 и крепёжных планок; без отвёртки кандидат должен быть виден, но недоступен с понятной причиной.
- Mossberg 590: JS14 должен блокировать снятие верхней планки; после снятия JS14 планка снимается и восстанавливается из возвращённой универсальной планки Gunworks.
- Trench Gun: M5 должен отображаться как «Штык-нож» без raw `BayonetKnife` / `UI_GOMIW_PERMANENT`, сниматься и ставиться обратно через bayonet-механику Gunworks.
- M92FS: магазин сохраняет корректный live-count в иконке и tooltip; PX1/другие GoM-слоты не должны порождать служебные raw-ключи.
- FNC / M24 / SKS: встроенные детали видны, показывают состояние и остаются защищёнными от generic removal.
- Сложить/разложить FNC/AKS74U и M24/BAR, а также штык SKS: окно должно обновить state без роста ширины и без ERROR.
- По одному обвесу каждого поколения I–VII и U: название и характеристики.
- Kobra I / OKP3 II / Reflex S2 III / EXPS1 IV / EXPS3 V / JS14 VI / Aimpoint VII.
- Elcan X2 I / LR4X II / TA28 III / TR06X IV / PSO1 V / LR10X VI / LRX12X VII.
- Stub I / MKC II / MK2 III.
- PRL-1 U, Booster U и сошки U должны сохранять STOCK-механику.
- Ранние поколения должны встречаться чаще исходника, старшие — реже. Для оценки нужен новый сгенерированный лут.
- Tooltip: короткие синие модели через `/`, без сырого `Tooltip_Weapon_*` и без роста ERROR-счётчика.
- Настройки масштаба: 25/50/75/.../250% без `$s$`.
- FN FNC: встроенный приклад не должен появляться в «Убрать насадку».
- Realistic Combat: dual-wield, shove/stomp, удар по лежачему, травма/снятие оружия с левой руки.
- Homemade Suppressors: пластик / банка / труба, прежний баланс и semi/auto/burst audio.

После теста полезен свежий `console.txt`, особенно строка `[GOM Inspect Weapon Compat] Fix 3 inspect ... parts=[...]` и любые ERROR/Exception после неё.

## Структура репозитория

- `README.md` — текущее состояние, версии и чеклист проверки.
- `CHANGELOG_RU.txt` — общий журнал: дата → мод → версия → что исправлено/изменено.
- `My Mods/` — основные пользовательские моды.
- `My Patch Mods/` — отдельные патчи и UI/rebalance-моды.
- `Planning/` — только актуальные таблицы планирования/утверждения ребаланса.

Старые промежуточные RELEASE / VALIDATION / HISTORY / AUDIT отчёты из корня **не входят** в этот GitHub-ready пакет: их информация сведена в этот README, чтобы репозиторий не захламлялся десятками служебных файлов.
