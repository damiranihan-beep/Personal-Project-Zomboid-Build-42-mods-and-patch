# Fix 4.1 — дополнительное ТЗ 16.08.2026

## 1. Тип оружия в каждом названии Guns of Marz

Проверен актуальный набор `media/scripts/MarzWeapons/items/weapons` версии 42.16: **67 firearm-форм**. У каждой есть короткая типовая пометка в RU ItemName. Отдельно исправлены все пистолеты, S&W 629 и runtime-формы M203/Masterkey, где в Fix 4 тип отсутствовал.

## 2. «Снять все насадки»

Добавлена команда обычного контекстного меню оружия. Она не вызывает прямой `detachWeaponPart`. План строится по фактически установленным WeaponPart и зависимостям Gunworks.

Безопасные ограничения:
- нужна исправная отвёртка;
- `Clip` и внутренние `Slide/Pump/Bolt/Lever/Barrel/Animated*` не трогаются;
- permanent/integrated parts не трогаются;
- активный underbarrel не снимается до выхода из подствольного режима;
- дочерние насадки снимаются раньше родительских планок/адаптеров;
- если родителя блокирует деталь, которую нельзя безопасно включить в план, родитель тоже остаётся;
- bayonet использует штатный `ISBayonetRemove`; обычные детали — `ISRemoveWeaponUpgrade`.

## 3. Tidy Up Meister и осмотр оружия с пола

Использован публичный API Tidy Up Meister 2.0.4:

`registerActionPolicy("riskyInspectAction", { ignore = true })`

Перенос оружия с пола и временное экипирование остаются подготовительными действиями, а сам `riskyInspectAction` больше не вооружает Tidy-сессию. Поэтому Tidy не должен тут же возвращать оружие на пол и закрывать окно осмотра.

## 4. Дополнительная защита Inspect Weapon

Индивидуальное снятие проверяет не только RequiredAttachment/UniversalAttachment, но и `Railing.HasMountedAccessoryOnRailing` и активный underbarrel. Отвёртка обязательна и для съёмного bayonet attach/remove. Дополнительно защищены ISBayonetAttach/ISBayonetRemove, поэтому Gunworks context/radial не обходят это правило; встроенный fold/unfold штыка не блокируется.

## 5. Предрелизная статическая проверка

- Актуальные firearm-формы Guns of Marz 42.16: **67/67** имеют типовую пометку; отдельно проверены P226, S&W 629, Hi-Power и M92FS.
- Основной Lua compat-патча и Weapon Reload Menu Cleaner проходят `texluac -p`; RU/EN UI-таблицы compat-патча также проходят синтаксическую проверку.
- Tidy Up Meister 2.0.4 действительно экспортирует `registerActionPolicy`, а `riskyInspectAction` — точное имя класса действия оригинального Inspect Weapon.
- Для съёмных штыков защищены сами `ISBayonetAttach:isValid` / `ISBayonetRemove:isValid`; поэтому отсутствие отвёртки нельзя обойти через другой UI-вызов этих действий. Обычный Gunworks context-menu дополнительно показывает такие пункты недоступными.
- `Снять все насадки` не вызывает прямой `attachWeaponPart` / `detachWeaponPart`: используются штатные timed actions.

Это статическая предрелизная проверка исходников; окончательная проверка поведения UI/анимаций выполняется уже в игре на пользовательской сборке.
