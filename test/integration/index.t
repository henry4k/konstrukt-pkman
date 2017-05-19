#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"
mkdir "$STAGE/repositories"
ln -s "$HERE/packages/simple.1.0.0.zip" "$STAGE/packages/"

start-webserver --root "$STAGE"

cat >"$STAGE/config.json" <<EOF
{
   "searchPaths": ["$STAGE/packages"],
   "repositories": ["$WEBSERVER_URL/index.json"],
   "documentationCacheDir": "$STAGE/documentation",
   "repositoryCacheDir": "$STAGE/repositories"
}
EOF

plan 4
command-ok 'pkman generate-index "$WEBSERVER_URL/packages" "$STAGE/index.json"'
command-ok 'test -f "$STAGE/index.json"'

command-ok 'pkman update'
test -f "$STAGE/repositories/"*
ok $? 'repository index exists'
