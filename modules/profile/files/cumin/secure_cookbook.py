#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

"""Run the cookbook command only as configured for deployed use."""

import argparse
import subprocess


def restrict_args():
    parser = argparse.ArgumentParser(
        "Run the cookbook command only as configured for deployed use."
    )
    parser.add_argument(
        "-c",
        "--config-file",
        type=str,
        choices=["/etc/spicerack/config.yaml"],
        help="Only the default is accepted for cookbook config.",
    )
    return parser.parse_known_args()


def main():
    _, cmd_args = restrict_args()
    cmd = ["/usr/bin/cookbook"]
    cmd.extend(cmd_args)
    completed = subprocess.run(cmd)
    return completed.returncode


if __name__ == "__main__":
    exit(main())
