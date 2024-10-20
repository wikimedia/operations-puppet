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
import shlex
import string
import subprocess
import sys
import tempfile

import yaml
from conftool.cli import ConftoolClient
from kubernetes import client, config, watch
from kubernetes.client.models.v1_pod import V1Pod
from wmflib import interactive

logger = logging.Logger(__name__)

NAMESPACE = 'mw-script'


class ClientError(Exception):
    """Something went wrong on our end; incorrect invocation or config. Think 4xx."""
    icon = '🚩'


class ServerError(Exception):
    """Something went wrong beyond this wrapper; local subcommand failure, API error. Think 5xx."""
    icon = '☠️'


def config_file(namespace: str, cluster: str, deploy: bool = False) -> str:
    if deploy:
        namespace += '-deploy'
    return f'/etc/kubernetes/{namespace}-{cluster}.config'


def kube_env(namespace: str, cluster: str, deploy: bool = False) -> dict[str, str]:
    # Duplicates the functionality of modules/profile/files/kubernetes/kube-env.sh.
    return {
        'K8S_CLUSTER': cluster,
        'KUBECONFIG': config_file(namespace, cluster, deploy),
    }


def job_name(namespace: str, cluster: str, release: str) -> str:
    # Duplicates the functionality of mw.name.namespace.env.release in the Helm chart.
    return f'{namespace}.{cluster}.{release}'


def get_primary_dc() -> str:
    ct = ConftoolClient(configfile='/etc/conftool/config.yaml',
                        schemafile='/etc/conftool/schema.yaml')
    mwconfig = ct.get('mwconfig')
    return mwconfig('common', 'WMFMasterDatacenter').val


def app_container(release: str) -> str:
    # Duplicates the name in the Helm chart (based on base.name.release).
    return f'mediawiki-{release}-app'


def mediawiki_image(cluster: str) -> str:
    # Find out what multiversion image is in use by mw-web, and use the same one.
    kube_config = config.load_kube_config(config_file=config_file('mw-web', cluster))
    apps_client = client.AppsV1Api(client.ApiClient(kube_config))
    deployment_name = f'mw-web.{cluster}.main'
    deployment = apps_client.read_namespaced_deployment(name=deployment_name, namespace='mw-web')
    container_name = app_container('main')
    containers = [container for container in deployment.spec.template.spec.containers
                  if container.name == container_name]
    if not containers:
        raise ValueError(
            f'Container {container_name} not found in the {deployment_name} deployment template')
    [container] = containers
    return container.image.removeprefix('docker-registry.discovery.wmnet/')


def check_config_file(namespace: str, cluster: str) -> None:
    # Make sure we can open the kubernetes config file. If not, either the namespace/cluster are
    # wrong or we're not in the appropriate usergroup.
    try:
        with open(config_file(namespace, cluster), 'r'):
            pass
    except PermissionError as e:
        stat = os.stat(e.filename)
        group = grp.getgrgid(stat.st_gid).gr_name
        is_group_readable = stat.st_mode & 0o200
        if group == 'root' or not is_group_readable:
            raise ClientError(f"You don't have permission to read the Kubernetes config file "
                              f"{e.filename} (try sudo)")
        else:
            raise ClientError(f"You don't have permission to read the Kubernetes config file "
                              f"{e.filename} (are you in the {group} group?)")
    except FileNotFoundError as e:
        if not glob.glob(f'/etc/kubernetes/*-{glob.escape(cluster)}.config'):
            raise ClientError(f'Kubernetes config file {e.filename} not found: there is no '
                              f'cluster {cluster}.')
        elif not glob.glob(f'/etc/kubernetes/{glob.escape(NAMESPACE)}-*.config'):
            raise ClientError(f'Kubernetes config file {e.filename} not found: there is no '
                              f'namespace {NAMESPACE}.')
        else:
            raise ClientError(f'Kubernetes config file {e.filename} not found: namespace '
                              f'{NAMESPACE} is not configured in cluster {cluster}.')


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


def wait_until_started(env_vars: dict[str, str], job: str, container: str) -> None:
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


def logs_command(env_vars: dict[str, str], release: str) -> str:
    env_vars_str = ' '.join(f'{key}={value}' for key, value in env_vars.items())
    job = job_name(NAMESPACE, env_vars['K8S_CLUSTER'], release)
    return f'{env_vars_str} kubectl logs -f job/{job} {app_container(release)}'


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


