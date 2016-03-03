class role::cache::maps {
    system::role { 'role::cache::maps':
        description => 'maps Varnish cache server',
    }

    include role::cache::2layer
    include role::cache::ssl::unified
    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.114' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['maps'][$::site],
    }

    $app_directors = {
        'kartotherian'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            # XXX note explicit abnormal hack: service only exists in codfw, but eqiad is Tier-1 in general
            # XXX this means traffic is moving x-dc without crypto!
            # XXX this also means users mapped to codfw frontends bounce traffic [codfw->eqiad->codfw] on their way in!
            'backends' => $role::cache::configuration::backends[$::realm]['kartotherian']['codfw'],
        },
    }

    $fe_def_beopts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'between_bytes_timeout' => '2s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_def_beopts = {
        'port'                  => 6533,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'between_bytes_timeout' => '4s',
        'max_connections'       => 1000,
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'do_gzip'          => true,
        'ttl_cap'          => '1d',
        'pass_random'      => true,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'https_redirects'  => true,
    })

    role::cache::instances { 'maps':
        fe_mem_gb      => 12,
        runtime_params => ['default_ttl=86400'],
        app_directors  => $app_directors,
        app_be_opts    => [],
        fe_vcl_config  => $fe_vcl_config,
        be_vcl_config  => $be_vcl_config,
        fe_extra_vcl   => [],
        be_extra_vcl   => [],
        be_storage     => $::role::cache::2layer::persistent_storage_args,
        fe_def_beopts  => $fe_def_beopts,
        be_def_beopts  => $be_def_beopts,
        cluster_nodes  => hiera('cache::maps::nodes'),
    }

    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.
    class { 'role::cache::kafka::webrequest':
        topic => 'webrequest_maps',
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.maps.frontend.request",
        statsd        => hiera('statsd'),
    }
}
