#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import logging
import os

from box import Box
from pathlib import Path
from flask import (
    Flask,
    request,
    abort
)

STATUS_DIR = '/var/lib/deadmanswitchamhook'

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=getattr(logging, log_level, logging.INFO),
                    format="{levelname} - {message}", style="{")
logger = logging.getLogger()

app = Flask(__name__)


@app.route("/dms", methods=['POST'])
def dms():
    body = Box(request.get_json())

    try:
        for alert in body.alerts:
            if alert.status == 'firing':
                labels = alert.labels
                if (labels.source == 'thanos'):
                    fname = 'thanos'
                else:
                    fname = f"{labels.source}_{labels.prometheus}_{labels.site}"

                Path(STATUS_DIR + '/' + fname).touch()

        logger.debug('Alerts received and parsed. Returning 200.')
        return "<p>received and parsed!</p>", 200
    except Exception:
        logger.error("Error occured while processing alerts...", exc_info=True)
        abort(500, description="Received but error occured while processing alerts!")
