# SC-272A — Unified Mobile Production Workflow

## Player contract

- The first Barracks and first War Factory retain the Primary behavior from
  SC-271B.
- The right-side drawer is now one vertically scrollable command surface.
- Sections expand and collapse independently.
- Infantry appears when a Barracks exists.
- Vehicles appear when a Refinery or War Factory exists.
- Special Powers remains an architectural placeholder until advanced
  technology is implemented.
- Repeated taps enqueue units rather than spawning them instantly.
- Every Barracks, Refinery, and War Factory owns its own queue.
- New infantry and tank orders route to the current primary building.
- Existing orders remain in the facility where they were placed.
- Ready units wait if every tested spawn position is occupied.
- Queue progress is visible on the battlefield.

## Prototype values

These values exist only to exercise the queue system:

- Rifle Infantry: 3 seconds
- Harvester: 5 seconds
- Tank: 6 seconds
- Queue capacity: 5

They are not final balance canon.
