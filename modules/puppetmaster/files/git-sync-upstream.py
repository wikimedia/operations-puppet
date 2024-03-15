#!/usr/bin/python3
# Fetch new git changes from upstream repos and rebase local changes on top.
# Rebase step is done in a temporary git clone that shares objects with the
# repo being rebased. This helps avoid consumers of the clone seeing partial
# application of local changes due to non-atomic operations.
import argparse
import datetime
from enum import Enum
import logging
import pwd
import os
import shutil
import subprocess

from pathlib import Path

import requests
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

# Send all git output to stdout
# This has to be set before git is imported.
os.environ["GIT_PYTHON_TRACE"] = "full"
import git  # noqa: I100

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%SZ",
)
logging.captureWarnings(True)
logger = logging.getLogger("sync-upstream")


def deploy_puppet_code():
    """On puppet7 and later servers we need to deploy puppet code after
       updating the git repo."""
    if Path("/usr/local/bin/puppetserver-deploy-code").is_file():
        logger.info("Deploying updated puppet code")
        try:
            subprocess.check_call(['/usr/local/bin/puppetserver-deploy-code'])
            return True
        except subprocess.CalledProcessError:
            logger.error("Call to puppetserver-deploy-code failed")
            return False


class repostate(Enum):
    FAIL = 0
    NOOP = 1
    UPDATE = 2


def rebase_repo(repo_path, latest_upstream_commit, prometheus_gauge):
    """Rebase the current HEAD of the given clone on top of the given tracking
    branch of it's origin repo.

    :param repo_path: git clone to rebase
    :param latest_upstream_commit: latest upstream commit
    """
    logger.info("Rebasing repository '%s' on top of commit '%s'", repo_path, latest_upstream_commit)
    datestring = datetime.datetime.now().strftime("%Y%m%d%H%M")
    branchname = "oot-branch-%s" % datestring
    tagname = "snapshot-%s" % datestring
    tempdir = "/tmp/%s" % tagname

    repo = git.Repo(repo_path)
    assert not repo.bare

    # diff index against working copy
    if repo.index.diff(None):
        logger.error("Local diffs detected.  Commit your changes!")
        prometheus_gauge.labels(repo_path).set(0)
        return repostate.FAIL

    repo.remotes.origin.fetch()

    current_branch = repo.git.rev_parse("--abbrev-ref", "HEAD")
    latest_commit = repo.git.rev_parse(current_branch)
    latest_merged_commit = repo.git.merge_base(latest_upstream_commit, "HEAD")

    if latest_upstream_commit == latest_merged_commit:
        logger.info("Up-to-date: %s", repo_path)
        prometheus_gauge.labels(repo_path).set(1)
        return repostate.NOOP
    try:
        # Perform rebase in a temporary workdir to avoid altering the state of
        # the current workdir. Rebasing in place can lead to Puppet using
        # files after the update but before local patches are re-applied.
        #
        # This next bit is largely cribbed from
        # https://github.com/encukou/bin/blob/master/oot-rebase
        os.makedirs(tempdir)

        tmprepo = git.Repo.init(tempdir)

        # This bit of magic should prevent us from needing to create a full
        # duplicate of all the objects in repo_path.
        # See: https://git-scm.com/docs/gitrepository-layout
        alt_file = os.path.join(tempdir, ".git/objects/info/alternates")
        with open(alt_file, "w") as alternates:
            alternates.write("%s/.git/objects" % repo_path)

        # Get ready to rebase in tmprepo:  fetch from upstream, and create and
        # check out a branch 'oot-rebase' that matches the state of the main
        # repo in repo_path:
        tmprepo.git.fetch(
            "-n",
            repo_path,
            "%s:oot-rebase/%s" % (current_branch, current_branch),
            "%s:oot-rebase/upstream" % (latest_upstream_commit),
        )
        tmprepo.git.checkout("oot-rebase/%s" % current_branch)

        # And... rebase.
        tmprepo.git.rebase(
            "--stat",
            "--strategy=recursive",
            "--strategy-option=patience",
            "oot-rebase/upstream",
        )

        # Now 'oot-rebase' in tmprepo has the final state we need.  Push that
        # branch to a temporary branch ('branchname') in the main repo.
        tmprepo.git.push(
            "--force-with-lease=%s:%s" % (current_branch, latest_commit),
            repo_path,
            "oot-rebase/%s:%s" % (current_branch, branchname),
        )

        # Finally reset our original repo to this new branch and discard the
        # 'branchname' branch
        repo.git.reset("--hard", branchname)
        repo.git.branch("-D", branchname)
        shutil.rmtree(tempdir)

    except git.exc.GitCommandError:
        logger.error("Rebase failed!")
        shutil.rmtree(tempdir)
        prometheus_gauge.labels(repo_path).set(0)
        return repostate.FAIL

    # For the sake of future rollbacks, tag the repo in the state we've just
    # set up
    repo.create_tag(tagname)
    logger.info("Tagged as %s", tagname)

    logger.info("Local hacks:")
    repo.git.log("--color", "--pretty=oneline", "--abbrev-commit", "origin/HEAD..HEAD")

    prometheus_gauge.labels(repo_path).set(1)
    return repostate.UPDATE


