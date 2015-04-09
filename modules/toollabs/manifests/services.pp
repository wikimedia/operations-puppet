# = Class: toollabs::services
# Provides various services based off tools manifests
#
# = Parameters
#
# [*active_host*]
#   fqdn of the host that's actively running the service monitors.
#   This can be switched via hiera to do failover
class toollabs::services(
    $active_host = 'tools-services-01.eqiad.wmflabs',
) inherits toollabs {

    if $::fqdn == $active_host {
        $service_ensure = running
    } else {
        $service_ensure = stopped
    }

    include gridengine::submit_host

    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => $service_ensure,
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
