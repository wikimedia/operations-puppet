class role::cache::bits (
    $bits_domain = 'bits.wikimedia.org',
    $top_domain = 'org'
) {
    system::role { 'role::cache::bits':
        description => 'bits Varnish cache server',
    }

    include role::cache::1layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['bits'][$::site],
    }

    if $::realm == 'production' {
        include role::cache::ssl::sni
    }

    $cluster_options = {
        'test_hostname'      => 'test.wikipedia.org',
        'enable_geoiplookup' => true,
        'do_gzip'            => true,
        'bits_domain'        => $bits_domain,
        'top_domain'         => $top_domain,
    }

    $varnish_directors = {
        'one' => {
            'backend' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $::role::cache::configuration::backends[$::realm]['bits_appservers'][$::mw_primary],
            },
            'test_wikipedia' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $::role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
        },
        'two' => {
            'backend' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => sort(flatten(values($role::cache::configuration::backends[$::realm]['bits']))),
            },
        }
    }

    $probe = $::role::cache::base::cluster_tier ? {
        'one'   => 'bits',
        default => 'varnish',
    }

    # The cutoff here is somewhat arbitrary.  Large-memory production hosts
    # use 2GB currently, and small-memory virtual hosts (some as little as 4G
    # total mem) use 1GB currently.  It seems ok for now as a general rule
    # here: don't use the larger 2GB value unless it's a relatively-small
    # fraction of available memory.
    if $::memorysize_mb >= 16384 {
        $memory_storage_size = 2
    }
    else {
        $memory_storage_size = 1
    }

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    varnish::instance { 'bits':
        name            => '',
        vcl             => 'bits',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => $varnish_directors[$::role::cache::base::cluster_tier],
        vcl_config      => {
            'retry503'     => 4,
            'retry5xx'     => 1,
            'cache4xx'     => '1m',
            'cluster_tier' => $::role::cache::base::cluster_tier,
            'layer'        => 'frontend',
            'ssl_proxies'  => $::role::cache::base::wikimedia_networks,
        },
        backend_options => {
            'port'                  => 80,
            'connect_timeout'       => '5s',
            'first_byte_timeout'    => '35s',
            'between_bytes_timeout' => '4s',
            'max_connections'       => 10000,
            'probe'                 => $probe,
        },
        cluster_options => $cluster_options,
    }

    include role::cache::logging::eventlistener
    # Include a varnishkafka instance that will produce
    # eventlogging events to Kafka.
    include role::cache::kafka::eventlogging

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic        => 'webrequest_bits',
            varnish_name => $::hostname,
            varnish_svc_name => 'varnish',
        }

        include role::cache::kafka::statsv
    }
}
