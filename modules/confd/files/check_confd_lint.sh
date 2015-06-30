#!/bin/bash
# Check for existence of confd template
# linting err state file and report
# last modtime which should equate to
# last error.  This file _does not exist_
# without errant state
#
# If confd is reporting a bad lint for a template
# the best way to narrow it down is to run 'confd'
# with the appropriate options for srv and
# '-onetime=true' which will output the individual
# template health

target='/var/run/confd_template_lint.err'
if [ -e "$target" ]; then
    mtime=$(/usr/bin/stat -c "%n last %y" $target)
    echo "CRITICAL - ${mtime}"
    exit 2
fi

echo "OK"
exit 0
