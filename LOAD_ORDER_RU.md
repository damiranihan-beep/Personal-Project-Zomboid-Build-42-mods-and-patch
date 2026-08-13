# Рекомендуемый автоматический load order

Настройки добавлены в `mod.info`, чтобы Mod Load Order Sorter / Mod Manager мог сам видеть зависимости.

1. **Guns of Marz / его базы**
2. **Weapon Attachment Tooltip Cleaner v1.1** — после MarzGuns и после Homemade Suppressors (фактически самый поздний tooltip wrapper оружейки)
3. **Homemade Suppressors Fix 3.8** — после SWMG / MarzGuns
4. **Fancy Handwork / FH**
5. **Realistic Combat Fix 3.4** — `loadModAfter=FancyHandworkB42_19,FH`
6. **Where Are My Zang Cigs + Smoking Sounds Overhaul**
7. **SmokingUniversalPatch** — уже содержит loadModAfter двух оригиналов
8. **Russian Translation Collection** — `loadLast=on` + load-after всех наших текущих проектов/основных исходников

ВАЖНО: `loadModAfter` задаёт порядок, но не делает необязательные моды обязательной зависимостью.
Поэтому Realistic Combat не получает `require=` на анимационные моды: он просто встаёт после них, если они присутствуют.
