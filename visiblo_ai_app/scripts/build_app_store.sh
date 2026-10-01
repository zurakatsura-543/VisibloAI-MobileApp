#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Clear native assets staged by simulator builds before archiving for devices.
flutter clean
flutter build ipa --release --export-method=app-store "$@"
for ipa in build/ios/ipa/*.ipa; do
  /usr/bin/python3 scripts/validate_ios_ipa.py "$ipa"
done
