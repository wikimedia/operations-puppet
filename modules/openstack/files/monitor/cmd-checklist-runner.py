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
import sys
import argparse
import subprocess
import yaml
import logging


def read_yaml_file(file):
    try:
        with open(file, "r") as stream:
            try:
                return [doc for doc in yaml.safe_load_all(stream)]
            except yaml.YAMLError as e:
                logging.error(e)
                exit(2)
    except FileNotFoundError as e:
        logging.error(e)
        exit(2)


def validate_dictionary(dictionary, keys):
    if not isinstance(dictionary, dict):
        logging.error(f"not a dictionary:\n{dictionary}")
        return False
    for key in keys:
        if dictionary.get(key) is None:
            logging.error(f"missing key '{key}' in dictionary:\n{dictionary}")
            return False
    return True


def load_envs(envvars_dict):
    for envvars in envvars_dict:
        logging.debug(envvars.items())
        for envvar in envvars.items():
            key = envvar[0]
            value = envvar[1]
            logging.debug(f"will try to set envvar: {key}={value}")
            os.environ[key] = os.getenv(key, value)


def stage_validate_config(args):
    docs = read_yaml_file(args.config_file)
    for doc in docs:
        logging.debug(f"validating doc {doc}")

        for definition in doc:
            if definition.get("envvars", None):
                load_envs(definition["envvars"])

            if definition.get("name", None):
                if not validate_dictionary(definition, ["name", "tests"]):
                    logging.error(f"couldn't validate file '{args.config_file}'")
                    return False
                for test in definition["tests"]:
                    if not validate_dictionary(test, ["cmd"]):
                        logging.error(f"couldn't validate file '{args.config_file}'")
                        return False

                ctx.checklist_dict = doc

    logging.debug(f"'{args.config_file}' seems valid")
    return True


def cmd_run(cmd, expected_retcode, expected_stdout, expected_stderr):
    success = True
    expanded_cmd = os.path.expandvars(cmd)
    logging.debug(f"running command: {expanded_cmd}")
    r = subprocess.run(cmd, capture_output=True, shell=True)

    if expected_retcode is not None:
        if r.returncode != expected_retcode:
            logging.warning(
                f"cmd '{expanded_cmd}', expected return code '{expected_retcode}', "
                f"but got '{r.returncode}'"
            )
            success = False
    else:
        logging.debug("no retcode defined for command, ignoring")

    if expected_stdout is not None:
        stdout = r.stdout.decode("utf-8").strip()
        if stdout != expected_stdout:
            logging.warning(
                f"cmd '{expanded_cmd}', expected stdout '{expected_stdout}', but got '{stdout}'"
            )
            success = False
    else:
        logging.debug("no stdout defined for command, ignoring")

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


def test_run(test_definition):
    logging.info("running test: {}".format(test_definition["name"]))

    for test in test_definition["tests"]:
        if cmd_run(
            test["cmd"],
            test.get("retcode", None),
            test.get("stdout", None),
            test.get("stderr", None),
        ):
            continue

        logging.warning("failed test: {}".format(test_definition["name"]))
        ctx.counter_test_failed += 1
        return

    ctx.counter_test_ok += 1


def stage_run_tests(args):
    for test_definition in ctx.checklist_dict:
        test_run(test_definition)


def stage_report():
    logging.info("---")
    total = ctx.counter_test_ok + ctx.counter_test_failed
    logging.info("--- passed tests: {}".format(ctx.counter_test_ok))
    logging.info("--- failed tests: {}".format(ctx.counter_test_failed))
    logging.info("--- total tests: {}".format(total))


def parse_args():
    description = "Utility to run arbitrary command tests"
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--config-file",
        default="cmd-checklist-config.yaml",
        help="File with configuration and testcase definitions. Defaults to '%(default)s'",
    )
    parser.add_argument("--debug", action="store_true", help="debug mode")

    return parser.parse_args()


class Context:
    def __init__(self):
        self.checklist_dict = None
        self.counter_test_failed = 0
        self.counter_test_ok = 0


# global data
ctx = Context()


def main():
    args = parse_args()

    logging_format = "[%(filename)s] %(levelname)s: %(message)s"
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
    logging.basicConfig(format=logging_format, level=logging_level, stream=sys.stdout)

    if not stage_validate_config(args):
        sys.exit(1)
    stage_run_tests(args)
    stage_report()


if __name__ == "__main__":
    main()
