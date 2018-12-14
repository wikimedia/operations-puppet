class profile::toolforge::grid::webservicemonitor(
){
    # webservicemonitor stuff, previously in services nodes
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
        ensure    => 'running',
        subscribe => Package['tools-manifest'],
    }
}
