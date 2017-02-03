# == Class role::analytics_cluster::hive::server
# Sets up Hive Server2
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hive::server {
    system::role { 'analytics_cluster::hive::server':
        description => 'hive-server2 service',
    }
    require ::role::analytics_cluster::hive::client

    # Setup hive-server
    class { '::cdh::hive::server': }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => '$ANALYTICS_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        nrpe::monitor_service { 'hive-server2':
            description   => 'Hive Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hive.service.server.HiveServer2"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::server'],
        }
    }
}
