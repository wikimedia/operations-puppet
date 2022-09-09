#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-
"""
pcc -- shell helper for the Puppet catalog compiler

Usage: pcc [--api-token TOKEN] [--username USERNAME] CHANGE NODES

Required arguments:
CHANGE                 Gerrit change number, change ID, or Git commit.
                        (May be 'latest' or 'HEAD' for the last commit.)
NODES                  Comma-separated list of nodes. '.eqiad.wmnet'
                        will be appended for any unqualified host names.

Optional arguments:
--api-token TOKEN      Jenkins API token. Defaults to JENKINS_API_TOKEN.
--username USERNAME    Jenkins user name. Defaults to JENKINS_USERNAME.

Examples:
$ pcc latest mw1031,mw1032

You can get your API token by clicking on your name in Jenkins and then
clicking on 'configure'.

pcc requires the jenkinsapi python module:
https://pypi.python.org/pypi/jenkinsapi (try `pip install jenkinsapi`)

Copyright 2014 Ori Livneh <ori@wikimedia.org>
Licensed under the Apache license.
"""

import json
import logging
import os
import re
import shlex
from argparse import ArgumentParser, RawDescriptionHelpFormatter
from subprocess import CalledProcessError, check_output, run
from time import sleep
from urllib.request import urlopen

from urllib3.exceptions import MaxRetryError

try:
    import jenkinsapi
except ImportError as error:
    raise SystemExit(
        """You need the `jenkinsapi` module. Try `pip install jenkinsapi`
or `sudo apt-get install python3-jenkinsapi` (if available on your distro)."""
    ) from error


LOG = logging.getLogger("PCC")
JENKINS_URL = "https://integration.wikimedia.org/ci/"
GERRIT_PORT = 29418
GERRIT_HOST = "gerrit.wikimedia.org"
GERRIT_BASE = "https://{}/r/changes".format(GERRIT_HOST)


red, green, yellow, blue, white = [("\x1b[9%sm{}\x1b[0m" % n).format for n in (1, 2, 3, 4, 7)]


def format_console_output(text):
    """Colorize log output."""
    newlines = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line[0] != "[":
            continue
        if "INFO" in line:
            newlines.append(blue(line))
        elif "WARNING" in line:
            newlines.append(yellow(line))
        elif "ERROR" in line or "CRITICAL" in line:
            newlines.append(red(line))
        else:
            newlines.append(line)
    return "\n".join(newlines)


def get_change_id(change="HEAD"):
    """Get the change ID of a commit (defaults to HEAD).

    Arguments:
        change (str): either HEAD or sha1 git reference

    Returns:
        (str): the gerrit change id
    """
    commit_message = check_output(["git", "log", "-1", change], universal_newlines=True)
    match = re.search("(?<=Change-Id: )(?P<id>.*)", commit_message)
    return match.group("id")


def get_gerrit_blob(change):
    """Return a json blob from a gerrit API endpoint

    Arguments:
        change (str): Either a change id or a change number

    Returns
        dict: A dictionary representing the json blob returned by gerrit

    """
    url = "{}/?q={}&o=CURRENT_REVISION&o=CURRENT_COMMIT&o=COMMIT_FOOTERS".format(
        GERRIT_BASE, change
    )
    LOG.debug("fetch gerrit blob: %s", url)
    req = urlopen(url)
    # To prevent against Cross Site Script Inclusion (XSSI) attacks, the JSON response
    # body starts with a magic prefix line: `)]}'` that must be stripped before feeding the
    # rest of the response body to a JSON
    # https://gerrit-review.googlesource.com/Documentation/rest-api.html#output
    return json.loads(req.read().split(b"\n", 1)[1])


def get_change(change):
    """Resolve a change ID to a change number via a Gerrit API lookup.

    Arguments:
        change (str): either a gerrit change number or the change id

    Returns:
        (dict): change = {'number': (int), 'patchset': (int), 'id': (str)}
    """
    res = get_gerrit_blob(change)
    LOG.debug("recived: %s", type(res))
    for found in res:
        if change in [found["change_id"], str(found["_number"])]:
            return {
                "number": found["_number"],
                "patchset": found["revisions"][found["current_revision"]]["_number"],
                "id": found["change_id"],
            }
    return None


