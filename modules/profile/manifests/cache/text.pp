class profile::cache::text(
    # static_host must serve MediaWiki (e.g. not wwwportal)
    $static_host = hiera('profile::cache::text::static_host', 'en.wikipedia.org'),
    $top_domain = hiera('profile::cache::text::top_domain', 'org'),
    $shortener_domain = hiera('profile::cache::text::shortener_domain', 'w.wiki'),
    $nodes = hiera('cache::text::nodes'),
    $statsd_host = hiera('statsd'),
    $req_handling = hiera('cache::req_handling'),
    $app_directors = hiera('cache::app_directors'),
    $app_def_be_opts = hiera('cache::app_def_be_opts'),
    ){
    # profile::cache::base needs to be evaluated before this one.
    require ::profile::cache::base
    # for VCL compilation using libGeoIP
    class { '::geoip': }
    class { '::geoip::dev': }

    class { 'tlsproxy::prometheus': }
    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.112' ],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '180s',
        'max_connections'       => 0,
        'probe'                 => 'varnish',
    }

    $common_vcl_config = {
        'purge_host_regex' => $::profile::cache::base::purge_host_not_upload_re,
        'static_host'      => $static_host,
        'top_domain'       => $top_domain,
        'shortener_domain' => $shortener_domain,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'enable_geoiplookup' => true,
    })

    $common_runtime_params = ['default_ttl=86400']

    $text_storage_args = $::profile::cache::base::file_storage_args

    class { 'role::cache::instances':
        cache_type        => 'text',
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:16',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => $app_directors,
        app_def_be_opts   => $app_def_be_opts,
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['text-common', 'zero', 'normalize_path', 'geoip'],
        be_extra_vcl      => ['text-common', 'normalize_path'],
        be_storage        => $text_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => $nodes,
    }

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka.
    # A kafka consumer then consumes these and emits
    # metrics.
    class { '::role::cache::kafka::statsv': }

    # varnishkafka eventlogging listens for eventlogging
    # requests and logs them to the eventlogging-client-side
    # topic.  EventLogging servers consume and process this
    # topic into many JSON based kafka topics for further
    # consumption.
    class { '::role::cache::kafka::eventlogging': }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
        statsd_server => $statsd_host,
    }


}
