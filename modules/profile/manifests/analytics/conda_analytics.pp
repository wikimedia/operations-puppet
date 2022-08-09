# SPDX-License-Identifier: Apache-2.0

# Class: profile::analytics::conda_analytics
#
# Includes the conda-analytics .deb package
class profile::analytics::conda_analytics(
    $ensure = lookup('profile::analytics::conda_analytics::ensure', {'default_value' => 'present'}),
) {
    class { 'conda_analytics':
        ensure => $ensure,
    }
}
