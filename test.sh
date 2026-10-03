#!/bin/sh
# Type-check every module of luce-browser-html with warnings as errors, run its unit tests, and
# regenerate html_syntax's named character reference tables into a temporary directory to
# compare them with the committed ones. Stops at the first failing step.
set -e
cd "$(dirname "$0")"

# Every hand-written fragment is laid out as the pinned compiler's formatter lays it out
# (generated fragments are compared with their generator's output instead).
echo "== luce-base fmt --check"
for file in $(git ls-files '*.lucb' | grep -v -e '/generated_' -e '_tables\.lucb$'); do
    luce-base fmt "$file" --check > /dev/null || { echo "$file is not formatted (luce-base fmt $file --write)"; exit 1; }
done

check() {
    echo "== luce-base check $1 -W"
    # -W reports warnings without failing, so any output at all fails the run.
    output=$(luce-base check "$1" -W 2>&1) || { echo "$output"; exit 1; }
    if [ -n "$output" ]; then
        echo "$output"
        exit 1
    fi
}

for module in html_syntax; do
    check "src/$module"
done

# Unit tests (TestHTMLTokenizer.cpp and cases pinned to the donor), module by module.
for module in html_syntax; do
    echo "== luce-base test src/$module"
    luce-base test "src/$module"
done

echo "== tools/gen_entities: regenerate the named character reference tables and compare"
mkdir -p build
luce-base build tools/gen_entities -o build/gen_entities
generated=$(mktemp -d)
trap 'rm -rf "$generated"' EXIT
build/gen_entities data "$generated"
for file in "$generated"/*.lucb; do
    cmp "$file" "src/html_syntax/$(basename "$file")"
done
