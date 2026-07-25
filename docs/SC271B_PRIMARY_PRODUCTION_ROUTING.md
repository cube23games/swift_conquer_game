# SC-271B — Primary Production Facility Routing

## Player-facing contract

1. The first completed Barracks is Primary Barracks.
2. Additional Barracks do not replace it.
3. The first completed War Factory is Primary War Factory.
4. Additional War Factories do not replace it.
5. Selecting a non-primary Barracks or War Factory exposes `Make Primary`.
6. Infantry and tank orders no longer require selecting the producing building.
7. If a primary building disappears, the oldest surviving matching building
   becomes primary.
8. A `P` marker identifies each primary production facility on the battlefield.

## Deliberate boundaries

SC-271B establishes routing and ownership only. It does not introduce build
timers, production queues, rally points, spawn reservations, exit-blocked
states, or the final expandable command drawer. Those remain isolated future
stages to preserve deterministic diagnosis.
