# SC-300 Application Contract

## One authoritative runtime

The player-facing application must read and mutate one
`SwiftRtsRuntime` instance. The UI cannot keep parallel copies of credits,
power, queues, selection, primary facilities or combat state.

## Mobile controls

- One finger: select, tap commands and drag-box unit selection.
- Two fingers: pan and pinch zoom together.
- Production drawer overlays the battlefield.
- Drawer/scrim interactions do not emit battlefield commands.
- Camera bookmarks 1–5 remain available at the top.
- Control groups 1–7 support recall and long-press assignment.

## Base loop

1. Start with one central Mobile HQ Center.
2. Move it if desired.
3. Explicitly deploy Headquarters.
4. Queue structures at Headquarters.
5. When a structure is READY, tap valid ground to place it.
6. Build Power Plant, Barracks, Refinery, War Factory and advanced structures
   according to data prerequisites.
7. Harvest ore, unload at a Refinery and expand Silo capacity.
8. Queue units at real facilities.
9. First matching production facility becomes Primary.
10. Reassign Primary without moving already-owned queue items.
11. Completed units wait when exits are blocked.
12. Rally points move new units away from production exits.

## Tactical loop

- formation move orders;
- target attacks and auto-acquisition;
- health/destruction;
- Engineer repair/capture/sabotage;
- Spy infiltration/stolen-tech compromise;
- locked 10% compromised-source purge;
- fog/shroud hidden/explored/visible states;
- advanced-tech generic special-power charging;
- sudden-death storm pressure;
- deterministic AI.

## Release integrity

- deterministic runtime snapshot;
- state hash;
- replay journal;
- integrity monitor hook;
- production branch remains untouched until an audited promotion;
- physical-device gate is mandatory after GitHub green.
