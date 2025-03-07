#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""Start a MediaWiki maintenance script on Kubernetes."""
import argparse
import collections
import glob
import grp
import json
import logging
import os
import random
import re
import shlex
import string
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import TextIO

import yaml
from conftool.cli import ConftoolClient
from kubernetes import client, config, watch
from kubernetes.client.models.v1_pod import V1Pod
from wmflib import interactive

logger = logging.Logger(__name__)

NAMESPACE = 'mw-script'
# Kubernetes config files to attempt to use for operations in this namespace, under
# /etc/kubernetes/{KUBE_CONFIG}-{CLUSTER}.yaml. For each of these, there's a second config with the
# same file permissions and a -deploy suffix. See profile::kubernetes::deployment_server::services
# in hieradata, where this matches the `kubeconfig` value (or, by default if that's missing, the
# `name` value).
KUBE_CONFIGS = [
    'mw-script',  # Normal access for members of the deployment group.
    'mw-script-restricted',  # Identical access for members of the restricted group.
]
# Read main_app.image from this values file to determine the live MW image version.
VALUES = '/etc/helmfile-defaults/mediawiki/release/mw-script-main.yaml'


class ClientError(Exception):
    """Something went wrong on our end; incorrect invocation or config. Think 4xx."""
    icon = '🚩'


class ServerError(Exception):
    """Something went wrong beyond this wrapper; local subcommand failure, API error. Think 5xx."""
    icon = '☠️'


class Job:
    def __init__(self, cluster: str, config_file: str, deploy_config_file: str) -> None:
        self.cluster = cluster
        self.config_file = config_file
        self.deploy_config_file = deploy_config_file
        self.release = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
        # Duplicates the functionality of mw.name.namespace.env.release in the Helm chart.
        self.name = f'{NAMESPACE}.{self.cluster}.{self.release}'
        # Duplicates the name in the Helm chart (based on base.name.release).
        self.app_container = f'mediawiki-{self.release}-app'

    @property
    def kube_env(self) -> dict[str, str]:
        # Duplicates the functionality of modules/profile/files/kubernetes/kube-env.sh.
        return {
            'K8S_CLUSTER': self.cluster,
            'KUBECONFIG': self.config_file,
        }

    @property
    def deploy_kube_env(self) -> dict[str, str]:
        return {
            'K8S_CLUSTER': self.cluster,
            'KUBECONFIG': self.deploy_config_file,
        }

    @property
    def logs_command(self) -> str:
        return (
            f'{env_vars_str(self.kube_env)} kubectl logs -f job/{self.name} {self.app_container}')

    def wait_until_started(self) -> None:
        kube_config = config.load_kube_config(config_file=self.config_file)
        core_client = client.CoreV1Api(client.ApiClient(kube_config))
        pod_list = core_client.list_namespaced_pod(
            namespace=NAMESPACE, label_selector=f'job-name={self.name}')
        if pod_list.items and is_started(pod_list.items[0], self.app_container):
            logger.info('🚀 Job is running.')
            return
        resource_version = pod_list.metadata.resource_version

        logger.info('⏳ Waiting for the container to start...')
        w = watch.Watch()
        for event in w.stream(core_client.list_namespaced_pod,
                              namespace=NAMESPACE,
                              label_selector=f'job-name={self.name}',
                              resource_version=resource_version,
                              timeout_seconds=300):
            pod = event['object']
            if is_started(pod, self.app_container):
                logger.info('🚀 Job is running.')
                break
        else:
            logger.warning(
                '🚩 Timed out waiting for the container to start. Proceeding anyway, but '
                'this might not work. To check on the job, run:\n'
                '%s kubectl describe job %s', env_vars_str(self.kube_env), self.name)
        w.stop()


def env_vars_str(env_vars: dict[str, str]) -> str:
    return ' '.join(f'{key}={value}' for key, value in env_vars.items())


def get_primary_dc() -> str:
    ct = ConftoolClient(configfile='/etc/conftool/config.yaml',
                        schemafile='/etc/conftool/schema.yaml')
    mwconfig = ct.get('mwconfig')
    return mwconfig('common', 'WMFMasterDatacenter').val


def mediawiki_image() -> str:
    # Find out what the most recently deployed multiversion image is and use that. This might not be
    # the same image that's actually running in the "normal" releases like mw-web (particularly if
    # we're in the middle of a deployment or rollback) but the values file is world-readable so this
    # works even if the user isn't in the deployment group.
    with open(VALUES, 'r') as f:
        values = yaml.safe_load(f)
    return values['main_app']['image']


