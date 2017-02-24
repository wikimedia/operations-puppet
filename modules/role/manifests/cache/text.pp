# filtertags: labs-project-deployment-prep
class role::cache::text(
    # static_host must serve MediaWiki (e.g. not wwwportal)
    $static_host = 'en.wikipedia.org',
    $top_domain = 'org',
    $shortener_domain = 'w.wiki',
) {
    require geoip
    require geoip::dev # for VCL compilation using libGeoIP
    include role::cache::base
    include role::cache::ssl::unified
    include ::standard

    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.112' ],
    }

    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['text'][$::site]
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
        'first_byte_timeout'    => '180s',
        'max_connections'       => 1000,
        'probe'                 => 'varnish',
    }

    $app_def_be_opts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '180s',
        'max_connections'       => 1000,
    }

    $app_directors = {
        'appservers'       => {
            'backend' => 'appservers.svc.eqiad.wmnet',
        },
        'api'              => {
            'backend' => 'api.svc.eqiad.wmnet',
        },
        'rendering'        => {
            'backend' => 'rendering.svc.eqiad.wmnet',
        },
        'security_audit'   => {
            'backend' => 'appservers.svc.eqiad.wmnet',
        },
        'appservers_debug'   => {
            # 'backend' => 'hassium.eqiad.wmnet',
            'backend' => 'hassaleh.codfw.wmnet',
            'be_opts' => { 'max_connections' => 20 },
        },
        'restbase_backend' => {
            'backend' => 'restbase.svc.eqiad.wmnet',
            'be_opts' => { 'port' => 7231, 'max_connections' => 5000 },
        },
        'cxserver_backend' => { # LEGACY: should be removed eventually
            'backend' => 'cxserver.svc.eqiad.wmnet',
            'be_opts' => { 'port' => 8080 },
        },
        'citoid_backend'   => { # LEGACY: should be removed eventually
            'backend' => 'citoid.svc.eqiad.wmnet',
            'be_opts' => { 'port' => 1970 },
        },
    }

    $req_handling = {
        'cxserver.wikimedia.org' => {
            'director' => 'cxserver_backend',
            'caching'  => 'pass',
        },
        'citoid.wikimedia.org'   => {
            'director' => 'citoid_backend',
            'caching'  => 'pass',
        },
        'default'                => {
            'director'       => 'appservers',
            'debug_director' => 'appservers_debug',
            'subpaths' => {
                '^/api/rest_v1/' => {
                    'director' => 'restbase_backend'
                },
                '^/w/api\.php'   => {
                    'director'       => 'api',
                    'debug_director' => 'appservers_debug',
                },
                '^/w/thumb(_handler)?\.php' => {
                    'director'       => 'rendering',
                    'debug_director' => 'appservers_debug',
                }
            }
        },
    }

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'static_host'      => $static_host,
        'top_domain'       => $top_domain,
        'shortener_domain' => $shortener_domain,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'enable_geoiplookup' => true,
        'ttl_cap'            => '1d',
    })

    $common_runtime_params = ['default_ttl=2592000']

    $text_storage_args = $::role::cache::base::file_storage_args

    role::cache::instances { 'text':
        fe_mem_gb         => ceiling(0.4 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:16',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => $app_directors,
        app_def_be_opts   => $app_def_be_opts,
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['text-common', 'zero', 'normalize_path', 'geoip'],
        be_extra_vcl      => ['text-common', 'normalize_path'],
        be_storage        => $text_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => hiera('cache::text::nodes'),
    }

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka.
    # A kafka consumer then consumes these and emits
    # metrics.
    class { '::role::cache::kafka::statsv': }

    # varnishkafka eventlogging listens for eventlogging
    # requests and logs them to the eventlogging-client-side
    # topic.  EventLogging servers consume and process this
    # topic into many JSON based kafka topics for further
    # consumption.
    class { '::role::cache::kafka::eventlogging': }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
        statsd_server => hiera('statsd'),
    }
}
