#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"

try-parse-package()
{
    local package="$1"
    rm -rf "$STAGE/packages/"*
    cp -r "$HERE/packages/$package" "$STAGE/packages/"
    pkman query &>/dev/null
}

test-good-package()
{
    local package="$1"
    local name="$2"
    try-parse-package "$package"
    ok $? "$name"
}

test-bad-package()
{
    local package="$1"
    local name="$2"
    try-parse-package "$package"
    (($? != 0))
    ok $? "$name"
}

plan 6
test-good-package 'simple.1.0.0' 'directories with correct metadata are okay'
test-good-package 'simple.1.0.0.zip' 'ZIP archives with correct metadata are okay'
test-good-package 'no-version' 'packages without version are okay'
test-bad-package 'no-type.1.0.0' 'missing type generates error'
test-bad-package 'version-mismatch.1.0.0' 'version mismatch generates error'
test-bad-package 'empty' 'empty directories are no packages'
