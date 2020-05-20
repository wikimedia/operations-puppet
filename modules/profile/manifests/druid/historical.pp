# Class: profile::druid::historical
#
class profile::druid::historical(
    $properties         = hiera('profile::druid::historical::properties', {}),
    $env                = hiera('profile::druid::historical::env', {}),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload', true),
    $ferm_srange        = hiera('profile::druid::ferm_srange', '$DOMAIN_NETWORKS'),
    $monitoring_enabled = hiera('profile::druid::historical::monitoring_enabled', false),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::historical
        $java_opts = $::profile::druid::monitoring::historical::java_opts

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

    # Druid historical Service
    class { '::druid::historical':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
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
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
