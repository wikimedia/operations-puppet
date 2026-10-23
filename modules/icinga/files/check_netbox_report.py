#!/bin/env python3
"""
check_netbox_report.py: Return nagios status code based on the state of a specified report class.

The job status alone is not reliable: scripts run via `manage.py runscript` (NetBox 4.0) and all
script runs on NetBox >= 4.1 end as "completed" even when tests fail (see T439130). The job data is
therefore inspected as well, and any failed test is considered a failed report.
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


def count_failures(result):
    """Count the failures of the report's test_* methods from the job data.

    pynetbox returns the job data as nested Records; dict() converts a Record
    (and the Records nested in it) to plain dicts.
    Note: log_failure() calls outside of test_* methods (plain custom scripts) are not counted.

    Arguments:
        result: the script's result (last job), as returned by pynetbox.

    Returns:
        int: the number of failures found.

    """
    tests = getattr(getattr(result, "data", None), "tests", None)
    if tests is None:
        return 0

    failures = 0
    for name, test in dict(tests).items():
        test_failures = test.get("failure", 0)
        if test_failures:
            logger.debug("Test %s has %d failures", name, test_failures)
        failures += test_failures
    return failures


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
    with open(args.config, "r", encoding="utf-8") as config_file:
        netboxconfig = safe_load(config_file)
    api = pynetbox.api(url=netboxconfig["url"], token=netboxconfig["token"])
    try:
        robj = api.extras.scripts.get(report)
    except pynetbox.core.query.RequestError as e:
        logger.error("Excepting getting report %s: %s", report, e)
        return print_status(
            STATUS_UNKNOWN,
            failedstatus,
            f"Netbox exception getting report data for report '{report}'"
        )

    if robj is None:
        return print_status(STATUS_UNKNOWN, failedstatus, f"Netbox report '{report}' not found")

    result = robj.result
    if not result:
        return print_status(STATUS_UNKNOWN, failedstatus,
                            f"Netbox report {report} has no result yet\n{robj.url}")

    status = result.status.value
    logger.debug("Report %s last job status: %s", report, status)
    if status == "errored":
        return print_status(STATUS_UNKNOWN, failedstatus,
                            f"Netbox report {report} errored\n{robj.url}")

    failures = count_failures(result)
    if status == "failed" or failures > 0:
        return print_status(STATUS_CRITICAL, failedstatus,
                            f"Netbox report {report} ({failures} failures)\n{robj.url}")

    return print_status(STATUS_OK, failedstatus, f"Netbox report {report}\n{robj.url}")


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as ex:
        logger.error("Unexpected exception occurred during check: %s", ex)
        sys.exit(STATUS_UNKNOWN)
