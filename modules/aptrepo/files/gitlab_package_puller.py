#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import re
import os
import glob
import json
import shutil
import logging
import zipfile
import argparse
import tempfile
import subprocess
import time

from typing import Union
from gitlab.v4.objects import (
    jobs as jobs_type,
    projects as projects_type,
    branches as branches_types,
)
from gitlab.base import RESTObject  # Required for typing

import gitlab
import gitlab.exceptions

JobsType = Union[jobs_type.ProjectJob, RESTObject]
ProjectsType = Union[projects_type.Project, RESTObject]
ProtectedBranchesType = Union[branches_types.ProjectProtectedBranch, RESTObject]

TRUSTED_PROJECT_PATH = "repos/releng/gitlab-trusted-runner"
TRUSTED_PROJECT_FILE = "projects.json"
APT_STAGING_PATH = "/srv/aptrepo/wikimedia-staging"

LOG = logging.getLogger("gitlab_package_puller")


class GitlabPackagePuller:
    """Pulls packages from the Gitlab under certain conditions, and prepares them for import
    into reprepro. This requires a read-api scoped access token for Gitlab. Tokens for general
    use should be a group access token, with a "Guest" role, and the "read_api" scope. Tokens
    can be created here: https://gitlab.wikimedia.org/groups/repos/-/settings/access_tokens
    with Admin Mode signed in
    """

    def __init__(self, args: argparse.Namespace) -> None:
        self.log = LOG.getChild(self.__class__.__name__)

        self.gitlab_host = args.host
        self.client: gitlab.Gitlab = gitlab.Gitlab(
            f"https://{self.gitlab_host}", private_token=self.gitlab_token()
        )

        self.trusted_project_paths = self.get_project_paths_from_trusted_list()
        self.allow_untrusted_projects = args.allow_untrusted_projects
        self.allow_unprotected_branches = args.allow_unprotected_branches
        self.import_debs = args.import_debs
        self.dry_run = getattr(args, "dry_run", False)
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
        self.metrics_dir = args.metrics_dir

        # In dry-run mode we redirect the destination directory to a temporary
        # working directory, so that we exercise the full flow (download,
        # unzip, moves) without touching the real incoming/ tree.
        self._dry_run_temp_dirs: list[str] = []
        if self.dry_run:
            dry_dest = tempfile.mkdtemp(prefix="gitlab_puller_dryrun_incoming_")
            self.log.info(
                "Dry-run enabled; using temporary destination dir %s instead of %s",
                dry_dest,
                self.destination_dir,
            )
            self.destination_dir = dry_dest
            self._dry_run_temp_dirs.append(dry_dest)

        # Simple run-scoped counters for Prometheus textfile metrics
        self.jobs_considered = 0
        self.jobs_downloaded = 0
        self.jobs_download_failed = 0
        self.jobs_extract_failed = 0
        self.jobs_move_failed = 0
        self.jobs_import_failed = 0
        self.projects_prepare_failed = 0
        self.reprepro_notify_failed = 0

    def gitlab_token(self) -> str:
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
            self.log.error(
                "Couldn't find GitLab token (env GITLAB_TOKEN or /etc/gitlab-puller-auth)."
            )
            raise RuntimeError("Missing GitLab token for GitlabPackagePuller")

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

        self.log.debug(
            "Downloading JSON trusted projects lists from project %s file %s",
            TRUSTED_PROJECT_PATH,
            TRUSTED_PROJECT_FILE,
        )

        trusted_project = self.client.projects.get(TRUSTED_PROJECT_PATH)
        response = trusted_project.files.raw(file_path=TRUSTED_PROJECT_FILE, ref="main")
        json_content = json.loads(response)

        keys = json_content.keys()
        self.log.debug(
            "Found %d trusted project paths from trusted project list", len(keys)
        )

        return list(keys)

    def fetch_packages_for_project(self) -> None:
        """Fetches packages for each project given as a parameter to the class"""
        for project_path in self.project_paths:
            self.log.debug("Fetching packages for %s", project_path)
            try:
                project = self.client.projects.get(project_path)
                # get the last N jobs only because this script runs every 5 minutes
                jobs = project.jobs.list(get_all=False, per_page=self.number_of_jobs)
                protected_branches = [b.name for b in project.protectedbranches.list()]
            except (
                gitlab.exceptions.GitlabGetError,
                gitlab.exceptions.GitlabListError,
            ) as error:
                self.projects_prepare_failed += 1
                self.log.error(
                    "Skipping project %s after GitLab API error while preparing package fetch: %s",
                    project_path,
                    error,
                )
                continue

            self.log.info("Found %d jobs for project %s", len(jobs), project.name)
            # We might have multiple jobs for a project, but we only want to download the most
            # recent artifacts for each of them.
            job_names_seen = set()
            for job in jobs:
                self.jobs_considered += 1
                if job.name in job_names_seen:
                    self.log.debug(
                        "Skipping job %s because we've already downloaded an artifact for it",
                        job.name,
                    )
                    continue
                if self.can_download_package(job, protected_branches):
                    if self.download_debs(job, project):
                        # We've successfully downloaded a job with a deb file,
                        # no sense going any further for this job name
                        self.jobs_downloaded += 1
                        self.log.info(
                            "Downloaded the most recent package for project %s, "
                            "job name %s, skipping the rest",
                            project.name,
                            job.name,
                        )
                        job_names_seen.add(job.name)
                else:
                    self.log.debug(
                        "No packages meeting criteria for job %s in project %s found",
                        job.name,
                        project.name,
                    )

    def can_download_package(
        self, job: JobsType, protected_branches: list[str]
    ) -> bool:
        """Checks to see if a job meets the criteria for downloading packages
        - Is the job correct?
        - Is the branch correct?
        - Is the branch protected?
        """
        job_str = f"{job.name}/{job.id}"  # Shortcut for logging the identifier

        if not re.match(self.artifact_creation_job_pattern, job.name):
            self.log.debug(
                "Rejected %s for not being an artifact creation job %s",
                job_str,
                self.artifact_creation_job_pattern,
            )
            return False
        if job.status != "success":
            self.log.debug("Rejected %s because its status was not success", job_str)
            return False
        if not any(re.match(pattern, job.ref) for pattern in self.allowed_branches):
            self.log.debug(
                "Rejected %s because its branch is not an allowed branch (%s)",
                job_str,
                job.ref,
            )
            return False
        if job.ref not in protected_branches and not self.allow_unprotected_branches:
            self.log.debug(
                "Rejected %s for not being in a protected branch", job_str
            )
            return False
        return True

    def download_debs(self, job: JobsType, project: ProjectsType) -> bool:
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
                self.log.info(
                    "Already downloaded artifact for project %s and job_id %s",
                    project.name,
                    job.id,
                )

                #  Returning true here so that we can optimistically skip older artifacts
                return True

            with open(zipfile_path, "wb") as f:
                self.log.info("Downloading artifact and writing %s", zipfile_path)
                try:
                    job.artifacts(streamed=True, action=f.write)
                except (
                    gitlab.exceptions.GitlabHttpError,
                    gitlab.exceptions.GitlabGetError,
                ):
                    # This is logged as debug/info, because some artifacts are expected
                    # to be cleaned up after a while
                    self.log.info("Artifacts do not exist in job %s", job.id)
                    self.jobs_download_failed += 1
                    return False

            os.mkdir(job_artifact_path)
            try:
                with zipfile.ZipFile(zipfile_path) as zf:
                    self.log.debug(
                        "Extracting zipfile %s to %s", zipfile_path, job_artifact_path
                    )
                    zf.extractall(path=job_artifact_path)
            except (zipfile.BadZipFile, OSError):
                self.log.exception(
                    "Failed to extract artifacts for project %s job %s",
                    project.name,
                    job.id,
                )
                self.jobs_extract_failed += 1
                return False

            moved_files: list[str] = []
            move_failed = False
            for f in glob.glob(
                os.path.join(job_artifact_path, "WMF_BUILD_DIR", "*")
            ):
                # Move files to the root of the incoming/ dir in the apt repo
                dest = os.path.join(self.destination_dir, os.path.basename(f))
                if self.dry_run:
                    self.log.info("[DRY-RUN] Would move %s to %s", f, dest)
                else:
                    try:
                        self.log.debug("Moving %s to %s", f, dest)
                        shutil.move(f, dest)
                        moved_files.append(dest)
                    except OSError:
                        self.log.exception(
                            "Failed to move %s to %s for project %s job %s",
                            f,
                            dest,
                            project.name,
                            job.id,
                        )
                        move_failed = True

            if move_failed:
                self.jobs_move_failed += 1

            if self.import_debs:
                if self.dry_run:
                    self.log.info(
                        "[DRY-RUN] Would import packages into apt-staging with: "
                        "reprepro -b %s processincoming default",
                        APT_STAGING_PATH,
                    )
                else:
                    self.import_deb_files_to_repo(moved_files)

        return True

    def import_deb_files_to_repo(self, moved_files: list[str] | None = None) -> None:
        """Uses the reprepro command to import the given debs to the staging repository"""
        self.log.debug("Attempting to import packages into the apt repo")
        result = subprocess.run(
            [
                "/usr/bin/reprepro",
                "-b",
                APT_STAGING_PATH,
                "processincoming",
                "default",
            ],
            check=False,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            self.log.error(
                "Couldn't import packages to apt-staging (rc=%s, stderr=%r)",
                result.returncode,
                result.stderr.strip() if result.stderr else "",
            )
            self.jobs_import_failed += 1
            self.handle_reprepro_failure(moved_files or [], result)
        else:
            self.log.info("Successfully imported packages into apt-staging")
            if result.stdout:
                self.log.debug("reprepro stdout: %s", result.stdout.strip())

    def handle_reprepro_failure(self, moved_files: list[str], result) -> None:
        """Handle reprepro failures by quarantining files and triggering notification.

        T409832
        """
        if moved_files:
            reject_dir = os.path.join(APT_STAGING_PATH, "incoming-rejected")
            try:
                os.makedirs(reject_dir, exist_ok=True)
            except OSError:
                self.log.exception(
                    "Failed to create quarantine directory %s", reject_dir
                )
                # If we cannot create a quarantine directory, we log and skip moving.
                reject_dir = None

            if reject_dir is not None:
                for path in moved_files:
                    if not os.path.exists(path):
                        continue
                    try:
                        dest = os.path.join(reject_dir, os.path.basename(path))
                        self.log.info(
                            "Moving %s to quarantine directory %s after reprepro failure",
                            path,
                            dest,
                        )
                        shutil.move(path, dest)
                    except OSError:
                        self.log.exception(
                            "Failed to move %s to quarantine directory %s", path, reject_dir
                        )

        # Feedback / notification hook (to be wired up properly later).
        self.notify_reprepro_failure(moved_files, result)

    def notify_reprepro_failure(self, moved_files: list[str], result) -> None:
        """Placeholder for feedback mechanism when reprepro fails.
        """
        if self.dry_run:
            self.log.info(
                "[DRY-RUN] Would notify uploaders about reprepro failure affecting %d files",
                len(moved_files),
            )
            # Metric to signal that a notification would have been sent.
            self.reprepro_notify_failed += 1
            return

        # FIXME: if a metric is not enough, we can add another mean notification here.
        # We still increment the metric so that missing notifications are visible.
        self.reprepro_notify_failed += 1

    def write_metrics(self, success: int) -> None:
        """Write a Prometheus textfile with simple run-scoped metrics."""
        # Allow disabling metrics by passing an empty string, though the default is /tmp
        if not self.metrics_dir:
            self.log.debug("Metrics directory not set; skipping writing metrics")
            return

        try:
            os.makedirs(self.metrics_dir, exist_ok=True)
        except OSError:
            self.log.exception(
                "Failed to create metrics directory %s, skipping metrics",
                self.metrics_dir,
            )
            return

        # If any import failed, consider the run as unsuccessful from a metrics
        # perspective, even if no unhandled exception was raised.
        if self.jobs_import_failed > 0:
            success = 0

        metrics_path = os.path.join(self.metrics_dir, "gitlab_package_puller.prom")
        now = int(time.time())

        lines = [
            (
                "# HELP gitlab_package_puller_jobs_considered "
                "Number of CI jobs inspected in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_considered gauge",
            f"gitlab_package_puller_jobs_considered {self.jobs_considered}",
            (
                "# HELP gitlab_package_puller_jobs_downloaded "
                "Number of CI jobs whose artifacts were downloaded in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_downloaded gauge",
            f"gitlab_package_puller_jobs_downloaded {self.jobs_downloaded}",
            (
                "# HELP gitlab_package_puller_run_success "
                "Whether the last run completed without unhandled exceptions "
                "(1=success, 0=failure)"
            ),
            "# TYPE gitlab_package_puller_run_success gauge",
            f"gitlab_package_puller_run_success {success}",
            (
                "# HELP gitlab_package_puller_last_run_timestamp_seconds "
                "Unix timestamp of the end of the last run"
            ),
            "# TYPE gitlab_package_puller_last_run_timestamp_seconds gauge",
            f"gitlab_package_puller_last_run_timestamp_seconds {now}",
            (
                "# HELP gitlab_package_puller_jobs_download_failed "
                "Number of CI jobs whose artifacts failed to download in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_download_failed gauge",
            f"gitlab_package_puller_jobs_download_failed {self.jobs_download_failed}",
            (
                "# HELP gitlab_package_puller_jobs_extract_failed "
                "Number of CI jobs whose artifacts failed to extract in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_extract_failed gauge",
            f"gitlab_package_puller_jobs_extract_failed {self.jobs_extract_failed}",
            (
                "# HELP gitlab_package_puller_jobs_move_failed "
                "CI jobs whose artifacts failed to move to destination dir in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_move_failed gauge",
            f"gitlab_package_puller_jobs_move_failed {self.jobs_move_failed}",
            (
                "# HELP gitlab_package_puller_jobs_import_failed "
                "CI jobs whose packages failed to import into apt-staging in the last run"
            ),
            "# TYPE gitlab_package_puller_jobs_import_failed gauge",
            f"gitlab_package_puller_jobs_import_failed {self.jobs_import_failed}",
            (
                "# HELP gitlab_package_puller_projects_prepare_failed "
                "Number of projects skipped after a GitLab API error while preparing "
                "package fetch in the last run"
            ),
            "# TYPE gitlab_package_puller_projects_prepare_failed gauge",
            (
                f"gitlab_package_puller_projects_prepare_failed "
                f"{self.projects_prepare_failed}"
            ),
            (
                "# HELP gitlab_package_puller_reprepro_notify_failed "
                "Number of times a reprepro failure notification was (or would have been) "
                "triggered in the last run"
            ),
            "# TYPE gitlab_package_puller_reprepro_notify_failed gauge",
            f"gitlab_package_puller_reprepro_notify_failed {self.reprepro_notify_failed}",
        ]

        if self.dry_run:
            self.log.info("[DRY-RUN] Printing instead of writing metrics")
            print("\n".join(lines) + "\n")
            return

        try:
            with open(metrics_path, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
        except OSError:
            self.log.exception("Failed to write metrics file %s", metrics_path)
            return

        self.log.debug("Wrote Prometheus metrics to %s", metrics_path)

    def cleanup(self) -> None:
        """Cleanup any temporary resources created for dry-run mode."""
        if not self.dry_run:
            return

        for path in self._dry_run_temp_dirs:
            try:
                self.log.info("[DRY-RUN] Removing temporary directory %s", path)
                shutil.rmtree(path, ignore_errors=True)
            except OSError:
                self.log.exception("Failed to remove temporary directory %s", path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Gitlab package puller", description="Fetches packages from GitLab CI"
    )
    parser.add_argument(
        "-D",
        "--destination-dir",
        default="/srv/aptrepo/wikimedia-staging/incoming",
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
        help=(
            "Regex to match branches allowed to generate artifacts. "
            "Can be specified multiple times"
        ),
    )
    parser.add_argument(
        "--allow-untrusted-projects",
        action="store_true",
        help="Allows project paths that aren't in the list of jobs run on trusted runners",
    )
    parser.add_argument(
        "--allow-unprotected-branches",
        action="store_true",
        help="Allows project paths that aren't in unprotected branches",
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
        help=(
            "List of project paths (e.g., 'repos/sre/miscweb') to fetch packages from. "
            "This is usually from the list of projects specified in the trusted runner list."
        ),
    )
    parser.add_argument(
        "-n",
        "--number-of-jobs",
        type=int,
        nargs="?",
        default=50,
        help="Number of CI jobs to check for new packages",
    )
    parser.add_argument(
        "-i",
        "--import-debs",
        action="store_true",
        help="Imports the downloaded .deb files into the staging repo",
    )
    parser.add_argument(
        "--metrics-dir",
        default="/var/lib/prometheus/node.d/",
        help="Directory to write Prometheus textfile metrics into",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Download and extract artifacts and simulate reprepro imports, "
            "but do not modify the real apt repository"
        ),
    )

    args = parser.parse_args()

    level_name = args.log_level.upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    )

    puller = GitlabPackagePuller(args)

    run_success = 0
    try:
        puller.fetch_packages_for_project()
        run_success = 1
    except Exception:
        LOG.exception("Unhandled exception during package fetch")
        run_success = 0
    finally:
        try:
            puller.write_metrics(run_success)
        except Exception:
            LOG.exception("Failed to write Prometheus metrics file")
        try:
            puller.cleanup()
        except Exception:
            LOG.exception("Failed during dry-run cleanup")
