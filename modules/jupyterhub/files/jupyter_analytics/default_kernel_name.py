#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
"""
Print the name that nb_conda_kernels gives the python kernel of a conda environment.

Usage: default_kernel_name.py CONDA_ENV_PREFIX

jupyterhub-singleuser.sh runs this script with the python of the jupyter-analytics
environment. It exits with status 1 if it does not find the kernel.
"""
import os
import sys

from nb_conda_kernels import CondaKernelSpecManager


def main():
    env_prefix = os.path.realpath(sys.argv[1])
    kernel_dir = os.path.join(env_prefix, 'share', 'jupyter', 'kernels', 'python3')
    for name, resource_dir in sorted(CondaKernelSpecManager().find_kernel_specs().items()):
        if os.path.realpath(resource_dir) == kernel_dir:
            print(name)
            return 0
    print(f'No kernel uses {kernel_dir}', file=sys.stderr)
    return 1


if __name__ == '__main__':
    sys.exit(main())
