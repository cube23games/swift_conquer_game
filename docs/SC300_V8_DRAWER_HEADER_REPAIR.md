# SC-300 v8 — Exact Drawer Header Repair

Diagnostic source:
- run: `41200628037`
- commit: `438e560483b69f971983a61ad19d557c2fa0b0a1`

The v7 render-tree diagnostic identified the exact overflowing RenderFlex:

- creator: `Column <- Expanded <- Row <- SizedBox`
- size: `238 x 54`
- title paragraph: `40 px`
- subtitle paragraph: `26 px`
- combined content: `66 px`
- available header height: `54 px`
- overflow: `12 px`

The text was:
- `SWIFT PRODUCTION`
- `deterministic mobile RTS command surface`

v8 changes only those two header Text widgets:
- `maxLines: 1`
- `softWrap: false`
- `overflow: TextOverflow.ellipsis`

The diagnostic-only test instrumentation is removed and the normal
short-landscape tests are restored.

No gameplay, simulation, economy, AI, combat, engineer, spy, power, replay,
integrity, faction, queue, or match logic changes.
