# Project Zomboid Build 42.20.2 — Personal Mod Repository

Актуальное состояние пользовательских модов и патчей после рабочего прохода **16.08.2026**.

## Текущие версии

- **Guns of Marz Attachment Rebalance — 2.0.0** — утверждённый stock-based ребаланс поколений I–VII/U + редкость.
- **Weapon Attachment Tooltip Cleaner — 2.7.2 TEST** — компактная совместимость насадок без опасной подмены `MountOn`.
- **Russian Translation Collection for Mods — 4.5.2** — RetroDashboard 0.2.0 RU (11/11 собственных ключей), Barricaded World RU, компактные типы оружия Guns of Marz и прежние локализационные фиксы.
- **Homemade Suppressors for Guns of Marz — 3.16 TEST**.
- **Guns of Marz Core Fixes — 1.1** — FNC stock + M24 integrated bipod permanent-part fixes.
- **Inspect Weapon - Guns of Marz Compatibility — 0.6.0 / Fix 4.1** — модельно-зависимые слоты, планки/адаптеры, live-магазин, очистка битых hover-tooltip и сохранение правил Gunworks.
- **Weapon Reload Menu Cleaner — 1.0.0** — единое подменю разрядки без дублей ванили/Picking Meister/Gunworks.
- **Realistic Combat — 3.8 TEST**, технический ID `RealisticCombat`.
- **Smoking Universal Patch 42.20.2 — 1.4.3** — без изменений этого прохода.

## Что сделано в текущем проходе

### Weapon Reload Menu Cleaner 1.0.0

- Несколько пересекающихся пунктов `Вытащить магазин` / `Разрядить <оружие>` / `Разрядить оружие` сводятся в один пункт **`Разрядить оружие >`**.
- Для оружия, где одновременно есть магазин/боеприпасы магазина и патрон в патроннике: **`Магазин и ствол`** / **`Только магазин`**.
- Если остаётся только патронник: **`Ствол`**.
- Съёмный магазин извлекается штатным `ISEjectMagazine`; несъёмный/внутренний магазин разгружается штатным `ISUnloadBulletsFromFirearm`; патронник — `ISRackFirearm`.
- Порядок полного разряжания намеренный: сначала магазин, затем патронник, чтобы передёргивание не дослало новый патрон.
- Реальное действие устранения заклинивания остаётся отдельным; обычное ручное передёргивание без патрона в патроннике тоже не удаляется как «дубль».
- Прямой записи ammo/chamber state нет: сохраняются Gunworks/Guns of Marz reload hooks.

### Inspect Weapon - Guns of Marz Compatibility 0.6.0 / Fix 4.1

- Для Guns of Marz больше не рисуются шесть одинаковых жёстких слотов на каждом оружии.
- Слоты берутся из реальной совместимости конкретной модели: direct `WeaponPart MountOn` + model-specific UniversalAttachment Gunworks + bayonet registry + реально установленные runtime-части.
- **Browning Hi-Power** больше не получает выдуманные `Ремень`, `Приклад`, `Затыльник`; показываются только поддерживаемые этой моделью категории.
- Съёмный магазин остаётся отдельным слотом **`Магазин`** с live-count. Несъёмный/внутренний магазин не изображается как съёмная насадка.
- Реальные планки, адаптеры и нестандартные GoM PartType отображаются как отдельные слоты.
- Старые attachment-tooltip Inspect Weapon закрываются при перестроении окна; для управляемых GoM-слотов проблемный `ISToolTipInv` не открывается, поэтому красные/битые зависшие строки не должны оставаться после снятия/установки прицела.
- Установка/снятие **не обходят Gunworks**: отвёртка, RequiredAttachment, UniversalAttachment dependencies, permanent/integrated детали и bayonet actions сохраняются.
- Статы, `MountOn`, ammo, condition и баланс не меняются.

- В обычном контекстном меню добавлено **`Снять все насадки`**: только безопасно съёмные детали, с обязательной отвёрткой и child-first зависимостями Gunworks.
- Съёмный штык также не ставится и не снимается без отвёртки через обычное меню или radial Gunworks; встроенное складывание/раскладывание штыка остаётся отдельной механикой.
- Permanent/integrated/internal/Clip и активный underbarrel массовым действием не снимаются; заблокированные родители остаются на месте.
- Tidy Up Meister больше не возвращает оружие на пол после `Осмотр оружия`: `riskyInspectAction` зарегистрирован в его compatibility API как `ignore`.
- Индивидуальные действия Inspect Weapon также учитывают Railing/Underbarrel и не обходят отвёртку даже для bayonet-пути.

### Russian Translation Collection 4.5.2

- Найден используемый мод панели: **Banger's Retro Car Dashboard / RetroDashboard 0.2.0**, Workshop `3739256322`.
- Проверены исходные EN/UA-файлы и все вызовы `getText()` в Lua текущей версии: собственных ключей **11**, переведено **11/11**.
- `Off/On`, `Locked/Unlocked`, `Heating/Cooling`, `Dashboard backlight` теперь имеют русские состояния.
- Переведено меню масштаба и единиц скорости панели.
- Код приборной панели не менялся; русификатор только добавляет штатные RU-ключи и грузится после `RetroDashboard`.

