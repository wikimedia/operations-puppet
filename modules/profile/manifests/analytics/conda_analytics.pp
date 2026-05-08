# SPDX-License-Identifier: Apache-2.0

# Class: profile::analytics::conda_analytics
#
# Includes the conda-analytics .deb package
# [*ensure*]
#   This parameter determines whether or not to install the conda-analytics-package.
#
# [*ensure_next*]
#   This parameter determines whether or not to install the conda-analytics-next
#   package, which allows for the concurrent installation of two environments.
#   The intention is that the -next package should be available to help with the
#   migration of workload from one spark version to another.
#
# [*remove_conda_env_pkgs_dir*]
#   This option is used to delete the conda pkgs directory when installing the deb
#   package. This pkgs dir is used when cloning the environment. So, It's only
#   used on statboxes and launchers.
#   Default: true
#
class profile::analytics::conda_analytics (
    Wmflib::Ensure $ensure             = lookup('profile::analytics::conda_analytics::ensure', {'default_value' => 'present'}),
    Wmflib::Ensure $ensure_next        = lookup('profile::analytics::conda_analytics::ensure_next', {'default_value' => 'absent'}),
    Boolean $remove_conda_env_pkgs_dir = lookup('profile::analytics::conda_analytics::remove_conda_env_pkgs_dir', {'default_value' => true})
) {
    class { 'conda_analytics':
        ensure                    => $ensure,
        ensure_next               => $ensure_next,
        remove_conda_env_pkgs_dir => $remove_conda_env_pkgs_dir,
    }
}
