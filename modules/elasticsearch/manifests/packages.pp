# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages (
    String $java_package,
    String $package_name,
    Boolean $send_logs_to_logstash,
) {
    include ::java::tools

    # In roles where multiple Java daemons are defined,
    # there might be the chance of duplicate declaration of
    # the openjdk package. We should create a standard/shared
    # way of deploying java across our puppet code base,
    # but for the moment a conditional is sufficient.
    if !defined(Package[$java_package]) {
        if os_version('debian == buster') and $java_package == 'openjdk-8-jdk' {

            apt::package_from_component { 'openjdk8-buster':
                component => 'component/jdk8',
                packages  => ['openjdk-8-jdk']
            }
        } else {

            require_package($java_package)

        }
    }

    package { 'elasticsearch':
        ensure  => present,
        require => Package[$java_package],
        name    => $package_name,
    }

    # library for elasticsearch
    require_package('python-elasticsearch')
    require_package('python-ipaddr')

    ### install and link additional log4j appender to send logs over GELF

    # we only require the packages, we do not remove them as there might be
    # other dependencies
    if $send_logs_to_logstash {
        require_package('liblogstash-gelf-java')
        require_package('libjson-simple-java')
    }

    # symlinks are removed if log shipping is disabled
    file { '/usr/share/elasticsearch/lib/logstash-gelf.jar':
        ensure => ensure_link($send_logs_to_logstash),
        target => '/usr/share/java/logstash-gelf.jar',
    }
    file { '/usr/share/elasticsearch/lib/json-simple.jar':
        ensure => ensure_link($send_logs_to_logstash),
        target => '/usr/share/java/json-simple.jar',
    }

}
