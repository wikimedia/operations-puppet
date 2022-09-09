# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::coordinator
#
# NOTE that most Druid service profiles default ferm_srange
# to profile::druid::ferm_srange, but coordinator
# defaults to profile::druid::coordinato::ferm_srange, to
# haver finer control over how Druid accepts queries.
#
class profile::druid::coordinator(
    Hash[String, Any] $properties = lookup('profile::druid::coordinator::properties', {'default_value' => {}}),
    Hash[String, String] $env     = lookup('profile::druid::coordinator::env', {'default_value' => {}}),
    Boolean $daemon_autoreload    = lookup('profile::druid::daemons_autoreload', {'default_value' => true}),
    String $ferm_srange           = lookup('profile::druid::coordinator::ferm_srange', {'default_value' => '$DOMAIN_NETWORKS'}),
    Boolean $monitoring_enabled   = lookup('profile::druid::coordinator::monitoring_enabled', {'default_value' => false}),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::coordinator
        $java_opts = $::profile::druid::monitoring::coordinator::java_opts

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

    # Druid coordinator Service
    class { '::druid::coordinator':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
        logger_prefix    => $class_prefix,
    }

    ferm::service { 'druid-coordinator':
        proto  => 'tcp',
        port   => $::druid::coordinator::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-coordinator':
            description  => 'Druid coordinator',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'${class_prefix}.cli.Main server coordinator\'",
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
