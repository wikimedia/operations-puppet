# Class: profile::druid::overlord
#
class profile::druid::overlord(
    $properties         = hiera('profile::druid::overlord::properties'),
    $env                = hiera('profile::druid::overlord::env'),
    $monitoring_enabled = hiera('profile::druid::monitoring_enabled'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
    $ferm_srange        = hiera('profile::druid::ferm_srange'),
) {

    require ::profile::druid::common

    # Druid overlord Service
    class { '::druid::overlord':
        properties       => $properties,
        env              => $env,
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-overlord':
        proto  => 'tcp',
        port   => $::druid::overlord::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-overlord':
            description  => 'Druid overlord',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server overlord\'',
            critical     => false,
        }
    }
}
