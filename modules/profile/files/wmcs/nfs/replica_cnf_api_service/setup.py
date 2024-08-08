#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

from pathlib import Path

from setuptools import setup

cur_file = Path(__file__)
requirements = [
    line
    for line in (cur_file.parent / "requirements.txt").read_text().splitlines()
    if not line.startswith("#")
]

setup(
    name="replica_cnf_api_service",
    version="1.0",
    description="API to generate replica.cnf credentials for toolforge and paws",
    author="David Caro",
    author_email="dcaro@wikimedia.org",
    url="http://toolforge.org",
    install_requires=requirements,
    packages=["replica_cnf_api_service"],
)
