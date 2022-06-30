#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# (C) 2020 by Arturo Borrero Gonzalez <aborrero@wikimedia.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#

# Using python3 mainly because arg parsing. Otherwise bash should be more
# straight forward, given this is simply chaining ssh commands.
#
# Read the docs here:
# https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Packaging

import os
import argparse
import subprocess
import random
import string


class Context:
    def __init__(self):
        self.args = None
        self.deb_list = []
        self.random_dir = "/tmp/wmcs-package-build-{}".format(self.randomword(5))
        self.git_repo_dir = ""

    def randomword(self, length):
        letters = string.ascii_lowercase
        return "".join(random.choice(letters) for i in range(length))


# our global data, to easily share stuff between different stages
ctx = Context()


def msg_dry(msg):
    print("DRY: {}: {}".format(os.path.basename(__file__), msg))


def msg_info(msg):
    print("INFO: {}: {}".format(os.path.basename(__file__), msg))


def msg_error(msg):
    print("ERROR: {}: {}".format(os.path.basename(__file__), msg))


def do_exit(msg):
    msg_error("Ending script: {}".format(msg))
    msg_info("no further cleanups are done, so you can investigate by hand")
    exit(1)


def parse_args():
    description = "Utility to build and upload a .deb package to aptly"
    parser = argparse.ArgumentParser(description=description)
    help = """git repository URL with the source pkg. This script will do a
           fresh git clone of that repo. Typical value is something like:
           https://gerrit.wikimedia.org/r/operations/software/tools-webservice
           """
    parser.add_argument("--git-repo", required=True, help=help)
    help = """git branch to use to build the package from.
           Defaults to "%(default)s"
           """
    parser.add_argument("--git-branch", default="master", help=help)
    help = """target distribution when building the package with sbuild.
           Defaults to "%(default)s"
           """
    parser.add_argument("--build-dist", default="buster", help=help)
    help = """package build host. Typically a VM in CloudVPS with
           role::wmcs::toolforge::package_builder.
           Defaults to "%(default)s"
           """
    parser.add_argument(
        "--build-host",
        default="tools-package-builder-04.tools.eqiad1.wikimedia.cloud",
        help=help,
    )
    help = """target distribution in aptly. The resulting deb package will be
           uploaded to this distribution and then the repository will be
           published. Can be specified multiple times for multiple target
           distributions. If this argument is not provided, no aptly operations
           will be done. Example: -a buster-tools -a buster-toolsbeta
           """
    parser.add_argument("-a", "--aptly-dist", action="append", help=help)
    help = """aptly server host. Typically a VM in CloudVPS with
           role::wmcs::toolforge::services.
           Defaults to "%(default)s"
           """
    parser.add_argument(
        "--aptly-host", default="tools-services-05.tools.eqiad1.wikimedia.cloud", help=help
    )
    help = """If this option is present, this script won't backup aptly data
           over NFS
           """
    parser.add_argument("-b", "--no-backup", action="store_true", help=help)
    help = """Dry run: only show what this script would do, but don't do it for
           real
           """
    parser.add_argument("-d", "--dry-run", action="store_true", help=help)

    return parser.parse_args()


def ssh(host, cmd, capture_output=False):
    ssh_cmd = 'ssh {} "{}"'.format(host, cmd)
    if ctx.args.dry_run:
        msg_dry(ssh_cmd)
        return

    r = subprocess.run(ssh_cmd, shell=True, capture_output=capture_output)
    if r.returncode != 0:
        do_exit("failed SSH command: {}".format(ssh_cmd))

    if r.stdout:
        return r.stdout.decode("utf-8")


def ssh_copy(srchost, dsthost, filepath):
    ssh_cmd = 'ssh {} "cat {}" | ssh {} "cat > {}"'.format(
        srchost, filepath, dsthost, filepath
    )
    if ctx.args.dry_run:
        msg_dry(ssh_cmd)
        return

    r = subprocess.run(ssh_cmd, shell=True)
    if r.returncode != 0:
        do_exit("failed SSH copy command: {}".format(ssh_cmd))


