# Partly stolen/derived from: https://github.com/goozbach/bash-tap-functions/blob/master/tap-functions

_executed_tests=0

plan()
{
    local count=${1:?}
    echo "1..$count"
}

skip-all()
{
    local reason=$1
    echo "1..0 # skip $reason"
    exit 0
}

diag-stream()
{
    sed 's/^/# /'
}

diag()
{
    echo "$@" | diag-stream
}

BAIL-OUT()
{
    local reason=$1
    echo "Bail out! $reason" >&2
    exit 255
}

ok()
{
    local result=${1:?}
    local name=$2

    _executed_tests=$(($_executed_tests + 1))

    if [[ $result -ne 0 ]]; then
        echo -n 'not '
    fi
    echo -n "ok $_executed_tests"

    if [[ -n "$name" ]]; then
        echo -n " - $name"
    fi

    echo # print \n
}

skip()
{
    local reason=$1
    _executed_tests=$(($_executed_tests + 1))
    echo "ok $_executed_tests # skip $reason"
}



command-ok()
{
    diag "Output of '$*':"
    eval $@ | diag-stream
    ok ${PIPESTATUS[0]} "$*"
}

_equals()
{
    local result="${1:?}"
    local constant="${2:?}"

    if [[ "$result" == "$constant" ]]; then
        return 0
    else
        return 1
    fi
}

is()
{
    local result="$1"
    local constant="${2:?}"
    local name="$3"

    _equals "$result" "$constant"
    local r=$?
    ok $r "$name"
    if (( r != 0 )); then
        diag "         got: '$result'"
        diag "    expected: '$constant'"
    fi
}

isnt()
{
    local result="$1"
    local constant="${2:?}"
    local name="$3"

    _equals "$result" "$constant"
    (( $? != 0 )) # invert $?
    local r=$?
    ok $r "$name"
    if (( r != 0 )); then
        diag "         got: '$result'"
        diag "    expected: anything else"
    fi
}

_bash_major_version=${BASH_VERSION%%.*}
_matches()
{
    local result="$1"
    local pattern="${2:?}"

    if [[ -z "$result" || -z "$pattern" ]]; then
        return 1
    else
        if (( _bash_major_version >= 3 )); then
            eval '[[ "$result" =~ "$pattern" ]]'
        else
            echo "$result" | egrep -q "$pattern"
        fi
    fi
}

like()
{
    local result="$1"
    local pattern="${2:?}"
    local name="$3"

    _matches "$result" "$pattern"
    local r=$?
    ok $r "$name"
    if (( r != 0 )); then
        diag "    '$result' doesn't match '$pattern'"
    fi
}

unlike()
{
    local result="$1"
    local pattern="${2:?}"
    local name="$3"

    _matches "$result" "$pattern"
    (( $? != 0 )) # invert $?
    local r=$?
    ok $r "$name"
    if (( r != 0 )); then
        diag "    '$result' matches '$pattern'"
    fi
}
