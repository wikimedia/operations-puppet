#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# Copyright C 2019-, Wikimedia Foundation, Inc.
# This script is licensed under the apache license
"""
Builds the envoy configuration, given a configuration directory, from the
following files:
- $dir/admin-config.yaml
- $dir/listeners.d/*.yaml
- $dir/clusters.d/*.yaml

The output will be placed in $dir/envoy.yaml, if compilation is successful,
after verifying
the validity of the resulting configuration.

For an introduction to envoy's configuration file, see e.g.

https://www.envoyproxy.io/docs/envoy/v1.11.0/start/start#quick-start-to-run-simple-example
"""
import argparse
import glob
import logging
import os
import shutil
import subprocess
import sys

from typing import Generator, List

import yaml

# Helper functions below taken from
# https://vincent.bernat.ch/en/blog/2019-sustainable-python-script
logger = logging.getLogger(os.path.splitext(os.path.basename(sys.argv[0]))[0])


class CustomFormatter(
    argparse.RawDescriptionHelpFormatter, argparse.ArgumentDefaultsHelpFormatter
):
    pass


def parse_args(args: List[str] = sys.argv[1:]):
    """Parse arguments."""
    parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__, formatter_class=CustomFormatter
    )
    parser.add_argument("--configdir", "-c", metavar="DIR")
    log = parser.add_mutually_exclusive_group()
    log.add_argument(
        "--debug", "-d", action="store_true", default=False, help="enable debugging"
    )
    log.add_argument(
        "--silent",
        "-s",
        action="store_true",
        default=False,
        help="don't log to console",
    )
    return parser.parse_args(args)


def setup_logging(options: argparse.Namespace):
    """Configure logging."""
    root = logging.getLogger("")
    root.setLevel(logging.WARNING)
    logger.setLevel(options.debug and logging.DEBUG or logging.INFO)
    if not options.silent:
        ch = logging.StreamHandler()
        ch.setFormatter(logging.Formatter("%(levelname)s[%(name)s] %(message)s"))
        logger.addHandler(ch)


class EnvoyConfig:
    def __init__(self, base_dir: str):
        self._base_dir = base_dir
        self.admin_file = os.path.join(base_dir, "admin-config.yaml")
        self.runtime_file = os.path.join(base_dir, "runtime.yaml")
        self.config_file = os.path.join(base_dir, "envoy.yaml")
        self.config = {
            "admin": {},
            "static_resources": {"listeners": [], "clusters": []},
        }

    def _read_admin(self):
        with open(self.admin_file, "r") as admin_fh:
            admin = yaml.safe_load(admin_fh)
        self.config["admin"] = admin

    def _read_runtime(self):
        try:
            with open(self.runtime_file, "r") as runtime_fh:
                static_runtime = yaml.safe_load(runtime_fh)
        except FileNotFoundError:
            # Runtime config is optional. If the file is absent, don't set
            # layered_runtime in the output config, so we get the default.
            return
        self.config["layered_runtime"] = {
            "layers": [
                {"name": "static_layer", "static_layer": static_runtime},
                # Include an empty admin_layer *after* the static layer, so we can
                # continue to make changes via the admin console and they'll overwrite
                # values from the previous layer.
                {"name": "admin_layer", "admin_layer": {}},
            ]
        }

    def _walk_dir(self, what: str, glob_expr: str) -> Generator[str, None, None]:
        """Returns the full path of files in a directory"""
        for filename in sorted(glob.glob(os.path.join(what, glob_expr))):
            if os.path.isfile(filename):
                yield filename

    def _read(self, name: str, what: str):
        logger.debug("Reading %s into %s", name, what)
        with open(name, "r") as file_handle:
            data = yaml.safe_load(file_handle)
        self.config["static_resources"][what].append(data)

    def populate_config(self):
        """Populate the configuration.

        If anything goes wrong, exceptions will be raised
        """
        self._read_admin()
        self._read_runtime()
        for what in ["listeners", "clusters"]:
            dirname = os.path.join(self._base_dir, what + ".d")
            logger.debug("Reading %s from %s", what, dirname)
            for filename in self._walk_dir(dirname, "*.yaml"):
                self._read(filename, what)

    def verify_config(self, tmpdir: str = "/tmp/.envoyconfig") -> bool:
        """Verifies the configuration stored is valid."""
        try:
            if not os.path.isdir(tmpdir):
                os.mkdir(tmpdir, 0o755)
            tmpconfig = os.path.join(tmpdir, "envoy.yaml")
            self.write_config(config_file=tmpconfig)
            subprocess.check_output(
                [
                    "sudo",
                    "-u",
                    "envoy",
                    "/usr/bin/envoy",
                    "-c",
                    tmpconfig,
                    "--mode validate",
                ]
            )
            return True
        except subprocess.CalledProcessError as e:
            logger.error("Error encountered while verifying the configuration")
            logger.info("verification exited with return code %d", e.returncode)
            logger.info("== Stdout:")
            logger.info(e.stdout)
            if e.stderr is not None:
                logger.info("== Stderr:")
                logger.info(e.stderr)
            return False
        except Exception as e:
            logger.exception("Error while verifying the configuration: %s", e)
            return False
        finally:
            shutil.rmtree(tmpdir)

    def write_config(self, config_file=None):
        if config_file is None:
            config_file = self.config_file
        with open(config_file, "w") as config_fh:
            yaml.safe_dump(self.config, config_fh)


# The main script
if __name__ == "__main__":
    exitcode = 0
    options = parse_args()
    setup_logging(options)
    try:
        configuration = EnvoyConfig(options.configdir)
        configuration.populate_config()
        if configuration.verify_config():
            configuration.write_config()
        else:
            logger.error("Configuration invalid, config file NOT overwritten")
            exitcode = 1
    except Exception as e:
        logger.exception("%s", e)
        exitcode = 2
    sys.exit(exitcode)
