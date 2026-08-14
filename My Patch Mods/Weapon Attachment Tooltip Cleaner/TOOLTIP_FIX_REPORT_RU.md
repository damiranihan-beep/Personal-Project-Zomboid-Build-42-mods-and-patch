# Weapon Attachment Tooltip Cleaner 2.6 — отчёт

## Подтверждённое live-тестами

- 2.4 вернул Show Weapon Stats Plus и полезные оружейные строки.
- 2.5 попытался временно передавать `nil` в `WeaponPart:setMountOn()` и вызвал ERROR-spam при наведении.
- 2.5.1 исправил этот NPE: используется только валидный пустой `ArrayList`, затем возвращается исходный `MountOn`. Пользователь подтвердил, что ошибок при наведении больше нет.
- В 2.5.1 штатное значение MountOn уже скрывалось, но оставался сам заголовок `Можно закрепить на:`, а собственный список WATC не появлялся.

## Исправление 2.6

1. **Собственный список больше не зависит от Java `getMountOn()` -> Lua conversion.**
   `CompatibilityMap.lua` генерируется из присланных текущих исходников Guns of Marz и Homemade Suppressors.

2. **Точная совместимость вместо широких fake-групп.**
   - магазины: reverse-map по `MagazineType` и `ModelWeaponPart`;
   - обычные насадки: reverse-map по `ModelWeaponPart`, где он есть;
   - универсальная планка Пикатинни: reverse-map из `MarzWeapons/Registries/UniversalAttachments.lua`;
   - Homemade Suppressors: точный список из их собственного `MountOn`.

3. **Формат на маленьком экране.**
   `Можно прикрепить на: Beretta M92FS / Browning Hi-Power / ...`
   Длинные русские классы (`— штурмовая винтовка` и т.п.) в этом списке убираются, строка переносится вниз по ширине.

4. **Старый заголовок скрывается отдельно.**
   WATC содержит blank-override `Tooltip_weapon_CanBeMountOn` в JSON и TXT и теперь является последним UI-слоем после `MyRussianTranslations`. Для этого удалена обратная зависимость Translation Pack -> WATC, чтобы не было циклического load order.

5. **Границы мода сохранены.**
   WATC не меняет реальный `MountOn`, характеристики, оружие, магазины или баланс. HandWeapon renderer остаётся у Show Weapon Stats Plus.
