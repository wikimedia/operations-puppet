# == Define druid::service
# Abstraction to ease standing up Druid services.
#
# Each Druid service consists of
# /etc/druid/$service/{env.sh,log4j2.xml,runtime.properties}.
# This define renders each of those files, and then starts the service.
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
    file { "/etc/druid/${service}/runtime.properties":
        content => template('druid/runtime.properties.erb'),
    }

    $env_ensure = $env ? {
        undef   => 'absent',
        default => 'present',
    }

    file { "/etc/druid/${service}/env.sh":
        ensure => $env_ensure,
        content => template('druid/env.sh.erb'),
    }

    file { "/etc/druid/${service}/log4j2.xml":
        content => template('druid/log4j2.xml.erb'),
    }

    $service_ensure = $enabled ? {
        false   => 'stopped',
        default => 'running',
    }
    service { "druid-${service}":
        ensure      => $service_ensure,
        enable      => $enabled,
        hasrestart  => true,
    }

    # Subscribe the Service its config files if $should_subscribe.
    if $should_subscribe {
        File["/etc/druid/${service}/runtime.properties"] ~> Service["druid-${service}"]
        File["/etc/druid/${service}/env.sh"]             ~> Service["druid-${service}"]
        File["/etc/druid/${service}/log4j2.xml"]         ~> Service["druid-${service}"]
    }
    # Else just make the Service require its config files.
    else {
        File["/etc/druid/${service}/runtime.properties"] -> Service["druid-${service}"]
        File["/etc/druid/${service}/env.sh"]             -> Service["druid-${service}"]
        File["/etc/druid/${service}/log4j2.xml"]         -> Service["druid-${service}"]
    }
}