class profile::swift::proxy {

    # Global variables
    # These variables are most probably defined in the common hierarchy.
    $graphite_host = hiera('graphite_host', 'graphite-in.eqiad.wmnet')
    $statsd_host = hiera('statsd_host', 'localhost')
    $app_routes = hiera('discovery::app_routes')

    # Swift-wide variables
    # Usually found in {common,$site}/swift.yaml
    $cluster_name = hiera('swift::cluster', "${::site}-prod")
    $swift_frontends = hiera('swift::proxyhosts')
    $accounts = hiera('swift::accounts')
    $account_keys = hiera('swift::account_keys')
    $shard_container_list = hiera('swift::shard_container_list')
    $thumbor_wiki_list = hiera('swift::thumbor_wiki_list')

    # Proxy-specific
    $svc_host = hiera(
        'swift::proxy::proxy_service_host',
        "ms-fe.svc.${::site}.wmnet"
    )
    $thumb_server = hiera(
        'swift::proxy::rewrite_thumb_server',
        "rendering.svc.${app_routes['mediawiki']}.wmnet"
    )
    $memcached_servers = hiera('swift::proxy::memcached')
    $thumbor_host = hiera('swift::proxy::thumbor', undef)

    $dispersion_account = hiera('swift::proxy::dispersion_account', 'dispersion')
    $rewrite_account = hiera('swift::proxy::rewrite_account', 'mw_media')


    class { '::swift::proxy':
        proxy_service_host   => $svc_host,
        thumborhost          => $thumbor_host,
        shard_container_list => $shard_container_list,
        statsd_host          => $statsd_host,
        rewrite_thumb_server => $thumb_server,
        memcached_servers    => $memcached_servers,
        accounts             => $accounts,
        credentials          => $account_keys,
        dispersion_account   => $dispersion_account,
        rewrite_account      => $rewrite_account,
        thumbor_wiki_list    => $thumbor_wiki_list,
        statsd_metric_prefix => "swift.${cluster_name}.${::hostname}",
    }

    class { '::lvs::realserver':
        realserver_ips => ipresolve($svc_host),
    }

    class { '::memcached':
        size => 128,
        port => 11211,
    }

    ferm::service { 'swift-proxy':
        proto   => 'tcp',
        notrack => true,
        port    => '80',
    }

    $swift_frontends_ferm = join($swift_frontends, ' ')

    ferm::service { 'swift-memcached':
        proto   => 'tcp',
        port    => '11211',
        notrack => true,
        srange  => "@resolve((${swift_frontends_ferm}))",
    }

    monitoring::service { 'swift-http-frontend':
        description   => 'Swift HTTP frontend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
    }
    monitoring::service { 'swift-http-backend':
        description   => 'Swift HTTP backend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/backend",
    }
}
