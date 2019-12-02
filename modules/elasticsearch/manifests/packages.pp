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

    if os_version('debian == buster') and $java_package == 'openjdk-8-jdk' {

        apt::repository { 'openjdk-8':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'component/jdk8',
            notify     => Exec['apt_update_java8'],
        }

        exec {'apt_update_java8':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

        package { 'openjdk-8-jdk':
            ensure  => present,
            require => [
                Apt::Repository['openjdk-8'],
                Exec['apt_update_java8'],
            ],
        }

    } else {

        require_package($java_package)

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
