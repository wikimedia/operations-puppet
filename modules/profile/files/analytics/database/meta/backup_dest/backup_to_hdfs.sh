#!/bin/bash

# Copies $source into HDFS $dest_dir/YYYY-MM-DDTHH.MM.SS

set -x
set -e

source="${1}"
dest_dir="${2}"

dest="${dest_dir}/$(date +%FT%H.%M.%S)"

/usr/bin/hdfs dfs -put -f "${source}" "${dest}"
