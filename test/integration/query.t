#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"
mkdir "$STAGE/repositories"
ln -s "$HERE/packages/simple.1.0.0" "$STAGE/packages/"

cat >"$STAGE/config.json" <<EOF
{
   "searchPaths": ["$STAGE/packages"],
   "repositories": [],
   "documentationCacheDir": "$STAGE/documentation",
   "repositoryCacheDir": "$STAGE/repositories"
}
EOF

plan 3
like "$(pkman query)" 'simple 1.0.0' 'package is found'
like "$(pkman query simple)" 'simple 1.0.0' 'specific query yields the package'
unlike "$(pkman query xyz)" 'simple' "query doesn't show the package if something else is searched"
