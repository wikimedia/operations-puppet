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

    # Include icinga alerts if production realm.
    if $monitoring_enabled {

        nrpe::monitor_service { 'hive-metasore':
            description   => 'Hive Metastore',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hive.metastore.HiveMetaStore"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hive::metastore'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hive',
        }
    }
}
