#!/usr/bin/env python
from __future__ import print_function

"""
Nagios plugin alerting if BGP is configured but no BGP sessions are in
ESTABLISHED state

Copyright 2018 Valentin Gutierrez
Copyright 2018 Wikimedia Foundation, Inc.

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY. It
may be used, redistributed and/or modified under the terms of the GNU General
Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
"""

import argparse
import sys
from enum import Enum

import requests
from prometheus_client.parser import text_fd_to_metric_families


class BGPStatus(Enum):
    DISABLED = 0
    ENABLED = 1
    NOT_REPORTED = 2


class ExitCode(Enum):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3


class PyBalMetrics(Enum):
    BGP_ENABLED = 'pybal_bgp_enabled'
    BGP_SESSION_ESTABLISHED = 'pybal_bgp_session_established'


class PyBalBGPSessionsCheck(object):
    def __init__(self, argument_list):
        ap = argparse.ArgumentParser(description=__doc__)
        ap.add_argument('--pybal-url',
                        help='pybal metrics instrumentation URL',
                        type=str,
                        default='http://localhost:9090/metrics')
        ap.add_argument('--req-timeout',
                        help='HTTP request timeout in seconds',
                        type=float,
                        default=1.0)

        self.args = ap.parse_args(argument_list)
        self.bgp_metrics = None
        self.missing_sessions = []

    def get_url(self, url):
        req = requests.get(url, timeout=self.args.req_timeout)
        req.raise_for_status()
        return req

    def get_bgp_metrics(self):
        req = self.get_url(self.args.pybal_url)
        self.bgp_metrics = [metric
                            for metric in text_fd_to_metric_families(req.iter_lines())
                            if "bgp" in metric.name]

    def is_bgp_enabled(self):
        for metric in self.bgp_metrics:
            if metric.name == PyBalMetrics.BGP_ENABLED.value:
                return BGPStatus(metric.samples[0][2])
        return BGPStatus.NOT_REPORTED

    def are_bgp_sessions_established(self):
        for metric in self.bgp_metrics:
            if metric.name == PyBalMetrics.BGP_SESSION_ESTABLISHED.value:
                if not bool(metric.samples[0][2]):
                    self.missing_sessions.append(metric.samples[0][1])

        if not self.missing_sessions:
            return True

        return False

    @staticmethod
    def ret(exit_code, msg):
        print("{}: {}".format(exit_code.name, msg))
        return exit_code.value

    def run(self):
        try:
            self.get_bgp_metrics()
            bgp_status = self.is_bgp_enabled()
            if bgp_status == BGPStatus.DISABLED:
                return self.ret(ExitCode.OK,  "BGP not enabled")
            elif bgp_status == BGPStatus.NOT_REPORTED:
                return self.ret(ExitCode.UNKNOWN, "BGP status not reported")

            if not self.are_bgp_sessions_established():
                return self.ret(ExitCode.CRITICAL,
                                "BGP missing sessions: {}".format(self.missing_sessions))

            return self.ret(ExitCode.OK, "BGP sessions established")
        except requests.exceptions.RequestException as e:
            return self.ret(ExitCode.UNKNOWN,
                            "Unable to retrieve PyBal metrics: {}".format(e))
        except Exception as e:
            return self.ret(ExitCode.UNKNOWN,
                            "Unexpected error: {}".format(e))


if __name__ == '__main__':
    check = PyBalBGPSessionsCheck(sys.argv[1:])
    sys.exit(check.run())
