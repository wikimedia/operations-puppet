# Class: profile::druid::middlemanager
#
class profile::druid::middlemanager(
    $properties         = hiera('profile::druid::middlemanager::properties', {}),
    $env                = hiera('profile::druid::middlemanager::env', {}),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload', true),
    $ferm_srange        = hiera('profile::druid::ferm_srange', '$DOMAIN_NETWORKS'),
    $monitoring_enabled = hiera('profile::druid::middlemanager::monitoring_enabled', false),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::middlemanager
        $java_opts = $::profile::druid::monitoring::middlemanager::java_opts

        if $env['DRUID_EXTRA_JVM_OPTS'] {
            $monitoring_env_vars = {
                'DRUID_EXTRA_JVM_OPTS' => "${env['DRUID_EXTRA_JVM_OPTS']} ${java_opts}"
            }
        } else {
            $monitoring_env_vars = {
                'DRUID_EXTRA_JVM_OPTS' => $java_opts
            }
        }
    } else {
        $monitoring_env_vars = {}
    }

    # Druid middlemanager Service
    class { '::druid::middlemanager':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
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

    if $monitoring_enabled {
        # Special case for the middlemanager daemon: its correspondent Java
        # process name is 'middleManager'
        nrpe::monitor_service { 'druid-middlemanager':
            description  => 'Druid middlemanager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server middleManager\'',
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
