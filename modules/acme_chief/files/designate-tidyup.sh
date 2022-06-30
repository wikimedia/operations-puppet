#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u

/usr/local/bin/acme-chief-designate-tidyup.py | \
logger -t acme-chief-designate-tidyup
