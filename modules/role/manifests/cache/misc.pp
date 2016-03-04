class role::cache::misc {
    system::role { 'role::cache::misc':
        description => 'misc Varnish cache server'
    }

    include role::cache::2layer
    include role::cache::ssl::misc

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['misc_web'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '2s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '4s',
        'max_connections'       => 100,
        'probe'                 => 'varnish',
    }

    $app_def_be_opts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '4s',
        'max_connections'       => 100,
    }

    $app_directors = {
        'analytics1001' => { # Hadoop Yarn ResourceManager GUI
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['analytics1001.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8088 }),
        },
        'analytics1027' => { # Hue (Hadoop GUI)
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['analytics1027.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8888 }),
        },
        'antimony' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['antimony.wikimedia.org'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8080 }),
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['bromine.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'bohrium' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['bohrium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'californium' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['californium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'labtestweb2001' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['labtestweb2001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'dataset1001' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['dataset1001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'etherpad1001' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['etherpad1001.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
        },
        'gallium' => { # CI server
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['gallium.wikimedia.org' ],
            'be_opts'  => $app_def_be_opts,
        },
        'graphite1001' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['graphite1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'iridium' => { # main phab
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['iridium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['krypton.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'magnesium' => { # RT and racktables
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['magnesium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'neon' => { # monitoring tools (icinga et al)
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['neon.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'netmon1001' => { # servermon
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['netmon1001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['mw1152.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'palladium' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['palladium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'planet1001' => {
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['planet1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'ruthenium' => { # parsoid rt test server
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['ruthenium.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8001 }),
        },
        'rutherfordium' => { # people.wikimedia.org
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['rutherfordium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'stat1001' => { # metrics and metrics-api
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['stat1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'terbium' => { # noc.wikimedia.org
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['terbium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'mendelevium' => { # OTRS (search is really slow, hence bbt=60s below)
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['mendelevium.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'between_bytes_timeout' => '60s' })
        },
        'ytterbium' => { # Gerrit
            'dynamic' => 'no',
            'type' => 'random',
            'backends' => ['ytterbium.wikimedia.org'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8080 }),
        },
        'logstash' => {
            'dynamic'  => 'no',
            'type' => 'hash', # maybe-wrong? but current value before this commit! XXX
            'backends' => [
                'logstash1001.eqiad.wmnet',
                'logstash1002.eqiad.wmnet',
                'logstash1003.eqiad.wmnet',
            ],
            'be_opts'  => merge($app_def_be_opts, { 'probe' => 'logstash' }),
        },
        'wdqs' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['wdqs1001.eqiad.wmnet', 'wdqs1002.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'probe' => 'wdqs' }),
        },
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'do_gzip'          => true,
        'allowed_methods'  => '^(GET|DELETE|HEAD|POST|PURGE|PUT)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
    }

    role::cache::instances { 'misc':
        fe_mem_gb        => 8,
        runtime_params   => [],
        app_directors    => $app_directors,
        app_be_opts      => $app_be_opts,
        fe_vcl_config    => $common_vcl_config,
        be_vcl_config    => $common_vcl_config,
        fe_extra_vcl     => ['misc-common'],
        be_extra_vcl     => ['misc-common'],
        be_storage       => $::role::cache::2layer::persistent_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => hiera('cache::misc::nodes'),
    }

    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.
    class { 'role::cache::kafka::webrequest':
        topic => 'webrequest_misc',
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.misc.frontend.request",
        statsd        => hiera('statsd'),
    }
}
