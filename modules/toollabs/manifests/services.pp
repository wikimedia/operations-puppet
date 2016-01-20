# = Class: toollabs::services
# Provides various services based off tools manifests
#
# = Parameters
#
# [*active*]
#   true if all the current set of services should run actively,
#   false if they should just be hot standby
class toollabs::services(
    $active = false,
) inherits toollabs {

    include gridengine::submit_host

    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => ensure_service($active),
        subscribe => Package['tools-manifest'],
    }

    file { '/usr/local/sbin/bigbrother':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/bigbrother',
    }

    file { '/etc/init/bigbrother.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/bigbrother.conf',
    }

    service { 'bigbrother':
        ensure    => ensure_service($active),
        subscribe => File['/usr/local/sbin/bigbrother', '/etc/init/bigbrother.conf'],
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
