#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

#
# This software has been developed to expose the results of o11y metamonitoring checks
# to external uptime monitoring services. It uses Flask to expose its endpoint.
# Since it runs under Gunicorn, its behavior can be customized via environment variables.
#
# STATUS_DIR:
#   Directory where each module can find the current status of metamonitoring checks.
#   Each module has its own subfolder within this directory.
#
# DEADMANSWITCH_THRESHOLD:
#   Number of seconds after which a deadmanswitch alert is considered obsolete.
#
# ALERTMANAGER_URL:
#   URL of the Alertmanager instance to query.
#
# DEADMANSWITCH_ALERT_NAME:
#   Name of the deadmanswitch alert as defined in the Prometheus/Thanos alerting rules.
#
# SUPPORTED_SERVICES:
#   Comma-separated list (no spaces) of supported services (prometheus,thanos).
#   Prometheus and Thanos are currently supported; others may be added.
#
# MONITORED_INSTANCES:
#   Comma-separated list (no spaces) of Prometheus/Thanos instance names
#   for which a deadmanswitch alert is expected.
#   e.g: thanos,prometheus_ops_eqiad,prometheus_ops_codfw
#
# ICINGA_ACTIVE_HOST:
#   Icinga instance that triggers pages if it’s not working as expected.
#
# LOG_LEVEL: log level.
#

import logging
import os
import time
import requests
import json
import re

from pathlib import Path
from typing import Tuple
from box import Box, BoxList
from enum import Enum
from flask import Flask, abort
from datetime import datetime, timezone

STATUS_DIR = Path(os.getenv("STATUS_DIR", "/var/lib/o11y-metamonitoring").lower())
DOWNTIME_DIR = STATUS_DIR / "downtimes"
DEADMANSWITCH_THRESHOLD = int(os.getenv("DEADMANSWITCH_THRESHOLD", "600"))
ALERTMANAGER_URL = os.getenv("ALERTMANAGER_URL", "http://localhost:9093").lower()
DEADMANSWITCH_ALERT_NAME = os.getenv("DEADMANSWITCH_ALERT_NAME", "DeadManSwitch")
SUPPORTED_SERVICES = os.getenv("SUPPORTED_SERVICES", "prometheus,thanos,icinga").split(
    ","
)
MONITORED_INSTANCES = os.environ["MONITORED_INSTANCES"].split(",")
ICINGA_ACTIVE_HOST = os.environ["ICINGA_ACTIVE_HOST"]


log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format="{levelname} - {funcName} - {message}",
    style="{",
)
logger = logging.getLogger()


class Retval(Enum):
    def __init__(self, message: str, code: int):
        self._message = message
        self._code = code

    OK = (
        "No instances with outdated timestamp (or bad state) have been detected.",
        200,
    )
    MODULENOTFOUND = ("Module Not Found.", 404)
    SERVICENOTFOUND = ("Service Not Found.", 404)
    OUTDATED = ("Instance(s) with outdated timestamp: {}.", 424)
    BADCOUNT = (
        "The found instances don't match the expected number of instances ({}).",
        424,
    )
    BADSTATE = (
        'Instances not in "OK" or "RECOVERY" state: {}.',
        424,
    )

    def customized(self, value: str) -> Tuple[int, str]:
        return (self._message.format(value), self._code)


# It filters out all elements that don't start with $f
# Useful to distinguish between Thanos and Prometheus instances
def filterMonitoredInstance(f: str) -> Tuple[str]:
    return list(filter(lambda x: x.startswith(f), MONITORED_INSTANCES))


# Checks for alerts that have been notified by Alertmanager to the deadmanswitch hook.
# Continuously tests Alertmanager's routing capabilities.
# Intended to checked only on the active Alertmanager instance.
def deadmanswitchnotified(service: str) -> Tuple[str, int]:
    folder = STATUS_DIR / "deadmanswitchamhook"

    instances = filterMonitoredInstance(service)

    filecount = sum(1 for filename in instances if (folder / filename).exists())

    logger.info(f"Found: {filecount} vs Expected: {len(instances)}")
    if filecount != len(instances):
        return Retval.BADCOUNT.customized("{}/{}".format(filecount, len(instances)))

    now = time.time()
    badts = []
    for file in folder.iterdir():
        if file.name.startswith(service):
            logger.debug(f"processing {file}")
            if file.is_file():
                fts = file.stat().st_mtime
                if now - fts > DEADMANSWITCH_THRESHOLD:
                    logger.info(
                        f"{file} has a timestamp older than {DEADMANSWITCH_THRESHOLD}"  # noqa: E501
                    )
                    badts.append(file.name)

    if len(badts) == 0:
        return Retval.OK.value

    return Retval.OUTDATED.customized(",".join(badts))


