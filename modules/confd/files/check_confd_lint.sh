#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Check for existence of confd template linting err state
# files and report last modtime which should equate to
# last error.  Files _do not exist_ without errant state
#
# If confd is reporting a bad lint for a template
# the best way to narrow it down is to run 'confd'
# with the appropriate options for srv and
# '-onetime=true' which will output the individual
# template health
#
# * A global linting error is surfaced and not per template

/bin/ls /var/run/confd-template/*.err &>/dev/null
if [ $? -eq 0 ]; then
    target=$(/bin/ls -t /var/run/confd-template/*.err | head -1)
    mtime=$(/usr/bin/stat -c "%n last %y" $target)
    echo "CRITICAL - ${mtime}"
    exit 2
fi

echo "OK"
exit 0
