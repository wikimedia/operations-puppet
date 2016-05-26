# == Define druid::service
# Abstraction to ease standing up Druid services.
#
# Each Druid service consists of
# /etc/druid/$service/{env.sh,log4j2.xml,runtime.properties}.
# This define installs the service package and
# renders each of those files, and then starts the service.
#
# == Parameters
#
# [*runtime_properties*]
#   Hash of properties to render in the runtime.properties file.
#
# [*service*]
#   Name of the service.  This defaults to $title.
#
# [*env*]
#   Hash of shell environment variables to render in env.sh
#
# [*enable*]
#   True if the service should be started, false otherwise.
#   Default: true
#
# [*should_subscribe*]
#   True if the service should refresh if any of its config files change.
#   Default: false
#
define druid::service(
    $runtime_properties,
    $service          = $title,
    $env              = undef,
    $enable           = true,
    $should_subscribe = false,
)
{
    require_package("druid-${service}")

    file { "/etc/druid/${service}/runtime.properties":
        content => template('druid/runtime.properties.erb'),
    }

    $env_ensure = $env ? {
        undef   => 'absent',
        default => 'present',
    }

    file { "/etc/druid/${service}/env.sh":
        ensure  => $env_ensure,
        content => template('druid/env.sh.erb'),
    }

    file { "/etc/druid/${service}/log4j2.xml":
        content => template('druid/log4j2.xml.erb'),
    }

    service { "druid-${service}":
        ensure     => ensure_service($enable),
        enable     => $enable,
        hasrestart => true,
    }

    # Subscribe the Service its config files if $should_subscribe.
    if $should_subscribe {
        Class['::druid']                                 ~> Service["druid-${service}"]
        File["/etc/druid/${service}/runtime.properties"] ~> Service["druid-${service}"]
        File["/etc/druid/${service}/env.sh"]             ~> Service["druid-${service}"]
        File["/etc/druid/${service}/log4j2.xml"]         ~> Service["druid-${service}"]
    }
    # Else just make the Service require its config files.
    else {
        Class['::druid']                                 -> Service["druid-${service}"]
        File["/etc/druid/${service}/runtime.properties"] -> Service["druid-${service}"]
        File["/etc/druid/${service}/env.sh"]             -> Service["druid-${service}"]
        File["/etc/druid/${service}/log4j2.xml"]         -> Service["druid-${service}"]
    }


    ferm::service { "druid-${service}":
        proto  => 'tcp',
        port   =>  $runtime_properties['druid.port'],
        srange => '$ALL_NETWORKS',
    }
    if $::realm == 'production' {
        $ensure_monitor_service = $enable ? {
            false   => 'absent',
            default => 'present',
        }
        # middlemanager is a special case.  The druid java process
        # is called middleManager, with a capital M.
        $java_service_name = $service ? {
            'middlemanager' => 'middleManager',
            default         => $service,
        }
        nrpe::monitor_service { "druid-${service}":
            ensure       => $ensure_monitor_service,
            description  => "Druid ${service}",
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a 'io.druid.cli.Main server ${java_service_name}'",
            # TODO: parameterize this,
            # or move monitoring/ferm into its own class.
            critical     => false,
        }
    }
}
