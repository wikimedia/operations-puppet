#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# check the size of user home dirs
# and send a warning if they become too large (T343364)

source /etc/home_size_warning.conf

for userhome in /home/*; do
    home_dir_size=$(du -s ${userhome} | cut -f1)
    if [ "$home_dir_size" -gt "$home_dir_limit" ]; then
      cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "peopleweb - home dir size warning - ${userhome}" -a "Auto-Submitted: auto-generated" ${rcpt_address}
user ${user} has a home dir larger than ${home_dir_limit} (${home_dir_size}) on host ${hostname}.
(sent via $(basename $0) on $(hostname) at $(date))
EOF
    fi
done
