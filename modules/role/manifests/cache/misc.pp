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
            'backends' => {
                'eqiad' => 'analytics1027.eqiad.wmnet',
            },
            'be_opts'  => { 'port' => 8888 },
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'backends' => {
                'eqiad' => 'bromine.eqiad.wmnet',
            },
        },
        'bohrium' => {
            'backends' => {
                'eqiad' => 'bohrium.eqiad.wmnet',
            },
            'probe'   => {
                'url'     => '/piwik.php',
                'timeout' => '3s',
            },
        },
        'californium' => {
            'backends' => {
                'eqiad' => 'californium.wikimedia.org',
            },
        },
        'darmstadtium' => {
            'backends' => {
                'eqiad' => 'darmstadtium.eqiad.wmnet',
            },
            'be_opts'  => {'port' => 81, 'max_connections' => 5},
        },
        'labtestweb2001' => {
            'backends' => {
                'eqiad' => 'labtestweb2001.wikimedia.org',
            },
        },
        'labtestspice' => {
            'backends' => {
                'eqiad' => 'labtestcontrol2001.wikimedia.org',
            },
            'be_opts'  => { 'port' => 6082 },
        },
        'labspice' => {
            'backends' => {
                'eqiad' => 'labcontrol1001.wikimedia.org',
            },
            'be_opts'  => { 'port' => 6082 },
        },
        'etherpad1001' => {
            'backends' => {
                'eqiad' => 'etherpad1001.eqiad.wmnet',
            },
            'be_opts'  => { 'port' => 9001 },
        },
        'eventstreams' => {
            'backends' => {
                'eqiad' => 'eventstreams.svc.eqiad.wmnet',
            },
            'be_opts'  => { 'port' => 8092 },
        },
        'contint1001' => { # CI server
            'backends' => {
                'eqiad' => 'contint1001.wikimedia.org',
            },
        },
        'graphite1001' => {
            'backends' => {
                'eqiad' => 'graphite1001.eqiad.wmnet',
            },
        },
        'graphite2001' => {
            'backends' => {
                'eqiad' => 'graphite2001.codfw.wmnet',
            },
        },
        'iridium' => { # main phab
            'backends' => {
                'eqiad' => 'iridium.eqiad.wmnet',
            },
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'backends' => {
                'eqiad' => 'krypton.eqiad.wmnet',
            },
        },
        'labmon1001' => {
            'backends' => {
                'eqiad' => 'labmon1001.eqiad.wmnet',
            },
        },
        'netmon1001' => { # servermon
            'backends' => {
                'eqiad' => 'netmon1001.wikimedia.org',
            },
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'backends' => {
                'eqiad' => 'terbium.eqiad.wmnet',
            },
        },
        'planet1001' => {
            'backends' => {
                'eqiad' => 'planet1001.eqiad.wmnet',
            },
        },
        'pybal_config' => {
            'backends' => {
                'eqiad' => 'puppetmaster1001.eqiad.wmnet',
            },
        },
        'rcstream' => {
            'backends' => {
                'eqiad' => 'rcs1001.eqiad.wmnet',
            },
            # 'backends' => {
                'eqiad' => 'rcs1002.eqiad.wmnet',
            }, # manual backup option if 1001 fails
            'be_opts'  => { max_connections => 1000 },
        },
        'ruthenium' => { # parsoid rt test server
            'backends' => {
                'eqiad' => 'ruthenium.eqiad.wmnet',
            },
            'be_opts'  => { 'port' => 8001 },
        },
        'rutherfordium' => { # people.wikimedia.org
            'backends' => {
                'eqiad' => 'rutherfordium.eqiad.wmnet',
            },
        },
        'thorium' => { # metrics and metrics-api
            'backends' => {
                'eqiad' => 'thorium.eqiad.wmnet',
            },
        },
        'ununpentium' => { # rt.wikimedia.org
            'backends' => {
                'eqiad' => 'ununpentium.wikimedia.org',
            },
        },
        'mendelevium' => { # OTRS
            'backends' => {
                'eqiad' => 'mendelevium.eqiad.wmnet',
            },
        },
        'logstash_director' => {
            'backends' => {
                'eqiad' => 'kibana.svc.eqiad.wmnet',
            },
        },
        'wdqs_director' => {
            'backends' => {
                'eqiad' => 'wdqs.svc.eqiad.wmnet',
            },
        },
        'ores' => {
            'backends' => {
                'eqiad' => 'ores.svc.eqiad.wmnet',
            },
            'be_opts'  => { 'port' => 8081 },
        },
    }

    # $req_handling declares how requests are handled based on their attributes.
    # The first level of keys map request hostnames (Host: header)
    # * If characters outside of '[-.A-Za-z0-9]' are detected in the hostname,
    #   it will be treated as a hostname regex.
    # * If the special hostname 'default' is specified, that stanza will apply
    #   to all requests which do not match other hostname comparisons.
    # * If no default is specified, non-matching requests return 404s.
    # * Attributes:
    #   director - required routing destination, string key from $app_directors.
    #   caching  - 'normal' (default), 'pass', 'pipe', or 'websockets'.  pass
    #     and pipe cause those returns at recv time unconditionally, and
    #     websockets enables websocket upgrade support, and implies pass for
    #     normal requests and pipe after the upgrade.
    #   subpaths - hash - If present, this is the only allowed key.  Request
    #     handling will be split on the path portion of the URL.  Keys are path
    #     regexes, and the value of each key should be a sub-hash of the same
    #     per-hostname attributes above (director required, caching defaulting
    #     to 'normal').  Requests which match no subpath will use the
    #     host-level attributes (404 if no host-level attributes).

    $req_handling = {
        '15.wikipedia.org'                   => { 'director' => 'bromine' },
        'analytics.wikimedia.org'            => { 'director' => 'thorium' },
        'annual.wikimedia.org'               => { 'director' => 'bromine' },
        'bugs.wikimedia.org'                 => { 'director' => 'iridium' },
        'bugzilla.wikimedia.org'             => { 'director' => 'iridium' },
        'config-master.wikimedia.org'        => {
            'director' => 'pybal_config',
            'caching'  => 'pass',
        },
        'datasets.wikimedia.org'             => {
            'director' => 'thorium',
            'caching'  => 'pass',
        },
        'dbtree.wikimedia.org'               => { 'director' => 'noc' },
        'docker-registry.wikimedia.org'      => { 'director' => 'darmstadtium' },
        'doc.wikimedia.org'                  => { 'director' => 'contint1001' },
        'endowment.wikimedia.org'            => { 'director' => 'bromine' },
        'etherpad.wikimedia.org'             => {
            'director' => 'etherpad1001',
            'caching'  => 'websockets',
        },
        'git.wikimedia.org'                  => { 'director' => 'iridium' },
        'grafana-admin.wikimedia.org'        => {
            'director' => 'krypton',
            'caching'  => 'pass',
        },
        'grafana-labs-admin.wikimedia.org'   => {
            'director' => 'labmon1001',
            'caching'  => 'pass',
        },
        'grafana-labs.wikimedia.org'         => {
            'director' => 'labmon1001',
            'caching'  => 'pass',
        },
        'grafana.wikimedia.org'              => {
            'director' => 'krypton',
            'caching'  => 'pass',
        },
        'graphite-labs.wikimedia.org'        => { 'director' => 'labmon1001' },
        'graphite.wikimedia.org'             => { 'director' => 'graphite1001' },
        'horizon.wikimedia.org'              => { 'director' => 'californium' },
        'hue.wikimedia.org'                  => { 'director' => 'analytics1027' },
        'iegreview.wikimedia.org'            => { 'director' => 'krypton' },
        'integration.wikimedia.org'          => { 'director' => 'contint1001' },
        'labspice.wikimedia.org'             => { 'director' => 'labspice' },
        'labtestspice.wikimedia.org'         => { 'director' => 'labtestspice' },
        'labtesthorizon.wikimedia.org'       => { 'director' => 'labtestweb2001' },
        'logstash.wikimedia.org'             => { 'director' => 'logstash_director' },
        'metrics.wikimedia.org'              => { 'director' => 'thorium' },
        'noc.wikimedia.org'                  => { 'director' => 'noc' },
        'ores.wikimedia.org'                 => { 'director' => 'ores' },
        'parsoid-tests.wikimedia.org'        => { 'director' => 'ruthenium' },
        'people.wikimedia.org'               => {
            'director' => 'rutherfordium',
            'caching'  => 'pass',
        },
        'performance.wikimedia.org'          => { 'director' => 'graphite1001' },
        'phabricator.wikimedia.org'          => { 'director' => 'iridium' },
        'phab.wmfusercontent.org'            => { 'director' => 'iridium' },
        'pivot.wikimedia.org'                => { 'director' => 'thorium' },
        'piwik.wikimedia.org'                => {
            'director' => 'bohrium',
            'caching'  => 'pass',
        },
        '^([^.]+\.)?planet\.wikimedia\.org$' => { 'director' => 'planet1001' },
        'query.wikidata.org'                 => { 'director' => 'wdqs_director' },
        'racktables.wikimedia.org'           => { 'director' => 'krypton' },
        'releases.wikimedia.org'             => { 'director' => 'bromine' },
        'rt.wikimedia.org'                   => { 'director' => 'ununpentium' },
        'scholarships.wikimedia.org'         => { 'director' => 'krypton' },
        'servermon.wikimedia.org'            => { 'director' => 'netmon1001' },
        'smokeping.wikimedia.org'            => { 'director' => 'netmon1001' },
        'static-bugzilla.wikimedia.org'      => { 'director' => 'bromine' },
        'stats.wikimedia.org'                => { 'director' => 'thorium' },
        'stream.wikimedia.org'               => {
            'director' => 'eventstreams',
            'caching'  => 'pipe',
            'subpaths' => {
                '^/(socket\.io|rc(stream_status)?)(/|$)' => {
                    'director' => 'rcstream',
                    'caching'  => 'websockets',
                },
            },
        },
        'ticket.wikimedia.org'               => {
            'director' => 'mendelevium',
            'caching'  => 'pass',
        },
        'toolsadmin.wikimedia.org'           => { 'director' => 'californium' },
        'torrus.wikimedia.org'               => { 'director' => 'netmon1001' },
        'transparency.wikimedia.org'         => { 'director' => 'bromine' },
        'yarn.wikimedia.org'                 => { 'director' => 'thorium' },
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
        app_def_be_opts   => $app_def_be_opts,
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
