#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Cookbook testing script

It allows testing a Gerrit patch on the cookbook repository checking out the change locally
on the cumin host where the command is run and running the cookbook with the change code instead
of the officially deployed one. It also allows to specify a given patch set (PS) to use.
The cookbook binary will be invoked with the -c/--config argument already set to point to the
custom configuration pointing to the testing checkout.

After a first checkout it is possible to modify the files in place and test it again. The script
will automatically detect that there are local changes and ask the operator what to do, as long
as the local modifications are on the same branch (hence the same PS) requested.

It should be used with caution but at least provides a standard way to test cookbook changes.
All the extra parameters are passed to the cookbook binary.

Example usage:

    # Use the latest PS of Gerrit change 12345 to make a DRY-RUN of the downtime cookbook
    test-cookbook -c 12345 --dry-run sre.hosts.dowmtime -h

    # Use a specific PS of Gerrit change 12345 to make a REAL run of the downtime cookbook
    test-cookbook -c 12345 --ps 3 sre.hosts.dowmtime -h

    # Cleanup a previously tested change
    test-cookbook --delete -c 12345

The generated files structure is as follows:

    ~/cookbooks_testing/  # Parent directory of all modified files
    ~/cookbooks_testing/config.yaml  # The configuration file that is passed to the cookbook binary
    ~/cookbooks_testing/cookbooks  # Symlink that points to the currently tested change
    ~/cookbooks_testing/cookbooks-$CHANGE_ID  # The git checkout of a given the change ID
    ~/cookbook_testing/logs  # The log directory where all cookbooks will log into

"""
import argparse
import getpass
import json
import logging
import sys
from pathlib import Path
from subprocess import CompletedProcess, Popen, run

import requests
import yaml

from wmflib.config import load_yaml_config
from wmflib.interactive import ask_confirmation


logger = logging.getLogger(__name__)
GERRIT = "https://gerrit.wikimedia.org/r"
CONFIG = Path("/etc/test-cookbook.yaml")
BASE_DIR = Path("~/cookbooks_testing").expanduser()


class CookbookTesting:
    "Class to setup and run a cookbook from a Gerrit patch."""

    logs_dir = BASE_DIR / "logs"
    cookbooks_symlink = BASE_DIR / "cookbooks"
    spicerack_config = Path("/etc/spicerack/config.yaml")
    custom_config = BASE_DIR / "config.yaml"

    def __init__(self, *, repos: list[str], change: int, patch_set: int,
                 remaining_args: list[str], no_sal: bool = False):
        """Initialize the instance and auto-detect last patch set if not set."""
        self.change = str(change)
        self.remaining_args = remaining_args
        self.cookbooks_dir = BASE_DIR / f"cookbooks-{self.change}"
        self.no_sal = no_sal

        project, latest_ps = self.get_gerrit_data()

        if project not in repos:
            raise ValueError(
                f"Change {change} is in project {project} which is not available on this host"
            )
        self.git_url = f"{GERRIT}/{project}"

        if patch_set is None:
            self.patch_set = latest_ps
        else:
            self.patch_set = str(patch_set)

    def run(self) -> int:
        """Execute the cookbook."""
        logger.info("Setting up Cookbooks change %s patch set %s for testing",
                    self.change, self.patch_set)
        BASE_DIR.mkdir(parents=True, exist_ok=True)
        self.setup_repo()
        self.setup_config()
        self.cookbooks_symlink.unlink(missing_ok=True)
        self.cookbooks_symlink.symlink_to(self.cookbooks_dir)

        command = ["sudo", "cookbook", "-c", str(self.custom_config)] + self.remaining_args
        logger.info("=" * 50)
        logger.info("Executing: %s", " ".join(command))
        logger.info("=" * 50)

        result = Popen(command, umask=0o002)
        result.wait()
        return result.returncode

    def delete(self) -> int:
        """Delete che checkout."""
        if "cookbooks_testing" not in str(self.cookbooks_dir):
            raise RuntimeError(f"Refusing to delete malformed dir {self.cookbooks_dir}")

        # Can't use shutil.rmtree because of files created by root
        # umask and sticky bit are not enough
        ask_confirmation(f"Recursively removing {self.cookbooks_dir} ?")
        run(["/usr/bin/sudo", "/usr/bin/rm", "-rf", str(self.cookbooks_dir)], check=True)
        self.cookbooks_symlink.unlink(missing_ok=True)
        return 0

    def setup_config(self) -> None:
        """Sync the config file from official spicerack and modify the path to the cookbooks."""
        config_raw = run(
            ["sudo", "/usr/bin/cat", str(self.spicerack_config)],
            capture_output=True,
            text=True,
            check=True,
        )
        config = yaml.safe_load(config_raw.stdout)
        config["cookbooks_base_dirs"] = [str(self.cookbooks_symlink)]
        config["logs_base_dir"] = str(self.logs_dir)

        if self.no_sal:
            logger.warning("Not logging to SAL!")
            del config["tcpircbot_host"]
            del config["tcpircbot_port"]

        self.custom_config.write_text(yaml.dump(config))

    def get_gerrit_data(self) -> tuple[str, str]:
        """Find the repository name and the latest patch set for the given change."""
        raw_response = requests.get(f"{GERRIT}/changes/?q={self.change}&o=CURRENT_REVISION")
        payload = "".join(raw_response.text.splitlines()[1:])
        response = json.loads(payload)[0]
        project = response["project"]
        revision = response["current_revision"]
        patch_set = response["revisions"][revision]["_number"]
        logger.info(
            "Change exists in project %s with latest patch set being %s",
            project, patch_set
        )
        return project, patch_set

    def run_git(self, args, **run_kwargs) -> CompletedProcess:
        """Run a git command logging the parameters."""
        command = ["/usr/bin/git"]
        if args[0] != "clone":
            command += ["-C", str(self.cookbooks_dir)]

        command += args
        logger.info("Executing command %s", " ".join(command))
        return run(command, **run_kwargs)

    def setup_repo(self) -> None:
        """Setup the repository."""
        if not self.cookbooks_dir.exists():
            logger.info("Checkout of change %s not found, cloning the repo", self.change)
            self.run_git(
                ["clone", "--depth", "10", self.git_url, str(self.cookbooks_dir)], check=True)

        status = self.run_git(
            ["status", "--porcelain"], capture_output=True, text=True, check=True)

        branch_name = f"change-{self.change}-{self.patch_set}"
        if status.stdout:
            logger.info("Found local modifications:\n%s", status.stdout)
            current_branch = self.run_git(
                ["branch", "--show-current"], capture_output=True, text=True, check=True)
            current_branch_name = current_branch.stdout.strip()
            if current_branch_name != branch_name:
                raise RuntimeError(f"Found local modifications on branch {current_branch_name} but "
                                   f"branch {branch_name} was requested")

            ask_confirmation("Do you want to continue the test with the local modifications above?")
            logger.info("Skipping the checkout with local modications in place")
        else:
            logger.info("No local modification found, fetching change from Gerrit")
            ref = f"refs/changes/{self.change[-2:]}/{self.change}/{self.patch_set}"
            self.run_git(["fetch", self.git_url, ref], check=True)
            branch_exists = self.run_git(["rev-parse", "--verify", branch_name], check=False)

            if branch_exists.returncode != 0:
                logger.info("Checking out the patch set into branch %s", branch_name)
                self.run_git(["checkout", "-b", branch_name, "FETCH_HEAD"], check=True)
            else:
                logger.info("Switching to already existing branch %s", branch_name)
                self.run_git(["checkout", branch_name], check=True)


