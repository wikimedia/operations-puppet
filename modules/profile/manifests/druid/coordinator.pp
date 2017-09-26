# Class: profile::druid::coordinator
#
class profile::druid::coordinator(
    $properties         = hiera('profile::druid::coordinator::properties'),
    $env                = hiera('profile::druid::coordinator::env'),
    $monitoring_enabled = hiera('profile::druid::monitoring_enabled'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
    $ferm_srange        = hiera('profile::druid::ferm_srange'),
) {

    # Druid coordinator Service
    class { '::druid::coordinator':
        properties       => $properties,
        env              => $env,
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-coordinator':
        proto  => 'tcp',
        port   => $::druid::coordinator::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-coordinator':
            description  => 'Druid coordinator',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server coordinator\'',
            critical     => false,
        }
    }
}
