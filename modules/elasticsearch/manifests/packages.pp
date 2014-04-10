# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages {

     if ! defined ( Package['openjdk-7-jdk'] ) {
         package { 'openjdk-7-jdk':
             # we want openjdk 1.7.0_25 for elasticsearch
             ensure => '7u25-2.3.10-1ubuntu0.12.04.2',
         }
    }

    package { 'elasticsearch':
        require => Package['openjdk-7-jdk'],
        ensure  => 'present',
    }

    if ! defined ( Package['curl'] ) {
        package { 'curl': ensure => present }
    }
}
