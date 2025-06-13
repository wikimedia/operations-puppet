#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import logging
import os
import time
import requests

from pathlib import Path
from typing import Tuple
from box import BoxList
from enum import Enum
from flask import (
    Flask,
    abort
)
from datetime import (
    datetime,
    timezone
)

STATUS_DIR = '/var/lib'
DEADMANSWITCH_THRESHOLD = 600
ALERTMANAGER_URL = 'http://localhost:9093'
DMS_ALERT_NAME = 'DeadManSwitch'
SUPPORTED_SERVICES = ['prometheus', 'thanos']


log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=getattr(logging, log_level, logging.INFO),
                    format="{levelname} - {funcName} - {message}", style="{")
logger = logging.getLogger()

monitored_instances = os.getenv("MONITORED_INSTANCES", "").split(",")


class Retval(Enum):
    def __init__(self, message: str, code: int):
        self._message = message
        self._code = code

    OK = (
        'No instances with outdated timestamp have been detected.',
        200
    )
    MODULENOTFOUND = (
        "Module Not Found",
        404
    )
    SERVICENOTFOUND = (
        "Service Not Found",
        404
    )
    OUTDATED = (
        "Instance(s) with outdated timestamp: #PLACEHOLDER.",
        424
    )
    BADCOUNT = (
        "Received DMS alert count doesn't match the number of Prometheus instances",
        424
    )

    def customized(self, value: str):
        return (self._code, self._message.replace('#PLACEHOLDER', value))


def filterMonitoredInstance(f):
    return list(filter(lambda x: x.startswith(f), monitored_instances))


def deadmanswitchnotified(service: str) -> Tuple[str, int]:
    folder = Path(f"{STATUS_DIR}/deadmanswitchamhook")

    instances = filterMonitoredInstance(service)

    filecount = sum(
                1 for filename in instances
                if os.path.isfile(
                    os.path.join(folder, filename)
                )
            )

    logger.info(f"Found: {filecount} vs Expected: {len(instances)}")
    if filecount != len(instances):
        return Retval.BADCOUNT.value

    now = time.time()
    badts = []
    for file in folder.iterdir():
        if file.name.startswith(service):
            logger.debug(f"processing {file}")
            if file.is_file():
                fts = file.stat().st_mtime
                if now - fts > DEADMANSWITCH_THRESHOLD:
                    logger.info(
                        f'{file} has a timestamp older than {DEADMANSWITCH_THRESHOLD}'  # noqa: E501
                    )
                    badts.append(file)

    if len(badts) == 0:
        return Retval.OK.value

    return Retval.OUTDATED.customized(','.join(badts))


def deadmanswitchonamdb(service: str) -> Tuple[str, int]:
    instances = filterMonitoredInstance(service)

    resp = requests.get(f"{ALERTMANAGER_URL}/api/v2/alerts")
    alerts = BoxList(resp.json())
    matching_alerts = [
        alert for alert in alerts
        if (alert.labels.alertname == DMS_ALERT_NAME) and (alert.labels.source == service)
    ]

    logger.info(f"Found: {len(matching_alerts)} vs Expected: {len(instances)}")
    if len(matching_alerts) != len(instances):
        return Retval.BADCOUNT.value

    now = time.time()
    badts = []
    for alert in matching_alerts:
        if alert.labels.source == service:
            logger.debug(f"processing {alert}")
            ats = datetime.strptime(
                alert.updatedAt, "%Y-%m-%dT%H:%M:%S.%fZ"
            ).replace(
                tzinfo=timezone.utc
            ).timestamp()

            if now - ats > DEADMANSWITCH_THRESHOLD:
                logger.info(
                    f'{alert} has a timestamp older than {DEADMANSWITCH_THRESHOLD}'  # noqa: E501
                )
                if service == "prometheus":
                    badts.append(f"{alert.labels.source}_{alert.labels.prometheus}_{alert.labels.site}")  # noqa: E501
                elif service == "thanos":
                    badts.append(service)

    if len(badts) == 0:
        return Retval.OK.value

    return Retval.OUTDATED.customized(','.join(badts))


KNOWN_MODULES = {
    'deadmanswitchnotified': deadmanswitchnotified,
    'deadmanswitchonamdb': deadmanswitchonamdb
}


app = Flask(__name__)


@app.route('/<string:service>/<string:module>', methods=['GET'])
def show_subpath(service, module):
    try:
        if service not in SUPPORTED_SERVICES:
            return Retval.SERVICENOTFOUND.value
        elif module not in KNOWN_MODULES.keys():
            return Retval.MODULENOTFOUND.value
        else:
            return KNOWN_MODULES[module](service)
    except Exception:
        logger.error('An error occured during execution...', exc_info=True)
        abort(500, "Internal Server Error")
