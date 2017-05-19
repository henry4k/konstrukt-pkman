#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"
mkdir "$STAGE/repositories"

start-webserver --root "$HERE/example-server"

cat >"$STAGE/config.json" <<EOF
{
   "searchPaths": ["$STAGE/packages"],
   "repositories": ["$WEBSERVER_URL/index.json"],
   "documentationCacheDir": "$STAGE/documentation",
   "repositoryCacheDir": "$STAGE/repositories"
}
EOF


plan 2
command-ok 'pkman update'
test -f "$STAGE/repositories/"*
ok $? 'repository index exists'
