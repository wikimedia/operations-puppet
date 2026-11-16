#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
#
# Starts jupyterhub-singleuser from the jupyter-analytics environment.
# The first argument is the prefix of the conda environment that the user chose.
# If it is __NEW__, this script clones a new conda environment from conda-analytics first.
# All other arguments go to jupyterhub-singleuser.

set -e

CONDA_ENV_PREFIX="${1:?Give the prefix of a conda environment, or __NEW__.}"
shift

: "${CONDA_BASE_ENV_PREFIX:=/opt/conda-analytics}"
: "${JUPYTER_ENV_PREFIX:=/opt/jupyter-analytics}"
: "${JUPYTER_SERVER_CONFIG_DIR:=/etc/jupyterhub/server_config}"

if [ "${CONDA_ENV_PREFIX}" == '__NEW__' ]; then
    # Source the clone script to get CONDA_NEW_ENV_PREFIX. Give it an empty argument,
    # so that it uses its default environment name and not the arguments of this script.
    source /usr/bin/conda-analytics-clone ''
    # The clone script disables errexit at its end.
    set -e
    CONDA_ENV_PREFIX="${CONDA_NEW_ENV_PREFIX}"
fi

server_args=()
if [ -x "${CONDA_ENV_PREFIX}/bin/python" ]; then
    # Ask nb_conda_kernels for the name of the python kernel of the chosen environment.
    default_kernel=$("${JUPYTER_ENV_PREFIX}/bin/python" \
        "$(dirname "$0")/default_kernel_name.py" "${CONDA_ENV_PREFIX}") || default_kernel=''
    if [ -n "${default_kernel}" ]; then
        server_args+=("--MappingKernelManager.default_kernel_name=${default_kernel}")
    else
        echo "Warning: Cannot find the kernel of ${CONDA_ENV_PREFIX}. Starting without a default kernel." >&2
    fi
    # terminal_bashrc activates this environment.
    export JUPYTER_TERMINAL_CONDA_ENV="${CONDA_ENV_PREFIX}"
else
    echo "Warning: ${CONDA_ENV_PREFIX} has no python. Starting without a default kernel." >&2
fi

# Add our settings to the search path for Jupyter configuration files. The settings
# of the user in ~/.jupyter have a higher priority. terminal_bashrc removes this variable.
export JUPYTER_CONFIG_PATH="${JUPYTER_SERVER_CONFIG_DIR}"

exec "${JUPYTER_ENV_PREFIX}/bin/jupyterhub-singleuser" "${server_args[@]}" "$@"
