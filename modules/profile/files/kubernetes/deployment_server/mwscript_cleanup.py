#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""Remove lingering Helm releases from completed maintenance scripts on K8s."""
import argparse
import datetime
import logging
import subprocess
import sys

from kubernetes import client, config

logger = logging.Logger(__name__)

EXCLUDE_RELEASES = {'prometheus'}
EXPIRY_TIME = datetime.timedelta(days=7)
MINIMUM_AGE = datetime.timedelta(minutes=5)
NAMESPACE = 'mw-script'


def get_releases(api_client: client.ApiClient) -> list[str]:
    # mwscript_k8s generates the release names, outside of helmfile, so we can't ask helmfile to
    # list all the releases that exist. Instead, we can get them from the k8s API. (We could also
    # get them from `helm list`, but it's slow and doesn't offer consistent-snapshot pagination,
    # so we get bad data if the list of releases changes while we're trying to iterate over it.)
    core = client.CoreV1Api(api_client)
    secrets_list = core.list_namespaced_secret(
        namespace=NAMESPACE, field_selector='type=helm.sh/release.v1')
    # Store the release names in a set, since duplicate names will appear if Helm has two revisions
    # of the same release.
    releases = set[str]()
    for secret in secrets_list.items:
        # Secret names are of the form 'sh.helm.release.v1.abcde123.v42', for revision 42 of a
        # release named 'abcde123'.
        if not secret.metadata.name.startswith('sh.helm.release.v1.'):
            # We could just log this and skip it, but with our field selector we really expect to
            # only see Helm-release secrets with a digestible name. If something's changed in the
            # format, crash noisily so we can fix it, instead of quietly skipping all the releases.
            raise ValueError(f'Unexpected secret name: {secret.metadata.name}')
        release_name, _ = secret.metadata.name.removeprefix('sh.helm.release.v1.').split('.v')
        if release_name in EXCLUDE_RELEASES:
            continue
        # Avoid a race condition where we'd delete a new release before its job is created. Helm's
        # modifiedAt label should be the same time as Kubernetes's creation_timestamp, but it's the
        # Helm semantics that we care about, so use the timestamp that `helm list` would report.
        try:
            updated_ts = secret.metadata.labels['modifiedAt']
        except KeyError:
            logger.debug('Skipping release %s: modifiedAt label not set', release_name)
            continue
        updated = datetime.datetime.fromtimestamp(int(updated_ts), tz=datetime.timezone.utc)
        age = datetime.datetime.now(tz=datetime.timezone.utc) - updated
        if age < MINIMUM_AGE:
            logger.debug('Skipping release %s: updated recently', release_name)
            continue
        releases.add(release_name)
    logger.info('Found %d releases', len(releases))
    # Sort the releases before returning, just for convenience: it makes it easier to gauge progress
    # while tailing the logs.
    return sorted(releases)


def all_jobs_expired(api_client: client.ApiClient, release: str) -> bool:
    batch = client.BatchV1Api(api_client)
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
    api_client = client.ApiClient(config.load_kube_config(config_file))
    errors = False
    for release in get_releases(api_client):
        if all_jobs_expired(api_client, release):
            try:
                destroy(release, args.cluster, args.dry_run)
            except subprocess.SubprocessError:
                logger.exception('Failed to destroy release %s', release)
                errors = True
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
