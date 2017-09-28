# Class: profile::druid::historical
#
class profile::druid::historical(
    $properties         = hiera('profile::druid::historical::properties'),
    $env                = hiera('profile::druid::historical::env'),
    $monitoring_enabled = hiera('profile::druid::monitoring_enabled'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
    $ferm_srange        = hiera('profile::druid::ferm_srange'),
) {

    require ::profile::druid::common

    # Druid historical Service
    class { '::druid::historical':
        properties       => $properties,
        env              => $env,
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-historical':
        proto  => 'tcp',
        port   => $::druid::historical::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-historical':
            description  => 'Druid historical',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server historical\'',
            critical     => false,
        }
    }
}
