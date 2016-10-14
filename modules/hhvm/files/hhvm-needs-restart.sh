#!/bin/bash
# Script used to determine if HHVM needs to be restarted.
# Will return an exit code of 0 if HHVM needs to be restarted,
# and 1 if it doesn't.

# Maximum number of days HHVM should run without being restarted
MAX_RUN_DAYS=3
# Maximum memory occupation from HHVM before being restarted
MAX_MEM=50
# Maximum queue size with respect to the load before being restarted.
# This is very dangerous and should only be defined after very careful consideration
MAX_QUEUE_RATIO=

function usage {
    cat <<EOF
hhvm-needs-restart [-m MAX_MEM] [-d DAYS] [-q QUEUE_RATIO]

Can be used to conditionally verify if any of the conditions for restarting HHVM
are met. Checks are set by command-line flags

 -d sets the number of days the HHVM process might be running before being
    restarted. Defaults to 3 days.
 -m sets the maximum % of memory HHVM can use; if the threshold is exceeded,
    a restart is needed. Defaults to 50%.
 -q the ratio of queued requests compared to the ones being processed above
    which HHVM is assumed to be in a bad state. This is experimental and should
    only be used interactively. Disabled by default.
EOF
    exit 1
}

while getopts ":m:d:q:" opt; do
    case "${opt}" in
        m)
            test $OPTARG && MAX_MEM=$OPTARG
            ;;
        d)
            test $OPTARG && MAX_RUN_DAYS=$OPTARG
            ;;
        q)
            if [ $OPTARG ]; then
                echo "WARNING: setting up the queue check is experimental"
                MAX_QUEUE_RATIO=$OPTARG
            fi
            ;;
        *)
            usage
            ;;
    esac
done


MAX_RUN=$(( 86400 * ${MAX_RUN_DAYS} ))

RUN_TIME=$(ps -C hhvm -o etimes= | head -n 1 )

# Check that HHVM is running, first.
test ${RUN_TIME} || exit 1

if (( ${RUN_TIME} > ${MAX_RUN} )); then
    echo "HHVM needs restarting: running since ${RUN_TIME} seconds"
    exit 0
fi

# Used Memory
/bin/ps -C hhvm -o pmem= | awk -v max_mem=${MAX_MEM} '{sum+=$1}
END {
  if (sum > max_mem) {
    print "HHVM needs restart: using " sum "% of available memory";
    exit 0;
  }
}'

# Queue size
# If not defined, just exit as if everything is fine
test -z $MAX_QUEUE_RATIO && exit 1
HIGH_RATIO=$(hhvmadm check-health | \
                    jq "if (.queued > (${MAX_QUEUE_RATIO} * .load)) then 1 else 0 end")
if (( $HIGH_RATIO )); then
    print "HHVM needs restart: queue > ${MAX_QUEUE_RATIO} * load"
    exit 0
fi
# No need for a restart
exit 1
