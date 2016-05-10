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
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'max_connections'       => 100,
        'probe'                 => 'varnish',
    }

    $app_def_be_opts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'max_connections'       => 100,
    }

    # misc-cluster specific (for now!):
    #   every director must have exactly one of...
    #     'req_host' => request hostname (or array of them)
    #     'req_host_re' => request hostname regex
    # ...and for sanity's sake, there should be no overlap among them
    #
    # Maintenance flag:
    # It is also possible to force a director to return a HTTP 503
    # response to each request. This allows a better user experience
    # during downtimes caused by maintenance (e.g. OS reimage).
    # To use it, set the following flag in the target director:
    # 'maintenance' => 'Error message to display to the user.'
    #
    $app_directors = {
        'analytics1027' => { # Hue (Hadoop GUI)
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['analytics1027.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8888 }),
            'req_host' => 'hue.wikimedia.org',
        },
        'antimony' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['antimony.wikimedia.org'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8080 }),
            'req_host' => 'git.wikimedia.org',
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['bromine.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'static-bugzilla.wikimedia.org',
                'annual.wikimedia.org',
                'transparency.wikimedia.org',
                '15.wikipedia.org',
                'releases.wikimedia.org'
            ],
        },
        'bohrium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['bohrium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'piwik.wikimedia.org',
        },
        'californium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['californium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'horizon.wikimedia.org',
        },
        'labtestweb2001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labtestweb2001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'labtesthorizon.wikimedia.org',
        },
        'etherpad1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['etherpad1001.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
            'req_host' => 'etherpad.wikimedia.org',
        },
        'gallium' => { # CI server
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['gallium.wikimedia.org' ],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'doc.wikimedia.org',
                'integration.wikimedia.org'
            ],
        },
        'graphite1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['graphite1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'performance.wikimedia.org',
                'graphite.wikimedia.org'
            ],
        },
        'iridium' => { # main phab
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['iridium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'phabricator.wikimedia.org',
                'phab.wmfusercontent.org',
                'bugzilla.wikimedia.org',
                'bugs.wikimedia.org'
            ],
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['krypton.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'scholarships.wikimedia.org',
                'iegreview.wikimedia.org',
                'racktables.wikimedia.org',
                'grafana.wikimedia.org',
                'grafana-admin.wikimedia.org'
            ],
        },
        'netmon1001' => { # servermon
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['netmon1001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'servermon.wikimedia.org',
                'smokeping.wikimedia.org',
                'torrus.wikimedia.org'
            ],
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['mw1152.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'noc.wikimedia.org',
                'dbtree.wikimedia.org'
            ],
        },
        'palladium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['palladium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'config-master.wikimedia.org',
        },
        'planet1001' => {
            'dynamic'     => 'no',
            'type'        => 'random',
            'backends'    => ['planet1001.eqiad.wmnet'],
            'be_opts'     => $app_def_be_opts,
            'req_host_re' => '(?i)^([^.]+\.)?planet\.wikimedia\.org$'
        },
        'rcstream' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [
                'rcs1001.eqiad.wmnet',
                'rcs1002.eqiad.wmnet',
            ],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'stream.wikimedia.org',
        },
        'ruthenium' => { # parsoid rt test server
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['ruthenium.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8001 }),
            'req_host' => 'parsoid-tests.wikimedia.org',
        },
        'rutherfordium' => { # people.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['rutherfordium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'people.wikimedia.org',
        },
        'stat1001' => { # metrics and metrics-api
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['stat1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'metrics.wikimedia.org',
                'stats.wikimedia.org',
                'datasets.wikimedia.org',
                'analytics.wikimedia.org',
            ],
        },
        'mendelevium' => { # OTRS
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['mendelevium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'ticket.wikimedia.org',
        },
        'logstash_director' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [
                'logstash1001.eqiad.wmnet',
                'logstash1002.eqiad.wmnet',
                'logstash1003.eqiad.wmnet',
            ],
            'be_opts'  => merge($app_def_be_opts, { 'probe' => 'logstash' }),
            'req_host' => 'logstash.wikimedia.org',
        },
        'wdqs_director' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [
                'wdqs1001.eqiad.wmnet',
                'wdqs1002.eqiad.wmnet'
            ],
            'be_opts'  => merge($app_def_be_opts, { 'probe' => 'wdqs' }),
            'req_host' => 'query.wikidata.org',
        },
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'allowed_methods'  => '^(GET|DELETE|HEAD|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
    }

    role::cache::instances { 'misc':
        fe_mem_gb        => ceiling(0.5 * $::memorysize_mb / 1024.0),
        runtime_params   => [],
        app_directors    => $app_directors,
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        app_be_opts      => $app_be_opts,
        # lint:endignore
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