def parse_change_arg(change):
    """Resolve a Gerrit change

    Arguments
        change (str): the change ID or change number to test.  To test HEAD pass last or latest

    Returns
        int: the change number or -1 to indicate a faliure

    """
    if change.isdigit() or change.startswith("I"):
        return get_change(change)
    if change in ["last", "latest"]:
        change = "HEAD"
    return get_change(get_change_id(change))


def parse_nodes(string_list, default_suffix=".eqiad.wmnet"):
    """If nodes contains ':' as the second character then the string_list
    is returned unmodified assuming it is a host variable override.
    https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Host_variable_override

    Otherwise qualify any unqualified nodes in a comma-separated list by
    appending a default domain suffix."""
    if string_list.startswith(("P:", "C:", "O:", "re:", "parse_commit", "cumin:")):
        return string_list
    return ",".join(
        node if "." in node else node + default_suffix for node in string_list.split(",")
    )


class ParseCommitException(Exception):
    """Raised when no hosts found"""


def parse_commit(change):
    """Parse a commit message looking for a Hosts: lines

    Arguments:
        change (str): the change ID to use

    Returns:
        str: The lists of hosts or an empty string

    """
    hosts = []
    res = get_gerrit_blob(change)

    for result in res:
        if result["change_id"] != change:
            continue
        commit = result["revisions"][result["current_revision"]]["commit_with_footers"]
        break
    else:
        raise ParseCommitException("No Hosts found")

    for line in commit.splitlines():
        if line.startswith("Hosts:"):
            # Strip any comments after '#'
            if "#" in line:
                line = line.split("#", 1)[0]
            hosts.append(line.split(":", 1)[1].strip())

    return ",".join(hosts)


def get_args():
    """Parse Arguments"""

    parser = ArgumentParser(description=__doc__, formatter_class=RawDescriptionHelpFormatter)
    parser.add_argument(
        "change",
        default="last",
        nargs='?',
        help="The change number or change ID to test. " "Alternatively last or latest to test head",
    )
    parser.add_argument(
        "nodes",
        type=parse_nodes,
        default="parse_commit",
        nargs='?',
        help="Either a Comma-separated list of nodes or a Host Variable Override. "
        "Alternatively use `parse_commit` to parse",
    )
    parser.add_argument(
        "--api-token",
        default=os.environ.get("JENKINS_API_TOKEN"),
        help="Jenkins API token. Defaults to JENKINS_API_TOKEN.",
    )
    parser.add_argument(
        "--username",
        default=os.environ.get("JENKINS_USERNAME"),
        help="Jenkins user name. Defaults to JENKINS_USERNAME.",
    )
    parser.add_argument(
        "-F",
        "--post-fail",
        action="store_true",
        help="Post PCC report to gerrit on faliure and down vote verify status",
    )
    parser.add_argument(
        "-C",
        "--post-crash",
        action="store_true",
        help="Post PCC report to gerrit when polling fails",
    )
    parser.add_argument(
        "-N", "--no-post-success", action="store_true", help="Do not post PCC report to gerrit"
    )
    parser.add_argument(
        "-f",
        "--fail-fast",
        action="store_true",
        help="If passed, will stop the compilation when the first failure happens.",
    )
    parser.add_argument("-v", "--verbose", action="count")
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {None: logging.ERROR, 1: logging.WARN, 2: logging.INFO, 3: logging.DEBUG}.get(
        args_level, logging.DEBUG
    )


def post_comment(change, comment, verify=None):
    """Post a comment to the specificed gerrit change

    Arguments:
        change (dict): the gerrit change dict
        comment (str): the comment to post
        verify (bool,None): indicate how to vote on the verified status
                            None: no vote
                            True: +1
                            False: -1
    """

    # pylint: disable=line-too-long
    verified = (
        " --verified {}".format({True: 1, False: -1}.get(verify))
        if isinstance(verify, bool)
        else ""
    )  # noqa: E501
    command = 'ssh -p {port} {host} gerrit review {number},{patchset}{verified} -m \\"{comment}\\"'.format(  # noqa: E501
        port=GERRIT_PORT,
        host=GERRIT_HOST,
        number=change["number"],
        patchset=change["patchset"],
        comment=comment,
        verified=verified,
    )
    # pylint: enable=line-too-long
    LOG.debug("post comment: %s", command)
    try:
        run(shlex.split(command), check=True)
    except CalledProcessError as error:
        LOG.error("failed to post comment: %s\n%s", comment, error)


