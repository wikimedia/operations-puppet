# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::overlord
#
class profile::druid::overlord(
    Hash[String, Any] $properties            = lookup('profile::druid::overlord::properties', {'default_value' => {}}),
    Hash[String, String] $env                = lookup('profile::druid::overlord::env', {'default_value' => {}}),
    Optional[Array[String]] $firewall_access = lookup('profile::druid::overlord::firewall_access'),
    Boolean $daemon_autoreload               = lookup('profile::druid::daemons_autoreload', {'default_value' => true}),
    Boolean $monitoring_enabled              = lookup('profile::druid::overlord::monitoring_enabled', {'default_value' => false}),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::overlord
        $java_opts = $::profile::druid::monitoring::overlord::java_opts

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

    # Druid overlord Service
    class { '::druid::overlord':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
        logger_prefix    => $class_prefix,
    }

    firewall::service { 'druid-overlord':
        proto    => 'tcp',
        port     => $::druid::overlord::runtime_properties['druid.port'],
        src_sets => $firewall_access,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-overlord':
            description  => 'Druid overlord',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'${class_prefix}.cli.Main server overlord\'",
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
