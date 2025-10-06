#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

"""
The Wheel of Misfortune gathers processes to kill and kills them based on your
favorite parameters!
"""

import argparse
from datetime import datetime, timezone
import logging
import os
import random
import socket
import signal
import subprocess
import sys
import time
from typing import List

import psutil


# A list of shells and remote shells people actually use interactively
SHELLS = (
    "/bin/bash",
    "/bin/csh",
    "/bin/tcsh",
    "/bin/zsh",
    "/lib/systemd/systemd",  # Needed for the systemd mounted cgroups of a shell
    "/usr/bin/bash",
    "/usr/bin/csh",
    "/usr/bin/fish",
    "/usr/bin/mosh-server",
    "/usr/bin/mysql",
    "/usr/bin/screen",
    "/usr/bin/sudo",  # `become $TOOL` is seen as `/usr/bin/sudo -niu $TOOL`
    "/usr/bin/tcsh",
    "/usr/bin/tmux",
    "/usr/bin/zsh",
    "/usr/lib/openssh/sshd-session",  # T406504: openssh 9.8 subprocess
    "/usr/lib/systemd/systemd",  # Needed for the systemd mounted cgroups of a shell
    "/usr/lib/systemd/systemd-executor",  # Needed for systemd to manage PAM session
    "/usr/sbin/sshd",
)


def email_user(
    user: str,
    procname: str,
    hostname: str,
) -> bool:
    # here we email the user after all that
    subject = "{} killed by Wheel of Misfortune on Toolforge bastion".format(procname)
    body_str = """
Your process `{procname}` has been killed on {hostname} by the Wheel of
Misfortune script.

You are receiving this email because you are listed as the shell user running
the killed process or as a maintainer of the tool that was.

Long-running processes and services are intended to be run on the Kubernetes
environment, not on the bastion servers themselves. In order to ensure that
login servers don't get heavily burdened by such processes, this script selects
long-running processes at random for destruction.

For further support, visit #wikimedia-cloud on libera.chat or
<https://wikitech.wikimedia.org>
""".format(
        procname=procname, hostname=hostname
    )
    body = body_str.encode("utf-8")
    args = [
        b"/usr/bin/mail",
        b"-s",
        subject.encode("utf-8"),
        # This is the Unix username. Exim will qualify that with @toolforge.org,
        # which the Toolforge mail servers will route to the address in LDAP.
        user.encode("utf-8"),
    ]
    p = subprocess.Popen(
        args,
        stdout=subprocess.PIPE,
        stdin=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    p.communicate(input=body)[0]
    return True


def spin_the_wheel(min_uid: int, victims: int, age: float) -> List[psutil.Process]:
    lucky_contestants = []
    now = datetime.now(timezone.utc).timestamp()
    for proc in psutil.process_iter():
        # Ignore shells and remotes themselves
        # proc.exe() is blank surprisingly often, but apparently only in cases
        # we don't care about
        if proc.exe() in SHELLS:
            continue

        uids = proc.uids()
        created = proc.create_time()
        time_ago = now - age
        if uids[0] >= min_uid and created < time_ago:
            lucky_contestants.append(proc)

    ages = [now - x.create_time() for x in lucky_contestants]
    # The choices function does not like empty arrays
    if not lucky_contestants:
        return []

    return random.choices(lucky_contestants, weights=ages, k=victims)


def slay(victims: List[psutil.Process]) -> None:
    hostname = socket.gethostname()
    for vic in victims:
        if not psutil.pid_exists(vic.pid):
            logging.warning("Victim %s does not exist; skipping", vic.pid)
            continue

        logging.info(
            "Killing %s", vic.as_dict(attrs=["pid", "username", "uids", "name"])
        )
        # Save aside proc info before you kill it for later emailing.
        username = vic.username()
        proc_name = vic.name()
        os.kill(vic.pid, signal.SIGINT)
        # Give it a couple seconds to die honorably
        time.sleep(2)
        if psutil.pid_exists(vic.pid):
            os.kill(vic.pid, signal.SIGKILL)
        email_user(username, proc_name, hostname)


def main():
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    parser = argparse.ArgumentParser(
        description=(
            "The Wheel of Misfortune will kill random user "
            "processes, weighted by age"
        )
    )
    parser.add_argument(
        "--age",
        "-a",
        type=int,
        required=True,
        help="Age of candidate processes in days, defaults to 3",
    )
    parser.add_argument(
        "--victims",
        "-v",
        type=int,
        required=True,
        help="Number of processes to kill",
    )
    parser.add_argument(
        "--min-uid",
        "-m",
        type=int,
        required=True,
        help="Minimum UID to consider kill-worthy",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Change nothing, just talk about it",
    )
    args = parser.parse_args()

    days = float(args.age * 86400)
    victims = spin_the_wheel(min_uid=args.min_uid, victims=args.victims, age=days)
    if args.dry_run:
        logging.info("I would kill:")
        for vic in victims:
            logging.info(vic.as_dict(attrs=["pid", "username", "uids", "name"]))

        sys.exit()

    slay(victims)
    sys.exit()


if __name__ == "__main__":
    main()
