#!/bin/bash

#
# jupyterhub-singleuser-cond-env
# Launches jupyterhub-singleuser from the provided conda environment path.
# If __NEW__ is provided, a new stacked conda env will be created from
# CONDA_BASE_ENV_PATH.
#

set -e

# conda env should ALWAYS be provided as $1
CONDA_ENV_PATH="${1}"
if [ -z "${CONDA_ENV_PATH}" ]; then
    echo "Must provide path of conda env to activate."
    exit 1
fi
if [ ! -e ${CONDA_ENV_PATH} -a ${CONDA_ENV_PATH} != '__NEW__' ]; then
    echo "Cannot start jupyterhub-singleruser sourced from ${CONDA_ENV_PATH}.  It does not exist."
    exit 1
fi
shift
# The remaining arguments should be passed to jupyterhub-singleuser directly.
jupyterhub_singleuser_args=$@
shift $#

if [ "${CONDA_ENV_PATH}" == '__NEW__' ]; then
    # Set CONDA_BASE_ENV_PATH to another directory if you don't want to use the default.
    : ${CONDA_BASE_ENV_PATH:=/usr/lib/anaconda-wmf}

    if [ ! -e "${CONDA_BASE_ENV_PATH}" ]; then
        echo "Cannot create new stacked conda env.  No base conda env exists at ${CONDA_BASE_ENV_PATH}."
        exit 1
    fi
        if [ ! -e "${CONDA_BASE_ENV_PATH}/bin/conda-create-stacked" ]; then
        echo "Cannot create new stacked conda env. ${CONDA_BASE_ENV_PATH} is not a base environment; no bin/conda-create-stacked exists."
        exit 1
    fi

    # Create a new stacked conda environment. We source the script rather than running it
    # so we can more easily determine the path of the newly created conda env.
    # conda-create-stacked sets a bunch of variables, including the one we need:
    # CONDA_STACKED_ENV_PATH.
    source "${CONDA_BASE_ENV_PATH}"/bin/conda-create-stacked
    CONDA_ENV_PATH="${CONDA_STACKED_ENV_PATH}"
fi

# Make sure juptyerhub-singleuser is installed in the conda env.
if [ ! -e ${CONDA_ENV_PATH}/bin/jupyterhub-singleuser ]; then
    echo "Cannot launch jupyterhub-singleuser from ${CONDA_ENV_PATH}; it is not installed there."
    exit 1;
fi

# conda-create-stacked will create an bin/activate in the stacked environment that will
# do the right thing. If CONDA_ENV_PATH is a base or regular (non stacked) conda env,
# the bin/activate script will be conda's default (non stacked) one.
# In either case, we can source bin/activate.
source ${CONDA_ENV_PATH}/bin/activate

# Start jupyterhub-singleuser from the conda env.
${CONDA_ENV_PATH}/bin/jupyterhub-singleuser $jupyterhub_singleuser_args
