#!/bin/bash
# This script should not be necessary. The python should be capable of this check
set -e

if ! `/usr/local/bin/labs-ip-alias-dump.py --check-changes-only`; then
    /usr/local/bin/labs-ip-alias-dump.py; /usr/bin/rec_control reload-lua-script
fi
