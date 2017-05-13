#!/bin/bash
# vim: set filetype=sh:
source "$(dirname "$0")/common.bash"

mkdir "$STAGE/packages"
ln -s "$HERE/packages/simple.1.0.0.zip" "$STAGE/packages/"

start-webserver --root "$STAGE"

cat >"$STAGE/config.json" <<EOF
{
   "repositories":
   [
      "$WEBSERVER_URL/index.json"
   ]
}
EOF

plan 4
command-ok 'pkman generate-index "$WEBSERVER_URL/packages" "$STAGE/index.json"'
command-ok 'test -f "$STAGE/index.json"'

command-ok 'pkman update'
test -f "$STAGE/repositories/"*
ok $? 'repository index exists'
