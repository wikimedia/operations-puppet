#!/bin/bash

DELIMITER='|'

usage () {

echo "USAGE: [-c CONFIGFILE] [\"NAME|DIRECTORY PATTERN|FILTER\"]"

}

# USAGE: collect NAME DIRECTORY_PATTERN [FILTER]
collect () {

# Globbing is expected
# shellcheck disable=SC2086
DIRS=$(find $2 -maxdepth 0 -type d -not -path "${3}")

# Expansion is expected
# shellcheck disable=SC2086
timeout 10m nice -n 19 ionice -c 3 du --block-size=1 --summarize ${DIRS} 2>/dev/null \
    | awk -v name="${1}" '{ printf("node_directory_size_bytes{directory=\"%s\",name=\"%s\"} %d\n", $2, name, $1); }' \
    >> "${OUTFILE}"

}

if [ $# -eq 0 ]; then
    usage
    exit 0
else
    if [ "${1}" == "-h" ]; then
        usage
        exit 0
    fi
    if [ "${1}" == "-c" ]; then
        export CONFIGFILE=$2
        if [ -e "${CONFIGFILE}" ]; then
            # shellcheck source=config
            # shellcheck disable=SC1091
            source "${CONFIGFILE}"
        fi
    else
        export OUTFILE=/dev/stdout
        # shellcheck disable=SC2124
        export TO_MEASURE=$@
    fi

fi

echo '# HELP node_directory_size_bytes Directory size in bytes' > "${OUTFILE}"
echo '# TYPE node_directory_size_bytes gauge' >> "${OUTFILE}"
for I in "${TO_MEASURE[@]}"; do
    collect "$(echo "${I}" | cut -d "${DELIMITER}" -f 1)" "$(echo "${I}" | cut -d "${DELIMITER}" -f 2)" "$(echo "${I}" | cut -d "${DELIMITER}" -f 3)"
done

if [ ! '/dev/stdout' == $OUTFILE ]; then
    mv "${OUTFILE}" "${OUTFILE}.prom"
fi
