class role::cache::misc {
    system::role { 'role::cache::misc':
        description => 'misc Varnish cache server'
    }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['misc_web'][$::site],
    }

    $cluster_nodes = hiera('cache::misc::nodes')
    $site_cluster_nodes = $cluster_nodes[$::site]

    include role::cache::ssl::misc

    $memory_storage_size = 8

    $varnish_be_directors = {
        'one' => {
            'analytics1001' => { # Hadoop Yarn ResourceManager GUI
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['analytics1001.eqiad.wmnet'],
            },
            'analytics1027' => { # Hue (Hadoop GUI)
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['analytics1027.eqiad.wmnet'],
            },
            'antimony' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['antimony.wikimedia.org'],
            },
            'bromine' => { # ganeti VM for misc. static HTML sites
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['bromine.eqiad.wmnet'],
            },
            'caesium' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['caesium.eqiad.wmnet'],
            },
            'californium' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['californium.wikimedia.org'],
            },
            'dataset1001' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['dataset1001.wikimedia.org'],
            },
            'etherpad1001' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['etherpad1001.eqiad.wmnet'],
            },
            'gallium' => { # CI server
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['gallium.wikimedia.org' ],
            },
            'graphite1001' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['graphite1001.eqiad.wmnet'],
            },
            'iridium' => { # main phab
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['iridium.eqiad.wmnet'],
            },
            'krypton' => { # ganeti VM for misc. PHP apps
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['krypton.eqiad.wmnet'],
            },
            'magnesium' => { # RT and racktables
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['magnesium.wikimedia.org'],
            },
            'neon' => { # monitoring tools (icinga et al)
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['neon.wikimedia.org'],
            },
            'netmon1001' => { # servermon
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['netmon1001.wikimedia.org'],
            },
            'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['mw1152.eqiad.wmnet'],
            },
            'palladium' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['palladium.eqiad.wmnet'],
            },
            'planet1001' => {
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['planet1001.eqiad.wmnet'],
            },
            'ruthenium' => { # parsoid rt test server
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['ruthenium.eqiad.wmnet'],
            },
            'rutherfordium' => { # people.wikimedia.org
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['rutherfordium.eqiad.wmnet'],
            },
            'stat1001' => { # metrics and metrics-api
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['stat1001.eqiad.wmnet'],
            },
            'terbium' => { # noc.wikimedia.org
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['terbium.eqiad.wmnet'],
            },
            'mendelevium' => { # OTRS
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['mendelevium.eqiad.wmnet'],
            },
            'ytterbium' => { # Gerrit
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['ytterbium.wikimedia.org'],
            },
            'logstash' => {
                'dynamic'  => 'no',
                'type' => 'hash', # maybe-wrong? but current value before this commit! XXX
                'backends' => [
                    'logstash1001.eqiad.wmnet',
                    'logstash1002.eqiad.wmnet',
                    'logstash1003.eqiad.wmnet',
                ],
            },
            'wdqs' => {
                'dynamic' => 'no',
                'type'    => 'random',
                backends  => ['wdqs1001.eqiad.wmnet', 'wdqs1002.eqiad.wmnet'],
            },
        },
        'two' => {
            'backend'        => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $cluster_nodes['eqiad'],
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $cluster_nodes['eqiad'],
                'service'  => 'varnish-be-rand',
            },
        },
    }

    $be_opts = array_concat($::role::cache::2layer::backend_scaled_weights, [
        {
            'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
            'port'          => 3128,
            'probe'         => 'varnish',
        },
        {
            'backend_match' => '^(antimony|ytterbium)',
            'port'          => 8080,
        },
        {
            'backend_match' => '^(ruthenium)',
            'port'          => 8001,
        },
        {
            'backend_match' => '^logstash',
            'probe'         => 'logstash',
        },
        {
            'backend_match' => '^wdqs',
            'probe'         => 'wdqs',
        },
        {
            # hue serves requests on port 8888
            'backend_match' => '^analytics1027',
            'port'          => 8888,
        },
        {
            # Yarn ResourceManager UI serves requests on port 8088
            'backend_match' => '^analytics1001',
            'port'          => 8088,
        },
        {
            # etherpad nodejs listens on 9001
            'backend_match' => '^etherpad1001',
            'port'          => 9001,
        },
        {
            'port'                  => 80,
            'connect_timeout'       => '5s',
            'first_byte_timeout'    => '35s',
            'between_bytes_timeout' => '4s',
            'max_connections'       => 100,
        }
    ])

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'do_gzip'          => true,
        'allowed_methods'  => '^(GET|DELETE|HEAD|POST|PURGE|PUT)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
    }

    $fe_vcl_config = merge($common_vcl_config, {
        'layer'            => 'frontend',
    })

    $be_one_vcl_config = merge($common_vcl_config, {
        'layer'           => 'backend',
        'has_def_backend' => 'no',
    })

    $be_two_vcl_config = merge($common_vcl_config, {
        'layer'           => 'backend',
    })

    $be_vcl_config = $::site_tier ? {
        'one'   => $be_one_vcl_config,
        default => $be_two_vcl_config,
    }

    varnish::instance { 'misc-backend':
        name            => '',
        vcl             => 'misc-backend',
        extra_vcl       => ['misc-common'],
        ports           => [ 3128 ],
        admin_port      => 6083,
        storage         => $::role::cache::2layer::persistent_storage_args,
        vcl_config      => $be_vcl_config,
        directors       => $varnish_be_directors[$::site_tier],
        backend_options => $be_opts,
    }

    varnish::instance { 'misc-frontend':
        name            => 'frontend',
        vcl             => 'misc-frontend',
        extra_vcl       => ['misc-common'],
        ports           => [ 80 ],
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        vcl_config      => $fe_vcl_config,
        directors       => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_cluster_nodes,
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $cluster_nodes['eqiad'],
                'dc'       => 'eqiad',
                'service'  => 'varnish-be-rand',
            },
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '185s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
    }

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest': topic => 'webrequest_misc' }
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.misc.frontend.request",
        statsd        => hiera('statsd'),
    }
}
