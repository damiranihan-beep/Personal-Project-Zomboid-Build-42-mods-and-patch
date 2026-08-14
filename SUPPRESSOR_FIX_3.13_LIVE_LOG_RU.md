# Suppressor Fix 3.13 — разбор live-лога 14.08.2026

В `console(20260814-111510).txt` единственная ошибка, относящаяся непосредственно к тесту поломки нашего глушителя, идёт из `dropBrokenPlastic` / `processShot`: `WeaponPart.setMountOn` получает `mountOn = null` при `instanceItem` сломанного пластикового глушителя.

Исправления 3.13:
1. Всем broken WeaponPart добавлен валидный MountOn.
2. После working→critical→broken и detach выполняется `StatsFactory.ReapplyAllModifiers`.
3. Звук синхронизирован с `MarzGunsSoundOverhaul`: используем его `*_silence`, чтобы два мода не перетягивали SwingSound.
4. Финальный критический выстрел сохраняет баланс -25/-35/-45% шума и дополнительно получает короткий свист/шипение как заметный сигнал поломки.
