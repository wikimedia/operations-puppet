class role::cache::misc {
    system::role { 'role::cache::misc':
        description => 'misc Varnish cache server'
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['misc_web'][$::site],
    }

    include role::cache::1layer

    include role::cache::ssl::misc

    $memory_storage_size = 8

    varnish::instance { 'misc':
        name            => '',
        vcl             => 'misc',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        vcl_config      => {
            'retry503'        => 4,
            'retry5xx'        => 1,
            'cache4xx'        => '1m',
            'layer'           => 'frontend',
            'ssl_proxies'     => $::role::cache::base::wikimedia_networks,
            'default_backend' => 'antimony',    # FIXME
            'allowed_methods' => '^(GET|HEAD|POST|PURGE|PUT)$',
        },
        backends        => [
            'antimony.wikimedia.org',
            'caesium.eqiad.wmnet',
            'californium.wikimedia.org',
            'dataset1001.wikimedia.org',
            'gallium.wikimedia.org',  # CI server
            'ytterbium.wikimedia.org', # Gerrit
            'graphite1001.eqiad.wmnet',
            'zirconium.wikimedia.org',
            'ruthenium.eqiad.wmnet', # parsoid rt test server
            'logstash1001.eqiad.wmnet',
            'logstash1002.eqiad.wmnet',
            'logstash1003.eqiad.wmnet',
            'netmon1001.wikimedia.org', # servermon
            'iridium.eqiad.wmnet', # main phab
            'terbium.eqiad.wmnet', # public_html
            'neon.wikimedia.org', # monitoring tools (icinga et al)
            'magnesium.wikimedia.org', # RT and racktables
            'stat1001.eqiad.wmnet', # metrics and metrics-api
            'palladium.eqiad.wmnet',
            'analytics1027.eqiad.wmnet', # Hue (Hadoop GUI)
            'analytics1001.eqiad.wmnet', # Hadoop Yarn ResourceManager GUI
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
