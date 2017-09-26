# Class: profile::druid::middlemanager
#
class profile::druid::middlemanager(
    $properties  = hiera('profile::druid::middlemanager::properties'),
    $env         = hiera('profile::druid::middlemanager::env'),
) {
    require ::profile::druid::common

    # Druid middlemanager Service
    class { '::druid::middlemanager':
        properties       => $properties,
        env              => $env,
        should_subscribe => $::profile::druid::common::daemon_autoreload,
    }

    ferm::service { 'druid-middlemanager':
        proto  => 'tcp',
        port   => $::druid::middlemanager::runtime_properties['druid.port'],
        srange => $::profile::druid::common::ferm_srange,
    }

    # Allow incoming connections to druid.indexer.runner.startPort + 900
    $peon_start_port = $::druid::middlemanager::runtime_properties['druid.indexer.runner.startPort']
    $peon_end_port   = $::druid::middlemanager::runtime_properties['druid.indexer.runner.startPort'] + 900
    ferm::service { 'druid-middlemanager-indexer-task':
        proto  => 'tcp',
        port   => "${peon_start_port}:${peon_end_port}",
        srange => $ferm_srange,
    }

    if $::profile::druid::common::monitoring_enabled {
        # Special case for the middlemanager daemon: its correspondent Java
        # process name is 'middleManager'
        nrpe::monitor_service { 'druid-middlemanager':
            description  => 'Druid middlemanager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server middleManager\'',
            critical     => false,
        }
    }
}
