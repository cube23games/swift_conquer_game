# Train Package Layout

```text
TRAIN_PACKAGE/
├── README.md
├── TRAIN_METADATA.json
├── SHADOW_GREEN_LOCK.json
├── SHA256SUMS.txt
└── stages/
    └── STAGE-01/
        ├── STAGE_METADATA.json
        └── payload/
            └── exact/changed/files
```

`STAGE_METADATA.json` records the stage ID, order, title, commit message, exact changed-file allowlist, input SHA-256, output SHA-256, stage verifiers, and historical verifiers.

The production runner must reject any payload difference from the metadata and any internal package difference from `SHA256SUMS.txt`.