def parse_args() -> tuple[argparse.Namespace, list[str]]:
    """Parse the command line arguments."""
    parser = argparse.ArgumentParser(
        description=__doc__, add_help=False, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(  # Not using required=True to allow to use -h/--help without -c/--change
        "-c",
        "--change",
        type=int,
        help="The Gerrit change ID to fetch.")
    parser.add_argument(
        "--ps",
        type=int,
        help="The optional patch set to fetch. If not specified the last one will be fetched.")
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Delete any existing environment for the given change.")
    parser.add_argument(
        "--no-sal-logging",
        action="store_true",
        help="Do not log to SAL. Use with CAUTION!")
    parser.add_argument(
        "-h",
        "--help",
        action="store_true",
        help="show this help message and exit")

    args, remaining_args = parser.parse_known_args()

    if args.help:
        if remaining_args:  # Re-inject the help option in the remaining args
            remaining_args.append("--help")
        else:  # Print this wrapper help message and exit
            parser.exit(message=parser.format_help())

    if not args.change:
        parser.error("the following arguments are required: -c/--change")

    return args, remaining_args


def main() -> int:
    """Execute the script."""
    logging.basicConfig(level=logging.INFO)
    args, remaining_args = parse_args()
    config = load_yaml_config(CONFIG)
    cookbook_testing = CookbookTesting(
        repos=config["cookbook_repos"],
        change=args.change,
        patch_set=args.ps,
        remaining_args=remaining_args,
        no_sal=args.no_sal_logging)

    if args.delete:
        return cookbook_testing.delete()

    return cookbook_testing.run()


if __name__ == "__main__":
    if getpass.getuser() == "root":
        print("This script must be run as your own user, without sudo.", file=sys.stderr)
        sys.exit(1)

    sys.exit(main())
