#!/bin/bash
set -u
set -e
source /etc/geoipupdate_job

if [[ $(hostname -f) == ${puppet_ca_server} ]]; then
    /usr/bin/printf "$(/bin/date -Iseconds): geoipupdate attempting to download MaxMind .dat files into \"${data_directory}\"" >> ${geoipupdate_log} && \
    /usr/bin/geoipupdate -f "${config_file}" -d "${data_directory}" &>> ${geoipupdate_log}
else
    /usr/bin/printf "$(/bin/date): geoipupdate skipping download of MaxMind .dat files into \"${data_directory}\". This is not the CA server and we sync the entire volatile dir from there separately." >> ${geoipupdate_log}
fi
