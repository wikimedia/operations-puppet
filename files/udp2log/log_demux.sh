#!/usr/bin/env bash

# Clicktracking Demuxing Script
# Author: Ori Livneh
#
# Reads logs from standard input. Writes each intro into a file whose name is
# generated from the extension and active site names. If unspecified,
# destination folder defaults to "/var/log". This script is meant to have the
# output of udp2log piped into it.
#
# Log rotation can be implemented by adding $(date +%F) to the file mask.
#
# Usage: log_demux.sh [destination folder]

LOGDIR=${1:-"/var/log"}

while IFS= read -r line ; do
	read -r wiki identifier tail <<< "${line}"
	IFS="@-" read -r extension version event tail <<< "${identifier}"

	# If this does not appear to be a clicktracking log line, skip.
	if [[ "$extension" == ext* ]] ; then
		# If the message appears well-formed, interpolate it with the
		# file mask to generate a destination file name.
		logname="${wiki}-${extension#ext.}"
	else
		# Malformed messages are written into a default logfile.
		logname="default"
	fi
	logfile="${LOGDIR}/${logname}.log"
	printf '%s\n' "${line}" >> "${logfile}" \
		|| echo "Error writing to ${logfile}" >&2
done
