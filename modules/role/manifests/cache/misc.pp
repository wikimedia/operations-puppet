class role::cache::misc {
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

    # $app_directors defines the backend applayer services this varnish can
    # route requests to.
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
        },
        'bromine' => { # ganeti VM for misc. static HTML sites
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['bromine.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'bohrium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['bohrium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'californium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['californium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'labtestweb2001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labtestweb2001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'etherpad1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['etherpad1001.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 9001 }),
        },
        'gallium' => { # CI server
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['gallium.wikimedia.org' ],
            'be_opts'  => $app_def_be_opts,
        },
        'graphite1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['graphite1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'iridium' => { # main phab
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['iridium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'krypton' => { # ganeti VM for misc. PHP apps
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['krypton.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'labmon1001' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['labmon1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'netmon1001' => { # servermon
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['netmon1001.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'noc' => { # noc.wikimedia.org and dbtree.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['mw1152.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'palladium' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['palladium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'planet1001' => {
            'dynamic'     => 'no',
            'type'        => 'random',
            'backends'    => ['planet1001.eqiad.wmnet'],
            'be_opts'     => $app_def_be_opts,
        },
        'rcstream' => {
            'dynamic'  => 'no',
            'type'     => 'hash',
            'backends' => [
                'rcs1001.eqiad.wmnet',
                'rcs1002.eqiad.wmnet',
            ],
            'be_opts'  => $app_def_be_opts,
        },
        'ruthenium' => { # parsoid rt test server
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['ruthenium.eqiad.wmnet'],
            'be_opts'  => merge($app_def_be_opts, { 'port' => 8001 }),
        },
        'rutherfordium' => { # people.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['rutherfordium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'stat1001' => { # metrics and metrics-api
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['stat1001.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
        },
        'ununpentium' => { # rt.wikimedia.org
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['ununpentium.wikimedia.org'],
            'be_opts'  => $app_def_be_opts,
        },
        'mendelevium' => { # OTRS
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => ['mendelevium.eqiad.wmnet'],
            'be_opts'  => $app_def_be_opts,
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
        },
        'wdqs_director' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [
                'wdqs1001.eqiad.wmnet',
                'wdqs1002.eqiad.wmnet',
            ],
            'be_opts'  => merge($app_def_be_opts, { 'probe' => 'wdqs' }),
        },
        'ores' => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => [ 'ores.svc.eqiad.wmnet', ],
            'be_opts'  => merge($app_def_be_opts, { 'port' => '8081' }),
        },
    }

    # WIP - not all of the below is implemented, several commits coming!
    #
    # This declares how requests are handled based on the request hostname
    # and/or path (and possibly more in the future).  For now what's controlled
    # here is backend selection, websocket support, and pass-only mode (no
    # possible caching for these reqs).
    # The first layer of keys are mostly request hostnames.  If characters
    # outside of '[-.A-Za-z0-9]' are detected in the key, the "hostname" will
    # be treated as a hostname regex.  The special key "default" applies if
    # nothing else matches the request hostname.  Ordering is not gauranteed,
    # so regexes should not overlap each other or the explicit hostnames.
    # Within each hostname stanza there are parameters:
    #  director => required, names a director from $app_directors above
    #  force-pass => boolean, default false, causes "return (pass)"
    #  websockets => boolean, default false, turns on websockets support
    #  subpaths => hash.  If present, this is the only allowed key.  Request
    #     handling will be split on the path portion of the URL.  Keys are path
    #     regexes, and the value of each key should be a sub-hash of the same
    #     per-hostname options above.  The special key "default" applies for
    #     paths that do not match any of the other keys.

    $req_handling => {
        '15.wikipedia.org'                       => { 'director' => 'bromine' },
        'analytics.wikimedia.org'                => { 'director' => 'stat1001' },
        'annual.wikimedia.org'                   => { 'director' => 'bromine' },
        'bugs.wikimedia.org'                     => { 'director' => 'iridium' },
        'bugzilla.wikimedia.org'                 => { 'director' => 'iridium' },
        'config-master.wikimedia.org'            => { 'director' => 'palladium' },
        'datasets.wikimedia.org'                 => { 'director' => 'stat1001' },
        'dbtree.wikimedia.org'                   => { 'director' => 'noc' },
        'doc.wikimedia.org'                      => { 'director' => 'gallium' },
        'endowment.wikimedia.org'                => { 'director' => 'bromine' },
        'etherpad.wikimedia.org'                 => { 'director' => 'etherpad1001' },
        'git.wikimedia.org'                      => { 'director' => 'iridium' },
        'grafana-admin.wikimedia.org'            => { 'director' => 'krypton' },
        'grafana-labs-admin.wikimedia.org'       => { 'director' => 'labmon1001' },
        'grafana-labs.wikimedia.org'             => { 'director' => 'labmon1001' },
        'grafana.wikimedia.org'                  => { 'director' => 'krypton' },
        'graphite-labs.wikimedia.org'            => { 'director' => 'labmon1001' },
        'graphite.wikimedia.org'                 => { 'director' => 'graphite1001' },
        'horizon.wikimedia.org'                  => { 'director' => 'californium' },
        'hue.wikimedia.org'                      => { 'director' => 'analytics1027' },
        'iegreview.wikimedia.org'                => { 'director' => 'krypton' },
        'integration.wikimedia.org'              => { 'director' => 'gallium' },
        '(?i)^([^.]+\.)?planet\.wikimedia\.org$' => { 'director' => 'planet1001' },
        'latesthorizon.wikimedia.org'            => { 'director' => 'labtestweb2001' },
        'logstash.wikimedia.org'                 => { 'director' => 'logstash_director' },
        'metrics.wikimedia.org'                  => { 'director' => 'stat1001' },
        'noc.wikimedia.org'                      => { 'director' => 'noc' },
        'ores.wikimedia.org'                     => { 'director' => 'ores' },
        'parsoid-tests.wikimedia.org'            => { 'director' => 'ruthenium' },
        'people.wikimedia.org'                   => { 'director' => 'rutherfordium' },
        'performance.wikimedia.org'              => { 'director' => 'graphite1001' },
        'phabricator.wikimedia.org'              => { 'director' => 'iridium' },
        'phab.wmfusercontent.org'                => { 'director' => 'iridium' },
        'piwik.wikimedia.org'                    => { 'director' => 'bohrium' },
        'query.wikimedia.org'                    => { 'director' => 'wdqs_director' },
        'racktables.wikimedia.org'               => { 'director' => 'krypton' },
        'releases.wikimedia.org'                 => { 'director' => 'bromine' },
        'rt.wikimedia.org'                       => { 'director' => 'ununpentium' },
        'scholarships.wikimedia.org'             => { 'director' => 'krypton' },
        'servermon.wikimedia.org'                => { 'director' => 'netmon1001' },
        'smokeping.wikimedia.org'                => { 'director' => 'netmon1001' },
        'static-bugzilla.wikimedia.org'          => { 'director' => 'bromine' },
        'stats.wikimedia.org'                    => { 'director' => 'stat1001' },
        'stream.wikimedia.org'                   => { 'director' => 'rcstream' },
        'ticket.wikimedia.org'                   => { 'director' => 'mendelevium' },
        'torrus.wikimedia.org'                   => { 'director' => 'netmon1001' },
        'transparency.wikimedia.org'             => { 'director' => 'bromine' },
    }

    $common_vcl_config = {
        'allowed_methods'  => '^(GET|DELETE|HEAD|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'ttl_cap'            => '1d',
    })

    # We're testing file vs persistent as a factor in some varnish4 bugs observed...
    $storage_parts = $::role::cache::2layer::storage_parts
    $storage_size = $::role::cache::2layer::storage_size
    $misc_storage_args = join([
        "-s main1=file,/srv/${storage_parts[0]}/varnish.main1,${storage_size}G",
        "-s main2=file,/srv/${storage_parts[1]}/varnish.main2,${storage_size}G",
    ], ' ')

    role::cache::instances { 'misc':
        fe_mem_gb        => ceiling(0.5 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf => 'lg_dirty_mult:8,lg_chunk_size:17',
        runtime_params   => ['default_ttl=3600'],
        app_directors    => $app_directors,
        fe_vcl_config    => $fe_vcl_config,
        be_vcl_config    => $be_vcl_config,
        fe_extra_vcl     => ['misc-common'],
        be_extra_vcl     => ['misc-common'],
        be_storage       => $misc_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => hiera('cache::misc::nodes'),
    }
}
