class profile::wmcs::graphite {

    include graphite::wmcs::archiver

    class { '::uwsgi': }

    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite', 'uwsgi',
                    'headers', 'authnz_ldap', 'ldap'],
    }

    class { 'profile::graphite::base':
        storage_dir  => '/srv/carbon',
        auth         => false,
        hostname     => 'graphite-labs.wikimedia.org',
        cors_origins => [ 'https?://(grafana-labs|grafana-labs-admin).wikimedia.org' ],
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
        srange => '@resolve(labmon1001.eqiad.wmnet)',
    }

    ferm::service { 'carbon_c_relay-local_relay_tcp':
        proto  => 'tcp',
        port   => '1903',
        srange => '@resolve(labmon1001.eqiad.wmnet)',
    }

    ferm::service { 'statsite_udp':
        proto  => 'udp',
        port   => '8125',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'statsite_tcp':
        proto  => 'udp',
        port   => '8125',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_c_relay-frontend_relay_udp':
        proto  => 'udp',
        port   => '2003',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_c_relay-frontend_relay_tcp':
        proto  => 'tcp',
        port   => '2003',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_pickled':
        proto  => 'tcp',
        port   => '2004',
        srange => '$LABS_NETWORKS',
    }
}
