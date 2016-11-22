class role::cache::misc {
    include role::cache::base
    include role::cache::ssl::unified

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.115' ],
    }

    class { '::lvs::realserver':
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
    #
    # Every director must have exactly one of...
    #     'req_host'    => request hostname (or array of them)
    #     'req_host_re' => request hostname regex
    # You may also add one of:
    #     'req_url'     => url path (or an array of them)
    #     'req_url_re'  => url path regex
    #
    # These two options will be used to build a series of conditional
    # routes.  If you have overlapping conditions, make sure that
    # the director with the more specific condition comes alphabetically
    # before ones with less specific conditions.  E.g. given the following
    # directors that both handle requests to mydirector.wikimedia.org,
    #
    #   '10_mydirector_special_case' => {
    #       'req_host' => 'mydirector.wikimedia.org',
    #       'req_url' => '/special/case'
    #       ...
    #   },
    #   '20_mydirector' => {
    #       'req_host' => 'mydirector.wikimedia.org'
    #       ...
    #   }
    #
    # It is important that the director with req_url comes alphabetically
    # before the one without, as the VCL conditionals will be rendered in
    # alphabetical order.  If this was not the case, the conditional that
    # matches just req_host would evaluate before the one with req_url,
    # and all requests would be handled by the director without req_url.
    # If your req_host rule does not overlap with any other director
    # here, then alphabetical order does not matter.
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
        'bromine' => { # ganeti VM for misc. static HTML sites
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['bromine.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'static-bugzilla.wikimedia.org',
                'annual.wikimedia.org',
                'endowment.wikimedia.org',
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
            'req_host' => [
                'horizon.wikimedia.org',
                'toolsadmin.wikimedia.org',
            ],
        },
        'darmstadtium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['darmstadtium.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, {'port' => 81, 'max_connections' => 5}),
            'req_host' => 'docker-registry.wikimedia.org',
        },
        'labtestweb2001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labtestweb2001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'labtesthorizon.wikimedia.org',
        },
        'labtestspice' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labtestcontrol2001.wikimedia.org'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
            'req_host' => 'labtestspice.wikimedia.org',
        },
        'labspice' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labcontrol1001.wikimedia.org'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
            'req_host' => 'labspice.wikimedia.org',
        },
        'etherpad1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['etherpad1001.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
            'req_host' => 'etherpad.wikimedia.org',
        },
        'contint1001' => { # CI server
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['contint1001.wikimedia.org' ],
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
                'bugs.wikimedia.org',
                'git.wikimedia.org'
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
        'labmon1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labmon1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'grafana-labs.wikimedia.org',
                'grafana-labs-admin.wikimedia.org',
                'graphite-labs.wikimedia.org',
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
            'backends' => ['terbium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'noc.wikimedia.org',
                'dbtree.wikimedia.org'
            ],
        },
        'planet1001' => {
            'dynamic'     => 'no',
            'type'        => 'random',
            'backends'    => ['planet1001.eqiad.wmnet'],
            'be_opts'     => $app_def_be_opts,
            'req_host_re' => '^([^.]+\.)?planet\.wikimedia\.org$'
        },
        'pybal_config' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['puppetmaster1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'config-master.wikimedia.org',
        },
        'rcstream' => {
            'dynamic'  => 'no',
            'type'     => 'hash',
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
                'yarn.wikimedia.org',
                'pivot.wikimedia.org',
            ],
        },
        'ununpentium' => { # rt.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['ununpentium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'rt.wikimedia.org',
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
            'backends' => [ 'kibana.svc.eqiad.wmnet' ],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'logstash.wikimedia.org',
        },
        'wdqs_director' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [ 'wdqs.svc.eqiad.wmnet', ],
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'query.wikidata.org',
        },
        'ores' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [ 'ores.svc.eqiad.wmnet', ],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8081 }),
            'req_host' => 'ores.wikimedia.org',
        },
    }

    $common_vcl_config = {
        'allowed_methods'  => '^(GET|DELETE|HEAD|PATCH|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'ttl_cap'            => '1d',
    })

    $common_runtime_params = ['default_ttl=3600']

    role::cache::instances { 'misc':
        fe_mem_gb         => ceiling(0.4 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:16',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => $app_directors,
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['misc-common'],
        be_extra_vcl      => ['misc-common'],
        be_storage        => $::role::cache::base::file_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => hiera('cache::misc::nodes'),
    }
}
