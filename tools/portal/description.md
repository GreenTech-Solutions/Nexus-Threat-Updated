**A fork of [Nexus-Threat](https://mods.factorio.com/mod/Nexus-Threat) by Karu_Kiruna, updated for Factorio 2.1.** All credit for the mod goes to Karu_Kiruna. It is a stopgap until the original has a 2.1 release; then this fork is deprecated. Source: [GreenTech-Solutions/Nexus-Threat-Updated](https://github.com/GreenTech-Solutions/Nexus-Threat-Updated).

The storms, instability and shield of [Nexus Extended Promethium Endgame (2.1)](https://mods.factorio.com/mod/Nexus-Updated). It comes as a dependency of Nexus-Updated.

## What the fork changes

- Factorio 2.1
- The shield regeneration setting works: the shield regenerates outside storms
- The shield is computed every 10 ticks over the stabilizers only (less script time during storms)
- Debug commands are for admins only
- Map settings for the storms: instability half-life, lightning chance per instability, lightning attempts per tick. The defaults keep the original behaviour
- Remote interface `nexus-threat` for other mods: `set_storm_multiplier(m)`, `get_state()`

## Switching a save from Nexus-Threat

Install all three mods of the fork (Nexus-Updated, Nexus-Threat-Updated, Nexus-Graphics-Updated) **before** you load the save. A save loaded without them loses everything of Nexus.

Prototype and setting names are unchanged. The shield stabilizers keep their tier; the instability and the shield start from 0.

## Credits

- Karu_Kiruna, the author of [Nexus-Threat](https://mods.factorio.com/mod/Nexus-Threat)
