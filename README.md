# Soft Targeting

Exposes World of Warcraft's soft targeting CVars in the game's own Options panel
(Options → AddOns → Soft Targeting), instead of leaving most of them console-only.

Supports retail (Standard) and World of Warcraft: Forever from a single TOC. The TOC also
lists the Classic clients (Mists of Pandaria Classic, Titan-Reforged, Anniversary and
Classic Era), but the addon is untested there.

## Pages

- **Soft Targeting**: locked-target behaviour (auto-set target, match locked target,
  soft targeting while locked) and display settings (nameplate icon size, tooltip
  duration, world text).
- **Enemy**, **Friend**, **Interact**: mode, arc, range, nameplate, icon and tooltip
  for each unit type.
- **Interact** also has the interact-only settings: hard range cutoff, icons on game
  objects, low priority icons, interact key sound and, on Forever, only-in-range.

Controls whose CVar doesn't exist in the running client are left out.

## Notes

Settings are registered with `Settings.RegisterProxySetting` over
`Settings.CreateCVarAccessorClosures`. The `Settings.SetupCVar*` helpers build their
setting objects in addon (insecure) code, and because `Settings.GetSetting` walks every
registered setting, that taints Blizzard code such as action button clicks
(`UseAction()` gets blocked).

Protected CVars (enemy and interact mode and range, and auto-set target) are greyed
out in combat.
