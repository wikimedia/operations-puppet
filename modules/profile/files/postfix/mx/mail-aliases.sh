#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -o nounset
# shellcheck source=/dev/null
source /etc/mail-aliases.conf
/usr/bin/mail -s "${SUBJECT} from $(hostname -s)" "${RECIPIENT}" <"${ALIAS_FILE}"
