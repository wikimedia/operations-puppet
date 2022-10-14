# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::base
#
class profile::statistics::base(
    $statistics_servers = lookup('statistics_servers'),
    $enable_stat_host_addons = lookup('profile::statistics::base::enable_stat_host_addons', { 'default_value' => true}),
    $mysql_credentials_group = lookup('profile::statistics::base::mysql_credentials_group', { 'default_value' => undef}),
) {

    require ::profile::analytics::cluster::packages::statistics
    require ::profile::analytics::cluster::repositories::statistics

    include ::profile::analytics::cluster::gitconfig

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    class { 'statistics::compute':
        enable_stat_host_addons => $enable_stat_host_addons,
        mysql_credentials_group => $mysql_credentials_group,
    }
}
