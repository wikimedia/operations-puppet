# = Class: toollabs::services
# Provides various services based off tools manifests
class toollabs::services inherits toollabs {

    include gridengine::submit_host

    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => running,
        subscribe => Package['tools-manifest'],
    }

    file { '/usr/local/bin/webservice':
        ensure  => present,
        source  => 'puppet:///modules/toollabs/webservice2',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['python-yaml'], # Present on all hosts, defined for puppet diamond collector
    }
}
