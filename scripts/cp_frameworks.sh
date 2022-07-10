#!/bin/sh
set -euo pipefail
echo "Use carthage to copy framework"

if [ -x /usr/local/bin/carthage ]; then
    carthage=/usr/local/bin/carthage
elif [ -x /opt/homebrew/bin/carthage ]; then
    carthage=/opt/homebrew/bin/carthage
else
    echo "Cannot find carthage"
    exit 1
fi

$carthage copy-frameworks
