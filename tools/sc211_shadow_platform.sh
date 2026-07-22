#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

if [ ! -d android ]; then
  flutter create . \
    --platforms=android \
    --project-name swift_conquer_game \
    --org com.swiftconquer
fi

flutter pub get
flutter build apk --release
test -f build/app/outputs/flutter-apk/app-release.apk
sha256sum build/app/outputs/flutter-apk/app-release.apk
