# == Class profile::druid::worker
# Installs the druid daemons and configures them. This includes firewalling
# and optional monitoring/alarming.
#
class profile::druid::worker(
    $daemon_autoreload = hiera('profile::druid::worker::autoreload'),
    $ferm_srange       = hiera('profile::druid::worker::ferm_srange'),
    $monitor_enabled   = hiera('profile::druid::worker::monitor_enabled'),
) {
    # Druid Broker Service
    class { '::druid::broker':
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-broker':
        proto  => 'tcp',
        port   => $::druid::broker::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    # Druid Coordinator Service
    class { '::druid::coordinator':
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-coordinator':
        proto  => 'tcp',
        port   => $::druid::coordinator::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    # Druid Historical Service
    class { '::druid::historical':
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-historical':
        proto  => 'tcp',
        port   => $::druid::historical::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    # Druid MiddleManager Indexing Service
    class { '::druid::middlemanager':
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-middlemanager':
        proto  => 'tcp',
        port   => $::druid::middlemanager::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    # Allow incoming connections to druid.indexer.runner.startPort + 900
    $peon_start_port = $::druid::middlemanager::runtime_properties['druid.indexer.runner.startPort']
    $peon_end_port   = $::druid::middlemanager::runtime_properties['druid.indexer.runner.startPort'] + 900
    ferm::service { 'druid-middlemanager-indexer-task':
        proto  => 'tcp',
        port   => "${peon_start_port}:${peon_end_port}",
        srange => $ferm_srange,
    }

    # Druid Overlord Indexing Service
    class { '::druid::overlord':
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-overlord':
        proto  => 'tcp',
        port   => $::druid::overlord::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitor_enabled {
        nrpe::monitor_service { 'druid-broker':
            description  => 'Druid broker',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server broker\'',
            critical     => false,
        }

        nrpe::monitor_service { 'druid-coordinator':
            description  => 'Druid coordinator',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server coordinator\'',
            critical     => false,
        }

        nrpe::monitor_service { 'druid-historical':
            description  => 'Druid historical',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server historical\'',
            critical     => false,
        }

        # Special case for the middlemanager daemon: its correspondent Java
        # process name is 'middleManager'
        nrpe::monitor_service { 'druid-middlemanager':
            description  => 'Druid middlemanager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server middleManager\'',
            critical     => false,
        }

        nrpe::monitor_service { 'druid-overlord':
            description  => 'Druid overlord',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server overlord\'',
            critical     => false,
        }
    }
}