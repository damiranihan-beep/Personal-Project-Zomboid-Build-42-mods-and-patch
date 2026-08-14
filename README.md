# Project Zomboid Build 42.20.2 — Personal Mod Repository

Актуальное состояние пользовательских модов и патчей после рабочего прохода **15.08.2026**.

## Текущие версии

- **Guns of Marz Attachment Rebalance — 2.0.0** — утверждённый stock-based ребаланс поколений I–VII/U + редкость.
- **Weapon Attachment Tooltip Cleaner — 2.7.2 TEST** — компактная синяя совместимость + PartType fallback.
- **Russian Translation Collection for Mods — 4.4.3** — zoom hotfix, PartType Guns of Marz, названия поколений.
- **Homemade Suppressors for Guns of Marz — 3.16 TEST**.
- **Guns of Marz Core Fixes — 1.0**.
- **Realistic Combat — 3.8 TEST**, технический ID `RealisticCombat`.
- Smoking Universal Patch — без изменений этого прохода.

## Что сделано 15.08.2026

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
- Guns of Marz Core Fixes 1.0;
- WATC 2.7.2 gameplay/UI-код;
- заводские и самодельные глушители;
- MountOn / совместимость установки.

## Рекомендуемый порядок загрузки

1. Hot Brass / Gunworks framework dependencies
2. Guns of Marz (`SWMG`, `MarzGuns`)
3. Guns of Marz Core Fixes 1.0
4. MarzGuns Sound Overhaul
5. Guns of Marz Attachment Rebalance 2.0.0
6. Homemade Suppressors for Guns of Marz 3.16 TEST
7. CleanUI / Armor Makes Sense / Equipment UI / Open All Containers / Reorder Containers / Picking Meister / Show Weapon Stats Plus
8. Russian Translation Collection 4.4.3 (`loadLast=on`)
9. Weapon Attachment Tooltip Cleaner 2.7.2 TEST (`loadLast=on`, после переводчика)
10. Fancy Handwork / compatibility patch
11. Realistic Combat 3.8 TEST

## Что проверить в игре

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

После теста полезен свежий `console.txt`, особенно любые ERROR/Exception после строк `[GOM Attachment Rebalance] v2.0.0`.

## Структура репозитория

- `README.md` — текущее состояние, версии и чеклист проверки.
- `CHANGELOG_RU.txt` — общий журнал: дата → мод → версия → что исправлено/изменено.
- `My Mods/` — основные пользовательские моды.
- `My Patch Mods/` — отдельные патчи и UI/rebalance-моды.
- `Planning/` — только актуальные таблицы планирования/утверждения ребаланса.

Старые промежуточные RELEASE / VALIDATION / HISTORY / AUDIT отчёты из корня **не входят** в этот GitHub-ready пакет: их информация сведена в этот README, чтобы репозиторий не захламлялся десятками служебных файлов.
