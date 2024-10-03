#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

# This script is used to dump the labswiki database compressed and saves to the dump_dir

dump_dir=$1
/usr/local/bin/mwscript maintenance/dumpBackup.php labswiki --current --uploads  | \
    sed 's/<model>yaml<\/model>/<model>wikitext<\/model>/g'                      | \
    sed 's/<format>application\/yaml<\/format>/<format>text\/x-wiki<\/format>/g' | \
    nice -n 19 gzip -9 > ${dump_dir}/labswiki-$(date '+%Y%m%d').xml.gz
