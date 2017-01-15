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

    include ::gridengine::submit_host

    package { 'tools-manifest':
        ensure => latest,
    }

    package { 'toollabs-webservice':
        ensure => latest,
    }

    file { '/usr/local/bin/webservice':
        ensure => link,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        target => '/usr/bin/webservice',
    }

    service { 'webservicemonitor':
        ensure    => ensure_service($active),
        subscribe => Package['tools-manifest'],
    }

    diamond::collector { 'SGE':
        source   => 'puppet:///modules/toollabs/monitoring/sge.py',
    }
}
