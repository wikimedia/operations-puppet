# Class: profile::druid::coordinator
#
class profile::druid::coordinator(
    $properties  = hiera('profile::druid::coordinator::properties'),
    $env         = hiera('profile::druid::coordinator::env'),
) {
    require ::profile::druid::common

    # Druid coordinator Service
    class { '::druid::coordinator':
        properties       => $properties,
        env              => $env,
        should_subscribe => $::profile::druid::common::daemon_autoreload,
    }

    ferm::service { 'druid-coordinator':
        proto  => 'tcp',
        port   => $::druid::coordinator::runtime_properties['druid.port'],
        srange => $::profile::druid::common::ferm_srange,
    }

    if $::profile::druid::common::monitoring_enabled {
        nrpe::monitor_service { 'druid-coordinator':
            description  => 'Druid coordinator',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server coordinator\'',
            critical     => false,
        }
    }
}
