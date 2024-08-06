#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""Start a MediaWiki maintenance script on Kubernetes."""
import argparse
import glob
import grp
import json
import logging
import os
import random
import string
import subprocess
import sys
import tempfile
from typing import Dict

import yaml
from conftool.cli import ConftoolClient
from kubernetes import client, config, watch
from kubernetes.client.models.v1_pod import V1Pod
from wmflib import interactive

logger = logging.Logger(__name__)

BUILD_REPORT_PATH = '/srv/mediawiki-staging/scap/image-build/report.json'
BUILD_REPORT_IMAGE_TYPE = 'mediawiki'
BUILD_REPORT_IMAGE_NAME = 'multiversion-image'
NAMESPACE = 'mw-script'


def kube_env(namespace: str, cluster: str) -> Dict[str, str]:
    # Duplicates the functionality of modules/profile/files/kubernetes/kube-env.sh.
    return {
        'K8S_CLUSTER': cluster,
        'KUBECONFIG': f'/etc/kubernetes/{namespace}-{cluster}.config',
    }


def job_name(namespace: str, cluster: str, release: str) -> str:
    # Duplicates the functionality of mw.name.namespace.env.release in the Helm chart.
    return f'{namespace}.{cluster}.{release}'


def get_primary_dc() -> str:
    ct = ConftoolClient(configfile='/etc/conftool/config.yaml',
                        schemafile='/etc/conftool/schema.yaml')
    mwconfig = ct.get('mwconfig')
    return mwconfig('common', 'WMFMasterDatacenter').val


def mediawiki_image():
    with open(BUILD_REPORT_PATH) as f:
        build_report = json.load(f)

    last_build = build_report.get(BUILD_REPORT_IMAGE_TYPE, {}).get(BUILD_REPORT_IMAGE_NAME)
    if not last_build:
        raise ValueError(
            f'No image for "{BUILD_REPORT_IMAGE_TYPE}.{BUILD_REPORT_IMAGE_NAME}" found in '
            f'{BUILD_REPORT_PATH}'
        )

    prefix = 'docker-registry.discovery.wmnet/'
    if not last_build.startswith(prefix):
        raise ValueError(
            f'Unexpected value "{last_build}" for image '
            f'"{BUILD_REPORT_IMAGE_TYPE}.{BUILD_REPORT_IMAGE_NAME}" found in {BUILD_REPORT_PATH}'
        )
    return last_build[len(prefix):]


def check_config_file(namespace: str, cluster: str) -> None:
    # Make sure we can open the kubernetes config file. If not, either the namespace/cluster are
    # wrong or we're not in the appropriate usergroup.
    try:
        config_path = kube_env(namespace, cluster)['KUBECONFIG']
        with open(config_path, 'r'):
            pass
    except PermissionError as e:
        stat = os.stat(e.filename)
        group = grp.getgrgid(stat.st_gid).gr_name
        is_group_readable = stat.st_mode & 0o200
        if group == 'root' or not is_group_readable:
            logger.error(
                "🚩 You don't have permission to read the Kubernetes config file %s (try sudo)",
                e.filename)
        else:
            logger.error(
                "🚩 You don't have permission to read the Kubernetes config file %s (are you in the "
                "%s group?)",
                e.filename, group)
        raise
    except FileNotFoundError as e:
        if not glob.glob(f'/etc/kubernetes/*-{glob.escape(cluster)}.config'):
            logger.error('🚩 Kubernetes config file %s not found: there is no cluster %s.',
                         e.filename, cluster)
        elif not glob.glob(f'/etc/kubernetes/{glob.escape(NAMESPACE)}-*.config'):
            logger.error('🚩 Kubernetes config file %s not found: there is no namespace %s.',
                         e.filename, NAMESPACE)
        else:
            logger.error('🚩 Kubernetes config file %s not found: namespace %s is not configured in'
                         ' cluster %s.',
                         e.filename, NAMESPACE, cluster)
        raise


def is_started(pod: V1Pod, container: str) -> bool:
    if pod.status.phase in {'Running', 'Succeeded', 'Failed'}:
        return True
    if pod.status.phase == 'Unknown':
        return False
    # The pod status is Pending. Find our container and see if it's ready yet.
    if not pod.status.container_statuses:  # Sometimes it's None instead of an empty list.
        return False
    for container_status in pod.status.container_statuses:
        if container_status.name == container:
            return container_status.state.running or container_status.state.terminated
    return False


def wait_until_started(env_vars: Dict[str, str], job: str, container: str) -> None:
    kube_config = config.load_kube_config(config_file=env_vars['KUBECONFIG'])
    core_client = client.CoreV1Api(client.ApiClient(kube_config))
    pod_list = core_client.list_namespaced_pod(
        namespace=NAMESPACE, label_selector=f'job-name={job}')
    if pod_list.items and is_started(pod_list.items[0], container):
        logger.info('🚀 Job is running.')
        return
    resource_version = pod_list.metadata.resource_version

    logger.info('⏳ Waiting for the container to start...')
    w = watch.Watch()
    for event in w.stream(core_client.list_namespaced_pod,
                          namespace=NAMESPACE,
                          label_selector=f'job-name={job}',
                          resource_version=resource_version,
                          timeout_seconds=300):
        pod = event['object']
        if is_started(pod, container):
            logger.info('🚀 Job is running.')
            break
    else:
        env_vars_str = ' '.join(f'{key}={value}' for key, value in env_vars.items())
        logger.warning('🚩 Timed out waiting for the container to start. Proceeding anyway, but '
                       'this might not work. To check on the job, run:\n'
                       '%s kubectl describe job %s', env_vars_str, job)
    w.stop()


