#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

cat >"$STAGE/config.json" <<EOF
{
   "repositories":
   [
      "$WEBSERVER_URL/index.json"
   ],
   "searchPaths": []
}
EOF

mkdir "$STAGE/repositories"

start-webserver --root "$HERE/example-server"

plan 2
command-ok 'pkman update'
test -f "$STAGE/repositories/"*
ok $? 'repository index exists'
