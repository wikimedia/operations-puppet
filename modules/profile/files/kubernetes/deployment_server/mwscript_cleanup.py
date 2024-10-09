#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""Remove lingering Helm releases from completed maintenance scripts on K8s."""
import argparse
import datetime
import itertools
import json
import logging
import re
import subprocess
import sys
from typing import Iterable

from kubernetes import client, config

logger = logging.Logger(__name__)

EXPIRY_TIME = datetime.timedelta(days=7)
MINIMUM_AGE = datetime.timedelta(minutes=5)
NAMESPACE = 'mw-script'


def get_releases(config_file: str) -> Iterable[str]:
    # mwscript_k8s generates the release names, outside of helmfile, so we can't ask helmfile to
    # list all the releases that exist. Instead, we can get them from helm.
    for offset in itertools.count(0, step=256):
        p = subprocess.run([
            'helm',
            '--namespace', NAMESPACE,
            'list',
            '--output', 'json',
            '--max', '256',
            '--offset', str(offset)],
            env={'KUBECONFIG': config_file}, check=True, capture_output=True, text=True)
        releases = json.loads(p.stdout)
        if not releases:
            return
        for release in releases:
            # Helm's release timestamps end with " +0000 UTC". Pre-3.11, fromisoformat() wants
            # "+00:00".
            updated_str = release['updated'].replace(' +0000 UTC', '+00:00')
            # Helm also includes nanoseconds, but datetime only takes microseconds.
            updated_str = re.sub(r'(\.\d{6})\d*', r'\1', updated_str)
            updated = datetime.datetime.fromisoformat(updated_str)
            age = datetime.datetime.now(tz=datetime.timezone.utc) - updated
            # Avoid a race condition where we'd delete a new release before its job is created.
            if age < MINIMUM_AGE:
                logger.debug('Skipping release %s: updated recently', release['name'])
                continue
            yield release['name']


def all_jobs_expired(batch: client.BatchV1Api, release: str) -> bool:
    job_list = batch.list_namespaced_job(namespace=NAMESPACE, label_selector=f'release={release}')
    # Usually, the job is cleaned up via ttlSecondsAfterFinished. So if there are no jobs, we'll go
    # ahead and uninstall the release. If the job is terminated but still here, we'll assume it was
    # kept around on purpose, so we'll clean up only if it finished at least EXPIRY_TIME ago.
    # (Despite the function name, there shouldn't be multiple jobs in the release. But if there are,
    # we'll clean up only if all of them are expired.)
    for job in job_list.items:
        # If the job's status has the Completed or Failed condition, the job's end time is the time
        # that condition was set. There shouldn't be more than one matching condition, but if there
        # are, we'll return the most recent time.
        end_times = [condition.last_transition_time
                     for condition in (job.status.conditions if job.status.conditions else [])
                     if condition.status == 'True' and condition.type in {'Complete', 'Failed'}]
        if not end_times:
            # No Completed/Failed condition, so the job is still running (or suspended).
            logger.debug('Skipping release %s: job has no end time', release)
            return False
        end_time = max(end_times)
        age = datetime.datetime.now(tz=datetime.timezone.utc) - end_time
        if age < EXPIRY_TIME:
            logger.debug('Skipping release %s: job completed recently', release)
            return False
    return True


def destroy(release: str, cluster: str, dry_run: bool) -> None:
    if dry_run:
        logger.info('Dry run: Would destroy release %s', release)
        return
    logger.info('Destroying release %s', release)
    subprocess.run([
        'helmfile',
        '--file', f'/srv/deployment-charts/helmfile.d/services/{NAMESPACE}/helmfile.yaml',
        '--environment', cluster,
        '--selector', f'name={release}',
        'destroy'
        ],
        env={
            'PATH': '/usr/bin',  # Our helmfiles use an unqualified path for helmBinary.
            'RELEASE_NAME': release,  # RELEASE_NAME is consumed by the helmfile template.
        },
        check=True
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Remove lingering Helm releases from completed maintenance scripts on K8s.')
    parser.add_argument('--debug', action='store_true', help='Print debug output.')
    parser.add_argument('--dry-run', action='store_true',
                        help='Only list objects that would be deleted.')
    parser.add_argument('cluster', help='Name of Kubernetes cluster, like "eqiad"')
    args = parser.parse_args()

    logger.setLevel(logging.DEBUG if args.debug else logging.INFO)
    logger.addHandler(logging.StreamHandler())

    config_file = f'/etc/kubernetes/{NAMESPACE}-deploy-{args.cluster}.config'
    batch = client.BatchV1Api(client.ApiClient(config.load_kube_config(config_file)))

    errors = False
    for release in get_releases(config_file):
        if all_jobs_expired(batch, release):
            try:
                destroy(release, args.cluster, args.dry_run)
            except subprocess.SubprocessError:
                logger.exception('Failed to destroy release %s', release)
                errors = True
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
