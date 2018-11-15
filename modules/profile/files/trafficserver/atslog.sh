#!/bin/sh
# atslog -- print ATS non-PURGE logs to standard output

LOG_SOCKET=/var/run/trafficserver/notpurge.sock fifo-log-tailer "$@"
