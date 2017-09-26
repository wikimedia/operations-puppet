# Class: profile::druid::overlord
#
class profile::druid::overlord(
    $properties  = hiera('profile::druid::overlord::properties'),
    $env         = hiera('profile::druid::overlord::env'),
) {
    require ::profile::druid::common

    # Druid overlord Service
    class { '::druid::overlord':
        properties       => $properties,
        env              => $env,
        should_subscribe => $::profile::druid::common::daemon_autoreload,
    }

    ferm::service { 'druid-overlord':
        proto  => 'tcp',
        port   => $::druid::overlord::runtime_properties['druid.port'],
        srange => $::profile::druid::common::ferm_srange,
    }

    if $::profile::druid::common::monitoring_enabled {
        nrpe::monitor_service { 'druid-overlord':
            description  => 'Druid overlord',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server overlord\'',
            critical     => false,
        }
    }
}
