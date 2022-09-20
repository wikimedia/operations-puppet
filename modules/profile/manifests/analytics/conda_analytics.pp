# SPDX-License-Identifier: Apache-2.0

# Class: profile::analytics::conda_analytics
#
# Includes the conda-analytics .deb package
#
# [*remove_conda_env_pkgs_dir*]
#   This option is used to delete the conda pkgs directory when installing the deb
#   package. This pkgs dir is used when cloning the environment. So, It's only
#   used on statboxes and launchers.
#   Default: true
class profile::analytics::conda_analytics(
    $ensure                          = lookup('profile::analytics::conda_analytics::ensure', {'default_value' => 'present'}),
    Boolean $remove_conda_env_pkgs_dir = lookup('profile::analytics::conda_analytics::remove_conda_env_pkgs_dir', {'default_value' => true})
) {
    class { 'conda_analytics':
        ensure                    => $ensure,
        remove_conda_env_pkgs_dir => $remove_conda_env_pkgs_dir
    }
}
