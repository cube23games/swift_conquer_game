# SwiftConquer SC-213–SC-270 Stage Map

This is the first-pass implementation map used by the master Shadow train.
Unknown canonical faction names, full rosters, and final balance values remain
data-driven placeholders rather than invented lore.

## Foundation

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-213 | Canonical value types and command contract | No | 4 |
| SC-214 | Deterministic clock and seeded random source | No | 3 |
| SC-215 | Command queue and validation boundary | No | 3 |
| SC-216 | Entity registry and immutable identity ownership | No | 3 |
| SC-217 | Ordered simulation system pipeline | No | 3 |
| SC-218 | Replay journal and deterministic state hashing | No | 4 |
| SC-219 | Map grid, spawns, blocked cells, and resources | No | 4 |
| SC-220 | Headless world foundation and first device-gate smoke | Yes | 6 |

## Controls

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-221 | Deterministic multi-selection state | No | 2 |
| SC-222 | Camera intent separated from simulation state | No | 2 |
| SC-223 | Move command and authoritative order application | No | 3 |
| SC-224 | Deterministic mobile formation planner | No | 2 |
| SC-225 | Grid navigation and deterministic path finding | No | 2 |
| SC-226 | Occupancy grid and movement collision reservations | No | 2 |
| SC-227 | Attack command contract and ownership checks | No | 3 |
| SC-228 | Stable target acquisition policy | No | 2 |
| SC-229 | Mobile input adapter emits intents instead of mutating world | No | 2 |
| SC-230 | Controls and movement checkpoint smoke | Yes | 2 |

## Economy

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-231 | Team wallet and configurable starting funds | No | 2 |
| SC-232 | Ore field depletion model | No | 2 |
| SC-233 | Harvester cargo and collection cycle | No | 2 |
| SC-234 | Refinery deposit service | No | 2 |
| SC-235 | Silo overflow storage limits | No | 2 |
| SC-236 | Power grid production and demand accounting | No | 2 |
| SC-237 | Owned-building construction radius rule | No | 2 |
| SC-238 | Mobile HQ deployment and building lifecycle | No | 2 |
| SC-239 | Per-building production queue model | No | 3 |
| SC-240 | Base and economy checkpoint smoke | Yes | 2 |

## Combat

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-241 | Typed deterministic damage packets | No | 2 |
| SC-242 | Armor and weapon specifications | No | 3 |
| SC-243 | Projectile state and deterministic travel | No | 2 |
| SC-244 | Authoritative combat resolver | No | 2 |
| SC-245 | Engineer repair service with three-engineer cap | No | 2 |
| SC-246 | Engineer capture and sabotage progress | No | 2 |
| SC-247 | Low-power penalties for production, engineers, aircraft, and superweapons | No | 2 |
| SC-248 | Deterministic death cleanup and wreck records | No | 3 |
| SC-249 | Enemy auto-retaliation policy | No | 2 |
| SC-250 | Combat and engineer checkpoint smoke | Yes | 2 |

## Domains

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-251 | Data-driven six-slot faction catalog without invented canon | No | 4 |
| SC-252 | Technology graph and unlock prerequisites | No | 3 |
| SC-253 | Spy technology access and stolen-tech removal policy | No | 2 |
| SC-254 | Generic land-unit archetype catalog | No | 3 |
| SC-255 | Aircraft ammo and low-power reload behavior | No | 3 |
| SC-256 | Naval movement and water-domain state | No | 2 |
| SC-257 | Transport and amphibious payload state | No | 2 |
| SC-258 | Superweapon charging and low-power shutdown | No | 2 |
| SC-259 | Configurable balance profile and scale targets | No | 2 |
| SC-260 | Mixed land, air, and naval checkpoint smoke | Yes | 2 |

## Final

| Stage | Title | Device gate | Files |
|---|---|---:|---:|
| SC-261 | Deterministic AI perception snapshot | No | 2 |
| SC-262 | AI economy planner | No | 2 |
| SC-263 | AI combat planner | No | 2 |
| SC-264 | Seeded AI decision scheduler | No | 2 |
| SC-265 | Match rules, timer, and sudden-death state | No | 3 |
| SC-266 | Victory conditions and surviving-team evaluation | No | 2 |
| SC-267 | Integrity monitor and anti-cheat response policy | No | 2 |
| SC-268 | Replay verification against authoritative hashes | No | 2 |
| SC-269 | Interactive Shadow vertical-slice screen | No | 4 |
| SC-270 | Final integrated vertical-slice smoke and device gate | Yes | 2 |

