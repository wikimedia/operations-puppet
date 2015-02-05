# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages {
    include ::java::tools

    if ! defined ( Package['openjdk-7-jdk'] ) {
        package { 'openjdk-7-jdk':
            ensure => 'present',
        }
    }

    package { 'elasticsearch':
        ensure  => present,
        require => Package['openjdk-7-jdk'],
    }

    # jq is really useful, especially for parsing
    # elasticsearch REST command JSON output.
    package { 'jq':
        ensure => present,
    }

    if ! defined ( Package['curl'] ) {
        package { 'curl': ensure => present }
    }

    # library for elasticsearch. only in trusty+
    if os_version('ubuntu >= trusty') {
        package { 'python-elasticsearch': ensure => present }
        package { 'python-ipaddr': ensure => present }
    }
}