def check_config_files(cluster: str) -> tuple[str, str]:
    # Make sure we can open one of the kubernetes configs, and return the first pair of paths
    # (regular and deploy) that work. If not, either the namespace/cluster are wrong or we're not in
    # the appropriate usergroups.
    groups_tried = set()
    for kube_config in KUBE_CONFIGS:
        path = f'/etc/kubernetes/{kube_config}-{cluster}.config'
        deploy_path = f'/etc/kubernetes/{kube_config}-deploy-{cluster}.config'
        try:
            with open(path, 'r'):
                pass
            with open(deploy_path, 'r'):
                pass
            return path, deploy_path
        except PermissionError as e:
            stat = os.stat(e.filename)
            group = grp.getgrgid(stat.st_gid).gr_name
            groups_tried.add(group)
        except FileNotFoundError as e:
            if not glob.glob(f'/etc/kubernetes/*-{glob.escape(cluster)}.config'):
                raise ClientError(f'Kubernetes config file {e.filename} not found: there is no '
                                  f'cluster {cluster}.')
            elif not glob.glob(f'/etc/kubernetes/{glob.escape(kube_config)}-*.config'):
                raise ClientError(f'Kubernetes config file {e.filename} not found: there is no '
                                  f'config {kube_config}.')
            else:
                raise ClientError(f'Kubernetes config file {e.filename} not found: config '
                                  f'{kube_config} does not exist in cluster {cluster}.')
    files = 'file' if len(KUBE_CONFIGS) == 1 else 'files'
    joined_groups = ' or '.join(groups_tried)
    groups = 'group' if len(groups_tried) == 1 else 'groups'
    raise ClientError(f"You don't have permission to read the Kubernetes config {files} for the "
                      f"namespace {NAMESPACE}. (Are you in the {joined_groups} {groups}?).")


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


def parse_duration(duration: str) -> int:
    try:
        if duration.endswith('d'):
            return int(duration[:-1]) * 86400
        elif duration.endswith('h'):
            return int(duration[:-1]) * 3600
        elif duration.endswith('m'):
            return int(duration[:-1]) * 60
        elif duration.endswith('s'):
            return int(duration[:-1])
        else:
            return int(duration)
    except ValueError:
        raise argparse.ArgumentTypeError(
            'must be a plain number of seconds, or a number with a unit like 1d, 2h, 30m, 40s')


def parse_filename_pair(filenames: str) -> tuple[str, TextIO]:
    if ':' in filenames:
        # Use rsplit() so that we can handle a colon in the local_name (which the user might not be
        # able to change) as long as there's no colon in the remote_name (which they can).
        local_name, remote_name = filenames.rsplit(':', maxsplit=1)
        # We'll still check against the full filename regex below, but check first for a specific
        # likely cause so that we can give a specific error message.
        if '/' in remote_name:
            raise argparse.ArgumentTypeError(
                'remote filename may not include a directory; files are placed in the working '
                'directory, /data')
    else:
        local_name = filenames
        remote_name = Path(local_name).name  # By default use the same filename (sans directories).

    # Use the same regex that the ConfigMap type is validated against.
    if not re.fullmatch('[-._a-zA-Z0-9]+', remote_name):
        # Briefer version of the error that Kubernetes would emit if we didn't catch this. (This is
        # possible with or without an explicit remote_name, e.g. if the local_name also wasn't
        # compliant.)
        raise argparse.ArgumentTypeError(
            "remote filename must consist of alphanumeric characters, '-', '_' or '.'")
    # Use the FileType factory instead of just calling open() ourselves, so that we get argparse's
    # error handling for free.
    return remote_name, argparse.FileType()(local_name)


