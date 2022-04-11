#!/bin/bash

set -e
set -u

/usr/local/bin/acme-chief-designate-tidyup.py | \
logger -t acme-chief-designate-tidyup
