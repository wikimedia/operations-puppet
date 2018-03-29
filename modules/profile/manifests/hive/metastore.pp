# == Class profile::hive::metastore
#
# Sets up Hive Metastore service
#
class profile::hive::metastore(
    $monitoring_enabled = hiera('profile::hive::metastore::monitoring_enabled', false),
    $ferm_srange        = hiera('profile::hive::metastore::ferm_srange', '$DOMAIN_NETWORKS'),
) {

    require ::profile::hive::client

    # Setup hive-metastore
    class { '::cdh::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        require ::profile::hive::monitoring::metastore

        nrpe::monitor_service { 'hive-metasore':
            description   => 'Hive Metastore',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hive.metastore.HiveMetaStore"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::metastore'],
        }
    }
}
