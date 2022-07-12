# SPDX-License-Identifier: Apache-2.0

# == Class conda_analytics
#
# Installs the conda-analytics.deb package.
# This package contains a conda environment with python and spark and
# other packages installed that are useful for working in the
# WMF Analytics data lake.
#
class conda_analytics(
    $ensure = 'present'
) {
    package { 'conda-analytics':
        ensure => stdlib::ensure($ensure, 'package')
    }

    # This is where the conda-analytics .deb package will install the conda-analytics conda environment.
    # Set this variable here for users of this class to have a reference to this.
    $prefix = '/opt/conda-analytics'
}