# Checks for alerts directly on the Alertmanager DB.
# Useful to verify DB synchronization between Alertmanager instances in the cluster.
# Intended to be checked on every Alertmanager instance.
def deadmanswitchonamdb(service: str) -> Tuple[str, int]:
    instances = filterMonitoredInstance(service)

    resp = requests.get(f"{ALERTMANAGER_URL}/api/v2/alerts")
    alerts = BoxList(resp.json())
    matching_alerts = [
        alert
        for alert in alerts
        if (alert.labels.alertname == DEADMANSWITCH_ALERT_NAME)
        and (alert.labels.source == service)
    ]

    logger.info(f"Found: {len(matching_alerts)} vs Expected: {len(instances)}")
    if len(matching_alerts) != len(instances):
        return Retval.BADCOUNT.customized(
            "{}/{}".format(len(matching_alerts), len(instances))
        )

    now = time.time()
    badts = []
    for alert in matching_alerts:
        if alert.labels.source != service:
            continue

        logger.debug(f"processing {alert}")
        ats = (
            datetime.strptime(alert.updatedAt, "%Y-%m-%dT%H:%M:%S.%fZ")
            .replace(tzinfo=timezone.utc)
            .timestamp()
        )

        if now - ats <= DEADMANSWITCH_THRESHOLD:
            continue

        logger.info(
            f"{alert} has a timestamp older than {DEADMANSWITCH_THRESHOLD}"  # noqa: E501
        )
        if service == "prometheus":
            badts.append(
                f"{alert.labels.source}_{alert.labels.prometheus}_{alert.labels.site}"
            )
        elif service == "thanos":
            badts.append(service)

    if len(badts) == 0:
        return Retval.OK.value

    return Retval.OUTDATED.customized(",".join(badts))


def extmon(service: str) -> Tuple[str, int]:
    folder = STATUS_DIR / "icinga_external_monitoring"
    instances = filterMonitoredInstance(service)

    filecount = 0
    for instance in instances:
        host = instance.split("_")[1]
        pattern = re.compile(r"^check_icinga_{}.*\.state$".format(host))
        if any(pattern.match(f.name) for f in folder.iterdir() if f.is_file()):
            logger.info("icinga/extmon: found {}".format(host))
            filecount = filecount + 1

    logger.info(f"Found: {filecount} vs Expected: {len(instances)}")
    if filecount != len(instances):
        return Retval.BADCOUNT.customized("{}/{}".format(filecount, len(instances)))

    # check_icinga_phi-alert-01.o11y.eqiad1.wikimedia.cloud.state
    # {
    #   "last_check": "2024-09-12T14:02:03.327335",
    #   "state": "OK",
    #   "last_notification": "2024-03-19T15:57:21.456432"
    # }
    now = datetime.utcnow().timestamp()
    badts = []
    badstate = []
    for file in folder.iterdir():
        if file.name.startswith("check_{}_{}".format(service, ICINGA_ACTIVE_HOST)):
            logger.debug(f"processing {file}")
            if file.is_file():
                with open(file, "r", encoding="utf-8") as f:
                    data = Box(json.load(f))
                fts = datetime.fromisoformat(data.last_check).timestamp()
                if now - fts > DEADMANSWITCH_THRESHOLD:
                    logger.info(
                        f"{file} has a timestamp older than {DEADMANSWITCH_THRESHOLD}"  # noqa: E501
                    )
                    badts.append(file.name)
                else:
                    logger.debug(
                        f"{file} has a timestamp newer than {DEADMANSWITCH_THRESHOLD}"  # noqa: E501
                    )
                if data.state not in ["OK", "RECOVERY"]:
                    logger.info(f"{file} has a bad state: {data.state}")  # noqa: E501
                    badstate.append(file.name)
                else:
                    logger.debug(f"{file} has a good state: {data.state}")  # noqa: E501

    if len(badts) > 0:
        return Retval.OUTDATED.customized(",".join(badts))

    if len(badstate) > 0:
        return Retval.BADSTATE.customized(",".join(badstate))

    return Retval.OK.value


KNOWN_MODULES = {
    "deadmanswitchnotified": deadmanswitchnotified,
    "deadmanswitchonamdb": deadmanswitchonamdb,
    "extmon": extmon,
}


# Downtimes are JSON files written under DOWNTIME_DIR (typically by
# cookbook)
def active_downtime(service: str, module: str) -> dict:
    dtfile = DOWNTIME_DIR / f"{service}:{module}.json"
    if not dtfile.is_file():
        return None

    try:
        downtime = json.loads(dtfile.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        logger.warning(f"Could not parse downtime file {dtfile}, ignoring")
        return None

    if downtime.get("expiry", 0) <= time.time():
        logger.info(f"Downtime {dtfile} has expired, ignoring")
        return None

    return downtime


app = Flask(__name__)


@app.route("/<string:service>/<string:module>", methods=["GET"])
def show_subpath(service, module):
    try:
        if service not in SUPPORTED_SERVICES:
            return Retval.SERVICENOTFOUND.value
        elif module not in KNOWN_MODULES.keys():
            return Retval.MODULENOTFOUND.value

        # A downtimed check always reports OK to external pollers, so planned
        # maintenance on a monitoring backend doesn't trigger a page.
        downtime = active_downtime(service, module)
        if downtime is not None:
            expiry = datetime.fromtimestamp(
                downtime["expiry"], tz=timezone.utc
            ).isoformat()
            msg = (
                f"Check downtimed until {expiry} "
                f"(reason: {downtime.get('reason', 'n/a')})."
            )
            logger.info(msg)
            return msg, 200

        return KNOWN_MODULES[module](service)
    except Exception:
        logger.error("An error occured during execution...", exc_info=True)
        abort(500, "Internal Server Error")