### Russian Translation Collection 4.5.1

- Barricaded World: `Disable protection for Door/Window` переведены как **`Выключить защиту двери/окна`**, включая `[Хост]` / `[Админ]` префиксы.
- Итог `Barricaded World: Protected/Unprotected ... doors ... windows ...` после защиты здания заменён русской строкой с теми же счётчиками дверей/окон.
- Длинные классовые хвосты в отображаемых названиях огнестрела Guns of Marz сокращены. Примеры: **`Mossberg 590 (ДР)`**, **`AR-15 (ГВ)`**, **`AK-47 (ШВ)`**, **`MP5 (ПП)`**.
- Дополнительный аудит 42.16: **67 из 67** актуальных firearm-форм имеют типовую пометку; P226/Hi-Power/M92FS и другие пистолеты получили `(пист.)`, S&W 629 — `(рев.)`.
- Игровые ID и характеристики оружия не менялись.

## Рекомендуемый порядок загрузки

1. Hot Brass / Gunworks framework dependencies
2. Guns of Marz (`SWMG`, `MarzGuns`)
3. Guns of Marz Core Fixes 1.1
4. MarzGuns Sound Overhaul
5. Guns of Marz Attachment Rebalance 2.0.0
6. Homemade Suppressors for Guns of Marz 3.16 TEST
7. Inspect Weapon (`RiskyInspectWeapon`)
8. Tidy Up Meister (`P4TidyUpMeister`) — если используется; compatibility patch грузится после него
9. Inspect Weapon - Guns of Marz Compatibility 0.6.0 / Fix 4.1
10. CleanUI / Armor Makes Sense / Equipment UI / Open All Containers / Reorder Containers / Picking Meister / Show Weapon Stats Plus
11. **Weapon Reload Menu Cleaner 1.0.0** — после Picking Meister и оружейных reload-wrapper'ов
12. Banger's Retro Car Dashboard (`RetroDashboard`)
13. Russian Translation Collection 4.5.2 (`loadLast=on`)
14. Weapon Attachment Tooltip Cleaner 2.7.2 TEST (`loadLast=on`, после переводчика согласно текущей сборке)
15. Fancy Handwork / compatibility patch
16. Realistic Combat 3.8 TEST

## Короткий чеклист теста

- Browning Hi-Power: в обычном контекстном меню один `Разрядить оружие >`, без старой тройки дублей.
- Mossberg 590 с внутренним магазином: один `Разрядить оружие >`; при патроне в патроннике доступны `Магазин и ствол` / `Только магазин`.
- Проверить заклинившее оружие: отдельное устранение заклинивания не должно исчезнуть.
- Inspect Browning Hi-Power: нет фиктивных ремня/приклада/затыльника; магазин, реальные планки/прицел/допустимые категории отображаются корректно.
- Снять/поставить прицел и планку: красная/битая плавающая строка не должна оставаться.
- Без отвёртки нельзя обойти правило снятия/установки GoM/Gunworks через Inspect Weapon.
- Контекст оружия с несколькими насадками: `Снять все насадки` без отвёртки недоступно; с отвёрткой сначала уходят дочерние прицелы/модули, затем их планки/адаптеры.
- Активировать подствольный режим и проверить массовое снятие: активный underbarrel и всё, что из-за него нельзя безопасно снять, должны остаться.
- Осмотреть оружие прямо с пола при включённом Tidy Up Meister: окно не должно мгновенно закрываться, оружие не должно автоматически улетать обратно на пол во время осмотра.
- P226 / Hi-Power / M92FS / S&W 629: в имени виден компактный тип `(пист.)` / `(рев.)`.
- Barricaded World: включить/снять защиту двери и здания; меню и итоговая строка должны быть русскими, счётчики дверей/окон — корректными.
- RetroDashboard: навести на радио/печь/замки/подсветку — `Off/On/Unlocked/Dashboard backlight` не должны появляться; ПКМ по приборке — масштаб и единицы скорости полностью по-русски.
- Проверить длинные контекстные строки типа `Вставить 1 патрон ... в Mossberg 590 (ДР)` — полный хвост `— дробовик` больше не должен раздувать меню.
- После проверки сохранить свежий `console.txt`; особенно полезны строки `[GOM Inspect Weapon Compat] Fix 4.1 ...` и любые ERROR/Exception рядом.

## Структура репозитория

- `README.md` — текущее состояние, версии и чеклист.
- `CHANGELOG_RU.txt` — общий журнал изменений.
- `My Mods/` — основные пользовательские моды.
- `My Patch Mods/` — отдельные compatibility/UI/rebalance патчи.
- `Planning/` — актуальные таблицы планирования/ребаланса.
