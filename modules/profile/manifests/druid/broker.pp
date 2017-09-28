# Class: profile::druid::broker
#
class profile::druid::broker(
    $properties         = hiera('profile::druid::broker::properties'),
    $env                = hiera('profile::druid::broker::env'),
    $ferm_srange        = hiera('profile::druid::broker::ferm_srange'),
    $monitoring_enabled = hiera('profile::druid::monitoring_enabled'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
) {

    require ::profile::druid::common

    # Druid Broker Service
    class { '::druid::broker':
        properties       => $properties,
        env              => $env,
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-broker':
        proto  => 'tcp',
        port   => $::druid::broker::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-broker':
            description  => 'Druid broker',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server broker\'',
            critical     => false,
        }
    }
}
