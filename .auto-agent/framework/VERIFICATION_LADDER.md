# Verification Ladder

1. **Implemented** — source exists.
2. **Locally verified** — permitted local static/source checks passed.
3. **Shadow CI verified** — every proposed incremental tree and final combined tree passed the configured shadow matrix.
4. **Production CI verified** — the exact pushed production commit passed the authoritative workflow.
5. **Artifact verified** — built artifact identity, package, version, signature, and checksum were inspected.
6. **Device verified** — installed behavior was tested on a real target device.
7. **Store verified** — store-console or distribution behavior was tested.
8. **Backend/provider verified** — real backend, billing, AI provider, or external service behavior was tested.

A higher level is never inferred from a lower one.
