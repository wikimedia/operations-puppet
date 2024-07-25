# SPDX-License-Identifier: Apache-2.0
# == Class: profile::graphite::production
#
# Set up graphite instance for production.
# Also includes icinga checks for anomalies for MediaWiki, EL & Swift metrics
# Instance requires people to authenticate via LDAP before they can see metrics.
#
class profile::graphite::production (
    Array[Stdlib::Fqdn] $graphite_hosts = lookup('profile::graphite::hosts'),
    Stdlib::Fqdn $primary_host = lookup('graphite_primary_host'),
) {
    $storage_dir = '/srv/carbon'

    class { '::httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'uwsgi', 'authnz_ldap'],
    }

    include profile::idp::client::httpd
    class { 'profile::graphite::base':
        storage_dir                        => $storage_dir,
        uwsgi_max_request_duration_seconds => 60,
        uwsgi_max_request_rss_megabytes    => 1024,
        provide_vhost                      => false,
        c_relay_settings                   => {
            forward_clusters => {
                'default'   => [
                  'graphite1005.eqiad.wmnet:1903',
                  'graphite2004.codfw.wmnet:1903',
                ],
                'big_users' => [
                  'graphite1005.eqiad.wmnet:1903',
                  'graphite2004.codfw.wmnet:1903',
                ]
            },
            cluster_routes   => [
                ['^cassandra\.', 'big_users'],
            ],
            'queue_depth'    => 500000,
            'batch_size'     => 8000,
        },
    }

    file { '/var/lib/carbon':
        ensure  => directory,
    }

    file { '/var/lib/carbon/whisper':
        ensure  => link,
        target  => "${storage_dir}/whisper",
        owner   => '_graphite',
        group   => '_graphite',
        require => Class['profile::graphite::base']
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

    # General cleanup of metric files not updated. ~3y
    graphite::whisper_cleanup { 'graphite-stale-metrics':
        directory => "${storage_dir}/whisper",
        keep_days => 1024,
    }

    include rsync::server

    rsync::server::module { 'carbon':
        path          => $storage_dir,
        uid           => '_graphite',
        gid           => '_graphite',
        hosts_allow   => $graphite_hosts,
        auto_firewall => true,
    }

    firewall::service { 'carbon_c_relay-local_relay_udp':
        proto  => 'udp',
        port   => 1903,
        srange => $graphite_hosts,
    }

    firewall::service { 'carbon_c_relay-local_relay_tcp':
        proto  => 'tcp',
        port   => 1903,
        srange => $graphite_hosts,
    }

    firewall::service { 'carbon_c_relay-frontend_relay_udp':
        proto    => 'udp',
        port     => 2003,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    firewall::service { 'carbon_c_relay-frontend_relay_tcp':
        proto    => 'tcp',
        port     => 2003,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    firewall::service { 'carbon_pickled':
        proto    => 'tcp',
        port     => 2004,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    backup::set { 'srv-carbon-whisper-coal': }
    # Backup 'daily' metrics, only every week
    backup::set { 'srv-carbon-whisper-daily':
        jobdefaults => 'Weekly-Mon-productionEqiad',
    }
    backup::set { 'var-lib-graphite-web-graphite-db': }

    # alert only on the primary server
    if $::fqdn == $primary_host {
        include profile::graphite::alerts
    }
}
