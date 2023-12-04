#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import re
import os
import glob
import shutil
import logging
import zipfile
import argparse
import tempfile

from typing import Union
from gitlab.v4.objects import jobs as jobs_type
from gitlab.base import RESTObject  # Required for typing

import gitlab

JobsType = Union[jobs_type.ProjectJob, RESTObject]


class GitlabPackagePuller:
    def __init__(self, args: argparse.Namespace) -> None:
        if len(args.project_ids) <= 0:
            raise RuntimeError("You must provide some projects to fetch artifacts from")

        self.client: gitlab.Gitlab = gitlab.Gitlab(
            args.host, private_token=os.environ["GITLAB_TOKEN"]
        )
        self.project_ids = args.project_ids
        self.artifact_creation_job = args.job
        self.destination_dir = args.destination_dir
        self.dry_run = args.dry_run
        self.allowed_branches = args.branches

    def fetch_packages_for_project(self) -> None:
        """Fetches packages for each project given as a parameter to the class"""
        for project_id in self.project_ids:
            project = self.client.projects.get(project_id)
            jobs = project.jobs.list()
            logging.info("Found %d jobs for project %s", len(jobs), project.name)

            for job in jobs:
                if self.can_download_package(job):
                    self.download_debs(job)
                else:
                    logging.info(
                        "No packages meeting criteria for job %s in project %s found",
                        job.name,
                        project.name,
                    )

    def can_download_package(self, job: JobsType) -> bool:
        """Checks to see if a job meets the criteria for downloading packages
        - Is the job correct?
        - Is the branch correct?
        """
        if job.name != self.artifact_creation_job:
            return False
        if not job.status == "success":
            return False
        if not any(re.match(pattern, job.ref) for pattern in self.allowed_branches):
            return False

        return True

    def download_debs(self, job: JobsType) -> None:
        """Downloads artifacts related to a given job, extracts the debs from a zipfile,
        and moves to the destination dir
        """
        with tempfile.TemporaryDirectory() as tmpdir:
            zipfile_path = os.path.join(tmpdir, "artifacts.zip")
            with open(zipfile_path, "wb") as f:
                print(f"Downloading artifact and writing {zipfile_path}")
                try:
                    job.artifacts(streamed=True, action=f.write)
                except (
                    gitlab.exceptions.GitlabHttpError,
                    gitlab.exceptions.GitlabGetError,
                ):
                    # This is logged as info, because some artifacts are expected
                    # to be cleaned up after a while
                    logging.info("Artifacts do not exist in job %s", job.id)
                    return

            with zipfile.ZipFile(zipfile_path) as zf:
                print(f"Extracting zipfile {zipfile_path}")
                zf.extractall(path=tmpdir)

            debfiles = glob.glob("**/*.deb", root_dir=tmpdir, recursive=True)

            for debfile in debfiles:
                dest_debfile = os.path.join(
                    self.destination_dir, debfile.split("/")[-1]
                )
                if os.path.exists(dest_debfile):
                    logging.info(
                        "The package file %s already exists, and won't be overwritten",
                        dest_debfile,
                    )
                elif not self.dry_run:
                    logging.info("Moving %s to %s", debfile, dest_debfile)
                    shutil.move(os.path.join(tmpdir, debfile), dest_debfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Gitlab package puller", description="Fetches packages from GitLab CI"
    )
    parser.add_argument("-d", "--dry-run", action="store_true")
    parser.add_argument(
        "-D",
        "--destination-dir",
        default="/srv/incoming-packages",
        help="Directory to save downloaded packages to",
    )
    parser.add_argument(
        "--host",
        default="https://gitlab.wikimedia.org",
        help="Gitlab host",
    )
    parser.add_argument(
        "-j",
        "--job",
        default="build_ci_deb",
        help="CI Job name that will generate packages to fetch",
    )
    parser.add_argument(
        "-b",
        "--branches",
        default=[".+-wikimedia"],
        nargs="*",
        help="Regex to match branches allowed to generate artifacts. Can be specified "
        "multiple times",
    )
    parser.add_argument(
        "project_ids",
        metavar="ID",
        type=int,
        nargs="+",
        help="List of project IDs to fetch packages from. This is usually from the list of "
        "projects specified in the trusted runner list.",
    )

    g = GitlabPackagePuller(parser.parse_args())
    g.fetch_packages_for_project()
