#!/bin/bash
#
# check_sysctl.sh - check running sysctl values against configuration files
# note: this will print only one mismatch to keep alert text concise
# 2017 Keith Herron <kherron@wikimedia.org>

# Command locations
sysctl_bin=$(which sysctl)
sudo_bin=$(which sudo)
sysctl_cmd="${sudo_bin} ${sysctl_bin}"

function print_help() {
    echo "
      $0 - check sysctl config file(s) against running values

      usage: $0 -f <file>

      options:
          -f  Required. Sysctl configuration file location(s). Use globbing to
              specify multiple files.
          -h  Print this help text.
    "

    exit 3
}

# Check that options were provided.
if [ $# -lt 1 ]; then
    print_help
fi

# Gather options. -f requires an argument -h does not.
while getopts 'f:h' OPT; do
    case $OPT in
        f)  files=$OPTARG;;
        h)  print_help;;
        *)  print_help;;
    esac
done

# Check if provided file(s) exist.
for file in ${files}; do
    if [ ! -r "${file}" ]; then
        echo "error: config file ${file} does not exist"
        print_help
        exit 1
    fi
done

for file in ${files}; do

    while read -r line; do

        # Skip lines that do not begin with an alphanumeric.
        [[ "${line}" =~ ^[:alnum:] ]] || continue

        # Remove whitespace from line.
        line=${line//[[:space:]]/}

        # Split line into key/val variables using = delimiter.
        configured_key="${line%=*}"
        configured_val="${line#*=}"

        running_val=$($sysctl_cmd -b "${configured_key}" 2>/dev/null)

        if [ -n "${running_val}" ]; then
            if [ "${running_val}" != "${configured_val}" ]; then
                echo -n "WARNING: "
                echo "${configured_key} running value ${running_val} does not match value of ${configured_val} configured in ${file}"
                exit 1
            else
                matched=yes
            fi
        fi

    done < "${file}"

done

if [ -n "${matched}" ]; then
    echo -n "OK: "
    echo "Running sysctl values match config file(s) ${files}"
    exit 0
else
    echo -n "UNKNOWN: "
    echo "No entries in this file match matched running values. Are you sure this is a sysctl config file?"
    exit 3
fi