def start(args: argparse.Namespace) -> dict[str, str]:
    environment = get_primary_dc()
    # If we can't open the config, bail out with a clear error message, instead of running helmfile.
    check_config_file(NAMESPACE, environment)

    # Since mwscript.args is a list, passing it on the helmfile command line would get into some
    # messy escaping. Instead, we'll write it to a values file, and pass that *path* to helmfile. As
    # long as we're doing that, we'll set all these values that way.
    values = {
        # For normal deployments, this value is managed by scap. For scripts, we'll use the image
        # currently used in the mw-web deployment (except when overridden by command-line flag).
        'main_app': {
            'image': args.mediawiki_image if args.mediawiki_image else mediawiki_image(environment),
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
            'activeDeadlineSeconds': args.timeout,
            'tty': args.attach and sys.stdin.isatty(),
        }
    }
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        yaml.dump(values, f)
        values_filename = f.name

    release = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    job = job_name(NAMESPACE, environment, release)
    logger.info('⏳ Starting %s on Kubernetes as job %s ...', args.script_name, job)
    try:
        subprocess.run([
            '/usr/bin/helmfile',
            *(['--quiet'] if not args.verbose else []),
            '--file', args.helmfile,
            '--environment', environment,
            # As of this writing, we don't need a selector because this is the only thing in the
            # helmfile. But it's included anyway, for futureproofing.
            '--selector', f'name={release}',
            'apply',
            '--values', values_filename,
            *(['--suppress-diff'] if args.verbose < 2 else []),
            ],
            env={
                'PATH': os.environ['PATH'],  # Our helmfiles use an unqualified path for helmBinary.
                'HELM_CACHE_HOME': '/var/cache/helm',  # Use the shared cache.
                'HELM_CONFIG_HOME': '/etc/helm',  # Needed for helm chart repos etc.
                'HELM_DATA_HOME': '/usr/share/helm',  # Needed for helm-diff.
                'RELEASE_NAME': release,  # Consumed by the helmfile template.
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

    container = app_container(release)
    env_vars = kube_env(NAMESPACE, environment)
    if args.follow:
        wait_until_started(env_vars, job, container)
        logger.info('📜 Streaming logs:')
        try:
            # When shelling out to kubectl, we pass $HOME through so that it finds (or creates)
            # .kube/cache there, instead of dropping it rudely into $PWD.
            subprocess.run(['/usr/bin/kubectl', 'logs', '-f', f'job/{job}', container],
                           env={**env_vars, 'HOME': os.environ['HOME']})
        except subprocess.CalledProcessError as e:
            raise ServerError(f'Command failed with status {e.returncode}: {shlex.join(e.cmd)}')
        except KeyboardInterrupt:
            logger.info('🔁 To resume streaming logs, run:\n%s', logs_command(env_vars, release))
    elif args.attach:
        wait_until_started(env_vars, job, container)
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
                f'job/{job}',
                '--container', container,
                '-it' if sys.stdin.isatty() else '-i'
                ],
                env={
                    # Switch from the read-only user to the deploy user, which has privileges to
                    # attach.
                    **kube_env(NAMESPACE, environment, deploy=True),
                    'HOME': os.environ['HOME']
                },
                check=True)
        except subprocess.CalledProcessError as e:
            raise ServerError(
                f'Command failed with status {e.returncode}: {shlex.join(e.cmd)}\n'
                f'For logs (may not work) run:\n{logs_command(env_vars, release)}')
    else:
        logger.info('🚀 Job is running. For streaming logs, run:\n%s',
                    logs_command(env_vars, release))

    os.unlink(values_filename)
    return {
        'cluster': env_vars['K8S_CLUSTER'],
        'config': env_vars['KUBECONFIG'],
        'deploy_config': config_file(NAMESPACE, environment, deploy=True),
        'job': job,
        'mediawiki_container': container,
        'namespace': NAMESPACE,
    }


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
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='Print extra output from the underlying helmfile invocation. (-vv: '
                             'Include the full helmfile diff.)')
    parser.add_argument('--comment', help='Set a comment label on the Kubernetes job.')
    parser.add_argument('--mediawiki_image',
                        help='Specify a MediaWiki image (without registry), e.g. '
                             'restricted/mediawiki-multiversion:2024-08-08-135932-publish '
                             '(Default: Use the same image as mw-web)')
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
