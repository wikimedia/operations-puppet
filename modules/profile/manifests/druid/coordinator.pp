# Class: profile::druid::coordinator
#
class profile::druid::coordinator(
    $properties         = hiera('profile::druid::coordinator::properties'),
    $env                = hiera('profile::druid::coordinator::env'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
    $ferm_srange        = hiera('profile::druid::ferm_srange'),
    $monitoring_enabled = hiera('profile::druid::coordinator::monitoring_enabled'),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        include ::profile::druid::monitoring::coordinator
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

    # Druid coordinator Service
    class { '::druid::coordinator':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-coordinator':
        proto  => 'tcp',
        port   => $::druid::coordinator::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-coordinator':
            description  => 'Druid coordinator',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server coordinator\'',
            critical     => false,
        }
    }
}
