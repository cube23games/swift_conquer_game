# SC-300 v7 RenderFlex Diagnostic

Goal: identify the exact creator of the persistent 12-pixel vertical overflow
without changing any SwiftConquer production UI or gameplay code.

The diagnostic test preserves all original SC-300 verifier tokens and prints:

- `SC300_FLEX_DIAG phase=drawer-open ...`
- `SC300_FLEX_CREATOR ...`
- full `RenderFlex.toStringDeep(...)` output for each measured overflow
- `SC300_INITIAL_EXCEPTION ...`
- `SC300_FLEX_DIAG phase=after-close ...`
- `SC300_CLOSED_EXCEPTION ...`

The run may remain red by design if the known open-drawer overflow is reproduced.
The evidence is the diagnostic creator path, not a green verdict.
