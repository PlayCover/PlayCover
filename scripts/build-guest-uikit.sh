#!/bin/sh
# Builds the dylib every 64-bit guest loads so UIKit scene updates stay on the main queue.
set -eu

SRC="${SRCROOT}/PlayCover/GuestUIKit/GuestUIKit.m"
OUT="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/GuestUIKit.dylib"
IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:--}"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$(dirname "$OUT")"
xcrun --sdk macosx clang \
    -dynamiclib \
    -target arm64-apple-ios14.0-macabi \
    -isysroot "$SDK" \
    -iframework "$SDK/System/iOSSupport/System/Library/Frameworks" \
    -framework Foundation \
    -framework UIKit \
    -framework Security \
    -fobjc-arc \
    -o "$OUT" \
    "$SRC"
vtool -set-build-version maccatalyst 11.0 14.0 -replace -output "$OUT" "$OUT"
codesign --force --sign "$IDENTITY" "$OUT"
