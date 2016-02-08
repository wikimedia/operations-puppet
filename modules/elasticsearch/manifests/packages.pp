# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages {
    include ::java::tools

    require_package('openjdk-7-jdk')

    package { 'elasticsearch':
        ensure  => present,
        require => Package['openjdk-7-jdk'],
    }

    require_package('curl')

    # library for elasticsearch. only in trusty+
    if os_version('ubuntu >= trusty') {
        require_package('python-elasticsearch')
        require_package('python-ipaddr')
    }


    ### install and link additional log4j appender to send logs over GELF
    $logging_package_ensure = $::elasticsearch::send_logs_to_logstash ? {
        true    => 'present',
        default => 'absent',
    }
    $logging_link_ensure = $::elasticsearch::send_logs_to_logstash ? {
        true    => 'link',
        default => 'absent',
    }

    package { [ 'liblogstash-gelf-java', 'libjson-simple-java' ]:
        ensure => $logging_package_ensure,
    }
    file { '/usr/share/elasticsearch/lib/logstash-gelf.jar':
        type   => $logging_link_ensure,
        target => '/usr/share/java/logstash-gelf.jar',
    }
    file { '/usr/share/elasticsearch/lib/json-simple.jar':
        type   => $logging_link_ensure,
        target => '/usr/share/java/json-simple.jar',
    }

}
