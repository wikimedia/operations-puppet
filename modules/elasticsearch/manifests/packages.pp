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

    if $::elasticsearch::send_logs_to_logstash {
        # TODO: deploy gelf4j jar (https://github.com/t0xa/gelfj /
        # http://central.maven.org/maven2/org/graylog2/gelfj/1.1.14/gelfj-1.1.14.jar) not sure if this needs to be done
        # via the internal archiva repository and curl, if a .deb package needs to be created, ...
    }

}
