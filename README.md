# Nexus-Threat-Updated

> Fork of Nexus-Threat by Karu_Kiruna ([mod portal](https://mods.factorio.com/mod/Nexus-Threat), source in
> [Karu010/Nexus-Extended-Promethium-Endgame](https://github.com/Karu010/Nexus-Extended-Promethium-Endgame)), updated
> for Factorio 2.1 and published as `Nexus-Threat-Updated`. All credit for the mod goes to Karu_Kiruna.
> It is a stopgap: once the original has a 2.1 release, this fork is deprecated.

The storms, instability and shield of [Nexus-Updated](https://github.com/GreenTech-Solutions/Nexus-Updated). It comes
as a dependency of Nexus-Updated; its strings are in the locale of Nexus-Updated, as in the original.

This repository holds the `Nexus-Threat` folder of the upstream repository with its history
(`git subtree split --prefix=Nexus-Threat`); `master` up to the tag `v1.0.6` is upstream as it is. What the fork changes
is in [changelog.txt](changelog.txt).

## Switching a save from Nexus-Threat

Prototype and setting names are unchanged. The state of the script starts anew under the new mod name: the
stabilizers are found again on the Nexus surface, the stabilizer tier is taken from them, and the instability and the
shield start from 0.

## Remote interface `nexus-threat`

- `set_storm_multiplier(m)`: scales the lightning chances (regular and wild), a finite number >= 0, default 1.0. It
  does not change the damage, the storm duration or the instability.
- `get_state()`: instability, shield and its maximum, storm state and timer, multiplier, stabilizer count, strike
  counters.

## License

GPLv3, as the original: [LICENSE](LICENSE).
