# SC-300 Clean-Room RTS Reference Notes

SwiftConquer does not copy third-party gameplay source into its runtime.
Public/open source was inspected to understand mature RTS responsibility
boundaries and failure modes.

## Reference repositories

### Electronic Arts — Command & Conquer: Red Alert
Repository:
`https://github.com/electronicarts/CnC_Red_Alert`

Relevant architectural references inspected:

- `CODE/FACTORY.CPP`
- `CODE/FACTORY.H`
- `CODE/SIDEBAR.CPP`
- `CODE/HOUSE.CPP`
- `CODE/BUILDING.CPP`

Design lessons translated into original SwiftConquer systems:

- production state belongs outside rendering/UI;
- production can be suspended, completed, abandoned and refunded;
- the player/house owns economy, power and build legality;
- the sidebar is a presentation/control surface, not the simulation;
- ready production and placement are separate states.

### Electronic Arts — Command & Conquer: Tiberian Dawn
Repository:
`https://github.com/electronicarts/CnC_Tiberian_Dawn`

Relevant references inspected:

- `FACTORY.CPP`
- `SIDEBAR.CPP`
- `HOUSE.CPP`
- `BUILDING.CPP`
- `COMBAT.CPP`

Design lessons:

- player economy and build eligibility should be deterministic;
- combat, buildings, production and presentation are separate concerns;
- build queues should not be hidden inside a screen widget.

### CnCNet Red Alert
Repository:
`https://github.com/CnCNet/CnCNet_RedAlert`

Used as restoration/compatibility context for the classic Red Alert engine and
modern community maintenance practices.

### OpenRA
Repository:
`https://github.com/OpenRA/OpenRA`

Relevant references inspected:

- `OpenRA.Mods.Common/Traits/Player/ProductionQueue.cs`
- `OpenRA.Mods.Common/Traits/Player/ClassicProductionQueue.cs`
- `OpenRA.Mods.Common/Traits/Buildable.cs`
- `OpenRA.Mods.Common/Traits/Power/Player/PowerManager.cs`
- `OpenRA.Game/Traits/Player/Shroud.cs`
- `OpenRA.Mods.Common/Traits/Sellable.cs`

Design lessons translated into SwiftConquer:

- per-building queues and shared/classic queues are distinct concepts;
- primary production buildings should control where globally requested units
  emerge;
- prerequisites belong in data/catalogs;
- power is player-level state that affects dependent systems;
- shroud needs separate hidden, explored and currently visible states;
- sale/refund logic should be a distinct rule rather than a UI shortcut.

### Tiberian Sun context

Electronic Arts has not published a full official Tiberian Sun engine source
release alongside the official Tiberian Dawn/Red Alert GPL releases.
CnCNet/OpenTS projects were therefore used only as public preservation and
behavioral context, not as an authoritative EA engine source.

## SwiftConquer-specific decisions retained

- explicit Mobile HQ deployment;
- mobile-first overlay production drawer;
- Primary Barracks/War Factory behavior;
- queues stay with the facility that owns them;
- rally points and blocked-exit READY holds;
- 15,000 prototype starting credits;
- ore/refinery/silo economy;
- low-power penalties;
- engineers, spies and the locked compromised-building 10% purge rule;
- deterministic AI/replays/integrity hooks;
- 10–15 minute target matches with sudden-death pressure;
- six data-driven faction slots;
- final faction/DLC/ordinary-sale canon remains uninvented.


## Recovered SwiftConquer legacy canon preserved

Legacy faction names recovered from prior project material:

- Swift Dominion
- Iron Pact
- Void Syndicate
- Verdant Union

Legacy DLC names recovered:

- Faction Ascension
- War Machines
- Void Expansion
- Verdant Worlds

The final modern six-faction identities, faction-specific rosters, exact costs,
build times, normal sale/refund rate, complete modern DLC contents, and full
spy-tech mapping remain unresolved and are not invented by SC-300.
