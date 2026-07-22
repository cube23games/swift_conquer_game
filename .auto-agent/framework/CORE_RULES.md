# Core Rules

1. Human authorization controls all consequential actions.
2. Lock every operation to the exact repository, account, branch, baseline commit, and origin SHA.
3. Require a clean working tree before mutation.
4. Create a safety branch before a production stage.
5. Use one focused commit per stage.
6. Use exact changed-file allowlists and input/output SHA-256 values.
7. Run the stage verifier and all relevant historical verifiers.
8. Never tag automatically.
9. Never interpret a network or polling failure as a CI failure.
10. Save exact run IDs and reconnect to the same runs.
11. Resume from a verified prefix without duplicate commits.
12. Preserve failed pushed specimens; repairs are new focused stages.
13. Keep `main` untouched during shadow validation.
14. Shadow-test every incremental tree plus the final combined tree.
15. Continue the shadow matrix after individual failures to collect the full failure set.
16. Promote to production only after exact shadow-green evidence exists.
17. Separate implemented, local, shadow-CI, production-CI, artifact, device, store, and backend/provider verification.
18. Keep secrets and private data out of packages and evidence.
19. Reject cache files and generated folders forbidden by the active profile.
20. For phone operators, visible command blocks must remain 40 lines or fewer.
