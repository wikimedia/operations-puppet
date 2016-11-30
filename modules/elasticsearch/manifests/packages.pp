# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages (
    $java_package,
) {
    include ::java::tools

    require_package($java_package)

    package { 'elasticsearch':
        ensure  => present,
        require => Package[$java_package],
    }

    require_package('curl')

    # library for elasticsearch. only in trusty+
    if os_version('ubuntu >= trusty') {
        require_package('python-elasticsearch')
        require_package('python-ipaddr')
    }

    ### install and link additional log4j appender to send logs over GELF

    # we only require the packages, we do not remove them as there might be
    # other dependencies
    if $::elasticsearch::send_logs_to_logstash {
        require_package('liblogstash-gelf-java')
        require_package('libjson-simple-java')
    }

    # symlinks are removed if log shipping is disabled
    file { '/usr/share/elasticsearch/lib/logstash-gelf.jar':
        ensure => ensure_link($::elasticsearch::send_logs_to_logstash),
        target => '/usr/share/java/logstash-gelf.jar',
    }
    file { '/usr/share/elasticsearch/lib/json-simple.jar':
        ensure => ensure_link($::elasticsearch::send_logs_to_logstash),
        target => '/usr/share/java/json-simple.jar',
    }

}
