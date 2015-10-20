class role::cache::misc {
    system::role { 'role::cache::misc':
        description => 'misc Varnish cache server'
    }

    include role::cache::1layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['misc_web'][$::site],
    }

    include role::cache::ssl::misc

    $memory_storage_size = 8

    varnish::instance { 'misc':
        name            => '',
        vcl             => 'misc',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        vcl_config      => {
            'has_def_backend'  => 'no',
            'retry503'         => 4,
            'retry5xx'         => 1,
            'cache4xx'         => '1m',
            'layer'            => 'frontend',
            'do_gzip'          => true,
            'allowed_methods'  => '^(GET|DELETE|HEAD|POST|PURGE|PUT)$',
            'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        },
        directors       => {
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
            'stat1001' => { # metrics and metrics-api
                'dynamic' => 'no',
                'type' => 'random',
                'backends' => ['stat1001.eqiad.wmnet'],
            },
            'terbium' => { # public_html
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
        backend_options => [
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
            'port'                  => 80,
            'connect_timeout'       => '5s',
            'first_byte_timeout'    => '35s',
            'between_bytes_timeout' => '4s',
            'max_connections'       => 100,
        }],
    }

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic => 'webrequest_misc',
            varnish_name => $::hostname,
            varnish_svc_name => 'varnish',
        }
    }

    # Parse varnishlogs for request statistics and send to statsd via diamond.
    varnish::monitoring::varnishreqstats { 'Misc':
        instance_name => 'frontend',
        metric_path   => "varnish.${::site}.misc.frontend.request",
        require       => Varnish::Instance['misc'],
    }
}
