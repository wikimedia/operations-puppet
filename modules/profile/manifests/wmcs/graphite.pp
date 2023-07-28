class profile::wmcs::graphite (
    Stdlib::Fqdn $graphite_host = lookup('graphite_host', {'default_value' => 'localhost'}),
) {

    include graphite::wmcs::archiver

    class { '::uwsgi': }

    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite', 'uwsgi',
                    'headers', 'authnz_ldap', 'ldap'],
    }

    class { 'profile::graphite::base':
        storage_dir  => '/srv/carbon',
        hostname     => 'graphite-labs.wikimedia.org',
        cors_origins => [
            'https?://grafana-cloud.wikimedia.org',
            'https?://grafana-labs.wikimedia.org',
        ],
    }

    file { '/var/lib/carbon':
        ensure  => link,
        target  => '/srv/carbon',
        owner   => '_graphite',
        group   => '_graphite',
        require => Class['profile::graphite::base']
    }

    ferm::service { 'carbon_c_relay-local_relay_udp':
        proto  => 'udp',
        port   => '1903',
        srange => "@resolve(${graphite_host})",
    }

    ferm::service { 'carbon_c_relay-local_relay_tcp':
        proto  => 'tcp',
        port   => '1903',
        srange => "@resolve(${graphite_host})",
    }
}
