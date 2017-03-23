#!/bin/bash
REDIS_HOST="127.0.0.1"
REDIS_PORT=$1
REPLICA_WARN=${2:-60}
REPLICA_CRIT=${3:-600}
_config_file="/etc/redis/tcp_${REDIS_PORT}.conf"

# TODO: make this scan included files as well in general
function get_in_redis_config {
    local _what=$1;
    local _config=${2:-$_config_file};
    awk "{if (\$1 == \"${_what}\") {for (i=2; i<NF; i++) printf \$i \" \"; print \$NF}}" $_config
}

_opts="-H ${REDIS_HOST} -p ${REDIS_PORT}"

# Find the master password from the config
_masterpass=$(get_in_redis_config "requirepass")
test "$_masterpass" && _opts="${_opts} -x ${_masterpass}"

# Now check the config file and the includes of it for a "slaveof" directive
for incl in $(get_in_redis_config "include");
do
    _slaveof=$(get_in_redis_config "slaveof" $incl | tr ' ' ':')
    test "$_slaveof" && break
done
test "$_slaveof" && _opts="${_opts} -r ${REPLICA_WARN},${REPLICA_CRIT}"

# Run the check
/usr/lib/nagios/plugins/check_redis $_opts
