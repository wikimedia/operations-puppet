class role::cache::misc {
    system::role { 'role::cache::misc':
        description => 'misc Varnish cache server'
    }

    include role::cache::1layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['misc_web'][$::site],
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
            'has_def_backend' => 'no',
            'retry503'        => 4,
            'retry5xx'        => 1,
            'cache4xx'        => '1m',
            'layer'           => 'frontend',
            'ssl_proxies'     => $::role::cache::base::wikimedia_networks,
            'allowed_methods' => '^(GET|HEAD|POST|PURGE|PUT)$',
        },
        backends        => [
            'analytics1001.eqiad.wmnet', # Hadoop Yarn ResourceManager GUI
            'analytics1027.eqiad.wmnet', # Hue (Hadoop GUI)
            'antimony.wikimedia.org',
            'caesium.eqiad.wmnet',
            'californium.wikimedia.org',
            'dataset1001.wikimedia.org',
            'etherpad1001.eqiad.wmnet',
            'gallium.wikimedia.org',  # CI server
            'graphite1001.eqiad.wmnet',
            'iridium.eqiad.wmnet', # main phab
            'logstash1001.eqiad.wmnet',
            'logstash1002.eqiad.wmnet',
            'logstash1003.eqiad.wmnet',
            'magnesium.wikimedia.org', # RT and racktables
            'neon.wikimedia.org', # monitoring tools (icinga et al)
            'netmon1001.wikimedia.org', # servermon
            'palladium.eqiad.wmnet',
            'ruthenium.eqiad.wmnet', # parsoid rt test server
            'stat1001.eqiad.wmnet', # metrics and metrics-api
            'terbium.eqiad.wmnet', # public_html
            'ytterbium.wikimedia.org', # Gerrit
            'zirconium.wikimedia.org',
        ],
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
        directors       => {
            'logstash' => [
                'logstash1001.eqiad.wmnet',
                'logstash1002.eqiad.wmnet',
                'logstash1003.eqiad.wmnet',
            ]
        },
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
}
