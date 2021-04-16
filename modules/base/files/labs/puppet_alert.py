#!/usr/bin/python3
#
# Copyright (c) 2019 Wikimedia Foundation and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Send an alert email to project members about a puppet failure.  This is
meant to be run on the affected instance.
"""
import calendar
import logging
import os
import socket
import sys
import time

from notify_maintainers import email_admins

sys.path.append("/usr/local/sbin/")

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24

logger = logging.getLogger(__name__)


def lastrun():
    # last_run_summary.yaml reports the last run but it updates the stamp even
    # on failed runs. Instead, check to see the last time puppet actually did
    # something.
    try:
        return os.path.getmtime("/var/lib/puppet/state/classes.txt")
    except os.error:
        logger.warning(
            "Unable to determine last puppet run; classes.txt missing."
        )
        # Returning 0 should imply that puppet has been broken since day one,
        # which is likely the case here!
        return 0


def main():
    elapsed = calendar.timegm(time.gmtime()) - lastrun()
    if elapsed > NAG_INTERVAL:

        try:
            with open("/etc/wmflabs-project") as f:
                project_name = f.read().strip()

        except Exception as error:
            logger.warning(
                "Unable to determine the current vm project: %s", error
            )
            project_name = "no_project"

        fqdn = socket.getfqdn()
        ip = socket.gethostbyname(socket.gethostname())

        # No f-strings until after Stretch goes away! Instead we have this ugly
        # stuff.
        subject = "[Cloud VPS alert][{}] Puppet failure on {} ({})".format(
            project_name, fqdn, ip
        )

        logger.info(
            (
                "It has been %s seconds since last Puppet run. Sending nag "
                "emails."
            ),
            NAG_INTERVAL,
        )

        body = """
Puppet is failing to run on the "{fqdn} ({ip})" instance in project
{project_name} in Wikimedia Cloud VPS.

Working Puppet runs are needed to maintain instance security and logins.
As long as Puppet continues to fail, this system is in danger of becoming
unreachable.

You are receiving this email because you are listed as member for the
project that contains this instance.  Please take steps to repair
this instance or contact a Cloud VPS admin for assistance.

You might find some help here:
    https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Cloud_VPS_alert_Puppet_failure_on

For further support, visit #wikimedia-cloud on freenode or
<https://wikitech.wikimedia.org>
""".format(fqdn=fqdn, ip=ip, project_name=project_name)
        email_admins(subject, body)


if __name__ == "__main__":
    main()