def start(args: argparse.Namespace) -> dict[str, str]:
    environment = get_primary_dc()
    # If we can't open the config, bail out with a clear error message, instead of running helmfile.
    config_file, deploy_config_file = check_config_files(environment)

    if args.file:
        try:
            textdata = {name: f.read() for name, f in args.file}
        except UnicodeDecodeError as e:
            raise ClientError(f'Invalid {e.encoding}: only text files may be passed with --file.')
    else:
        textdata = None
    # Since mwscript.args is a list, passing it on the helmfile command line would get into some
    # messy escaping. Instead, we'll write it to a values file, and pass that *path* to helmfile. As
    # long as we're doing that, we'll set all these values that way.
    values = {
        # Default to the latest multiversion image deployed by scap, with the option to override
        # by a command-line flag.
        'main_app': {
            'image': args.mediawiki_image if args.mediawiki_image else mediawiki_image(),
        },
        'mwscript': {
            'args': [args.script_name, *args.script_args],
            'labels': {
                'username': interactive.get_username(),
                # The label can't contain slashes or colons. If script_name has a path or an
                # extension name, use the filename only.
                'script': re.split('[/:]', args.script_name)[-1],
            },
            'comment': args.comment,
            'stdin': args.attach,
            'activeDeadlineSeconds': args.timeout,
            'tty': args.attach and sys.stdin.isatty(),
            'textdata': textdata,
        }
    }
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        yaml.dump(values, f)
        values_filename = f.name

    job = Job(environment, config_file, deploy_config_file)
    logger.info('⏳ Starting %s on Kubernetes as job %s ...', args.script_name, job.name)
    try:
        subprocess.run([
            '/usr/bin/helmfile',
            *(['--quiet'] if not args.verbose else []),
            '--file', args.helmfile,
            '--state-values-set', f'kubeConfig={job.deploy_config_file}',
            '--environment', environment,
            # As of this writing, we don't need a selector because this is the only thing in the
            # helmfile. But it's included anyway, for futureproofing.
            '--selector', f'name={job.release}',
            'apply',
            '--values', values_filename,
            *(['--suppress-diff'] if args.verbose < 2 else []),
            ],
            env={
                'PATH': os.environ['PATH'],  # Our helmfiles use an unqualified path for helmBinary.
                'HELM_CACHE_HOME': '/var/cache/helm',  # Use the shared cache.
                'HELM_CONFIG_HOME': '/etc/helm',  # Needed for helm chart repos etc.
                'HELM_DATA_HOME': '/usr/share/helm',  # Needed for helm-diff.
                'RELEASE_NAME': job.release,  # Consumed by the helmfile template.
            },
            check=True,
            stdout=subprocess.PIPE if not args.verbose else None,
            stderr=subprocess.STDOUT if not args.verbose else None,
            text=True if not args.verbose else None)
    except subprocess.CalledProcessError as e:
        # If we were keeping the subprocess output to ourselves, print it now.
        if not args.verbose:
            logger.error(e.stdout)
        # helmfile and/or helm will have already printed an error, so we don't need to add anything
        # (except the specific command we ran). This doesn't delete the values file, which we leave
        # in case it's needed for debugging. It lives in /tmp anyway, so failing to clean it up
        # isn't a disaster.
        raise ServerError(f'Command failed with status {e.returncode}: {shlex.join(e.cmd)}')

    if args.follow:
        job.wait_until_started()
        logger.info('📜 Streaming logs:')
        try:
            # When shelling out to kubectl, we pass $HOME through so that it finds (or creates)
            # .kube/cache there, instead of dropping it rudely into $PWD.
            subprocess.run(['/usr/bin/kubectl', 'logs', '-f', f'job/{job.name}', job.app_container],
                           env={**job.kube_env, 'HOME': os.environ['HOME']})
        except subprocess.CalledProcessError as e:
            raise ServerError(f'Command failed with status {e.returncode}: {shlex.join(e.cmd)}')
        except KeyboardInterrupt:
            logger.info('🔁 To resume streaming logs, run:\n%s\n'
                        'ℹ️ To terminate your job and delete it, run:\n%s kubectl delete job %s',
                        job.logs_command,
                        env_vars_str(job.deploy_kube_env),
                        job.name)
    elif args.attach:
        job.wait_until_started()
        if sys.stdin.isatty():
            logger.info(
                "ℹ️ Expecting a prompt but don't see it? Due to a race condition, the beginning of "
                "the output might be missing. " + (
                    'Try pressing enter.' if args.script_name in ['eval.php', 'shell.php']
                    else 'Try passing your input.'))
        logger.info('📜 Attached to stdin/stdout:')
        try:
            subprocess.run([
                '/usr/bin/kubectl',
                'attach',
                *(['--quiet'] if not args.verbose else []),
                f'job/{job.name}',
                '--container', job.app_container,
                '-it' if sys.stdin.isatty() else '-i'
            ],
                env={
                    # Switch from the read-only user to the deploy user, which has privileges to
                    # attach.
                    **job.deploy_kube_env,
                    'HOME': os.environ['HOME']
                },
                check=True)
        except subprocess.CalledProcessError as e:
            raise ServerError(
                f'Command failed with status {e.returncode}: {shlex.join(e.cmd)}\n'
                f'For logs (may not work) run:\n{job.logs_command}')
    else:
        logger.info('🚀 Job is running. For streaming logs, run:\n%s', job.logs_command)

    os.unlink(values_filename)
    return {
        'cluster': job.cluster,
        'config': job.config_file,
        'deploy_config': job.deploy_config_file,
        'job': job.name,
        'mediawiki_container': job.app_container,
        'namespace': NAMESPACE,
        'release': job.release,
    }


