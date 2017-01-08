class role::cache::misc {
    include role::cache::base
    include role::cache::ssl::unified

    class { 'prometheus::node_vhtcpd': }

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
    #   every director must have exactly one of...
    #     'req_host' => request hostname (or array of them)
    #     'req_host_re' => request hostname regex
    # ...and for sanity's sake, there should be no overlap among them
    #
    $app_directors = {
        'analytics1027' => { # Hue (Hadoop GUI)
            'backend'  => 'analytics1027.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8888 }),
            'req_host' => 'hue.wikimedia.org',
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'backend'  => 'bromine.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'static-bugzilla.wikimedia.org',
                'annual.wikimedia.org',
                'endowment.wikimedia.org',
                'transparency.wikimedia.org',
                '15.wikipedia.org',
                'releases.wikimedia.org',
            ],
        },
        'bohrium' => {
            'backend'  => 'bohrium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'piwik.wikimedia.org',
        },
        'californium' => {
            'backend'  => 'californium.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'horizon.wikimedia.org',
                'toolsadmin.wikimedia.org',
            ],
        },
        'darmstadtium' => {
            'backend'  => 'darmstadtium.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, {'port' => 81, 'max_connections' => 5}),
            'req_host' => 'docker-registry.wikimedia.org',
        },
        'labtestweb2001' => {
            'backend'  => 'labtestweb2001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'labtesthorizon.wikimedia.org',
        },
        'labtestspice' => {
            'backend'  => 'labtestcontrol2001.wikimedia.org',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
            'req_host' => 'labtestspice.wikimedia.org',
        },
        'labspice' => {
            'backend'  => 'labcontrol1001.wikimedia.org',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
            'req_host' => 'labspice.wikimedia.org',
        },
        'etherpad1001' => {
            'backend'  => 'etherpad1001.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
            'req_host' => 'etherpad.wikimedia.org',
        },
        'contint1001' => { # CI server
            'backend'  => 'contint1001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'doc.wikimedia.org',
                'integration.wikimedia.org',
            ],
        },
        'graphite1001' => {
            'backend'  => 'graphite1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'performance.wikimedia.org',
                'graphite.wikimedia.org',
            ],
        },
        'iridium' => { # main phab
            'backend'  => 'iridium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'phabricator.wikimedia.org',
                'phab.wmfusercontent.org',
                'bugzilla.wikimedia.org',
                'bugs.wikimedia.org',
                'git.wikimedia.org',
            ],
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'backend'  => 'krypton.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'scholarships.wikimedia.org',
                'iegreview.wikimedia.org',
                'racktables.wikimedia.org',
                'grafana.wikimedia.org',
                'grafana-admin.wikimedia.org',
            ],
        },
        'labmon1001' => {
            'backend'  => 'labmon1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'grafana-labs.wikimedia.org',
                'grafana-labs-admin.wikimedia.org',
                'graphite-labs.wikimedia.org',
            ],
        },
        'netmon1001' => { # servermon
            'backend'  => 'netmon1001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'servermon.wikimedia.org',
                'smokeping.wikimedia.org',
                'torrus.wikimedia.org',
            ],
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'backend'  => 'terbium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => [
                'noc.wikimedia.org',
                'dbtree.wikimedia.org',
            ],
        },
        'planet1001' => {
            'backend'     => 'planet1001.eqiad.wmnet',
            'be_opts'     => $app_def_be_opts,
            'req_host_re' => '^([^.]+\.)?planet\.wikimedia\.org$',
        },
        'pybal_config' => {
            'backend'  => 'puppetmaster1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'config-master.wikimedia.org',
        },
        'rcstream' => {
            'backend'  => 'rcs1001.eqiad.wmnet',
            # 'backend'  => 'rcs1002.eqiad.wmnet', # manual backup option if 1001 fails
            'be_opts'  => merge($app_def_be_opts, { max_connections => 1000 }),
            'req_host' => 'stream.wikimedia.org',
        },
        'ruthenium' => { # parsoid rt test server
            'backend'  => 'ruthenium.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8001 }),
            'req_host' => 'parsoid-tests.wikimedia.org',
        },
        'rutherfordium' => { # people.wikimedia.org
            'backend'  => 'rutherfordium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'people.wikimedia.org',
        },
        'thorium' => { # metrics and metrics-api
            'backend'  => 'thorium.eqiad.wmnet',
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
            'backend'  => 'ununpentium.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'rt.wikimedia.org',
        },
        'mendelevium' => { # OTRS
            'backend'  => 'mendelevium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'ticket.wikimedia.org',
        },
        'logstash_director' => {
            'backend'  => 'kibana.svc.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'logstash.wikimedia.org',
        },
        'wdqs_director' => {
            'backend'  => 'wdqs.svc.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
            'req_host' => 'query.wikidata.org',
        },
        'ores' => {
            'backend'  => 'ores.svc.eqiad.wmnet',
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
