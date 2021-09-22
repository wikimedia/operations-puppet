#!/bin/bash
source /etc/mail-exim-aliases
/usr/bin/mail -s '${SUBJECT}' ${RECIPIENT} < ${ALIAS_FILE}
