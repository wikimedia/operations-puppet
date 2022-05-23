#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# cron script to perform monthly login accounting.
#
# Written by Ian A. Murdock <imurdock@gnu.ai.mit.edu>
# Modified by Dirk Eddelbuettel <edd@debian.org>
# Modified by Tero Tilus <terotil@www.haapavesi.fi>
#   patch adopted by Christian Perrier <bubulle@debian.org> for #187538

LOGROTATE="/etc/cron.daily/logrotate"

test -x /usr/sbin/accton || exit 0

	echo "Login accounting for the month ended `date`:" > /var/log/wtmp.report
	echo >> /var/log/wtmp.report

	# The logrotate script happens to run before this one, effectively
	# swallowing all information out of wtmp before we can use it.
	# Hence, we need to use the previous file. Bad hack.
	# Too bad we never heard from the logrotate maintainer about this ...

	# edd 18 May 2002  make sure wtmp.1 exists

	# patch: conditional backported from debian/6.6.4-3
	# https://salsa.debian.org/pkg-security-team/acct/-/commit/83278eebd2d1caedfd4e664b2eff2972d5235341#ad11888c85d613885a59efcd8449d5029e3da7fb_30_30
	if test -f /var/log/wtmp.1 || test -f /var/log/wtmp.1.gz; then
	# end patch
		if [ -f /var/log/wtmp.1 ]
		then
			WTMP="/var/log/wtmp.1"
		elif [ -f /var/log/wtmp.1.gz ]
		then
			WTMP_WAS_GZIPPED="1"
			WTMP="`tempfile`"

			gunzip -c /var/log/wtmp.1.gz > "${WTMP}"
		fi

		ac -f "${WTMP}" -p | sort -nr -k2 >> /var/log/wtmp.report
		echo >> /var/log/wtmp.report
		last -f "${WTMP}" >> /var/log/wtmp.report

		if [ -n "${WTMP_WAS_GZIPPED}" ]
		then
			# remove temporary file
			rm -f "${WTMP}"
		fi
	else
		ac -p | sort -nr -k2 >> /var/log/wtmp.report
		echo >> /var/log/wtmp.report
		last >> /var/log/wtmp.report
	fi


chown root:adm /var/log/wtmp.report
chmod 640 /var/log/wtmp.report
