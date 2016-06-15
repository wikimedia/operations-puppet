class role::cache::text {
    require geoip
    require geoip::dev # for VCL compilation using libGeoIP
    include role::cache::2layer
    include role::cache::ssl::unified
    if $::standard::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.112' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['text'][$::site]
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
        'max_connections'       => 1000,
        'probe'                 => 'varnish',
    }

    $app_def_be_opts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '180s',
        'max_connections'       => 1000,
    }

    $apps = hiera('cache::text::apps')
    $app_directors = {
        'appservers'       => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['appservers']['backends'][$apps['appservers']['route']],
            'be_opts'  => $app_def_be_opts,
        },
        'api'              => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['api']['backends'][$apps['api']['route']],
            'be_opts'  => $app_def_be_opts,
        },
        'rendering'        => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['rendering']['backends'][$apps['rendering']['route']],
            'be_opts'  => $app_def_be_opts,
        },
        'security_audit'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['security_audit']['backends'][$apps['security_audit']['route']],
            'be_opts'  => $app_def_be_opts,
        },
        'appservers_debug'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['appservers_debug']['backends'][$apps['appservers_debug']['route']],
            'be_opts'  => merge($app_def_be_opts, { 'max_connections' => 20 }),
        },
        'restbase_backend' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['restbase']['backends'][$apps['restbase']['route']],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 7231, 'max_connections' => 5000 }),
        },
        'cxserver_backend' => { # LEGACY: should be removed eventually
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['cxserver']['backends'][$apps['cxserver']['route']],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8080 }),
        },
        'citoid_backend'   => { # LEGACY: should be removed eventually
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['citoid']['backends'][$apps['citoid']['route']],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 1970 }),
        },
    }

    $common_vcl_config = {
        'cache4xx'           => '1m',
        'purge_host_regex'   => $::role::cache::base::purge_host_not_upload_re,
        'static_host'        => $::role::cache::base::static_host,
        'bits_domain'        => $::role::cache::base::bits_domain,
        'top_domain'         => $::role::cache::base::top_domain,
        'pass_random'        => true,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'enable_geoiplookup' => true,
        'secure_post'        => false,
        'ttl_cap'            => '1d',
    })

    role::cache::instances { 'text':
        fe_mem_gb        => ceiling(0.37 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf => 'lg_dirty_mult:8,lg_chunk_size:16',
        runtime_params   => ['default_ttl=2592000'],
        app_directors    => $app_directors,
        fe_vcl_config    => $fe_vcl_config,
        be_vcl_config    => $be_vcl_config,
        fe_extra_vcl     => ['text-common', 'zero', 'normalize_path', 'geoip'],
        be_extra_vcl     => ['text-common', 'normalize_path'],
        be_storage       => $::role::cache::2layer::persistent_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => hiera('cache::text::nodes'),
    }

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka.
    # A kafka consumer then consumes these and emits
    # metrics.
    class { '::role::cache::kafka::statsv':
        varnish_name => 'frontend',
    }

    # varnishkafka eventlogging listens for eventlogging
    # requests and logs them to the eventlogging-client-side
    # topic.  EventLogging servers consume and process this
    # topic into many JSON based kafka topics for further
    # consumption.
    class { '::role::cache::kafka::eventlogging':
        varnish_name => 'frontend',
    }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
        statsd_server => 'statsd.eqiad.wmnet',
    }
}
