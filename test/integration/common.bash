NAME="$(basename "$0" .t)"
HERE="$PWD/$(dirname "$0")"

setup()
{
    STAGE="$(mktemp --tmpdir --directory "konstrukt-pkman.test.$NAME.XXX")"
    trap teardown EXIT
}

teardown()
{
    rm -r "$STAGE"
    if test -n "$WEBSERVER_PID"; then
        stop-webserver
    fi
}

read-property()
{
    sed -n -e "/^$1: / {
        s/^$1: //
        p
        q
    }" $2
}

start-webserver()
{
    mkfifo "$STAGE/webserver.fifo"
    "$HERE/webserver" $@ >"$STAGE/webserver.fifo" &
    WEBSERVER_PID=$!
    WEBSERVER_URL="$(read-property url "$STAGE/webserver.fifo")"
}

stop-webserver()
{
    curl --silent "$WEBSERVER_URL/stop"
    wait $WEBSERVER_PID
    unset WEBSERVER_PID
    unset WEBSERVER_URL
}

pkman()
{
    # launch pkman with correct config and try to enable luacov
    lua5.2 - --config "$STAGE/config.json" $@ <<EOF
    arg[0] = './pkman'
    pcall(require, 'luacov')
    dofile(arg[0])
EOF
}

source "$HERE/tap.bash"

setup