def main() -> int:
    logger.setLevel(logging.INFO)
    logger.addHandler(logging.StreamHandler())

    parser = argparse.ArgumentParser(
        description="Start a MediaWiki maintenance script on Kubernetes.\n\n"
                    "Pass any options below for this script, then '--', then all remaining "
                    "arguments are passed to MWScript.php. A typical invocation looks like:\n\n"
                    "%(prog)s --comment='backfill for T123456' -- Filename.php --wiki=aawiki "
                    "--script-specific-arg",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Print extra output from the underlying helmfile invocation.')
    parser.add_argument('--comment', help='Set a comment label on the Kubernetes job.')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-f', '--follow', action='store_true',
                       help='When the script is started, stream its logs.')
    group.add_argument('--attach', action='store_true',
                       help='When the script is started, attach to it interactively (see `kubectl '
                            'help attach`).')

    parser.add_argument('script_name',
                        help='Filename of maintenance script (first arg to MWScript.php).')
    parser.add_argument('script_args', nargs='*', help='Additional arguments to MWScript.php.')
    args = parser.parse_args()

    environment = get_primary_dc()
    # If we can't open the config, bail out with a clear error message, instead of running helmfile.
    try:
        check_config_file(NAMESPACE, environment)
    except (PermissionError, FileNotFoundError):
        return 1

    # Since mwscript.args is a list, passing it on the helmfile command line would get into some
    # messy escaping. Instead, we'll write it to a values file, and pass that *path* to helmfile. As
    # long as we're doing that, we'll set all these values that way.
    values = {
        # For normal deployments, this value is managed by scap. For scripts, we'll use the latest
        # build.  TODO: Add a flag to specify an image version?
        'main_app': {
            'image': mediawiki_image(),
        },
        'mwscript': {
            'args': [args.script_name, *args.script_args],
            'labels': {
                'username': interactive.get_username(),
                # The label can't contain slashes. If script_name is a path, use the file only.
                'script': args.script_name.split('/')[-1],
            },
            'comment': args.comment,
            'stdin': args.attach,
            'tty': args.attach and sys.stdin.isatty(),
        }
    }
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        yaml.dump(values, f)
        values_filename = f.name

    logger.info('⏳ Starting %s on Kubernetes...', args.script_name)
    release = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    try:
        subprocess.run([
            '/usr/bin/helmfile',
            *(['--quiet'] if not args.verbose else []),
            '--file', f'/srv/deployment-charts/helmfile.d/services/{NAMESPACE}/helmfile.yaml',
            '--environment', environment,
            # As of this writing, we don't need a selector because this is the only thing in the
            # helmfile. But it's included anyway, for futureproofing.
            '--selector', f'name={release}',
            'apply',
            '--values', values_filename,
            *(['--suppress-diff'] if not args.verbose else []),
            ],
            env={
                'PATH': os.environ['PATH'],  # Our helmfiles use an unqualified path for helmBinary.
                'HELM_CACHE_HOME': '/var/cache/helm',  # Use the shared cache.
                'HELM_CONFIG_HOME': '/etc/helm',  # Needed for helm chart repos etc.
                'HELM_DATA_HOME': '/usr/share/helm',  # Needed for helm-diff.
                'RELEASE_NAME': release,  # Consumed by the helmfile template.
            },
            check=True)
    except subprocess.CalledProcessError as e:
        # helmfile and/or helm will have already printed an error, so we don't need to add anything
        # (except the specific command we ran). This doesn't delete the values file, which we leave
        # in case it's needed for debugging. It lives in /tmp anyway, so failing to clean it up
        # isn't a disaster.  TODO: shlex.join() would make this more readable, but we're on Buster.
        logger.fatal('☠️ Command failed with status %d: %s', e.returncode, e.cmd)
        return 1

    job = job_name(NAMESPACE, environment, release)
    container = f'mediawiki-{release}-app'
    env_vars = kube_env(NAMESPACE, environment)
    if args.follow:
        wait_until_started(env_vars, job, container)
        logger.info('📜 Streaming logs:')
        try:
            subprocess.run(['/usr/bin/kubectl', 'logs', '-f', f'job/{job}', container],
                           env=env_vars)
        except subprocess.CalledProcessError as e:
            logger.fatal('☠️ Command failed with status %d: %s', e.returncode, e.cmd)
    elif args.attach:
        wait_until_started(env_vars, job, container)
        logger.info('📜 Attaching to stdin/stdout:')
        # Switch from the read-only user to the deploy user, which has privileges to attach.
        env_vars = kube_env(f'{NAMESPACE}-deploy', environment)
        try:
            subprocess.run([
                '/usr/bin/kubectl',
                'attach',
                *(['--quiet'] if not args.verbose else []),
                f'job/{job}',
                '--container', f'mediawiki-{release}-app',
                '-it' if sys.stdin.isatty() else '-i'
                ],
                env=env_vars, check=True)
        except subprocess.CalledProcessError as e:
            logger.fatal('☠️ Command failed with status %d: %s', e.returncode, e.cmd)
    else:
        env_vars_str = ' '.join(f'{key}={value}' for key, value in env_vars.items())
        logger.info('🚀 Job is running. For streaming logs, run:\n'
                    '%s kubectl logs -f job/%s mediawiki-%s-app',
                    env_vars_str, job, release)

    os.unlink(values_filename)
    return 0


if __name__ == '__main__':
    sys.exit(main())
