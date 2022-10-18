#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

#
# jupyterhub-singleuser-cond-env
# Launches jupyterhub-singleuser from the provided conda environment path.
# If __NEW__ is provided, a new cloned conda env will be created from
# CONDA_BASE_ENV_PREFIX.
#

set -e

# conda env should ALWAYS be provided as $1
CONDA_ENV_PREFIX="${1}"
if [ -z "${CONDA_ENV_PREFIX}" ]; then
    echo "Must provide path of conda env to activate."
    exit 1
fi
if [ ! -e "${CONDA_ENV_PREFIX}" -a "${CONDA_ENV_PREFIX}" != '__NEW__' ]; then
    echo "Cannot start jupyterhub-singleruser sourced from ${CONDA_ENV_PREFIX}.  It does not exist."
    exit 1
fi
shift
# The remaining arguments should be passed to jupyterhub-singleuser directly.
jupyterhub_singleuser_args=$@
shift $#

# Set CONDA_BASE_ENV_PREFIX to another directory if you don't want to use the default, or when testing.
: "${CONDA_BASE_ENV_PREFIX:=/opt/conda-analytics}"

if [ "${CONDA_ENV_PREFIX}" == '__NEW__' ]; then
    if [ ! -e "${CONDA_BASE_ENV_PREFIX}" ]; then
        echo "Cannot create new stacked conda env.  No base conda env exists at ${CONDA_BASE_ENV_PREFIX}."
        exit 1
    fi

    # Source this script rather than running it so that as side effect we get
    # CONDA_NEW_ENV_PREFIX and CONDA_NEW_ENV_NAME
    source /usr/bin/conda-analytics-clone
    CONDA_ENV_PREFIX="${CONDA_NEW_ENV_PREFIX}"
    CONDA_ENV_NAME="${CONDA_NEW_ENV_NAME}"
fi

# Make sure juptyerhub-singleuser is installed in the conda env.
if [ ! -e "${CONDA_ENV_PREFIX}"/bin/jupyterhub-singleuser ]; then
    echo "Cannot launch jupyterhub-singleuser from ${CONDA_ENV_PREFIX}; it is not installed there."
    exit 1;
fi

# if not a new env, we need to figure the conda env name
: "${CONDA_ENV_NAME:=$(basename "${CONDA_ENV_PREFIX}")}"

# activate the conda env.
source ${CONDA_BASE_ENV_PREFIX}/etc/profile.d/conda.sh
conda activate "${CONDA_ENV_NAME}"

# Start jupyterhub-singleuser from the conda env.
"${CONDA_ENV_PREFIX}"/bin/jupyterhub-singleuser $jupyterhub_singleuser_args