def main() -> int:
    logger.setLevel(logging.INFO)
    logger.addHandler(logging.StreamHandler())

    parser = argparse.ArgumentParser(
        description="Start a MediaWiki maintenance script on Kubernetes.\n\n"
                    "Pass any options below for this script, then '--', then all remaining "
                    "arguments are passed to MWScript.php. A typical invocation looks like:\n\n"
                    "%(prog)s --comment='backfill for T123456' -- Filename.php --wiki=aawiki "
                    "--script-specific-arg\n\n"
                    "More information: https://wikitech.wikimedia.org/wiki/Maintenance_scripts",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='Print extra output from the underlying helmfile invocation. (-vv: '
                             'Include the full helmfile diff.)')
    parser.add_argument('--comment', help='Set a comment label on the Kubernetes job.')
    parser.add_argument('--mediawiki_image',
                        help='Specify a MediaWiki image (without registry), e.g. '
                             'restricted/mediawiki-multiversion:2024-08-08-135932-publish '
                             '(Default: Use the latest image built and deployed by scap)')
    parser.add_argument('--file', action='append', type=parse_filename_pair,
                        help="Copy a text file into the MediaWiki container (in the script's "
                             "working directory) to be used as script input. Format: "
                             "path/to/local-file.txt[:remote-file.txt] -- omit colon section to "
                             "use the same filename (with any leading path stripped). Pass --file "
                             "again to copy multiple files.")
    parser.add_argument('--timeout', type=parse_duration,
                        help='Set a deadline for the job, to interrupt it after a set interval. '
                             'Examples: 1d, 2h, 30m, 40s, 40 -- number without unit is in seconds. '
                             '(Default: No deadline)')
    parser.add_argument('-o', '--output', choices=['none', 'json'], default='none',
                        help='Machine-readable output on stdout, in addition to normal logging on '
                             'stderr. Options other than "none" are incompatible with --attach, '
                             '--follow, and --verbose due to conflicting use of stdout. (Default: '
                             'none)')
    # Allow overriding the default helmfile. This should only be needed for development of the
    # mw-script infrastructure, and not by users of maintenance scripts.
    parser.add_argument(
        '--helmfile', help=argparse.SUPPRESS,
        default=f'/srv/deployment-charts/helmfile.d/services/{NAMESPACE}/helmfile.yaml')

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

    try:
        # Catch duplicate remote names like "--file input1:input --file input2:input", or even
        # "--file dir1/input --file dir2/input". If this were allowed, the second "input" would
        # clobber the first.
        if args.file:
            remote_names = collections.Counter(remote_name for remote_name, f in args.file)
            duplicates = ', '.join(remote_name for remote_name, n in remote_names.items() if n > 1)
            if duplicates:
                raise ClientError(f'Duplicate remote filenames for --file: {duplicates}')

        if args.output != 'none':
            if args.attach:
                raise ClientError(f'--output={args.output} cannot be passed with --attach.')
            elif args.follow:
                raise ClientError(f'--output={args.output} cannot be passed with --follow.')
            elif args.verbose:
                raise ClientError(f'--output={args.output} cannot be passed with --verbose.')

        job_info = start(args)
    except (ServerError, ClientError) as e:
        logger.critical(f'{e.icon}️ {e}')
        if args.output == 'json':
            print(json.dumps(
                {
                    'error': str(e),
                    'mwscript': None
                },
                indent=4))
        return 1
    if args.output == 'json':
        print(json.dumps(
            {
                'error': None,
                'mwscript': job_info,
            },
            indent=4))
    return 0


if __name__ == '__main__':
    sys.exit(main())
