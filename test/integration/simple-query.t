#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"
cp -r "$HERE/packages/simple.1.0.0" "$STAGE/packages/"

plan 3
like "$(pkman query)" 'simple 1.0.0' 'package is found'
like "$(pkman query simple)" 'simple 1.0.0' 'specific query yields the package'
unlike "$(pkman query xyz)" 'simple' "query doesn't show the package if something else is searched"
