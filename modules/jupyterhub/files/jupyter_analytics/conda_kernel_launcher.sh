#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
#
# Starts a Jupyter kernel in a conda environment. jupyter_server_config.py makes
# the conda kernels use this script.
# The first argument is the prefix of the conda environment.
# The other arguments are the command of the kernel.

set -e

CONDA_ENV_PREFIX="${1:?Give the prefix of a conda environment.}"
shift

# The settings of the single-user server are not for the kernels.
unset JUPYTER_CONFIG_PATH

source "${CONDA_BASE_ENV_PREFIX:-/opt/conda-analytics}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_PREFIX}"

exec "$@"
