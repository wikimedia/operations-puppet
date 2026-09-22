# SPDX-License-Identifier: Apache-2.0
# == Class profile::hive::server
#
# Sets up Hive Server2 (no metastore, needs another profile).
#
class profile::hive::server(
    Boolean $monitoring_enabled = lookup('profile::hive::server::monitoring_enabled', {default_value => false}),
    String $ferm_srange         = lookup('profile::hive::server::ferm_srange', {default_value => '$DOMAIN_NETWORKS'}),
) {
    include ::profile::hive::client

    # Setup hive-server
    class { '::bigtop::hive::server': }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => $ferm_srange,
    }

    include ::profile::hive::monitoring::server
}
