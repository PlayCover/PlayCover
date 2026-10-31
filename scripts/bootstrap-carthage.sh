#!/bin/sh
# Checkout PlayTools, then build it.
# swift-nio floats swift-collections to 1.7.4, whose swift-tools-version 6.4
# sources do not compile on Xcode 27.0 (27A5194q). Pin 1.1.3 before compiling.
set -eu

if [ -x /usr/local/bin/carthage ]; then
    carthage=/usr/local/bin/carthage
elif [ -x /opt/homebrew/bin/carthage ]; then
    carthage=/opt/homebrew/bin/carthage
elif [ -x /opt/local/bin/carthage ]; then
    carthage=/opt/local/bin/carthage
else
    echo "Cannot find carthage"
    exit 1
fi

if [ -z "${SRCROOT:-}" ]; then
    echo "SRCROOT is not set"
    exit 1
fi

cd "$SRCROOT"

# A checkout left behind without git metadata makes `carthage update` refuse to replace it.
if [ -d Carthage/Checkouts/PlayTools ] && [ ! -e Carthage/Checkouts/PlayTools/.git ]; then
    rm -rf Carthage/Checkouts/PlayTools
fi

if [ -e Carthage/Checkouts/PlayTools/.git ]; then
    echo "Using the PlayTools repo already checked out in this project."
    echo "Skipping carthage update so that checkout stays the only copy."
else
echo "Bootstrapping carthage"
env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" "$carthage" update --no-build --use-xcframeworks
fi

resolved="Carthage/Checkouts/PlayTools/PlayTools.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
/usr/bin/python3 - "$resolved" << 'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
# This graph is what actually compiles on Xcode 27.0 (27A5194q).
# Leaving resolution unpinned selects swift-collections 1.7.4, which does not.
data = {
    "originHash": "dd4b3820190814028b7a4ca2c138f5215df145753ed2a434b6bb89422721bd74",
    "pins": [
        {
            "identity": "swift-atomics",
            "kind": "remoteSourceControl",
            "location": "https://github.com/apple/swift-atomics.git",
            "state": {
                "revision": "0442cb5a3f98ab802acb777929fdb446bda11a34",
                "version": "1.3.1",
            },
        },
        {
            "identity": "swift-collections",
            "kind": "remoteSourceControl",
            "location": "https://github.com/apple/swift-collections.git",
            "state": {
                "revision": "9bf03ff58ce34478e66aaee630e491823326fd06",
                "version": "1.1.3",
            },
        },
        {
            "identity": "swift-nio",
            "kind": "remoteSourceControl",
            "location": "https://github.com/apple/swift-nio",
            "state": {
                "revision": "6db9d9abd92ad7399b8a564cafbb87d3507245fa",
                "version": "2.104.0",
            },
        },
        {
            "identity": "swift-system",
            "kind": "remoteSourceControl",
            "location": "https://github.com/apple/swift-system.git",
            "state": {
                "revision": "869129b7bf4ecc57b97d0193ad29690ca2134750",
                "version": "1.8.1",
            },
        },
        {
            "identity": "swordrpc",
            "kind": "remoteSourceControl",
            "location": "https://github.com/PlayCover/SwordRPC",
            "state": {
                "branch": "main",
                "revision": "4403152a16a040d8448d33d65ad5a034c9d1fa1b",
            },
        },
    ],
    "version": 3,
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2) + "\n")
print("Pinned PlayTools packages (swift-collections 1.1.3)")
PY

env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" "$carthage" build --cache-builds --use-xcframeworks
