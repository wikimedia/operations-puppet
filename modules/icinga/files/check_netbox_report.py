#!/bin/env python3
"""
check_netbox_report.py: Return nagios status code based on the state of a specified report class.
"""


import argparse
import logging
import sys

from yaml import safe_load

import pynetbox


STATUS_OK = 0
STATUS_WARNING = 1
STATUS_CRITICAL = 2
STATUS_UNKNOWN = 3
STATUS_NAMES = {
    STATUS_OK: "OK",
    STATUS_WARNING: "WARNING",
    STATUS_CRITICAL: "CRITICAL",
    STATUS_UNKNOWN: "UNKNOWN",
}

logger = logging.getLogger()


class RunReportError(Exception):
    """Raised when running a report results in non-200 reply."""


def setup_logging(verbose=False):
    """Setup the logging with a custom format to go to stdout."""
    formatter = logging.Formatter(fmt="%(asctime)s [%(levelname)s] %(message)s")
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    if not verbose:
        level = logging.INFO
    else:
        level = logging.DEBUG
    handler.setLevel(level)
    logging.getLogger("requests").setLevel(logging.WARNING)  # Silence noisy logger
    logger.addHandler(handler)
    logger.raiseExceptions = False
    logger.setLevel(level)


def parse_args():
    """Setup command line argument parser and return parsed args.

    Returns:
        :obj:`argparse.Namespace`: The resulting parsed arguments.

    """
    parser = argparse.ArgumentParser()

    parser.add_argument("report", help="Report to alert on.")
    parser.add_argument(
        "-c",
        "--config",
        help="The path to the config file to load. Default: %(default)s.",
        default="/etc/netbox/report_check.yaml",
    )
    parser.add_argument(
        "-w",
        "--warn",
        help="Make failed results have WARNING status rather than CRITICAL status.",
        action="store_true",
    )
    parser.add_argument("-v", "--verbose", help="Output more verbosity.", action="store_true")

    args = parser.parse_args()
    return args


def print_status(status, failurestatus, message):
    """Print status in coherent format, and return status value.

    This allows externally overriding critical statuses for UI purposes."""
    if status == STATUS_CRITICAL:
        status = failurestatus
    print("{} {}".format(message, STATUS_NAMES[status]))
    return status


def main():
    """Main routine.

    Take the first argument, and check the result of the report of that class.

    Returns:
        int: The Nagios status code result.

    """
    args = parse_args()
    setup_logging(args.verbose)

    failedstatus = STATUS_CRITICAL
    if args.warn:
        failedstatus = STATUS_WARNING

    report = args.report
    netboxconfig = safe_load(open(args.config, "r"))
    api = pynetbox.api(url=netboxconfig["url"], token=netboxconfig["token"])
    try:
        robj = api.extras.reports.get(report)
    except pynetbox.core.query.RequestError as ex:
        logger.error("Excepting getting report %s: %s", report, ex)
        return print_status(
            STATUS_UNKNOWN,
            failedstatus,
            "Netbox exception getting report data for report {}".format(report)
        )

    if robj.result.failed:
        return print_status(STATUS_CRITICAL, failedstatus, "Netbox report {}".format(report))

    return print_status(STATUS_OK, failedstatus, "Netbox report {}".format(report))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as ex:
        logger.error("Unexpected exception occurred during check: %s", ex)
        sys.exit(STATUS_UNKNOWN)
