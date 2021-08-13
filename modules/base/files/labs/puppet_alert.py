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
import subprocess

import yaml
from notify_maintainers import email_admins

sys.path.append("/usr/local/sbin/")

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24
READY_FILE = "/.cloud-init-finished"

logger = logging.getLogger(__name__)


def is_host_ready():
    return os.path.exists(READY_FILE)


def get_puppet_lastrunfile_path():
    return subprocess.check_output([
        "puppet", "config", "print", "lastrunfile"
    ]).decode('utf-8').strip()


def get_puppet_lastrunreport_path():
    return subprocess.check_output([
        "puppet", "config", "print", "lastrunreport"
    ]).decode('utf-8').strip()


def get_puppet_classfile_path():
    # last_run_summary.yaml reports the last run but it updates the stamp even
    # on failed runs. Instead, check to see the last time puppet actually did
    # something.
    return subprocess.check_output([
        "puppet", "config", "print", "classfile"
    ]).decode('utf-8').strip()


def get_last_success_time():
    return os.path.getmtime(get_puppet_classfile_path())


def get_last_run_summary():
    with open(get_puppet_lastrunfile_path(), encoding="utf-8") as puppet_state_fd:
        return yaml.safe_load(puppet_state_fd)


def get_last_run_report():
    """The custom loader is to ignore the special tags that puppet adds.

    It will just ignore them, for example, at the start of the report, puppet adds the following
    loader tag to the yaml:
    ```
    --- !ruby/object:Puppet::Transaction::Report
    ...
    ```
    """

    def unknown(loader, suffix, node):
        if isinstance(node, yaml.ScalarNode):
            constructor = loader.__class__.construct_scalar
        elif isinstance(node, yaml.SequenceNode):
            constructor = loader.__class__.construct_sequence
        elif isinstance(node, yaml.MappingNode):
            constructor = loader.__class__.construct_mapping
        data = constructor(loader, node)
        return data

    yaml.add_multi_constructor('!', unknown)
    yaml.add_multi_constructor('tag:', unknown)
    with open(get_puppet_lastrunreport_path(), encoding="utf-8") as puppet_report_fd:
        return yaml.load(puppet_report_fd, Loader=yaml.Loader)


def get_last_run_report_failed_resources():
    last_run_report = get_last_run_report()
    return [
        resource_name
        for resource_name, resource_data in last_run_report["resource_statuses"].items()
        if resource_data["failed"]
    ]


def main():
    exception_msg = ""
    first_line = ""
    failed_resources = []

    if not is_host_ready():
        logging.info("Host is not ready yet, file {} does not exist.".format(READY_FILE))
        return

    try:
        last_success_elapsed = (
            calendar.timegm(time.gmtime()) - get_last_success_time()
        )
        too_old = last_success_elapsed > NAG_INTERVAL
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
        if has_errors:
            failed_resources = get_last_run_report_failed_resources()
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
        with open("/etc/wmflabs-project", encoding="utf-8") as f:
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

---- Failed resources if any:

{failed_resources_str}

---- Exceptions that happened when running the script if any:
{exception_msg}
    """.format(
        fqdn=fqdn, ip=ip,
        first_line=first_line,
        project_name=project_name,
        last_run_summary=yaml.dump(last_run_summary),
        exception_msg=exception_msg or '  No exceptions happened.',
        failed_resources_str=(
            ('  * ' if failed_resources else '  No failed resources.')
            + '\n  * '.join(failed_resources)
        ),
    )
    email_admins(subject, body)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
