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

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'static_host'      => $static_host,
        'top_domain'       => $top_domain,
        'shortener_domain' => $shortener_domain,
        'pass_random'      => true,
        'req_handling'     => hiera('cache::req_handling'),
    }

    $be_vcl_config = $common_vcl_config

    $fe_vcl_config = merge($common_vcl_config, {
        'enable_geoiplookup' => true,
    })

    $common_runtime_params = ['default_ttl=86400']

    $text_storage_args = $::role::cache::base::file_storage_args

    $errorpage = {
        title  => 'Browser Connection Security Issue',
        pagetitle => "Your Browser's Connection Security is Outdated",
        logo_link => 'https://www.wikimedia.org',
        logo_src => 'https://www.wikimedia.org/static/images/wmf.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-2x.png 2x',
        content   => "<p>Your browser is connecting to our servers with outdated connection security.  The most common causes of this are using Internet Explorer on Windows XP (upgrade your operating system or use Firefox!), or interference from corporate or personal \"Web Security\" software which actually downgrades connection security.</p><p>Less than 0.2% of our users fall into this insecure category.  Currently, we randomly send a small percentage of such requests to this warning page (you can try again and still view content), but we'll be removing support for these insecure connections completely in the future, which will block your access to our sites if you haven't upgraded in time.</p><p>Our <a href=\"https://wikitech.wikimedia.org/wiki/HTTPS:_Browser_Recommendations\">HTTPS: Browser Recommendations</a> page on wikitech has more-detailed information on fixing this situation.</p>",
    }
    $error_browsersec_html = template('mediawiki/errorpage.html.erb')

    role::cache::instances { 'text':
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:16',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => hiera('cache::app_directors'),
        app_def_be_opts   => hiera('cache::app_def_be_opts'),
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['text-common', 'zero', 'normalize_path', 'geoip', 'browsersec'],
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
