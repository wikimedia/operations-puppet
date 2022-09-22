# SPDX-License-Identifier: Apache-2.0

# == Class conda_analytics
#
# Installs the conda-analytics.deb package.
# This package contains a conda environment with python and spark and
# other packages installed that are useful for working in the
# WMF Analytics data lake.
#
# === Parameters
#
# [*remove_conda_env_pkgs_dir*]
#   If true, a conda-analytics/remove-pkgs debconf setting will be set to true.
#   This setting is used by the conda-analytics .deb postinst step to
#   determine if the conda pkgs/ dir should be removed after installing the packages.
#   Conda pkgs/ dir is only needed if you ever plan to 'clone' the conda env, which is
#   only done on client nodes by real users.  Worker nodes can have pkgs/ removed to save space.
#   Default: true
#
class conda_analytics(
    $ensure = 'present',
    $remove_conda_env_pkgs_dir = true
) {
    package { 'conda-analytics':
        ensure => stdlib::ensure($ensure, 'package')
    }

    # This is where the conda-analytics .deb package will install the conda-analytics conda environment.
    # Set this variable here for users of this class to have a reference to this.
    $prefix = '/opt/conda-analytics'


    # TODO: Remove this conditional and use $remove_conda_env_pkgs_dir as the value of the setting.
    # For this to work, the postinst script has to be smarter and actually check or this value.
    # See: https://gitlab.wikimedia.org/repos/data-engineering/conda-analytics/-/blob/main/.gitlab-ci.yml
    if $remove_conda_env_pkgs_dir {
        debconf::set { 'conda-analytics/remove-pkgs':
            owner  => 'conda-analytics',
            type   => 'boolean',
            value  => true,
            before => Package['conda-analytics']
        }
    }
}
