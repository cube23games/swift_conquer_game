# SC-300 v4 — Short-Landscape Drawer Repair

GitHub run `41184937234` proved the SC-300 application compiles and its runtime
and determinism tests pass. The next gate found a 12-pixel bottom RenderFlex
overflow at 640x360.

The repair deliberately changes only `RtsProductionDrawer`:

1. Before HQ deployment, the disabled Structures section is no longer forced
   open. It remains visible as a locked section labeled `Deploy HQ to unlock`.
2. Catalog tiles retain a 92-pixel minimum visual size but may grow vertically
   when narrow widths cause subtitle wrapping.

This preserves the intended mobile UX while removing a hard height constraint.
The existing short-landscape tests remain authoritative.
