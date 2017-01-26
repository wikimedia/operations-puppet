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

    # $app_directors defines the backend applayer services this varnish can
    # route requests to.
    #
    $app_directors = {
        'analytics1027' => { # Hue (Hadoop GUI)
            'backend'  => 'analytics1027.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8888 }),
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'backend'  => 'bromine.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'bohrium' => {
            'backend'  => 'bohrium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'californium' => {
            'backend'  => 'californium.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
        },
        'darmstadtium' => {
            'backend'  => 'darmstadtium.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, {'port' => 81, 'max_connections' => 5}),
        },
        'labtestweb2001' => {
            'backend'  => 'labtestweb2001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
        },
        'labtestspice' => {
            'backend'  => 'labtestcontrol2001.wikimedia.org',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
        },
        'labspice' => {
            'backend'  => 'labcontrol1001.wikimedia.org',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 6082 }),
        },
        'etherpad1001' => {
            'backend'  => 'etherpad1001.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
        },
        'contint1001' => { # CI server
            'backend'  => 'contint1001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
        },
        'graphite1001' => {
            'backend'  => 'graphite1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'iridium' => { # main phab
            'backend'  => 'iridium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'backend'  => 'krypton.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'labmon1001' => {
            'backend'  => 'labmon1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'netmon1001' => { # servermon
            'backend'  => 'netmon1001.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'backend'  => 'terbium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'planet1001' => {
            'backend'     => 'planet1001.eqiad.wmnet',
            'be_opts'     => $app_def_be_opts,
        },
        'pybal_config' => {
            'backend'  => 'puppetmaster1001.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'rcstream' => {
            'backend'  => 'rcs1001.eqiad.wmnet',
            # 'backend'  => 'rcs1002.eqiad.wmnet', # manual backup option if 1001 fails
            'be_opts'  => merge($app_def_be_opts, { max_connections => 1000 }),
        },
        'ruthenium' => { # parsoid rt test server
            'backend'  => 'ruthenium.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8001 }),
        },
        'rutherfordium' => { # people.wikimedia.org
            'backend'  => 'rutherfordium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'thorium' => { # metrics and metrics-api
            'backend'  => 'thorium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'ununpentium' => { # rt.wikimedia.org
            'backend'  => 'ununpentium.wikimedia.org',
            'be_opts'  => $app_def_be_opts,
        },
        'mendelevium' => { # OTRS
            'backend'  => 'mendelevium.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'logstash_director' => {
            'backend'  => 'kibana.svc.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'wdqs_director' => {
            'backend'  => 'wdqs.svc.eqiad.wmnet',
            'be_opts'  => $app_def_be_opts,
        },
        'ores' => {
            'backend'  => 'ores.svc.eqiad.wmnet',
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8081 }),
        },
    }

    # $req_handling declares how requests are handled based on their attributes.
    # Currently this only maps request hostnames (Host: header)
    # If characters outside of '[-.A-Za-z0-9]' are detected in the hostname, it
    # will be treated as a hostname regex.
    # Attributes:
    #   director - routing destination, string key from $app_directors above

    $req_handling = {
        'hue.wikimedia.org'                  => { 'director' => 'analytics1027' },
        'static-bugzilla.wikimedia.org'      => { 'director' => 'bromine' },
        'annual.wikimedia.org'               => { 'director' => 'bromine' },
        'endowment.wikimedia.org'            => { 'director' => 'bromine' },
        'transparency.wikimedia.org'         => { 'director' => 'bromine' },
        '15.wikipedia.org'                   => { 'director' => 'bromine' },
        'releases.wikimedia.org'             => { 'director' => 'bromine' },
        'piwik.wikimedia.org'                => { 'director' => 'bohrium' },
        'horizon.wikimedia.org'              => { 'director' => 'californium' },
        'toolsadmin.wikimedia.org'           => { 'director' => 'californium' },
        'docker-registry.wikimedia.org'      => { 'director' => 'darmstadtium' },
        'latesthorizon.wikimedia.org'        => { 'director' => 'labtestweb2001' },
        'labtestspice.wikimedia.org'         => { 'director' => 'labtestspice' },
        'labspice.wikimedia.org'             => { 'director' => 'labspice' },
        'etherpad.wikimedia.org'             => { 'director' => 'etherpad1001' },
        'doc.wikimedia.org'                  => { 'director' => 'contint1001' },
        'integration.wikimedia.org'          => { 'director' => 'contint1001' },
        'graphite.wikimedia.org'             => { 'director' => 'graphite1001' },
        'performance.wikimedia.org'          => { 'director' => 'graphite1001' },
        'phabricator.wikimedia.org'          => { 'director' => 'iridium' },
        'phab.wmfusercontent.org'            => { 'director' => 'iridium' },
        'bugzilla.wikimedia.org'             => { 'director' => 'iridium' },
        'bugs.wikimedia.org'                 => { 'director' => 'iridium' },
        'git.wikimedia.org'                  => { 'director' => 'iridium' },
        'scholarships.wikimedia.org'         => { 'director' => 'krypton' },
        'iegreview.wikimedia.org'            => { 'director' => 'krypton' },
        'racktables.wikimedia.org'           => { 'director' => 'krypton' },
        'grafana.wikimedia.org'              => { 'director' => 'krypton' },
        'grafana-admin.wikimedia.org'        => { 'director' => 'krypton' },
        'grafana-labs.wikimedia.org'         => { 'director' => 'labmon1001' },
        'grafana-labs-admin.wikimedia.org'   => { 'director' => 'labmon1001' },
        'graphite-labs.wikimedia.org'        => { 'director' => 'labmon1001' },
        'servermon.wikimedia.org'            => { 'director' => 'netmon1001' },
        'smokeping.wikimedia.org'            => { 'director' => 'netmon1001' },
        'torrus.wikimedia.org'               => { 'director' => 'netmon1001' },
        'noc.wikimedia.org'                  => { 'director' => 'noc' },
        'dbtree.wikimedia.org'               => { 'director' => 'noc' },
        '^([^.]+\.)?planet\.wikimedia\.org$' => { 'director' => 'planet1001' },
        'config-master.wikimedia.org'        => { 'director' => 'pybal_config' },
        'stream.wikimedia.org'               => { 'director' => 'rcstream' },
        'parsoid-tests.wikimedia.org'        => { 'director' => 'ruthenium' },
        'people.wikimedia.org'               => { 'director' => 'rutherfordium' },
        'metrics.wikimedia.org'              => { 'director' => 'thorium' },
        'stats.wikimedia.org'                => { 'director' => 'thorium' },
        'datasets.wikimedia.org'             => { 'director' => 'thorium' },
        'analytics.wikimedia.org'            => { 'director' => 'thorium' },
        'yarn.wikimedia.org'                 => { 'director' => 'thorium' },
        'pivot.wikimedia.org'                => { 'director' => 'thorium' },
        'rt.wikimedia.org'                   => { 'director' => 'ununpentium' },
        'ticket.wikimedia.org'               => { 'director' => 'mendelevium' },
        'logstash.wikimedia.org'             => { 'director' => 'logstash_director' },
        'query.wikidata.org'                 => { 'director' => 'wdqs_director' },
        'ores.wikimedia.org'                 => { 'director' => 'ores' },
    }

    $common_vcl_config = {
        'allowed_methods'  => '^(GET|DELETE|HEAD|PATCH|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
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
