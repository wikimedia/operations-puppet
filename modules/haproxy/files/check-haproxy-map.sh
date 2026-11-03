#!/bin/bash -eu
# SPDX-License-Identifier: Apache-2.0
# Or, I hope no one ever tries to reuse this code, but I guess it's still licensed under Apache-2.0
/usr/bin/perl -pe 'die("bad line") unless (/^\s*$/ || /^#/ || /^\S+\s+\S+$/)' "$1" > /dev/null