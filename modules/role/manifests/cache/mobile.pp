class role::cache::mobile {
    include role::cache::2layer

    $mobile_nodes = hiera('cache::mobile::nodes')
    $site_mobile_nodes = $mobile_nodes[$::site]

    if $::realm == 'production' {
        $memory_storage_size = floor((0.125 * $::memorysize_mb / 1024.0) + 0.5) # 1/8 of total mem
    }
    else {
        $memory_storage_size = 1
    }

    if $::realm == 'production' {
        include role::cache::ssl::sni
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['mobile'][$::site],
    }

    system::role { 'role::cache::mobile':
        description => 'mobile Varnish cache server',
    }

    include standard
    include nrpe

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    $varnish_be_directors = {
        'one' => {
            'backend'        => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
            'api'            => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
            'test_wikipedia' => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
        },
        'two' => {
            'eqiad' => $mobile_nodes['eqiad'],
        }
    }

    if $::role::cache::base::cluster_tier == 'one' {
        $director_retries = 2
    } else {
        $director_retries = $::role::cache::2layer::backend_weight_avg * 4
    }

    class { 'varnish::htcppurger':
        varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    # lint:ignore:case_without_default
    case $::realm {
    # lint:endignore
        'production': {
            $cluster_options = {
                'enable_geoiplookup' => true,
            }
        }
        'labs': {
            $cluster_options = {
                'enable_geoiplookup' => true,
                'enable_esi'         => true,
            }
        }
    }

    $zero_site = $::realm ? {
        'production' => 'https://zero.wikimedia.org',
        'labs'       => 'http://zero.wikimedia.beta.wmflabs.org',
    }

    class { 'varnish::zero_update':
        site     => $zero_site,
        auth_src => 'puppet:///private/misc/zerofetcher.auth',
    }

    $runtime_param = $::site ? {
        # 'esams' => ["prefer_ipv6=on"],
        default  => [],
    }

    $director_type_cluster = $::role::cache::base::cluster_tier ? {
        'one'   => 'random',
        default => 'chash',
    }

    varnish::instance { 'mobile-backend':
        name               => '',
        vcl                => 'mobile-backend',
        port               => 3128,
        admin_port         => 6083,
        storage            => $::role::cache::2layer::persistent_storage_args,
        runtime_parameters => $runtime_param,
        directors          => $varnish_be_directors[$::role::cache::base::cluster_tier],
        director_type      => $director_type_cluster,
        director_options   => {
            'retries' => $director_retries,
        },
        vcl_config         => {
            'default_backend'  => $::role::cache::base::default_backend,
            'retry503'         => 4,
            'retry5xx'         => 1,
            'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'backend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                'max_connections' => 20,
            },
            {
                'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '180s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 600,
            },
        ]),
        cluster_options    => $cluster_options,
        wikimedia_networks => $::role::cache::base::wikimedia_networks,
    }

    varnish::instance { 'mobile-frontend':
        name             => 'frontend',
        vcl              => 'mobile-frontend',
        extra_vcl        => ['zero'],
        port             => 80,
        admin_port       => 6082,
        storage          => "-s malloc,${memory_storage_size}G",
        directors        => {
            'backend' => $site_mobile_nodes,
        },
        director_options => {
            'retries' => $::role::cache::2layer::backend_weight_avg * size($site_mobile_nodes),
        },
        director_type    => 'chash',
        vcl_config       => {
            'retry5xx'         => 0,
            'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'frontend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
        backend_options  => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '185s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
        cluster_options  => $cluster_options,
    }

    # varnish::logging to be removed once
    # udp2log kafka consumer is implemented and deployed.
    include role::cache::logging

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest': topic => 'webrequest_mobile' }
    }
}