def stage_git():
    # mkdir random dir
    msg_info("creating build dir {} in {}".format(ctx.random_dir, ctx.args.build_host))
    ssh(ctx.args.build_host, "mkdir {}".format(ctx.random_dir))
    # clone repo
    clone_cmd = "cd {} ; git clone {}".format(ctx.random_dir, ctx.args.git_repo)
    ssh(ctx.args.build_host, clone_cmd)
    # checkout branch
    branch_cmd = "cd {} ; git checkout {}".format(ctx.git_repo_dir, ctx.args.git_branch)
    ssh(ctx.args.build_host, branch_cmd)


def stage_sbuild():
    # simple sbuild. Well, some options were enabled to ensure a smooth run in
    # a non interactive session

    # TODO: using sudo here because T273942, but it isn't derisable and it shouldn't be neccesary
    sbuild_cmd = "cd {} ; sudo sbuild -v -A -d {} --no-clean-source".format(
        ctx.git_repo_dir, ctx.args.build_dist
    )
    ssh(ctx.args.build_host, sbuild_cmd)


def stage_pkg_copy():
    if not ctx.args.aptly_dist or len(ctx.args.aptly_dist) == 0:
        msg_info("Not copying .deb files because --aptly-dist was not set")
        return

    # discover .deb files
    ls_cmd = "cd {} ; ls *.deb".format(ctx.random_dir)
    ls_output = ssh(ctx.args.build_host, ls_cmd, True)
    if not ls_output and ctx.args.dry_run:
        ls_output = "dryexample1.deb\ndryexample2.deb\n"

    for ls_line in ls_output.split("\n"):
        if ls_line == "":
            continue
        ctx.deb_list.append(ls_line)
        msg_info("Detected .deb file: {}/{}".format(ctx.random_dir, ls_line))

    # create temp dir in aplty host
    msg_info("creating temp dir {} in {}".format(ctx.random_dir, ctx.args.aptly_host))
    ssh(ctx.args.aptly_host, "mkdir {}".format(ctx.random_dir))

    # copy deb files from the build host to the aptly host
    for deb_file in ctx.deb_list:
        file_path = "{}/{}".format(ctx.random_dir, deb_file)
        ssh_copy(ctx.args.build_host, ctx.args.aptly_host, file_path)


def stage_aptly():
    if not ctx.args.aptly_dist or len(ctx.args.aptly_dist) == 0:
        msg_info("Not running aptly stage because --aptly-dist was not set")
        return

    # repo add:
    # sudo aptly repo add stretch-tools jobutils_${VERSION}_all.deb
    # repo publish:
    # sudo aptly publish --skip-signing update stretch-tools
    for repo in ctx.args.aptly_dist:
        for deb_file in ctx.deb_list:
            file_path = "{}/{}".format(ctx.random_dir, deb_file)
            cmd = "sudo aptly repo add {} {}".format(repo, file_path)
            ssh(ctx.args.aptly_host, cmd)

        cmd = "sudo aptly publish --skip-signing update {}".format(repo)
        ssh(ctx.args.aptly_host, cmd)


def stage_backup():
    if not ctx.args.aptly_dist or len(ctx.args.aptly_dist) == 0:
        msg_info("Not running backup stage because --aptly-dist was not set")
        return
    if ctx.args.no_backup:
        return

    # the $INSTANCEPROJECT var is not available for this remote SSH session :-/
    # so harcode tools.admin instead.
    opts = '--chmod 440 --chown root:tools.admin -ilrt'
    dirs = '/srv/packages/ /data/project/.system/aptly/\$(hostname -f)/'  # noqa: W605

    cmd = "sudo rsync {} {}".format(opts, dirs)
    ssh(ctx.args.aptly_host, cmd)


def stage_cleanup():
    cmd = "rm -r {}".format(ctx.random_dir)
    ssh(ctx.args.build_host, cmd)

    if not ctx.args.aptly_dist or len(ctx.args.aptly_dist) == 0:
        return

    ssh(ctx.args.aptly_host, cmd)


def main():
    global ctx
    args = parse_args()
    ctx.args = args
    ctx.git_repo_dir = "{}/{}".format(ctx.random_dir, args.git_repo.split("/")[-1])

    stage_git()
    stage_sbuild()
    stage_pkg_copy()
    stage_aptly()
    stage_backup()
    stage_cleanup()


if __name__ == "__main__":
    main()
