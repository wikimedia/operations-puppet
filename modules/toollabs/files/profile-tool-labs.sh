#!/bin/sh
if tty -s
then
  [ -f /data/project/.system/tips.sh ] && /data/project/.system/tips.sh
fi
