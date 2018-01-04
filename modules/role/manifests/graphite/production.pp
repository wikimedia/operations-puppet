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
    include ::profile::statsd # all graphite hosts also include statsd

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

    # Nodepool, which has several metrics for each of the Jenkins jobs
    graphite::whisper_cleanup { 'graphite-nodepool':
        directory => "${storage_dir}/whisper/nodepool",
        keep_days => 15,
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