parser = argparse.ArgumentParser(description="Sync local puppet repo with upstream")
parser.add_argument(
    "--private-only", dest="private", action="store_true", help="Only sync the /labs/private repo"
)
parser.add_argument("--base-dir", default=Path("/var/lib/git"), type=Path)
parser.add_argument("--git-user", default="root")
parser.add_argument(
    "--prometheus-file",
    dest="prometheus_file",
    required=False,
    help="Collect statistics to this prometheus-node-exporter file",
)

args = parser.parse_args()

prometheus_registry = CollectorRegistry()

gauge_last_update = Gauge(
    "puppet_sync_upstream_last_update",
    "Last Puppet upstream sync in Unix time",
    registry=prometheus_registry,
)
gauge_last_update.set_to_current_time()
gauge_is_up_to_date = Gauge(
    "puppet_sync_upstream_rebase_success",
    "Result of last attempt to rebase a given repository, "
    "1 indicates success or being up-to-date and 0 indicates failure",
    labelnames=["repository"],
    registry=prometheus_registry,
)
if args.git_user != 'root':
    # Switch to git user for git operations
    os.seteuid(pwd.getpwnam(args.git_user).pw_uid)
    old_environ = os.environ.copy()
    os.environ['USER'] = args.git_user
    os.environ['HOME'] = pwd.getpwnam(args.git_user).pw_dir


repo_changes = 0
if args.private:
    resp = requests.get("https://config-master.wikimedia.org/labsprivate-sha1.txt")
    assert resp.status_code == 200
    if rebase_repo(
        str(args.base_dir / "labs/private"),
        resp.content.decode("ascii").strip(),
        gauge_is_up_to_date
    ) == repostate.UPDATE:
        repo_changes += 1
else:
    resp = requests.get("https://config-master.wikimedia.org/puppet-sha1.txt")
    assert resp.status_code == 200
    rs = rebase_repo(
        str(args.base_dir / "operations/puppet"),
        resp.content.decode("ascii").strip(),
        gauge_is_up_to_date
    )
    if rs == repostate.UPDATE:
        repo_changes += 1
    if rs != repostate.FAIL:
        resp = requests.get("https://config-master.wikimedia.org/labsprivate-sha1.txt")
        assert resp.status_code == 200
        if rebase_repo(
            str(args.base_dir / "labs/private"),
            resp.content.decode("ascii").strip(),
            gauge_is_up_to_date
        ) == repostate.UPDATE:
            repo_changes += 1

if os.geteuid() != 0:
    # Switch back to root
    os.seteuid(0)
    os.environ = old_environ
    if repo_changes > 0:
        deploy_puppet_code()

if args.prometheus_file is not None:
    write_to_textfile(args.prometheus_file, prometheus_registry)
    logger.info("Wrote Prometheus data to %s", args.prometheus_file)
