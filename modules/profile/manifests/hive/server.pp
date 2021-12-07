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

    # Include icinga alerts if production realm.
    if $monitoring_enabled {

        nrpe::monitor_service { 'hive-server2':
            description   => 'Hive Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hive.service.server.HiveServer2"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hive::server'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hive',
        }
    }
}
