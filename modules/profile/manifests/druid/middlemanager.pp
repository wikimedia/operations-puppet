# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::middlemanager
#
class profile::druid::middlemanager(
    Hash[String, Any] $properties = lookup('profile::druid::middlemanager::properties', {'default_value' => {}}),
    Hash[String, String] $env     = lookup('profile::druid::middlemanager::env', {'default_value' => {}}),
    Boolean $daemon_autoreload    = lookup('profile::druid::daemons_autoreload', {'default_value' => true}),
    String $ferm_srange           = lookup('profile::druid::ferm_srange', {'default_value' => '$DOMAIN_NETWORKS'}),
    Boolean $monitoring_enabled   = lookup('profile::druid::middlemanager::monitoring_enabled', {'default_value' => false}),
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

    $class_prefix = 'org.apache.druid'

    # Druid middlemanager Service
    class { '::druid::middlemanager':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
        logger_prefix    => $class_prefix,
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
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'${class_prefix}.cli.Main server middleManager\'",
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
