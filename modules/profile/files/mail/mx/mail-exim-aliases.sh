#!/bin/bash
source /etc/mail-exim-aliases
/usr/bin/mail -s "${SUBJECT} from $(hostname -s)" ${RECIPIENT} < ${ALIAS_FILE}
