#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import re
import os
import json
import logging
import zipfile
import argparse
import tempfile

from typing import Union
from gitlab.v4.objects import (
    jobs as jobs_type,
    projects as projects_type,
    branches as branches_types,
)
from gitlab.base import RESTObject  # Required for typing

import gitlab

JobsType = Union[jobs_type.ProjectJob, RESTObject]
ProjectsType = Union[projects_type.Project, RESTObject]
ProtectedBranchesType = Union[branches_types.ProjectProtectedBranch, RESTObject]

TRUSTED_PROJECT_PATH = "repos/releng/gitlab-trusted-runner"
TRUSTED_PROJECT_FILE = "projects.json"


class GitlabPackagePuller:
    """Pulls packages from the Gitlab under certain conditions, and prepares them for import
    into reprepro. This requires a read-api scoped access token for Gitlab. Tokens for general
    use should be a group access token, with a "Guest" role, and the "read_api" scope. Tokens
    can be created here: https://gitlab.wikimedia.org/groups/repos/-/settings/access_tokens
    with Admin Mode signed in
    """
    def __init__(self, args: argparse.Namespace) -> None:
        logging.basicConfig(level=args.log_level.upper())

        self.gitlab_host = args.host
        self.client: gitlab.Gitlab = gitlab.Gitlab(
            f"https://{self.gitlab_host}", private_token=self.gitlab_token()
        )

        self.trusted_project_paths = self.get_project_paths_from_trusted_list()
        self.allow_untrusted_projects = args.allow_untrusted_projects
        if args.project_paths:
            self.project_paths = self.check_project_paths_in_trusted_list(
                args.project_paths
            )
        else:
            self.project_paths = self.trusted_project_paths

        if len(self.project_paths) <= 0:
            raise RuntimeError("You must provide some projects to fetch artifacts from")

        self.artifact_creation_job_pattern = args.job
        self.destination_dir = args.destination_dir
        self.allowed_branches = args.branches
        self.number_of_jobs = args.number_of_jobs

    def gitlab_token(self) -> str | None:
        """Gets the gitlab token from either the environment variable, or the secrets file
        in /etc/gitlab-puller-auth. A new token can be created as a group access token with
        the details in the top comment
        """
        env_token = os.environ.get("GITLAB_TOKEN")
        if env_token:
            return env_token

        try:
            with open("/etc/gitlab-puller-auth", encoding="utf-8") as secrets_file:
                return secrets_file.read().strip()
        except FileNotFoundError:
            logging.exception(
                "Couldn't find GITLAB_TOKEN env variable set, or /etc/gitlab-puller-auth for token"
            )

    def check_project_paths_in_trusted_list(
        self,
        project_paths: str | list[str],
    ) -> list[str]:
        """Checks the list of trusted_project_paths against the project paths given, and raises an
        exception if any are found"""
        if isinstance(project_paths, str):
            project_paths = [project_paths]

        untrusted_paths = list(set(project_paths) - set(self.trusted_project_paths))
        if len(untrusted_paths) != 0 and not self.allow_untrusted_projects:
            raise RuntimeError(
                f"Project paths {untrusted_paths} not in trusted projects list"
            )

        return project_paths

    def get_project_paths_from_trusted_list(self) -> list[str]:
        """Downloads the trusted projects json file from gitlab and fetches project paths that are
        allowed run on trusted runners"""

        logging.debug(
            "Downloading JSON trusted projects lists from project %s file %s",
            TRUSTED_PROJECT_PATH,
            TRUSTED_PROJECT_FILE,
        )

        trusted_project = self.client.projects.get(TRUSTED_PROJECT_PATH)
        response = trusted_project.files.raw(file_path=TRUSTED_PROJECT_FILE, ref="main")
        json_content = json.loads(response)

        keys = json_content.keys()
        logging.debug(
            "Found %d trusted project paths from trusted project list", len(keys)
        )

        return keys

    def fetch_packages_for_project(self) -> None:
        """Fetches packages for each project given as a parameter to the class"""
        for project_path in self.project_paths:
            logging.debug("Fetching packages for %s", project_path)
            project = self.client.projects.get(project_path)
            # get the last 20 jobs only because this script runs every 5 minutes
            # default when get_all=False is used
            jobs = project.jobs.list(get_all=False, per_page=self.number_of_jobs)
            protected_branches = [b.name for b in project.protectedbranches.list()]
            logging.info("Found %d jobs for project %s", len(jobs), project.name)

            for job in jobs:
                if self.can_download_package(job, protected_branches):
                    self.download_debs(job, project)
                else:
                    logging.info(
                        "No packages meeting criteria for job %s in project %s found",
                        job.name,
                        project.name,
                    )

    def can_download_package(
        self, job: JobsType, protected_branches: list[ProtectedBranchesType]
    ) -> bool:
        """Checks to see if a job meets the criteria for downloading packages
        - Is the job correct?
        - Is the branch correct?
        - Is the branch protected?
        """
        job_str = f"{job.name}/{job.id}"  # Shortcut for logging the identifier

        if not re.match(self.artifact_creation_job_pattern, job.name):
            logging.debug(
                "Rejected %s for not being an artifact creation job %s",
                job_str,
                self.artifact_creation_job_pattern,
            )
            return False
        if not job.status == "success":
            logging.debug("Rejected %s because its status was not success", job_str)
            return False
        if not any(re.match(pattern, job.ref) for pattern in self.allowed_branches):
            logging.debug(
                "Rejected %s because its branch is not an allowed branch (%s)",
                job_str,
                job.ref,
            )
            return False
        if job.ref not in protected_branches:
            logging.debug("Rejected %s for not being in a protected branch", job_str)
            return False
        return True

    def download_debs(self, job: JobsType, project: ProjectsType) -> None:
        """Downloads artifacts related to a given job, extracts the WMF_BUILD_DIR from a zipfile,
        and moves to the destination dir
        """
        with tempfile.TemporaryDirectory() as tmpdir:
            zipfile_path = os.path.join(
                tmpdir, f"{project.name}_{job.id}_artifacts.zip"
            )
            job_artifact_path = os.path.join(
                self.destination_dir, f"{project.name}_{job.id}"
            )
            if os.path.exists(job_artifact_path):
                logging.info(
                    "Already downloaded artifact for project %s and job_id %s",
                    project.name,
                    job.id,
                )
                return

            with open(zipfile_path, "wb") as f:
                logging.debug("Downloading artifact and writing %s", zipfile_path)
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

            os.mkdir(job_artifact_path)
            with zipfile.ZipFile(zipfile_path) as zf:
                logging.debug(
                    "Extracting zipfile %s to %s", zipfile_path, job_artifact_path
                )
                zf.extractall(path=job_artifact_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Gitlab package puller", description="Fetches packages from GitLab CI"
    )
    parser.add_argument(
        "-D",
        "--destination-dir",
        default="/srv/incoming-packages",
        help="Directory to save downloaded packages to",
    )
    parser.add_argument(
        "--host",
        default="gitlab.wikimedia.org",
        help="Gitlab host",
    )
    parser.add_argument(
        "-j",
        "--job",
        default="^build_ci_deb*",
        help="Pattern to match jobs will generate packages to fetch",
    )
    parser.add_argument(
        "-b",
        "--branches",
        default=[".+-wikimedia", "main"],
        nargs="*",
        help="Regex to match branches allowed to generate artifacts. Can be specified "
        "multiple times",
    )
    parser.add_argument(
        "--allow-untrusted-projects",
        action="store_true",
        help="Allows project paths that aren't in the list of jobs run on trusted runners",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        default="warning",
        help="Log level (debug, info, warning, error, critical)",
    )
    parser.add_argument(
        "project_paths",
        metavar="PATH",
        type=str,
        nargs="?",
        help="List of project paths (e.g., '/repos/sre/miscweb') to fetch packages from. This is "
        "usually from the list of projects specified in the trusted runner list.",
    )
    parser.add_argument(
        "-n",
        "--number-of-jobs",
        type=int,
        nargs="?",
        default=50,
        help="Number of CI jobs to check for new packages",
    )

    g = GitlabPackagePuller(parser.parse_args())
    g.fetch_packages_for_project()
