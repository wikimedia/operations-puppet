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
}
