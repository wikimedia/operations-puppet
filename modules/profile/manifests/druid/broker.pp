# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::broker
#
# NOTE that most Druid service profiles default ferm_srange
# to profile::druid::ferm_srange, but broker
# defaults to profile::druid::broker::ferm_srange, to
# haver finer control over how Druid accepts queries.
#
class profile::druid::broker(
    Hash[String, Any] $properties = lookup('profile::druid::broker::properties', {'default_value' => {}}),
    Hash[String, String] $env     = lookup('profile::druid::broker::env', {'default_value' => {}}),
    String $ferm_srange           = lookup('profile::druid::broker::ferm_srange', {'default_value' => '$DOMAIN_NETWORKS'}),
    Boolean $daemon_autoreload    = lookup('profile::druid::daemons_autoreload', {'default_value' => true}),
    Boolean $monitoring_enabled   = lookup('profile::druid::broker::monitoring_enabled', {'default_value' => false}),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::broker
        $java_opts = $::profile::druid::monitoring::broker::java_opts

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

    # Druid Broker Service
    class { '::druid::broker':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
        logger_prefix    => $class_prefix,
    }

    ferm::service { 'druid-broker':
        proto  => 'tcp',
        port   => $::druid::broker::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-broker':
            description  => 'Druid broker',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'${class_prefix}.cli.Main server broker\'",
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
