#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/dumps/otherdumps/dailies.sh
#############################################################

source /usr/local/bin/dump_functions.sh

#/usr/bin/find ${otherdir}/pagetitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \; ; /usr/bin/find ${otherdir}/mediatitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \;
#cd ${repodir}; /usr/bin/python onallwikis.py --configfile ${confsdir}/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${otherdir}/pagetitles/{d}' --query "'select page_title from page where page_namespace=0;'"
#cd ${repodir}; /usr/bin/python onallwikis.py --configfile ${confsdir}/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --out#dir '${otherdir}/mediatitles/{d}' --query "'select page_title from page where page_namespace=6;'"
