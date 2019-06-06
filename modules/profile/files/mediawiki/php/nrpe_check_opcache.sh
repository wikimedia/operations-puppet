#!/bin/bash
#RUNBOOK_URL="https://wikitech.wikimedia.org/wiki/Application_servers"
usage() { echo "Usage: $0 -w <int> -c <int>" 1>&2; exit 3; }

numGe() {
    echo "$1" "$2" |awk 'BEGIN {err=1} {if ($1 >= $2) {err=0} } END {exit err}'
}

while getopts ":w:c:" opt; do
    case "$opt" in
        w)
            warning=${OPTARG}
            ;;
        c)
            critical=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$warning" ] || [ -z "$critical" ]; then
    usage
fi

OUT=$(php7adm /opcache-info | jq . 2>&1)
retval=$?
if [ $retval -ne 0 ]; then
   echo "UNKNOWN: Failed to parse output - $OUT"
   exit 3
fi
# First check if the opcache is full
if [[ $(echo "$OUT" | jq .cache_full) == "true" ]]; then
    echo "CRITICAL: opcache full."
    exit 2
fi

# Now check for the opcache cache-hit ratio. If it's below 99.85%, it's a critical alert.
# Skip the check if the service has been restarted since a few minutes.
hits=$(echo $OUT | jq .opcache_statistics.hits)
# We have around 4k files to accelerate. Use 5k for good measure as a base value of expected misses at startup.
if numGe "$hits" 3300000; then
    hitrate=$(echo $OUT | jq .opcache_statistics.opcache_hit_rate)
    if numGe 99.85 "$hitrate"; then
        echo "CRITICAL: opcache cache-hit ratio is below 99.85%"
        exit 2
    fi

    if numGe "$hits" 50000000 && numGe 99.99 "$hitrate"; then
        echo "WARNING: opcache cache-hit ratio is below 99.99"
        exit 1
    fi
fi

# Now check if the free space is below the critical level
freespace=$(echo $OUT | jq .memory_usage.free_memory/1024/1024)
if numGe $critical $freespace; then
    echo "CRITICAL: opcache free space is below $critical MB"
    exit 2
fi

if numGe $warning $freespace; then
    echo "WARNING: opcache free space is below $warning MB"
    exit 1
fi
echo "OK: opcache is healthy"
