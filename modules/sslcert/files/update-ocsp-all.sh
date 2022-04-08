#!/bin/bash

set -e
set -u

/usr/local/sbin/update-ocsp-all 2>&1 | \
logger -t update-ocsp-all
