# MCMT Mod for Age of Mythology: Retold

**Version:** 1.0.0

**Author:** Akinizer

**Last Updated:** [Date of Last Update]

## Description

The MCMT Mod is a comprehensive modification for Age of Mythology: Retold, introducing a vast array of new units, buildings, technologies, and powers, while also enhancing existing game content across all civilizations. Experience new legendary heroes, powerful mythical beasts, advanced siege weaponry, unique economic units, and much more. This mod aims to expand strategic options and provide a fresh gameplay experience.

## Features

### New Content:

*   **Legendary Heroes:**
    *   Landlord: A versatile hero with building capabilities and unique passive buffs.
    *   Conan: A powerful warrior with access to multiple god powers.
    *   Matsuri Yurio & Matsuri Azula: Psionic heroes with unique transformation and combat abilities.
    *   MCMT_KastorLegend, MCMT_ChampionOfFreyr, AchillesDismounted, and more.
*   **Elite Heroes & Warriors:**
    *   Farseer, Chieftain, Hitman, ValkyrieWarrior, WindRider, Partisan, Spartan, ImperialGuard, Peacemaker, AttackWolf.
*   **Gods and Mythical Beasts:**
    *   Playable versions of Thor, Chiron, Heracles, Hades.
    *   Awakened versions of Volstagg, Surtr, Fenrisulfr.
    *   New beasts like GorgonAvenger, Fafnirstrasz, Grootia, Earthshaker.
*   **Chinese Legends:**
    *   MCMT_HuangZhaowu, MCMT_HuangZhaowuWife, MCMT_NvChou.
*   **Super Weapons & Unique Units:**
    *   MCMT_GiantSiegeCrossbow, MCMT_Devastator, MCMT_ColossusOfRhodes.
    *   Onigami (Demolition Ship), SolarBarge (Flying Siege Unit).
    *   OxCartModelX (Advanced Caravan).
*   **CyberTech Units:**
    *   MotherShip, PrismTank, MirageTank, MirrorTank, Igniter, ScoutProbe.
*   **Atlantean Captains:**
    *   Hero versions for Arcus, Contarius, Murmillo, Katapeltes, Turma, Destroyer, Fanatic.
*   **New Buildings:**
    *   Bastion (Advanced Defensive/Training Structure).
    *   TempleOfPrimordials (Trains Gods and Legendary Myth Units).
    *   TechBuilding (Centralized Research Hub for MCMT Techs).
    *   MCMT_DwarvenForge, MageTower, StrategicVesselAssembly, AirCommand, TheAttractor.
*   **Naval Special Units:**
    *   Desolator, Flagship, Navigator, ScorpionBoat, FlyingDutchman, PirateCaptain, Blazemaster, Worldbreaker, MrWukong.
*   **New Technologies:**
    *   A wide range of new military, economic, and myth unit upgrades (e.g., MCMT_DivineArmaments, MCMT_NanofiberPlatings, MCMT_MonstrousRage, MCMT_VibrantLand).
*   **New Powers & Abilities:**
    *   Custom versions of existing god powers (e.g., MCMT_Meteor, MCMT_Frost, MCMT_Restoration).
    *   New unit-specific abilities and transformations.
    *   Unique powers like MCMT_OrbitalStrike.

### Enhancements to Existing Content:

*   **Unit Scaling:** Many existing units (buildings, myth units, heroes) have increased visual scale for a more epic feel.
*   **Civilization Improvements:**
    *   **Norse:** Valkyries spawn dismounted warriors upon death, various myth units buffed.
    *   **Egyptian:** Pharaohs and Priests buffed, Mummy reincarnation mechanics.
    *   **Greek:** Hero improvements (Jason, Atalanta, Theseus), Achilles dismounts on death.
    *   **Chinese:** Villager Clay variant, hero and myth unit buffs.
*   **Modified Technologies:** Vanilla game technologies like Crenellations, Ballistics, FortifiedTownCenter, and various armory/champion upgrades have been enhanced or expanded.
*   **Unit Transformations:**
    *   Custom transformations for units like MatsuriYurio (Flight mode).
*   **UI Enhancements:**
    *   Custom command panel pages for units like Conan and Landlord for easier access to their numerous abilities and build options.

## Installation

1.  **Locate your Age of Mythology: Retold mods folder:**
    *   Typically: `C:\Users\[YourUserName]\Games\Age of Mythology Retold\<SteamID>\mods\local\data\`
2.  **Copy the `mcmt` folder** (the folder containing this README and all mod files) into the `local` directory.
    *   The final path should look like: `...\mods\local\mcmt\`
3.  **Launch Age of Mythology: Retold.**
4.  **Enable the mod** from the in-game mod manager.

## How Content is Accessed

Most new units and technologies are integrated into the game via the "MCMT_Techs" master technology. This master tech is automatically granted to all civilizations upon reaching the Archaic Age.

*   **New Units:** Many new units are enabled directly by `MCMT_SpecialUnits` (a sub-tech of `MCMT_Techs`). They will typically be trainable from appropriate existing buildings (e.g., Town Center, Barracks, Temple) or new custom buildings like the Bastion, Temple of Primordials, or Strategic Vessel Assembly.
*   **New Researches:** New technologies become available for research in relevant buildings (e.g., Armory, Market, Temple, or the new `TechBuilding`) once `MCMT_Researches` (a sub-tech of `MCMT_Techs`) is active.
*   **Unit Command Panels:** Special units like Landlord and Conan have multi-page command panels, activated by researching `MCMT_Page1` and `MCMT_Page2` (which are made obtainable by `MCMT_UnitAccelPanels`, another sub-tech of `MCMT_Techs`).

## Compatibility

*   This mod extensively modifies `techtree_mods.xml`, `proto_mods.xml`, `abilities_mods.xml`, and `powers_mods.xml`.
*   It is likely to conflict with other mods that significantly alter these core game data files or introduce a large number of new units/techs in a similar manner.
*   Mods that only change textures, sounds, or make minor balance adjustments might be compatible.
*   Always back up your game files or use a mod manager that handles conflicts if you plan to use multiple large mods.

## Known Issues

*   Due to the large number of additions, some balance aspects may require further tuning.

## Credits

*   **Author:** Akinizer
*   **Tools Used:** Resource Manager, VSC

## Changelog

**v1.0.0 - 20.05.2025**
*   Initial Release / Major Update.

---

*Thank you for trying out the MCMT Mod! Feedback is welcome.*
