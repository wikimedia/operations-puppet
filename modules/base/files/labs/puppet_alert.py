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

import yaml
from notify_maintainers import email_admins

sys.path.append("/usr/local/sbin/")

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24
PUPPET_STATE_FILE = "/var/lib/puppet/state/last_run_summary.yaml"
# last_run_summary.yaml reports the last run but it updates the stamp even
# on failed runs. Instead, check to see the last time puppet actually did
# something.
PUPPET_SUCCESS_TIMESTAMP_FILE = "/var/lib/puppet/state/classes.txt"

logger = logging.getLogger(__name__)


def get_last_success_time():
    return os.path.getmtime(PUPPET_SUCCESS_TIMESTAMP_FILE)


def get_last_run_summary():
    return yaml.load(open(PUPPET_STATE_FILE))


def main():
    exception_msg = ""
    first_line = ""

    try:
        last_success_elapsed = (
            calendar.timegm(time.gmtime()) - get_last_success_time()
        )
        too_old = last_success_elapsed < NAG_INTERVAL
    except os.error as error:
        logging.warning("Unable to check puppet last success time: %s", error)
        exception_msg += (
            "\nUnable to check puppet last success time: {}".format(error)
        )
        last_success_elapsed = -1
        too_old = True

    try:
        last_run_summary = get_last_run_summary()
        has_errors = last_run_summary["events"]["failure"] > 0
    except Exception as error:
        logging.warning("Unable to read puppet last run summary: %s", error)
        exception_msg += "\nUnable to read puppet last run summary: {}".format(
            error
        )
        last_run_summary = {}
        has_errors = True

    if too_old and has_errors:
        first_line = (
            "Puppet did not run in the last {} seconds, and the last run was "
            "a failure.".format(
                last_success_elapsed
            )
        )

    elif too_old:
        first_line = (
            "Puppet did not run in the last {}, though the last run was a "
            "success.".format(
                last_success_elapsed
            )
        )

    elif has_errors:
        first_line = "Puppet is running with failures."

    if not too_old and not has_errors:
        logging.info("Puppet is running correctly, not notifying anyone.")
        return

    try:
        with open("/etc/wmflabs-project") as f:
            project_name = f.read().strip()

    except Exception as error:
        logger.warning("Unable to determine the current vm project: %s", error)
        exception_msg += (
            "\nUnable to determine the current vm project: {}".format(error)
        )
        project_name = "no_project"

    fqdn = socket.getfqdn()
    ip = socket.gethostbyname(socket.gethostname())

    logger.info(
        (
            "It has been more than %s seconds since last Puppet run or it "
            "failed. Sending nag emails."
        ),
        NAG_INTERVAL,
    )

    # No f-strings until after Stretch goes away! Instead we have this ugly
    # stuff.
    subject = "[Cloud VPS alert][{}] Puppet failure on {} ({})".format(
        project_name, fqdn, ip
    )

    body = """
Puppet is having issues on the "{fqdn} ({ip})" instance in project
{project_name} in Wikimedia Cloud VPS.

{first_line}

Working Puppet runs are needed to maintain instance security and logins.
As long as Puppet continues to fail, this system is in danger of becoming
unreachable.

You are receiving this email because you are listed as member for the
project that contains this instance.  Please take steps to repair
this instance or contact a Cloud VPS admin for assistance.

You might find some help here:
    https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Cloud_VPS_alert_Puppet_failure_on

For further support, visit #wikimedia-cloud on libera.chat or
<https://wikitech.wikimedia.org>

Some extra info follows:
---- Last run summary:
{last_run_summary}

---- Exceptions that happened if any:
{exception_msg}
    """.format(
        fqdn=fqdn, ip=ip, first_line=first_line, project_name=project_name,
        last_run_summary=yaml.dump(last_run_summary), exception_msg=exception_msg
    )
    email_admins(subject, body)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
