# SPDX-License-Identifier: Apache-2.0
# == Class profile::hive::metastore
#
# Sets up Hive Metastore service
#
class profile::hive::metastore(
    Boolean $monitoring_enabled = lookup('profile::hive::metastore::monitoring_enabled', {'default_value' => false}),
    String $ferm_srange         = lookup('profile::hive::metastore::ferm_srange', {'default_value' => '$DOMAIN_NETWORKS'}),
) {

    require ::profile::hive::client

    # Setup hive-metastore
    class { '::bigtop::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => $ferm_srange,
    }

    require ::profile::hive::monitoring::metastore
}
