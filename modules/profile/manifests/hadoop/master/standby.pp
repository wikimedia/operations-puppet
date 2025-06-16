# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::master::standby
#
# Sets up a standby/backup Hadoop Master node.
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
class profile::hadoop::master::standby(
    $cluster_name             = lookup('profile::hadoop::common::hadoop_cluster_name'),
    $monitoring_enabled       = lookup('profile::hadoop::master::standby::monitoring_enabled', { 'default_value' => false }),
    $excluded_hosts           = lookup('profile::hadoop::master::standby::excluded_hosts', { 'default_value' => [] }),
) {
    require ::profile::hadoop::common

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::namenode
        require ::profile::hadoop::monitoring::resourcemanager
    }

    class { '::bigtop::hadoop::namenode::standby':
        excluded_hosts => $excluded_hosts,
    }

    class { '::bigtop::hadoop::resourcemanager':
        excluded_hosts => $excluded_hosts,
    }

}
