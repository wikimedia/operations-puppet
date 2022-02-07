#!/usr/bin/env python3

# (C) 2021 by Arturo Borrero Gonzalez <arturo@debian.org>

#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#

# This file has been copy-pasted from:
# https://github.com/aborrero/sys-avenger/blob/master/src/cmd-checklist-runner.py

# checklist.yaml file format:
#  ---
#  - envvars:
#      - MYVAR: "myvalue"
#        MYVAR2: "myvalue2"
#  ---
#  - name: "this is a test that does something"
#    tests:
#      - cmd: cmd1
#        retcode: 0
#        stdout: "expected stdout from cmd1"
#        stderr: "expected stderr from cmd1"
#      - cmd: cmd2
#        retcode: 0
#        stdout: "expected stdout from cmd2"
#        stderr: "expected stderr from cmd2"
#

import os
import socket
import platform
import sys
import argparse
import subprocess
import yaml
import logging
from dataclasses import dataclass
from enum import Enum, auto
from typing import Optional, List


class InvalidConfigError(Exception):
    """Class to represent an invalid configuration error."""


class TestResult(Enum):
    """Class to represent a test result."""

    NOTRUN = auto()
    OK = auto()
    FAILED = auto()


@dataclass(frozen=True)
class Command:
    """Class to represent a command to be executed."""

    cmd: str
    retcode: Optional[int]
    stdout: Optional[str]
    stderr: Optional[str]


@dataclass()
class Test:
    """Class to represent a test to be executed."""

    name: str
    spec: List[Command]
    result: Optional[TestResult]


@dataclass(frozen=True)
class Envvar:
    """Class to represent an envvar."""

    key: str
    value: str


@dataclass(frozen=True)
class Config:
    """Class to represent user configuration."""

    envvars: Optional[List[Envvar]]
    tests: List[Test]
    exit_code_fail: Optional[bool] = False


def read_yaml_file(file):
    try:
        with open(file, "r") as stream:
            return [doc for doc in yaml.safe_load_all(stream)]
    except FileNotFoundError as e:
        logging.error(e)
        exit(2)


def validate_dictionary(dictionary, keys):
    if not isinstance(dictionary, dict):
        raise InvalidConfigError(f"not a dictionary:\n{dictionary}")
    for key in keys:
        if dictionary.get(key) is None:
            raise InvalidConfigError(f"missing key '{key}' in dictionary:\n{dictionary}")


def load_envs(config: Config):
    for envvar in config.envvars:
        key = envvar.key
        value = envvar.value
        logging.debug(f"will try to set envvar: {key}={value}")
        os.environ[key] = os.getenv(key, value)


def stage_validate_config(args) -> Config:
    envvars = []
    tests = []

    docs = read_yaml_file(args.config_file)
    for doc in docs:
        logging.debug(f"validating doc {doc}")

        for definition in doc:
            if definition.get("envvars", None):
                for envvar in definition["envvars"]:
                    for key, value in envvar.items():
                        new_envvar = Envvar(key=key, value=value)
                        envvars.append(new_envvar)

            if definition.get("name", None):
                validate_dictionary(definition, ["name", "tests"])

                test_cmds = []
                for test in definition["tests"]:
                    validate_dictionary(test, ["cmd"])
                    cmd = Command(
                        cmd=test.get("cmd"),
                        retcode=test.get("retcode", None),
                        stdout=test.get("stdout", None),
                        stderr=test.get("stderr", None),
                    )

                    test_cmds.append(cmd)

                test = Test(name=definition.get("name"), spec=test_cmds, result=TestResult.NOTRUN)
                tests.append(test)

    logging.debug(f"'{args.config_file}' seems valid")
    return Config(envvars=envvars, tests=tests, exit_code_fail=args.exit_code_fail)


