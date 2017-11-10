# Class: profile::druid::broker
#
# NOTE that most Druid service profiles default ferm_srange
# to profile::druid::ferm_srange, but broker
# defaults to profile::druid::broker::ferm_srange, to
# haver finer control over how Druid accepts queries.
#
class profile::druid::broker(
    $properties         = hiera('profile::druid::broker::properties'),
    $env                = hiera('profile::druid::broker::env'),
    $ferm_srange        = hiera('profile::druid::broker::ferm_srange'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload'),
    $monitoring_enabled = hiera('profile::druid::broker::monitoring_enabled'),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Kafka Broker process.
    if $monitoring_enabled {
        include ::profile::druid::broker::monitoring
        $broker_extra_java_opts = ::profile::druid::broker::monitoring::broker_extra_java_opts

        if $env['DRUID_EXTRA_JVM_OPTS'] {
            $monitoring_env_vars = {
                'DRUID_EXTRA_JVM_OPTS' => "${env['DRUID_EXTRA_JVM_OPTS']} ${broker_extra_java_opts}"
            }
        } else {
            $monitoring_env_vars = {
                'DRUID_EXTRA_JVM_OPTS' => $broker_extra_java_opts
            }
        }
    } else {
        $monitoring_env_vars = {}
    }

    # Druid Broker Service
    class { '::druid::broker':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-broker':
        proto  => 'tcp',
        port   => $::druid::broker::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-broker':
            description  => 'Druid broker',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server broker\'',
            critical     => false,
        }
    }
}
