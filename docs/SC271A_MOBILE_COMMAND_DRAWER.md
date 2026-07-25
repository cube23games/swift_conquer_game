# SC-271A — Mobile Command Drawer and Overflow Rescue

The promoted production-path APK displayed a RenderFlex overflow of 138 pixels
on the physical landscape device. The fixed right sidebar could not scroll,
making Barracks and later structures unreachable. The intended slide-out panel
was also missing.

SC-271A uses classic Command & Conquer / Red Alert information architecture as
a reference without copying proprietary artwork, code, names, or assets:

- right-side command area
- category tabs
- scrollable production choices
- visible unlock requirements
- construction followed by map placement

SwiftConquer adapts that structure for a phone:

- overlay drawer rather than permanently shrinking the battlefield
- right-edge handle and tap-outside dismissal
- responsive width between 280 and 360 logical pixels
- two-column scrollable production grid
- Structures, Infantry, Vehicles, and Tactical tabs
- compact one-row contextual command bar
- control groups and camera bookmarks moved into Tactical
- two-finger pan and pinch zoom
- automatic drawer collapse during map placement

This Shadow patch branches from promotion head
`99cc2376dda51f62a325087301a9cc001fcc98a7`.

It does not update `working/phase170-movement-ci` and creates no tag.
