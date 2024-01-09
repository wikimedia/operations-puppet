#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""Start a MediaWiki maintenance script on Kubernetes."""
import argparse
import glob
import grp
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
from wmflib import interactive

logger = logging.Logger(__name__)

LAST_BUILD_PATH = '/srv/mwbuilder/release/make-container-image/last-build'
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
    with open(LAST_BUILD_PATH) as f:
        last_build = f.read().strip()

    prefix = 'docker-registry.discovery.wmnet/'
    if not last_build.startswith(prefix):
        raise ValueError(f'Unexpected value "{last_build}" in {LAST_BUILD_PATH}')
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


def main() -> int:
    logger.setLevel(logging.INFO)
    logger.addHandler(logging.StreamHandler())

    # We set allow_abbrev to False to limit the chance that parse_known_args eats something intended
    # for MWScript.php, or for the maintenance script itself.
    parser = argparse.ArgumentParser(
        allow_abbrev=False,
        description="Start a MediaWiki maintenance script on Kubernetes.\n\n"
                    "After the options listed below are stripped out, the remainder of argv is "
                    "passed to MWScript.php. A typical invocation looks like:\n\n"
                    "%(prog)s Filename.php --wiki=aawiki --script-specific-arg")
    parser.add_argument('-v', '--verbose',
                        help='Print extra output from the underlying helmfile invocation.')
    args, mwscript_args = parser.parse_known_args()
    script_name = mwscript_args[0]

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
            'args': mwscript_args,
            'labels:': {
                'username': interactive.get_username(),
                'script': script_name,
            }
        }
    }
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        yaml.dump(values, f)
        values_filename = f.name

    logger.info('⏳ Starting %s on Kubernetes...', script_name)
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

    # TODO: Add an --attach flag and if passed, shell out to kubectl attach here instead
    env_vars = kube_env(NAMESPACE, environment)
    env_vars_str = ' '.join(f'{key}={value}' for key, value in env_vars.items())
    job = job_name(NAMESPACE, environment, release)
    logger.info('🚀 Job is running. For streaming logs, run:\n'
                '%s kubectl logs -f job/%s mediawiki-%s-app',
                env_vars_str, job, release)

    os.unlink(values_filename)
    return 0


if __name__ == '__main__':
    sys.exit(main())
