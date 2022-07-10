#!/bin/sh
set -euo pipefail

echo "Bootstraping carthage"

if [ -x /usr/local/bin/carthage ]; then
    carthage=/usr/local/bin/carthage
elif [ -x /opt/homebrew/bin/carthage ]; then
    carthage=/opt/homebrew/bin/carthage
else
    echo "Cannot find carthage"
    exit 1
fi

$carthage bootstrap --use-xcframeworks

if [ -f cartfile.resolved ]; then
    cartfile_changed=$(git diff --stat $(git_previous_successful_commit) $(git_commit) | grep '\|' | awk '{print $$1}' | grep cartfile.resolved)
    if test "$(cartfile_changed)"; then
        echo "## step: updating carthage"
        $carthage bootstrap --use-xcframeworks
    else
        echo "## carthage is up to date"
    fi
else
    echo "## step: installing carthage dependencies"
    $carthage bootstrap --use-xcframeworks
fi
