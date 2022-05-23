#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

"""
The Wheel of Misfortune gathers processes to kill and kills them based on your
favorite parameters!
"""

import argparse
from bisect import bisect as _bisect
from datetime import datetime, timezone
from itertools import accumulate as _accumulate, repeat as _repeat
import logging
import os
import random
import socket
import signal
import subprocess
import sys
import time
from typing import List

import ldap3
import psutil
import yaml


# A list of shells and remote shells people actually use interactively
SHELLS = (
    "/bin/bash",
    "/bin/csh",
    "/bin/tcsh",
    "/bin/zsh",
    "/usr/bin/bash",
    "/usr/bin/csh",
    "/usr/bin/fish",
    "/usr/bin/mysql",
    "/usr/bin/screen",
    "/usr/bin/tcsh",
    "/usr/bin/tmux",
    "/usr/bin/zsh",
    "/usr/sbin/sshd",
    "/usr/bin/mosh-server",
    "/lib/systemd/systemd",  # Needed for the systemd mounted cgroups of a shell
    "/usr/lib/systemd/systemd",  # Needed for the systemd mounted cgroups of a shell
)


def get_group_members(group: str, conn: ldap3.Connection) -> List[str]:
    conn.search(
        "ou=servicegroups,dc=wikimedia,dc=org",
        "(&(objectClass=posixGroup)(cn={}))".format(group),
        search_scope=ldap3.SUBTREE,
        attributes=["member"],
        time_limit=5,
        paged_size=1000,
    )
    users = []
    for resp in conn.response:
        for member in resp["attributes"]["member"]:
            users.append(member.split(",")[0])

    cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
        "cookie"
    ]
    while cookie:
        conn.search(
            "ou=servicegroups,dc=wikimedia,dc=org",
            "(&(objectClass=posixGroup)(cn={}))".format(group),
            ldap3.SUBTREE,
            attributes=["member"],
            time_limit=5,
            paged_size=1000,
            paged_cookie=cookie,
        )
        cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
            "cookie"
        ]
        for resp in conn.response:
            for member in resp["attributes"]["member"]:
                uid_str = member.split(",")[0]
                users.append(uid_str.split("=")[1])

    return users


def email_user(
    user: str,
    conn: ldap3.Connection,
    procname: str,
    hostname: str,
    project: str = "tools",
) -> bool:
    if user.startswith("{}.".format(project)):
        users_in_project = get_group_members(user, conn)
        for usr in users_in_project:
            email_user(usr, conn, procname, hostname, project)

    conn.search(
        "ou=people,dc=wikimedia,dc=org",
        "(&(objectClass=posixAccount)(uid={}))".format(user),
        search_scope=ldap3.SUBTREE,
        attributes=["uid", "mail"],
        time_limit=5,
        paged_size=1000,
    )
    users = []
    for resp in conn.response:
        attrs = resp["attributes"]
        users.append((attrs["uid"][0], attrs["mail"][0]))

    cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
        "cookie"
    ]
    while cookie:
        conn.search(
            "ou=people,dc=wikimedia,dc=org",
            "(&(objectClass=posixAccount)(uid={}))".format(user),
            ldap3.SUBTREE,
            attributes=["uid", "mail"],
            time_limit=5,
            paged_size=1000,
            paged_cookie=cookie,
        )
        cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
            "cookie"
        ]
        for resp in conn.response:
            attrs = resp["attributes"]
            users.append((attrs["uid"][0], attrs["mail"][0]))

    if len(users) == 1:
        # here we email the user after all that
        our_user = users[0]
        subject = "{} killed by Wheel of Misfortune on {} bastion".format(
            procname, project
        )
        body_str = """
Your process `{procname}` has been killed on {hostname} by the Wheel of
Misfortune script.

You are receiving this email because you are listed as the shell user running
the killed process or as a maintainer of the tool that was.

Long-running processes and services are intended to be run on the either the
Kubernetes environment or the job grid not on the bastion servers themselves. In
order to ensure that login servers don't get heavily burdened by such processes,
this script selects long-running processes at random for destruction.

See <https://phabricator.wikimedia.org/T266300> for more information on this
initative. You are invited to provide constructive feedback about the
importance of particular types long running processes to your work in support
of the Wikimedia movement.

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
            our_user[1].encode("utf-8"),
        ]
        p = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        p.communicate(input=body)[0]
        return True

    return False


# Copied from python 3.6. When we are not using Debian Stretch,
# just use random.choices()
def choices(population, weights=None, *, cum_weights=None, k=1):
    """Return a k sized list of population elements chosen with replacement.
    If the relative weights or cumulative weights are not specified,
    the selections are made with equal probability.
    """
    n = len(population)
    if cum_weights is None:
        if weights is None:
            _int = int
            n += 0.0  # convert to float for a small speed improvement
            return [
                population[_int(random.random() * n)] for i in _repeat(None, k)
            ]
        cum_weights = list(_accumulate(weights))
    elif weights is not None:
        raise TypeError("Cannot specify both weights and cumulative weights")
    if len(cum_weights) != n:
        raise ValueError("The number of weights does not match the population")
    bisect = _bisect
    total = cum_weights[-1] + 0.0  # convert to float
    hi = n - 1
    return [
        population[bisect(cum_weights, random.random() * total, 0, hi)]
        for i in _repeat(None, k)
    ]


def spin_the_wheel(
    min_uid: int = 500, victims: int = 1, age: float = 259200.0
) -> List[psutil.Process]:
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

    return choices(lucky_contestants, weights=ages, k=victims)


def slay(
    victims: List[psutil.Process],
    conn: ldap3.Connection,
    project: str = "tools",
) -> None:
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
        email_user(username, conn, proc_name, hostname, project)


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
        default=3,
        help="Age of candidate processes in days, defaults to 3",
    )
    parser.add_argument(
        "--victims",
        "-v",
        type=int,
        default=2,
        help="Number of processes to kill",
    )
    parser.add_argument(
        "--project",
        type=str,
        required=True,
        help="The Cloud VPS project you are running in or simulating",
    )
    parser.add_argument(
        "--min-uid",
        "-m",
        type=int,
        default=500,
        help="Minimum UID to consider kill-worthy",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Change nothing, just talk about it",
    )
    args = parser.parse_args()

    days = float(args.age * 86400)
    victims = spin_the_wheel(
        min_uid=args.min_uid, victims=args.victims, age=days
    )
    if args.dry_run:
        logging.info("I would kill:")
        for vic in victims:
            logging.info(vic.as_dict(attrs=["pid", "username", "uids", "name"]))

        sys.exit()

    with open("/etc/ldap.yaml") as f:
        ldap_config = yaml.safe_load(f)
    servers = ldap3.ServerPool(
        [ldap3.Server(s, connect_timeout=1) for s in ldap_config["servers"]],
        ldap3.ROUND_ROBIN,
        active=True,
        exhaust=True,
    )
    with ldap3.Connection(
        servers,
        read_only=True,
        user=ldap_config["user"],
        auto_bind=True,
        password=ldap_config["password"],
        raise_exceptions=True,
        receive_timeout=60,
    ) as conn:
        slay(victims, conn, args.project)
        sys.exit()


if __name__ == "__main__":
    main()
