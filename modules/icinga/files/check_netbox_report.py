#!/bin/env python3

import argparse
import logging
import os
import sys

from yaml import safe_load

import pynetbox
import requests


STATUS_OK = 0
STATUS_WARNING = 1
STATUS_CRITICAL = 2
STATUS_UNKNOWN = 3
STATUS_NAMES = {
    STATUS_OK: "OK",
    STATUS_WARNING: "WARNING",
    STATUS_CRITICAL: "CRITICAL",
    STATUS_UNKNOWN: "UKNOWN",
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

    parser.add_argument("reports", help="Report(s) to alert on.", nargs="+")
    parser.add_argument(
        "-c",
        "--config",
        help="The path to the config file to load. Default: %(default)s.",
        default="/etc/netbox/report_check.yaml",
    )
    parser.add_argument(
        "-r", "--run", help="Run the report before returning the result.", action="store_true"
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


def run_report(report_result):
    """Run a particular report based on the result object returned from Pynetbox

    We do this directly with requests since pynetbox does not have a mechanism to do this.

    Arguments:
        report_result (:obj:`pynetbox.core.response.Record`): the result object obtained from
        pynetbox

    Raises:
        Exception: if non-200 result occurs.

    """
    logger.info("Running report %s", report_result.name)
    # for some reason the URL field switches the scheme, but we know better
    url = (report_result.url + "run/").replace('http://', 'https://')
    headers = {
        "Authorization": "Token {}".format(report_result.api.token),
        "Accept": "application/json",
        'User-agent': 'wmf-icinga/{} (root@wikimedia.org)'.format(os.path.basename(__file__)),
    }
    result = requests.post(url, headers=headers)
    if result.status_code != 200:
        raise RunReportError("Failed to run report {} {}".format(result.status_code, result.text))


def main():
    """Main routine.

    Loop through each specified report, run if requested and summarize results.

    Returns:
        int: The Nagios status code result.

    """
    args = parse_args()
    setup_logging(args.verbose)

    failedstatus = STATUS_CRITICAL
    if args.warn:
        failedstatus = STATUS_WARNING

    netboxconfig = safe_load(open(args.config, "r"))
    api = pynetbox.api(url=netboxconfig["url"], token=netboxconfig["token"])
    try:
        # We have to get all reports rather than getting them one at a time, because .get()
        # returns report objects that are not fully populated.
        all_reports = {"{}.{}".format(r.module, r.name): r for r in api.extras.reports.all()}
    except pynetbox.core.query.RequestError:
        logger.error("Exception trying to get report data.")
        return STATUS_UNKNOWN

    results = {}
    for report in args.reports:
        if report not in all_reports:
            logger.warning(
                "Report not in report list: %s (report list has: %s)",
                report,
                tuple(all_reports.keys()),
            )
            results[report] = STATUS_UNKNOWN
            continue
        repobj = all_reports[report]
        if args.run:
            try:
                run_report(repobj.result)
            except RunReportError:
                logger.error("Exception trying to run report %s", report)
                results[report] = STATUS_UNKNOWN
                continue

            # refetch the object to refresh
            repobj = api.extras.reports.get(report)

        if repobj.result.failed:
            results[report] = failedstatus
        else:
            results[report] = STATUS_OK

    # Summarize results. Status return priority is
    # 'failedstatus' then UNKNOWN then OK
    endresult = STATUS_OK
    for report, result in results.items():
        if endresult == STATUS_OK:
            endresult = result
        elif endresult == STATUS_WARNING and result == failedstatus:
            endresult = result
        print("{} {}".format(report, STATUS_NAMES[result]))

    # FIXME we could put some perfdata here based on the contents of the reports
    return endresult


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as ex:
        logger.error("Unexpected exception occurred during check: %s", ex)
        sys.exit(STATUS_UNKNOWN)
