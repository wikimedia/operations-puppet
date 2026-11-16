#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
#
# Settings for the single-user servers of the jupyter-analytics JupyterHub.
# jupyterhub-singleuser.sh puts the directory of this file in JUPYTER_CONFIG_PATH,
# so other Jupyter servers on the host do not read it.

import os

from nb_conda_kernels import CondaKernelSpecManager
from nb_conda_kernels.manager import RUNNER_COMMAND

c = get_config()  # noqa: F821

CONDA_KERNEL_LAUNCHER = os.environ.get(
    'JUPYTER_CONDA_KERNEL_LAUNCHER', '/etc/jupyterhub/conda_kernel_launcher.sh'
)


class WMFCondaKernelSpecManager(CondaKernelSpecManager):
    """Start the conda kernels with conda_kernel_launcher.sh.

    The runner of nb_conda_kernels sources <conda root>/bin/activate with the
    environment as an argument. In conda-analytics, conda-pack supplies that script.
    It ignores the argument and activates the base environment.
    """

    def _all_specs(self):
        specs = super()._all_specs()
        n = len(RUNNER_COMMAND)
        for spec in specs.values():
            argv = spec['argv']
            # argv is RUNNER_COMMAND + [conda root, environment] + kernel command.
            if argv[:n] == RUNNER_COMMAND:
                spec['argv'] = [CONDA_KERNEL_LAUNCHER] + argv[n + 1:]
        return specs


# Offer the conda environments of the user as kernels.
c.ServerApp.kernel_spec_manager_class = WMFCondaKernelSpecManager

# Do not offer the base environments. Users cannot install packages into them.
c.CondaKernelSpecManager.env_filter = (
    r'^/opt/(conda-analytics|conda-analytics-next|jupyter-analytics)$'
)

# Do not offer the python of the server environment as a kernel.
c.CondaKernelSpecManager.ensure_native_kernel = False

# Start terminals as interactive non-login shells, so that /etc/profile does not
# change the environment again. terminal_bashrc activates the chosen conda environment.
c.ServerApp.terminado_settings = {
    'shell_command': [
        '/bin/bash', '--rcfile',
        os.environ.get('JUPYTER_TERMINAL_BASHRC', '/etc/jupyterhub/terminal_bashrc'),
    ],
}
