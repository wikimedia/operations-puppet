#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
source /etc/mail-exim-aliases
/usr/bin/mail -s "${SUBJECT} from $(hostname -s)" ${RECIPIENT} < ${ALIAS_FILE}
