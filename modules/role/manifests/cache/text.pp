class role::cache::text {
    system::role { 'role::cache::text':
        description => 'text Varnish cache server',
    }

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP
    include role::cache::2layer
    include role::cache::ssl::unified
    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.112' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['text'][$::site]
    }

    $app_directors = {
        'appservers'       => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
        },
        'api'              => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
        },
        'rendering'        => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
        },
        'security_audit'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['security_audit'][$::mw_primary],
        },
        'appservers_debug'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['appservers_debug'][$::mw_primary],
        },
        'restbase_backend' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $role::cache::configuration::backends[$::realm]['restbase'][$::mw_primary],
        },
        'cxserver_backend' => { # LEGACY: should be removed eventually
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $::role::cache::configuration::backends[$::realm]['cxserver'][$::mw_primary],
        },
        'citoid_backend'   => { # LEGACY: should be removed eventually
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $::role::cache::configuration::backends[$::realm]['citoid'][$::mw_primary],
        },
    }

    $app_be_opts = [
        {
            'backend_match'   => '^appservers-debug\.svc\.eqiad\.wmnet$',
            'max_connections' => 20,
        },
        {
            'backend_match'   => '^restbase\.svc\.|^deployment-restbase',
            'port'            => 7231,
            'max_connections' => 5000,
        },
        { # LEGACY: should be removed eventually
            'backend_match' => '^cxserver',
            'port'          => 8080,
            'probe'         => false,
        },
        { # LEGACY: should be removed eventually
            'backend_match' => '^citoid',
            'port'          => 1970,
            'probe'         => false,
        },
    ]

    $fe_def_beopts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '2s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_def_beopts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '180s',
        'between_bytes_timeout' => '4s',
        'max_connections'       => 1000,
    }

    $common_vcl_config = {
        'cache4xx'           => '1m',
        'purge_host_regex'   => $::role::cache::base::purge_host_not_upload_re,
        'static_host'        => $::role::cache::base::static_host,
        'bits_domain'        => $::role::cache::base::bits_domain,
        'top_domain'         => $::role::cache::base::top_domain,
        'do_gzip'            => true,
        'pass_random'        => true,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'enable_geoiplookup' => true,
        'https_redirects'    => true,
        'secure_post'        => false,
    })

    role::cache::instances { 'text':
        fe_mem_gb      => ceiling(0.125 * $::memorysize_mb / 1024.0),
        runtime_params => ['default_ttl=2592000'],
        app_directors  => $app_directors,
        app_be_opts    => $app_be_opts,
        fe_vcl_config  => $fe_vcl_config,
        be_vcl_config  => $be_vcl_config,
        fe_extra_vcl   => ['text-common', 'zero', 'normalize_path', 'geoip'],
        be_extra_vcl   => ['text-common', 'normalize_path'],
        be_storage     => $::role::cache::2layer::persistent_storage_args,
        fe_def_beopts  => $fe_def_beopts,
        be_def_beopts  => $be_def_beopts,
        cluster_nodes  => hiera('cache::text::nodes'),
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

    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.
    class { 'role::cache::kafka::webrequest':
        topic => 'webrequest_text',
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.text.frontend.request",
        statsd        => hiera('statsd'),
    }
}
