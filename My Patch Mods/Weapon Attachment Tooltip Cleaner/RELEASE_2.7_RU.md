# Weapon Attachment Tooltip Cleaner 2.7 — live test

## Что исправлялось по скринам 14.08.2026

1. Строка вида `>6=>?@8...` была не случайным мусором: это кириллица `Можно прикрепить на`, потерявшая старший байт при конкатенации переведённой Java-строки с Lua-строкой.
   - В 2.7 русские заголовки больше не конкатенируются.
   - Заголовок и значения рисуются раздельно.

2. Длинные списки TA28 брались из локализованных названий (`M16A1 — штурмовая винтовка`).
   - В 2.7 список использует отдельную read-only карту коротких моделей.
   - Реальные MountOn не меняются.

3. `UI_GOMAR_Optic_G2`, `..._Stats`, `..._Range` появлялись потому, что Attachment Rebalance разрешал `getText()` слишком рано.
   - Rebalance 1.0.2 повторно применяет перевод на OnGameStart.
   - WATC 2.7 дополнительно разрешает эти ключи непосредственно при выводе.

4. Английский `Allows mounting of scopes in 9x19mm pistols` у Beretta Mount был следствием отсутствующего элемента в MarzTooltipKeys.
   - Добавлены недостающие GoM mappings 094 / 116–120.

## Проверить в игре

- магазин Hi-Power: один заголовок + `Browning Hi-Power`;
- Beretta Mount: `Beretta M92FS / Beretta M93R / Browning Hi-Power / Sig Sauer P226`;
- TA28: только короткие модели, перенос вниз, без `— штурмовая винтовка`;
- LP Light: только короткие модели;
- PS1: `Информация` + `Поколение II` + русские строки 3%, без `UI_GOMAR_*`;
- Picatinny Rail: короткие модели;
- оружие: Show Weapon Stats Plus остаётся на месте;
- console: нет NPE `WeaponPart.setMountOn`, нет WATC error-spam.

## Не менялось

- Realistic Combat 3.8;
- Homemade Suppressors 3.16;
- Guns of Marz Core Fixes 1.0;
- реальные MountOn/совместимость;
- игровые характеристики прицелов (баланс остаётся в Attachment Rebalance).
