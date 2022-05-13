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
import json
import logging
import os
import socket
import subprocess
import sys
import time

from enum import Enum
from pathlib import Path
from typing import Dict, List, Tuple

import yaml

from notify_maintainers import email_admins

sys.path.append("/usr/local/sbin/")

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24
READY_FILE = "/.cloud-init-finished"
DISABLE_FILE = "/.no-puppet-checks"
OPT_OUT_PROJECTS = ["admin", "testlabs", "trove"]

logger = logging.getLogger(__name__)


def is_host_ready() -> bool:
    """Return if the host is ready

    Return:
        indicating ready state

    """
    return Path(READY_FILE).is_file()


def alerts_disabled() -> bool:
    """Indicate if the user has disabled alerts

    Return:
        indicating disabled state

    """
    return Path(DISABLE_FILE).is_file()


def get_puppet_config(config_item: str) -> str:
    """Run puppet config and return the config item

    Parameters:
        config_item: the config item to lookup

    Return
        the config value

    """
    return (
        subprocess.check_output(["puppet", "config", "print", config_item])
        .decode("utf-8")
        .strip()
    )


def puppet_disabled() -> Tuple[bool, str]:
    """check if puppet is disabled

    returns:
        Tuple with a bool indicating if the system is disabled and string indicating the reason

    """
    agent_disabled_lockfile = Path(get_puppet_config("agent_disabled_lockfile"))
    if not agent_disabled_lockfile.is_file:
        return False, ""
    message = json.loads(agent_disabled_lockfile.read_text())
    logger.info("puppet is disabled: %s", message["disabled_message"])
    return True, message["disabled_message"]


def get_last_success_time() -> float:
    """Return the mtime of the classfile

    Returns:
        mtime value

    """
    return Path(get_puppet_config("classfile")).lstat().st_mtime


def get_puppet_yaml_file(config_item) -> Dict:
    """Read a and parse a puppet yaml

    This method specifically handles the yaml ruby tags leftover from puppet

    Arguments:
        config_item: the config item pointing to the yaml file

    Returns:
        a dict representing the file content

    Raises:
        ValueError: if the config_item does not resolve to a valid file
    """
    yaml_file = Path(get_puppet_config(config_item))
    if not yaml_file.is_file:
        raise ValueError("%s: item dose not resolve to a file")

    def unknown(loader, _, node):
        if isinstance(node, yaml.ScalarNode):
            constructor = loader.__class__.construct_scalar
        elif isinstance(node, yaml.SequenceNode):
            constructor = loader.__class__.construct_sequence
        elif isinstance(node, yaml.MappingNode):
            constructor = loader.__class__.construct_mapping
        data = constructor(loader, node)
        return data

    yaml.add_multi_constructor("!", unknown)
    yaml.add_multi_constructor("tag:", unknown)
    return yaml.load(yaml_file.read_text(), Loader=yaml.Loader)


def get_last_run_report_failed_resources() -> List[str]:
    """Get a list of failed resources

    Returns:
        A list of failed resources

    """
    last_run_report = get_puppet_yaml_file("lastrunreport")
    return [
        resource_name
        for resource_name, resource_data in last_run_report["resource_statuses"].items()
        if resource_data["failed"]
    ]


class PuppetLogLevel(Enum):
    """Enum to track puppet message levels"""

    INFO = 1
    WARN = 2
    ERROR = 3


def get_last_run_log(level: PuppetLogLevel) -> List[str]:
    """Parse the last_run_report.yaml file for log messages from the last run

    Parameters:
        level: The minimum log level to report.  i.e. PuppetLogLevel.INFO will return all messages

    Returns:
        a list of messages ordered by time stamp

    """
    lastrunreport = get_puppet_yaml_file("lastrunreport")
    messages = dict()
    for log in lastrunreport["logs"]:
        if (
            log["level"] == "info"
            and level.value > 1
            or log["level"] == "warning"
            and level.value > 2
        ):
            continue
        messages[log["time"]] = "{}: {}".format(log["level"].upper(), log["message"])
    return dict(sorted(messages.items())).values()


def main():
    """Main entry point"""
    exception_msg = ""
    first_line = ""
    failed_resources = []

    if not is_host_ready():
        logging.info("Host is not ready yet, file %s does not exist.", READY_FILE)
        return

    if alerts_disabled():
        logging.info("Puppet alerts are disabled, file %s exists.", DISABLE_FILE)
        return

    try:
        project_name = Path("/etc/wmcs-project").read_text().strip()

    except Exception as error:
        logger.warning("Unable to determine the current vm project: %s", error)
        exception_msg += "\nUnable to determine the current vm project: {}".format(
            error
        )
        project_name = "no_project"

    if project_name in OPT_OUT_PROJECTS:
        # Just stop running quietly. We don't want alerts for these.
        return

    try:
        last_success_elapsed = calendar.timegm(time.gmtime()) - get_last_success_time()
        too_old = last_success_elapsed > NAG_INTERVAL
    except os.error as error:
        logging.warning("Unable to check puppet last success time: %s", error)
        exception_msg += "\nUnable to check puppet last success time: {}".format(error)
        last_success_elapsed = -1
        too_old = True

    try:
        last_run_summary = get_puppet_yaml_file("lastrunfile")
        has_errors = (
            last_run_summary["events"]["failure"] > 0
            or last_run_summary["events"]["total"] == 0
        )
        if has_errors:
            failed_resources = get_last_run_report_failed_resources()
    except Exception as error:
        logging.warning("Unable to read puppet last run summary: %s", error)
        exception_msg += "\nUnable to read puppet last run summary: {}".format(error)
        last_run_summary = {}
        has_errors = True

    disabled, disable_message = puppet_disabled()
    if disabled and too_old:
        first_line = "Puppet has been disabled for {} secs, with the following message: {}".format(
            last_success_elapsed, disable_message
        )
    elif too_old and has_errors:
        first_line = (
            "Puppet did not run in the last {:.0f} seconds, and the last run was "
            "a failure.".format(last_success_elapsed)
        )

    elif too_old:
        first_line = (
            "Puppet did not run in the last {:.0f} seconds, though the last run was "
            "a success.".format(last_success_elapsed)
        )

    elif has_errors:
        first_line = "Puppet is running with failures."

    if not too_old and not has_errors:
        logging.info("Puppet is running correctly, not notifying anyone.")
        return

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

If your host is expected to fail puppet runs and you want to disable this
alert, you can create a file under {disable_file}, that will skip the checks.

You might find some help here:
    https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Cloud_VPS_alert_Puppet_failure_on

For further support, visit #wikimedia-cloud on libera.chat or
<https://wikitech.wikimedia.org>

Some extra info follows:
---- Last run summary:
{last_run_summary}

---- Failed resources if any:

{failed_resources_str}

--- Last run log:

{last_run_log}

---- Exceptions that happened when running the script if any:
{exception_msg}
    """.format(
        fqdn=fqdn,
        ip=ip,
        project_name=project_name,
        first_line=first_line,
        disable_file=DISABLE_FILE,
        last_run_summary=yaml.dump(last_run_summary),
        failed_resources_str=(
            ("  * " if failed_resources else "  No failed resources.")
            + "\n  * ".join(failed_resources)
        ),
        last_run_log="\n".join(get_last_run_log(PuppetLogLevel.WARN)),
        exception_msg=exception_msg or "  No exceptions happened.",
    )
    email_admins(subject, body)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
