# Production Train

Production promotion is deliberately slower than shadow validation.

- Start from the exact approved baseline.
- Create a safety branch at that baseline.
- Apply one shadow-green stage.
- Run local source verifiers allowed by the profile.
- Commit and push one stage.
- identify the exact production CI run by head SHA.
- watch the saved run ID.
- stop on red, pause on verification unavailability, continue on green.
- never tag automatically.

The production CI remains authoritative even after shadow green. Shadow CI reduces surprises; it does not replace production CI.
