#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
A small application designed to be triggered by a systemd timer.
It runs the command defined in the --check-command option
(which corresponds to a previously declared Icinga/Nagios NRPE command),
parses the output, and stores it as Prometheus metrics
ready to be scraped via node-exporter.
"""

import shlex
import subprocess
import click
import re
import json
import logging
import traceback
import datetime
import os

from logging import LogRecord
from typing import Tuple, Iterator
from prometheus_client.core import GaugeMetricFamily, CollectorRegistry
from prometheus_client.parser import text_string_to_metric_families
from prometheus_client import Gauge, generate_latest
from pathlib import Path
from box import Box
from enum import IntEnum


# Configuration
SCRIPT_DIRECTORY = Path("/etc/nagios/nrpe.d")
NODE_EXPORTER_DIR = Path("/var/lib/prometheus/node.d")


# Nagios return codes
class StatusCodes(IntEnum):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3

    def get_severity(self, page: bool = False) -> str:
        """
        Maps Nagios exit values to the Prometheus severity label

        Args:
            page (bool): if CRITICAL should be interpreted as a paging alert

        Returns:
            status = WARNING  -> severity = warning
            status = CRITICAL -> severity = critical|page
                                 depending on the --page flag
            all other values  -> severity = info
        """
        if StatusCodes.WARNING.value == self.value:
            return self.name.lower()
        elif StatusCodes.CRITICAL.value == self.value:
            if page:
                return "page"
            else:
                return self.name.lower()
        else:
            return "info"


class ECSFormatter(logging.Formatter):
    """
    ECS 1.7.0 logging formatter
    """

    def __init__(self, cache_dir: Path, check_command: str) -> None:
        """
        Initializes an instance of ECSFormatter with the provided attributes.

        Args:
            cache_dir (Path): The Node Exporter cache directory where the previous status is stored.
            check_command (str): The name of the NRPE check command.
        """
        self._cache_dir = cache_dir
        self._check_command = check_command

    def detect_status_change(self, returncode: int) -> bool:
        """
        Detects whether the latest execution returned a different status code
        compared to the previous one, based on the node exporter cache.

        Args:
            returncode: The return code of the latest execution.

        Returns:
            True if a status change has been detected, False otherwise.
        """
        p = self._cache_dir / f"{self._check_command}.prom"
        if not (p.exists() and p.is_file() and os.access(p, os.R_OK)):
            return True

        with open(p, "r") as f:
            data = f.read()

        for family in text_string_to_metric_families(data):
            if family.name != "nagios_nrpe_check_result":
                continue

            for sample in family.samples:
                if sample.labels["status"] == StatusCodes(returncode).name:
                    if sample.value == 0:
                        return True
                    else:
                        return False

        return True

    def statuscode_to_kind_outcome_type(self, returncode: int) -> Tuple[str, str, str]:
        """
        Fills the ECS kind, outcome, and type categorization fields,
        taking into account the status change.

        Args:
            returncode: The return code of the latest execution.

        Returns:
            Tuple(kind, outcome, type), where:

            kind:
                - "state" if the current return code is OK
                - "alert" if the return code is WARNING or CRITICAL
                - "event" otherwise

            outcome:
                - "success" if the return code is OK
                - "failure" if WARNING or CRITICAL
                - "unknown" otherwise

            type:
                - "change" if a status change has been detected
                - "info" otherwise
        """
        etype = "change" if self.detect_status_change(returncode) else "info"
        if StatusCodes(returncode) == StatusCodes.OK:
            return (
                "state",
                "success",
                etype,
            )
        elif StatusCodes(returncode) <= StatusCodes.CRITICAL:
            return (
                "alert",
                "failure",
                etype,
            )
        else:
            return ("event", "unknown", etype)

    def format(self, record: LogRecord) -> str:
        """
        Returns an ECS-formatted JSON log entry with the @cee cookie,
        to ensure proper parsing by rsyslog.

        Args:
            record: A LogRecord containing extra fields:
                - executable: The command with absolute path and its arguments.
                - returncode: The command's return code.

        Returns:
            str: A JSON string representing the ECS log entry, parsable by rsyslog.
        """
        kind, outcome, etype = self.statuscode_to_kind_outcome_type(record.returncode)
        ecs_message = {
            "ecs.version": "1.7.0",
            "log.level": record.levelname.upper(),
            "message": str(record.msg),
            "event.category": "process",
            "event.kind": kind,
            "event.outcome": outcome,
            "event.type": etype,
            "event.module": self._check_command,
            "process.executable": record.executable,
            "process.exit_code": record.returncode,
            "timestamp": (
                record.timestamp
                if hasattr(record, "timestamp")
                else datetime.datetime.now(datetime.timezone.utc).isoformat()
            ),
        }
        # Prefix "@cee" cookie indicating rsyslog should parse the message as JSON
        return "@cee: %s" % json.dumps(ecs_message)


class DeferredProcess:
    """
    Placeholder class for deferred execution of subprocess.Popen.
    """

    def __init__(self, command: Tuple[str]) -> None:
        """
        Initializes an instance of DeferredProcess with the provided attributes.

        Args:
            command (str): The command, including its absolute path and arguments,
                           as returned by shlex.split(command_string).
        """
        self._command = command

    def execute(self) -> subprocess.Popen:
        """
        Invokes subprocess.Popen with the specified arguments.

        Returns:
            subprocess.Popen: The process object representing the executed command.
        """
        return subprocess.Popen(
            self._command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def get_command(self) -> Tuple[str]:
        """
        Returns the configured command.

        Returns:
            Tuple[str]: The command and its arguments as a tuple of strings.
        """
        return self._command


class NagiosConfig:
    """
    Parses and represents an NRPE check command configuration file.
    """

    def __init__(self, script_directory: Path, check_command: str) -> None:
        """
        Initializes an instance of NagiosConfig with the provided attributes.

        Args:
            script_directory (Path): The file system path where NRPE
                                     configuration files are located.
            check_command (str): The name of the NRPE check command
                                 used to identify the configuration file.
        """
        self._script_directory = script_directory
        self._check_command = check_command
        self._cfg = [""]

        # Exceptions are not caught here;
        # SystemdUnitFailed will take care of notifying the users.
        filepath = self._script_directory / f"{self._check_command}.cfg"
        with open(filepath, "r", encoding="utf-8") as file:
            self._cfg = file.readlines()

    def get_command(self) -> str:
        """
        Parses the configuration file.

        Returns:
            str: The configured command,
                 or an empty string if the file could not be parsed correctly.
        """
        pattern = re.compile(
            rf"^command\[(?P<check_name>{self._check_command})\]=(?P<command>.+)$",
            re.VERBOSE,
        )

        try:
            config_line = list(
                filter(
                    lambda x: x is not None,
                    map(lambda x: re.match(pattern, x.strip()), self._cfg),
                )
            )[0]
            return config_line.group("command")
        except IndexError:
            # print debug info only. The error will be reported to prometheus
            # through nagios_nrpe_check_config_error metric
            print(traceback.format_exc())
            return ""

    def get_executor(self) -> DeferredProcess:
        """
        Returns a Popen placeholder for deferred execution.

        Returns:
            DeferredProcess: The configured DeferredProcess,
                             or None if the config could not be parsed.
        """
        if self.get_command() == "":
            return None

        return DeferredProcess(shlex.split(self.get_command()))


class NagiosCollector:
    """
    Custom Prometheus collector for NRPE-style Nagios check config files.
    """

    def __init__(
        self,
        cache_dir: Path,
        check_command: str,
        executor: DeferredProcess,
        alert_rule_hash: str,
        perf_data: bool,
        page: bool,
        timeout: int,
    ) -> None:
        """
        Initializes an instance of NagiosCollector with the provided attributes.

        Args:
            cache_dir (Path): The file system path where Node Exporter retrieves metric files.
            check_command (str): The name of the NRPE check command
                                 used to identify the configuration file.
            executor (DeferredProcess): The Popen placeholder responsible
                                        for executing the configured command.
            alert_rule_hash (str): Used to uniquely identify the corresponding alert rule.
            perf_data (bool): True if performance data parsing is enabled.
            page (bool): if CRITICAL should be interpreted as a paging alert
            timeout (int): The execution timeout, in seconds.
        """
        self._cache_dir = cache_dir
        self._check_command = check_command
        self._executor = executor
        self._alert_rule_hash = alert_rule_hash
        self._perf_data = perf_data
        self._page = page
        self._timeout = timeout

    def store_log(self, executable: str, returncode: int, log: str) -> None:
        """
        Logs the command output in an ECS-compatible format.

        Args:
            executable: A string representing the executable with its absolute path and arguments.
            returncode: The status code of the command execution.
            log: The output of the command.
        """
        logger = logging.getLogger()
        logger.setLevel(logging.DEBUG)
        logHandler = logging.StreamHandler()
        formatter = ECSFormatter(self._cache_dir, self._check_command)
        logHandler.setFormatter(formatter)
        logger.addHandler(logHandler)

        logger.info(log, extra={"executable": executable, "returncode": returncode})

    def run_check(self, timeout: float) -> Tuple[int, str]:
        """
        Runs the NRPE check.

        Args:
            timeout: The execution timeout.

        Returns:
            Tuple: A tuple containing the return code and output.
        """
        try:
            executor = self._executor.execute()
            output, error = executor.communicate(timeout=timeout)

            return executor.returncode, output
        except subprocess.TimeoutExpired:
            print(traceback.format_exc())
            return (
                StatusCodes.UNKNOWN,
                f"Check execution timed out after {round(timeout, 1)} seconds",
            )
        except:  # noqa E722
            # print debug info only. The error will be reported to prometheus
            # through as an UNKNOWN status
            print(traceback.format_exc())
            return (StatusCodes.UNKNOWN, "An unknown error occurred.")

    def execute_and_parse(self, metric: Gauge, perfdata_metric: Gauge) -> None:
        """
        Invokes run_check and parses its output (including performance data) to populate
        the provided Gauge.

        Return codes outside the range 0-3 will be mapped to the value 3.

        Invokes store_log to ship the logs to Logstash.

        Args:
            metric: A Prometheus Gauge to map the execution return code.
            perfdata_metric: A Prometheus Gauge to store the parsed performance data.
        """
        code, output = self.run_check(self._timeout)

        if not (StatusCodes.OK <= code <= StatusCodes.UNKNOWN):
            code = StatusCodes.UNKNOWN

        self.store_log(shlex.join(self._executor.get_command()), code, output)

        text = output.replace('"', "'").split("|", 1)

        for status_label, status_code in StatusCodes.__members__.items():
            metric.add_metric(
                [
                    self._check_command,
                    self._alert_rule_hash,
                    status_label,
                    StatusCodes(status_code).get_severity(page=self._page),
                ],
                1 if status_code == code else 0,
            )

        if self._perf_data:
            perfdata = text[1].strip() if len(text) > 1 else ""
            pattern = re.compile(
                r"""(?P<label>'[^']*'|[^\s=']+)=                 # label
                    (?P<value>-?\d+(?:\.\d+)?)                   # value
                    (?P<uom>[a-zA-Z%]*)                          # UOM, optional
                    ;
                    (?P<warn>-?\d*(?:\.\d*)?)?;
                    (?P<crit>-?\d*(?:\.\d*)?)?;
                    (?P<min>-?\d*(?:\.\d*)?)?;
                    (?P<max>-?\d*(?:\.\d*)?)?                    # thresholds, optional
                """,
                re.VERBOSE,
            )
            for match in pattern.finditer(perfdata):
                m = Box(match.groupdict())
                perfdata_metric.add_metric(
                    [
                        self._check_command,
                        self._alert_rule_hash,
                        m.label,
                        m.get("uom", "undef"),
                        m.get("warn", "undef"),
                        m.get("crit", "undef"),
                        m.get("min", "undef"),
                        m.get("max", "undef"),
                    ],
                    m.value,
                )

    def collect(self) -> Iterator[GaugeMetricFamily]:
        """
        Parses NRPE-style .cfg files and runs defined command,
        updating Prometheus metrics with their exit codes and outputs.
        """
        metric = GaugeMetricFamily(
            "nagios_nrpe_check_result",
            "Result of Nagios-style check script execution",
            labels=["check_name", "alert_rule_hash", "status", "severity"],
        )

        perfdata = GaugeMetricFamily(
            "nagios_nrpe_check_perfdata",
            "PerfData generated by Nagios-style check script execution",
            labels=[
                "check_name",
                "alert_rule_hash",
                "entity",
                "unit",
                "warn",
                "crit",
                "min",
                "max",
            ],
        )

        error = GaugeMetricFamily(
            "nagios_nrpe_check_config_error",
            "True if errors occurred during check initialization.",
            labels=["check_name", "alert_rule_hash"],
        )

        if self._executor is not None:
            self.execute_and_parse(metric, perfdata)
        error.add_metric(
            [self._check_command, self._alert_rule_hash],
            1 if self._executor is None else 0,
        )

        if len(metric.samples) > 0:
            yield metric
        if len(perfdata.samples) > 0:
            yield perfdata
        yield error


@click.command()
@click.option("--check-command", required=True, help="The name of the check command")
@click.option(
    "--alert-rule-hash",
    required=True,
    help="Used to uniquely identify the corresponding alert rule.",
)
@click.option("--timeout", default=10, help="check command timeout in seconds")
@click.option(
    "--perf-data",
    is_flag=True,
    default=False,
    help="Parse perfdata as defined in https://nagios-plugins.org/doc/guidelines.html#AEN200",
)
@click.option(
    "--page",
    is_flag=True,
    default=False,
    help="if CRITICAL should be interpreted as a paging alert",
)
@click.option(
    "--cleanup", is_flag=True, default=True, help="Clean up on uncaught exceptions"
)
@click.option(
    "--dry-run", is_flag=True, default=False, help="Run without making changes"
)
@click.option("--debug", is_flag=True, default=False, help="Print verbose debug ouput")
def main(
    check_command: str,
    alert_rule_hash: str,
    timeout: int,
    perf_data: bool,
    page: bool,
    cleanup: bool,
    dry_run: bool,
    debug: bool,
) -> None:
    """
    Main entry point. Collects the data and store the result in a file.
    """
    OUTPUT_FILE = NODE_EXPORTER_DIR / f"{check_command}.prom"

    try:
        registry = CollectorRegistry()

        nagiosconfig = NagiosConfig(SCRIPT_DIRECTORY, check_command)
        nagioscollector = NagiosCollector(
            NODE_EXPORTER_DIR,
            check_command,
            nagiosconfig.get_executor(),
            alert_rule_hash,
            perf_data,
            page,
            timeout,
        )
        registry.register(nagioscollector)

        metrics_output = generate_latest(registry)
        if debug:
            print(metrics_output.decode("utf-8"))

        if not dry_run:
            with OUTPUT_FILE.open("wb") as f:
                f.write(metrics_output)
    except Exception:
        # Cleanup (enables the use of the up/absent function on the Prometheus side):
        # * Handle any uncaught exceptions
        # * Remove the output file from the node exporter directory
        # * Re-raise the exception
        if (
            cleanup
            and (
                NODE_EXPORTER_DIR.exists()
                and NODE_EXPORTER_DIR.is_dir()
                and os.access(NODE_EXPORTER_DIR, os.W_OK)
            )
            and (OUTPUT_FILE.exists() and OUTPUT_FILE.is_file())
        ):
            OUTPUT_FILE.unlink()
        raise


if __name__ == "__main__":
    main()
