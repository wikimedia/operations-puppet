#!/bin/bash
/usr/bin/timeout 10m /usr/bin/nice -n 19 /usr/bin/ionice -c 3 /usr/bin/du -b -s $1