def cmd_run(command: Command) -> bool:
    success = True

    expanded_cmd = os.path.expandvars(command.cmd)
    logging.debug(f"running command: {expanded_cmd}")
    r = subprocess.run(expanded_cmd, capture_output=True, shell=True)

    expected_retcode = command.retcode
    if expected_retcode is not None:
        if r.returncode != expected_retcode:
            logging.warning(
                f"cmd '{expanded_cmd}', expected return code '{expected_retcode}', "
                f"but got '{r.returncode}'"
            )
            success = False
    else:
        logging.debug("no retcode defined for command, ignoring")

    expected_stdout = command.stdout
    if expected_stdout is not None:
        stdout = r.stdout.decode("utf-8").strip()
        if stdout != expected_stdout:
            logging.warning(
                f"cmd '{expanded_cmd}', expected stdout '{expected_stdout}', but got '{stdout}'"
            )
            success = False
    else:
        logging.debug("no stdout defined for command, ignoring")

    expected_stderr = command.stderr
    if expected_stderr is not None:
        stderr = r.stderr.decode("utf-8").strip()
        if stderr != expected_stderr:
            logging.warning(
                f"cmd '{expanded_cmd}', expected stderr '{expected_stderr}', but got '{stderr}'"
            )
            success = False
    else:
        logging.debug("no stderr defined for command, ignoring")

    return success


def test_run(test: Test):
    logging.info(f"running: {test.name}")

    for command in test.spec:
        if cmd_run(command):
            continue

        logging.warning(f"failed test: {test.name}")
        test.result = TestResult.FAILED
        return

    test.result = TestResult.OK


def stage_run_tests(config: Config):
    load_envs(config)

    for test in config.tests:
        test_run(test)


def stage_report(config: Config):

    tests_ok = 0
    tests_failed = 0
    for test in config.tests:
        if test.result == TestResult.OK:
            tests_ok += 1
        elif test.result == TestResult.FAILED:
            tests_failed += 1

    logging.info("---")
    logging.info(f"--- passed tests: {tests_ok}")
    logging.info(f"--- failed tests: {tests_failed}")
    logging.info(f"--- total tests: {tests_ok + tests_failed}")

    exit_code = 0
    if config.exit_code_fail and tests_failed > 0:
        exit_code = 1

    sys.exit(exit_code)


def parse_args():
    description = "Utility to run arbitrary command tests"
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--config-file",
        default="cmd-checklist-config.yaml",
        help="File with configuration and testcase definitions. Defaults to '%(default)s'",
    )
    parser.add_argument("--debug", action="store_true", help="debug mode")
    parser.add_argument(
        "--exit-code-fail",
        action="store_true",
        help="report in the exit code if a check fails",
    )

    return parser.parse_args()


def stage_report_node_info():
    hostname = socket.gethostname()

    os = "[unknown OS]"
    try:
        with open("/etc/os-release", "r") as f:
            for line in f.readlines():
                if line.startswith("PRETTY_NAME="):
                    os = line.split("PRETTY_NAME=")[1].strip().strip('"')
                    break
    except Exception:
        pass

    release = platform.release()

    logging.info(f"--- {hostname} {os} {release}")
    logging.info("---")


def main():
    args = parse_args()

    logging_format = "[%(asctime)s] %(levelname)s: %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"
    if args.debug:
        logging_level = logging.DEBUG
    else:
        logging_level = logging.INFO
    logging.addLevelName(
        logging.WARNING, "\033[1;33m%s\033[1;0m" % logging.getLevelName(logging.WARNING)
    )
    logging.addLevelName(
        logging.ERROR, "\033[1;31m%s\033[1;0m" % logging.getLevelName(logging.ERROR)
    )
    logging.basicConfig(
        format=logging_format, level=logging_level, stream=sys.stdout, datefmt=date_format
    )

    try:
        config = stage_validate_config(args)
    except InvalidConfigError as e:
        logging.error(f"couldn't validate file '{args.config_file}': {e}")
        sys.exit(1)

    stage_report_node_info()
    stage_run_tests(config)
    stage_report(config)


if __name__ == "__main__":
    main()
