# == Class: wdqs::packages
#
# Provisions WDQS package and dependencies.
#
class wdqs::packages {
    include ::java::tools

    if ! defined ( Package['openjdk-7-jdk'] ) {
        package { 'openjdk-7-jdk':
            ensure => 'present',
        }
    }

    if ! defined ( Package['curl'] ) {
        package { 'curl': ensure => present }
    }

    if ! defined ( Package['maven'] ) {
        package { 'maven': ensure => present }
    }

}