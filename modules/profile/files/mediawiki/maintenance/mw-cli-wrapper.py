#!/usr/bin/python3
"""
Copyright (C) 2019 Giuseppe Lavagetto <glavagetto@wikimedia.org>
Copyright (C) 2021 Kunal Mehta <legoktm@debian.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

import subprocess
import sys
from pathlib import Path

import yaml

CONFD_FILE = Path("/etc/conftool-state/mediawiki.yaml")
# First check if the confd file is stale or not. If it is, just exit
subprocess.run(
    ["/usr/local/lib/nagios/plugins/check_confd_template", str(CONFD_FILE)],
    check=True,
    stdout=subprocess.DEVNULL,
)

state = yaml.safe_load(CONFD_FILE.read_text())
primary_dc = state["primary_dc"]
my_dc = Path("/etc/wikimedia-cluster").read_text().strip()
read_only = state["read_only"][my_dc]

# We don't exit with an error status code, it doesn't really
# make sense as this is an expected behaviour.
if primary_dc != my_dc:
    print("Skipping execution, not the primary datacenter!")
elif read_only:
    print("Skipping execution, in read-only mode!")
else:
    # In the primary DC and not in read-only mode
    subprocess.run(sys.argv[1:], check=True, shell=True)
