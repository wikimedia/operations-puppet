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
# [*logger_prefix*]
#   Druid has not always been an Apache project, so some versions
#   offer Java classes with the package prefix 'io.druid' meanwhile
#   the most recent ones 'org.apache.druid'.
#   Default: 'io.druid'
#
define druid::service(
    $runtime_properties,
    $service          = $title,
    $env              = undef,
    $enable           = true,
    $should_subscribe = false,
    $logger_prefix    = 'io.druid',
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
        ensure     => stdlib::ensure($enable, 'service'),
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
}
