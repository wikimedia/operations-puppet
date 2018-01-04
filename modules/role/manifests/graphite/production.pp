# == Class: role::graphite::production
#
# Set up graphite instance for production.
# Also includes icinga checks for anomalies for Mediawiki, EL & Swift metrics
# Instance requires people to authenticate via LDAP before they can see metrics.
#
class role::graphite::production {
    $storage_dir = '/var/lib/carbon'

    include ::standard
    include ::base::firewall

    class { 'role::graphite::base':
        storage_dir      => $storage_dir,
        auth             => true,
        c_relay_settings => {
            forward_clusters => {
                'default'   => [
                  'graphite1001.eqiad.wmnet:1903',
                  'graphite2001.codfw.wmnet:1903',
                ],
                'big_users' => [
                  'graphite1003.eqiad.wmnet:1903',
                  'graphite2002.codfw.wmnet:1903',
                ]
            },
            cluster_routes   => [
                ['^cassandra\.', 'big_users'],
                # wanobjectcache spams metrics with hex hashes - T178531
                ['^MediaWiki\.wanobjectcache\.[a-zA-Z0-9]{32}', 'blackhole'],
            ]
        }
    }

    class { 'role::graphite::cleanup':
        storage_dir => $storage_dir,
    }

    $graphite_hosts = [
        'graphite1001.eqiad.wmnet',
        'graphite1003.eqiad.wmnet',
        'graphite2001.codfw.wmnet',
        'graphite2002.codfw.wmnet',
    ]
    $graphite_hosts_ferm = join($graphite_hosts, ' ')

    include rsync::server

    rsync::server::module { 'carbon':
        path        => $storage_dir,
        uid         => '_graphite',
        gid         => '_graphite',
        hosts_allow => $graphite_hosts,
    }

    ferm::service { 'rsync-graphite':
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve((${graphite_hosts_ferm}))",
    }

    ferm::service { 'carbon_c_relay-local_relay_udp':
        proto  => 'udp',
        port   => '1903',
        srange => "@resolve((${graphite_hosts_ferm}))",
    }

    ferm::service { 'carbon_c_relay-local_relay_tcp':
        proto  => 'tcp',
        port   => '1903',
        srange => "@resolve((${graphite_hosts_ferm}))",
    }

    ferm::service { 'carbon_c_relay-frontend_relay_udp':
        proto  => 'udp',
        port   => '2003',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'carbon_c_relay-frontend_relay_tcp':
        proto  => 'tcp',
        port   => '2003',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'carbon_pickled':
        proto  => 'tcp',
        port   => '2004',
        srange => '$PRODUCTION_NETWORKS',
    }
}

