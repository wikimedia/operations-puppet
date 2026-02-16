#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations
import json
import os
import socket
import sys
import tempfile
import time
from pathlib import Path
from shutil import chown
from typing import Optional, Union

import requests
from requests.exceptions import RequestException

# provided by python3-jsonschema
from jsonschema import validate, ValidationError

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile


URL = 'https://test-kitchen.discovery.wmnet:30443/api/v1/experiments?authority=varnish&format=config'  # noqa: E501
TIMEOUT = 10
USER_AGENT = 'wmfuniq_experiment_fetcher/0.0.2 (sre-traffic@wikimedia.org)'
VARNISH_GROUP = 'varnish'
NODE_EXPORTER_PATH = '/var/lib/prometheus/node.d/wmfuniq_experiment_fetcher.prom'
# TODO: read it from disk
SCHEMA = '{"$schema":"http://json-schema.org/draft-04/schema#","title":"wmfuniq_abtests","description":"A collection of wmfuniq abtest definitions","type":"object","additionalProperties":false,"properties":{"_comment":{"type":"string"}},"patternProperties":{"^[A-Za-z0-9][-_.A-Za-z0-9]{7,62}$":{"title":"abtest","description":"Defines a single abtest","type":"object","required":["start","end","domains"],"additionalProperties":false,"properties":{"_comment":{"type":"string"},"start":{"description":"Start date in RFC 3999 UTC form, no subsecond values allowed and TZ offset must be Z","type":"string","pattern":"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"},"end":{"description":"End date in same form as start","type":"string","pattern":"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"},"cache_split":{"description":"Whether content cache should be split for this experiment, default true","type":"boolean"},"shared_selector":{"description":"Optional override of abtest name for ID derivation purposes","type":"string","pattern":"^[A-Za-z0-9][-_.A-Za-z0-9]{7,62}$"},"domains":{"type":"object","minProperties":1,"additionalProperties":false,"properties":{"_comment":{"type":"string"}},"patternProperties":{"^[a-z0-9][-_.a-z0-9]{0,254}$":{"description":"The domainname of a site used by the abtest, in lowercase","type":"object","required":["groups"],"additionalProperties":false,"properties":{"_comment":{"type":"string"},"unique_domain":{"type":"boolean"},"groups":{"description":"Named test groups for this site","type":"object","minProperties":1,"additionalProperties":false,"properties":{"_comment":{"type":"string"}},"patternProperties":{"^[A-Za-z0-9][-_.A-Za-z0-9]{0,62}$":{"description":"Range of buckets assigned to this group","type":"array","minItems":2,"maxItems":2,"items":{"type":"integer","minimum":0,"maximum":99999}}}}}}}}}}}}'  # noqa: E501


registry = CollectorRegistry()
http_status_last = Gauge('wmfuniq_experiment_fetcher_http_status_last',
                         'HTTP status code of the last request', registry=registry)
http_duration_seconds_last = Gauge('wmfuniq_experiment_fetcher_http_duration_seconds_last',
                                   'Duration of the last HTTP request', registry=registry)


def read_file(path: Union[str | os.PathLike], catch_exceptions: bool = True) -> Optional[str]:
    try:
        with open(path, 'r') as config_file:
            return config_file.read()
    except OSError:
        if catch_exceptions:
            return None
        else:
            raise


def fetch_config(url: str, timeout: float) -> Optional[str]:
    headers = {'User-Agent': USER_AGENT, 'X-Experiment-Config-Poller': socket.getfqdn()}
    try:
        start_time = time.time()
        r = requests.get(url, headers=headers, timeout=timeout)
    except RequestException:
        http_status_last.set(-1)
        return None
    finally:
        end_time = time.time()
        http_duration_seconds_last.set(end_time - start_time)

    http_status_last.set(r.status_code)
    if r.status_code != 200:
        print(f'Unexpected status code: {r.status_code}')
        return None

    if r.headers['Content-Type'] != 'application/json; charset=utf-8':
        print(f"Unexpected Content-Type: {r.headers['Content-Type']}")
        return None

    # validate returns None if validation is succesful and raises an exception otherwise
    # validate(r.json(), json.loads(read_file(SCHEMA_PATH, catch_exceptions=False)))
    try:
        validate(r.json(), json.loads(SCHEMA))
    except ValidationError:
        print(f"JSON doesn't match the schema: {r.text}")
        return None
    except Exception:  # use requests.exception.JSONDecodeError when requests 2.27 is available
        print(f'Invalid payload received: {r.text}')
        return None

    return r.text


def main(config_path: Union[str, os.PathLike]) -> None:
    new_config = fetch_config(URL, TIMEOUT)

    # NOOP if the config file hasn't been updated
    if new_config is None or new_config == read_file(config_path):
        return

    config_path = Path(config_path)
    config_dir = config_path.parent

    try:
        with tempfile.NamedTemporaryFile(delete=False, dir=config_dir) as temp_file:
            temp_file.write(new_config.encode('utf-8'))

        temp_path = Path(temp_file.name)
        # varnish group needs to be able to read the config file
        temp_path.chmod(0o640)
        chown(temp_path, group=VARNISH_GROUP)
        temp_path.replace(config_path)
    except OSError as ose:
        raise Exception("Unable to write config file", ose)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} config_path")
        sys.exit(1)

    main(Path(sys.argv[1]))
    write_to_textfile(NODE_EXPORTER_PATH, registry)
    sys.exit(0)
