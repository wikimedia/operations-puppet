class role::cache::bits inherits role::cache::1layer {

    if $::realm == 'production' {
        include role::cache::ssl_sni
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['bits'][$::site],
    }

    $common_cluster_options = {
        'test_hostname'      => 'test.wikipedia.org',
        'enable_geoiplookup' => true,
    }

    $default_backend = 'backend'
    $varnish_directors = {
        1 => {
            'backend' => $::role::cache::configuration::backends[$::realm]['bits_appservers'][$::mw_primary],
            'test_wikipedia' => $::role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
        },
        2 => {
            'backend' => sort(flatten(values($role::cache::configuration::backends[$::realm]['bits']))),
        }
    }

    $probe = $cluster_tier ? {
        1       => 'bits',
        default => 'varnish',
    }
    case $::realm {
        'labs': {
            $realm_cluster_options = {
                'top_domain'  => 'beta.wmflabs.org',
                'bits_domain' => 'bits.beta.wmflabs.org',
                'do_gzip'     => true,
            }
        }
        default: {
            $realm_cluster_options = {}
        }
    }
    $cluster_options = merge($common_cluster_options, $realm_cluster_options)

    if $::realm == 'production' {
        $memory_storage_size = 2
    }
    else {
        $memory_storage_size = 1
    }

    system::role { 'role::cache::bits':
        description => 'bits Varnish cache server',
    }

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    include standard
    include nrpe

    varnish::instance { 'bits':
        name            => '',
        vcl             => 'bits',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => $varnish_directors[$cluster_tier],
        director_type   => 'random',
        vcl_config      => {
            'default_backend' => $default_backend,
            'retry503'        => 4,
            'retry5xx'        => 1,
            'cache4xx'        => '1m',
            'cluster_tier'    => $cluster_tier,
            'layer'           => 'frontend',
            'ssl_proxies'     => $wikimedia_networks,
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
