#!/bin/bash
# Script used to determine if HHVM needs to be restarted.
# Will return an exit code of 0 if HHVM needs to be restarted,
# and 1 if it doesn't.

# Maximum number of days HHVM should run without being restarted
MAX_RUN_DAYS=3
MAX_RUN=$(( 86400 * ${MAX_RUN_DAYS} ))
# Maximum memory occupation from HHVM before being restarted
MAX_MEM=40
# Maximum queue size with respect to the load before being restarted.
# This is very dangerous and should only be defined after very careful consideration
MAX_QUEUE_RATIO=

RUN_TIME=$(ps -C hhvm -o etimes= | head -n 1 )
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
