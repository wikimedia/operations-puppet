# == Class: profile::graphite::production
#
# Set up graphite instance for production.
# Also includes icinga checks for anomalies for Mediawiki, EL & Swift metrics
# Instance requires people to authenticate via LDAP before they can see metrics.
#
class profile::graphite::production {
    $storage_dir = '/var/lib/carbon'

    class { '::httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'uwsgi', 'authnz_ldap'],
    }

    class { 'profile::graphite::base':
        storage_dir      => $storage_dir,
        auth             => true,
        c_relay_settings => {
            forward_clusters => {
                'default'   => [
                  'graphite1004.eqiad.wmnet:1903',
                  'graphite2003.codfw.wmnet:1903',
                ],
                'big_users' => [
                  'graphite1004.eqiad.wmnet:1903',
                  'graphite2003.codfw.wmnet:1903',
                ]
            },
            cluster_routes   => [
                ['^cassandra\.', 'big_users'],
                # wanobjectcache spams metrics with hex hashes - T178531
                ['^MediaWiki\.wanobjectcache\.[a-zA-Z0-9]{32}', 'blackhole'],
            ],
            'queue_depth'    => 500000,
            'batch_size'     => 8000,
        }
    }

    # Cleanup stale labs instances data - T143405
    graphite::whisper_cleanup { 'graphite-labs-instances':
        directory => "${storage_dir}/whisper/instances",
    }

    # Cleanup eventstreams rdkafka stale data - T160644
    graphite::whisper_cleanup { 'graphite-eventstreams':
        directory => "${storage_dir}/whisper/eventstreams/rdkafka",
        keep_days => 5,
    }

    # Cleanup zuul data
    graphite::whisper_cleanup { 'graphite-zuul':
        directory => "${storage_dir}/whisper/zuul",
    }
    # Zuul also generates metrics related to Gerrit
    graphite::whisper_cleanup { 'graphite-zuul-gerrit':
        directory => "${storage_dir}/whisper/gerrit",
    }

    # Cassandra metrics - T179057
    graphite::whisper_cleanup { 'graphite-cassandra':
        directory => "${storage_dir}/whisper/cassandra",
        keep_days => 182,
    }

    # ORES metrics - T169969
    graphite::whisper_cleanup { 'graphite-ores':
        directory => "${storage_dir}/whisper/ores",
        keep_days => 30,
    }

    $graphite_hosts = [
        'graphite1004.eqiad.wmnet',
        'graphite2003.codfw.wmnet',
    ]
    $graphite_hosts_ferm = join($graphite_hosts, ' ')

    include rsync::server

    rsync::server::module { 'carbon':
        path        => $storage_dir,
        uid         => '_graphite',
        gid         => '_graphite',
        hosts_allow => $graphite_hosts,
        auto_ferm   => true,
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

    backup::set { 'var-lib-carbon-whisper-coal': }
    backup::set { 'var-lib-graphite-web-graphite-db': }
}
