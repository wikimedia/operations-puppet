# Class: profile::druid::overlord
#
# NOTE that most Druid service profiles default ferm_srange
# to profile::druid::ferm_srange, but overlord
# defaults to profile::druid::overlord::ferm_srange, to
# haver finer control over how Druid accepts indexing tasks.
#
class profile::druid::overlord(
    $properties         = hiera('profile::druid::overlord::properties', {}),
    $env                = hiera('profile::druid::overlord::env', {}),
    $ferm_srange        = hiera('profile::druid::overlord::ferm_srange', '$DOMAIN_NETWORKS'),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload', true),
    $monitoring_enabled = hiera('profile::druid::overlord::monitoring_enabled', false),
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

    # Druid overlord Service
    class { '::druid::overlord':
        properties       => $properties,
        env              => merge($env, $monitoring_env_vars),
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-overlord':
        proto  => 'tcp',
        port   => $::druid::overlord::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-overlord':
            description  => 'Druid overlord',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server overlord\'',
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
