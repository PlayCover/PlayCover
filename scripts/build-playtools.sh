#!/bin/sh
# Build PlayTools from a local checkout and vendor it as ThirdParty/PlayTools/PlayTools.xcframework.
#
# Usage: scripts/build-playtools.sh
#   PLAYTOOLS_DIR  PlayTools checkout to build (default: ../PlayTools next to this repo)
#   ALLOW_DIRTY=1  build even if the checkout has uncommitted changes
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAYTOOLS_DIR="${PLAYTOOLS_DIR:-$REPO_ROOT/../PlayTools}"
OUTPUT_DIR="$REPO_ROOT/ThirdParty/PlayTools"
XCFRAMEWORK="$OUTPUT_DIR/PlayTools.xcframework"
VERSION_FILE="$OUTPUT_DIR/PlayTools.version.json"

if [ ! -d "$PLAYTOOLS_DIR/PlayTools.xcodeproj" ]; then
    echo "error: PlayTools.xcodeproj not found in $PLAYTOOLS_DIR (set PLAYTOOLS_DIR)" >&2
    exit 1
fi
PLAYTOOLS_DIR="$(cd "$PLAYTOOLS_DIR" && pwd)"

commit="$(git -C "$PLAYTOOLS_DIR" rev-parse HEAD)"
branch="$(git -C "$PLAYTOOLS_DIR" rev-parse --abbrev-ref HEAD)"
remote="$(git -C "$PLAYTOOLS_DIR" config "branch.$branch.remote" || echo origin)"
source_url="$(git -C "$PLAYTOOLS_DIR" remote get-url "$remote" 2>/dev/null || echo unknown)"
if [ -n "$(git -C "$PLAYTOOLS_DIR" status --porcelain)" ]; then
    dirty=true
    if [ "${ALLOW_DIRTY:-0}" != "1" ]; then
        echo "error: $PLAYTOOLS_DIR has uncommitted changes; commit them or rerun with ALLOW_DIRTY=1" >&2
        exit 1
    fi
    echo "warning: building PlayTools with uncommitted changes" >&2
else
    dirty=false
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/playtools-build.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Building PlayTools $commit ($branch) from $PLAYTOOLS_DIR"
# FASTLANE=1 skips the SwiftLint phase inside the PlayTools project.
xcodebuild build \
    -project "$PLAYTOOLS_DIR/PlayTools.xcodeproj" \
    -scheme PlayTools \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$WORK_DIR/DerivedData" \
    ONLY_ACTIVE_ARCH=NO \
    SUPPORTS_MACCATALYST=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY= \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    FASTLANE=1 \
    > "$WORK_DIR/xcodebuild.log" 2>&1 || {
        grep -E "error:" "$WORK_DIR/xcodebuild.log" >&2 || tail -n 50 "$WORK_DIR/xcodebuild.log" >&2
        echo "error: PlayTools build failed" >&2
        exit 1
    }

PRODUCTS="$WORK_DIR/DerivedData/Build/Products/Release-iphoneos"
FRAMEWORK="$PRODUCTS/PlayTools.framework"
DSYM="$PRODUCTS/PlayTools.framework.dSYM"

if [ ! -d "$FRAMEWORK/PlugIns/AKInterface.bundle" ]; then
    echo "error: $FRAMEWORK is missing PlugIns/AKInterface.bundle" >&2
    exit 1
fi

# PlayTools ships without library evolution, so the xcframework only carries a .swiftmodule.
set -- -create-xcframework -allow-internal-distribution -framework "$FRAMEWORK"
if [ -d "$DSYM" ]; then
    set -- "$@" -debug-symbols "$DSYM"
fi
xcodebuild "$@" -output "$WORK_DIR/PlayTools.xcframework"

mkdir -p "$OUTPUT_DIR"
rm -rf "$XCFRAMEWORK"
mv "$WORK_DIR/PlayTools.xcframework" "$XCFRAMEWORK"

xcode_version="$(xcodebuild -version | head -n 1)"
swift_version="$(xcrun swift --version 2>/dev/null | head -n 1)"
cat > "$VERSION_FILE" << EOF
{
  "source": "$source_url",
  "commit": "$commit",
  "branch": "$branch",
  "dirty": $dirty,
  "xcode": "$xcode_version",
  "swift": "$swift_version"
}
EOF

echo "Vendored PlayTools $commit into $XCFRAMEWORK"
