# SC-300 v6 — Base Verifier Compatibility

SC-300 v5 never reached GitHub. `tools/verify_sc300.py` stopped it because the UI test description no longer contained the required literal token `drawer handle closes production overlay`.

v6 restores that wording while keeping the stronger independent-frame checks and the collapsed-section unmount repair.

The v6 verifier explicitly preserves the original SC-300 UI test tokens:
- `short landscape phone`
- `drawer handle closes production overlay`
- `ChoiceChip`

No gameplay/runtime behavior is changed.
