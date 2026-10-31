# SC-300 v3 Analyzer Repair

Source remains the failed SC-300 v1 commit:
`cc5729b4105912e2849309dad4cb262a58165622`.

SC-300 v2 never committed or pushed because its own verifier correctly stopped
the launcher before `git commit`.

The actual gameplay repair is unchanged from v2:

- `_queueBar` receives `canvas` as a named parameter.
- Tank width is restored to `27 * zoom`.
- Three analyzer-proven unused imports are removed.

v3 additionally repairs the package verifier and workflow-generation mistakes:

- verifier searches for real newline characters, not literal `\n` text;
- workflow parent gate explicitly verifies the failed SC-300 v1 commit;
- package self-test executes the v3 verifier against a temporary staged tree.

No gameplay behavior changes. Protected production remains untouched.
