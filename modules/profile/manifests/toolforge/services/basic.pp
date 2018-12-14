class profile::toolforge::services::basic(
    $active_node = hiera('profile::toolforge::services::active_node'),
  ) {
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
        ensure    => ensure_service($::fqdn == $active_node),
        subscribe => Package['tools-manifest'],
    }

    diamond::collector { 'SGE':
        source   => 'puppet:///modules/toollabs/monitoring/sge.py',
    }
}
