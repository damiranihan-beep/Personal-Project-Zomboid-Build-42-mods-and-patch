# Weapon Reload Menu Cleaner

Private Build 42.20.2 compatibility patch for the current Project Zomboid collection.

It replaces overlapping firearm unload entries from vanilla/Picking Meister with one **Unload weapon** submenu. The actions themselves remain vanilla `ISEjectMagazine`, `ISUnloadBulletsFromFirearm` and `ISRackFirearm`, so Gunworks/Guns of Marz hooks still run.

For a detachable magazine, **Magazine only** ejects it and leaves a chambered round alone. **Magazine and chamber** ejects the magazine first and then racks the chamber. Fixed/internal-magazine firearms use the same menu wording but empty their internal ammunition before racking the chamber.

A jam-clearing action is kept separately. A genuine manual rack/cycle action with no chambered round is also preserved instead of being mistaken for an unload duplicate.
