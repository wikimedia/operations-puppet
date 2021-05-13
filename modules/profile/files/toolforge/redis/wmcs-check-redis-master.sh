#!/bin/bash
set -e
redis-cli info replication 2> /dev/null | grep -q 'role:master'