def main():  # pylint: disable=too-many-locals
    """Main Entry Point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    urllib_verbose = args.verbose - 1 if args.verbose else None
    logging.getLogger("urllib3").setLevel(get_log_level(urllib_verbose))
    change = parse_change_arg(args.change)
    if change is None or not all(change.values()):
        LOG.error("Unable to parse change: %s", args.change)
        return 1
    LOG.debug("Change ID: %s", change["id"])
    LOG.debug("Change number: %s,%s", change["number"], change["patchset"])

    if not args.api_token or not args.username:
        LOG.error(
            "You must either provide the --api-token and --username options"
            " or define JENKINS_API_TOKEN and JENKINS_USERNAME in your env."
        )
        return 1

    jenkins = jenkinsapi.jenkins.Jenkins(
        baseurl=JENKINS_URL,
        username=args.username.encode('utf-8'),
        password=args.api_token,
        # sometimes jenkins is quite slow to reply
        timeout=30,
    )

    print(
        yellow(
            "Compiling {change_number} on node(s) {nodes}...".format(
                change_number=change["number"], nodes=args.nodes
            )
        )
    )
    try:
        nodes = parse_commit(change["id"]) if args.nodes == "parse_commit" else args.nodes
    except KeyError as error:
        print("Unable to find commit message: {}".format(error))
        return 1
    except ParseCommitException as error:
        print(error)
        return 1

    if not nodes:
        print(
            yellow(
                "No nodes given on the command line, and no Hosts: footer in the commit message. "
                "PCC will compile your change for one of every type of node listed in site.pp. "
                "This is a good way to test a change with a potentially wide impact, but if you're "
                "doing it by accident, it consumes quite a lot of resources."
            )
        )
        confirm = input(yellow('Continue? (y/n) '))
        if not confirm.lower().startswith('y'):
            return 1

    job = jenkins.get_job("operations-puppet-catalog-compiler")
    build_params = {
        "GERRIT_CHANGE_NUMBER": str(change["number"]),
        "LIST_OF_NODES": nodes,
        "COMPILER_MODE": "change",
        "FAIL_FAST": "YES" if args.fail_fast else "",
    }

    invocation = job.invoke(build_params=build_params)

    try:
        invocation.block_until_building()
    except AttributeError:
        invocation.block(until="not_queued")

    build = invocation.get_build()
    console_url = build.baseurl + "/console"

    print("Your build URL is %s" % white(build.baseurl))

    running = True
    output = ""
    try:
        while running:
            sleep(1)
            running = invocation.is_running()
            new_output = build.get_console().rstrip("\n")
            console_output = format_console_output(new_output[len(output) :]).strip()  # noqa: E203
            if console_output:
                print(console_output)
            output = new_output
    except MaxRetryError as error:
        print(
            yellow(
                (
                    "Warning: polling jenkins failed please check PCC manually:\n\tError: {}\n{}"
                ).format(error, build.baseurl)
            )
        )
        if args.post_crash:
            post_comment(change, "PCC Check manually: {}".format(build.baseurl))

    node_status = {}
    node_status_matcher = re.compile(r"(?P<count>\d+)\s+(?P<mode>(?:DIFF|NOOP|FAIL|ERROR))")
    for match in node_status_matcher.finditer(output):
        # as the information we are intrested is at the end we only care about the last matches
        node_status[match["mode"]] = match["count"]
    node_status_str = " ".join(["{} {}".format(k, v) for k, v in node_status.items()])

    # Puppet's exit code is not always meaningful, so we grep the output
    # for failures before declaring victory.
    if "Run finished" in output and not re.search(r"[1-9]\d* (ERROR|FAIL)", output):
        print(green("SUCCESS ({})".format(node_status_str)))
        if not args.no_post_success:
            post_comment(change, "PCC SUCCESS ({}): {}".format(node_status_str, console_url), True)
        return 0
    print(red("FAIL ({})".format(node_status_str)))
    if args.post_fail:
        post_comment(change, "PCC FAIL ({}): {}".format(node_status_str, console_url), False)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
