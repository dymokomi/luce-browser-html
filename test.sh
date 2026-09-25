#!/bin/sh
# Type-check every module of luce-browser-html (and run its tests once there are any).
# Stops at the first failing step.
set -e
cd "$(dirname "$0")"

for module in html_syntax; do
    echo "== luce-base check src/luce_browser_html/$module"
    luce-base check "src/luce_browser_html/$module"
done
