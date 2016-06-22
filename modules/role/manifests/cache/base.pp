class role::cache::base(
    $zero_site = 'https://zero.wikimedia.org',
    $purge_host_only_upload_re = '^upload\.wikimedia\.org$',
    $purge_host_not_upload_re = '^(?!upload\.wikimedia\.org)',
    # static_host must serve MediaWiki (e.g. not wwwportal)
    $static_host = 'en.wikipedia.org',
    $upload_domain = 'upload.wikimedia.org',
    $bits_domain = 'bits.wikimedia.org',
    $top_domain = 'org',
    $shortener_domain = 'w.wiki',
) {
    include standard
    include nrpe
    include lvs::configuration
    include network::constants
    include conftool::scripts

    $cache_cluster = hiera('cache::cluster')

    system::role { "role::cache::${cache_cluster}":
        description => "${cache_cluster} Varnish cache server",
    }

    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
        statsd_server => 'statsd.eqiad.wmnet',
    }

    ::varnish::logging::statsd { 'default':
        statsd_server => 'statsd.eqiad.wmnet',
        key_prefix    => "varnish.${::site}.backends",
    }

    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.
    class { 'role::cache::kafka::webrequest':
        topic => "webrequest_${cache_cluster}",
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.${cache_cluster}.frontend.request",
        statsd        => hiera('statsd'),
    }

    ::varnish::logging::xcache { 'xcache':
        key_prefix    => "varnish.${::site}.${cache_cluster}.xcache",
        statsd_server => hiera('statsd'),
    }

    # Only production needs system perf tweaks and NFS client disable
    if $::realm == 'production' {
        include role::cache::perf
        include base::no_nfs_client
    }

    # Not ideal factorization to put this here, but works for now
    class { 'varnish::zero_update':
        site         => $zero_site,
    }

    ###########################################################################
    # auto-depool on shutdown + conditional one-shot auto-pool on start
    # note: we can't use 'service' because we don't want to 'ensure =>
    # stopped|running', and 'service_unit' with 'declare_service => false'
    # wouldn't enable the service in systemd terms, either.
    ###########################################################################

    $tp_unit_path = '/lib/systemd/system/traffic-pool.service'
    $varlib_path = '/var/lib/traffic-pool'

    file { $tp_unit_path:
        ensure => present,
        source => 'puppet:///modules/role/cache/traffic-pool.service',
        mode   => '0444',
        owner  => root,
        group  => root,
    }

    file { $varlib_path:
        ensure => directory,
        mode   => '0755',
        owner  => root,
        group  => root,
    }

    exec { 'systemd reload+enable for traffic-pool':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload && /bin/systemctl enable traffic-pool',
        subscribe   => File[$tp_unit_path],
        require     => File[$varlib_path],
    }

    nrpe::monitor_systemd_unit_state { 'traffic-pool':
        require  => File[$tp_unit_path],
        critical => false, # promote to true once better-tested in the real world
    }
}
