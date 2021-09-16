#!/bin/bash
set -u
set -e
source /etc/geoipupdate_job_legacy
/usr/bin/printf "$(/bin/date): geoipupdate downloading MaxMind .dat files into \"${data_directory}\"" >> ${geoipupdate_log} && \
/usr/bin/geoipupdate -f "${config_file}" -d "${data_directory}" > ${geoipupdate_log}
