# === class profile::trafficserver::tls
#
# Class that sets up a Traffic Server TLS terminator instance.
#
class profile::trafficserver::tls (
    String $user=hiera('profile::trafficserver::tls::user', 'trafficserver'),
    Stdlib::Port $port=hiera('profile::trafficserver::tls::port', 8443),
    Trafficserver::Inbound_TLS_settings $inbound_tls_settings=hiera('profile::trafficserver::tls::inbound_tls_settings'),
    Boolean $enable_xdebug=hiera('profile::trafficserver::tls::enable_xdebug', false),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::tls::mapping_rules', []),
    String $default_lua_script=hiera('profile::trafficserver::tls::default_lua_script', ''),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::tls::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::tls::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::tls::logs', []),
    Array[TrafficServer::Parent_rule] $parent_rules=hiera('profile::trafficserver::tls::parent_rules'),
    Wmflib::UserIpPort $prometheus_exporter_port=hiera('profile::trafficserver::tls::prometheus_exporter_port', 9322),
    Optional[String] $ocsp_proxy=hiera('http_proxy'),
){
    $errorpage = {
        title       => 'Wikimedia Error',
        pagetitle   => 'Error',
        logo_link   => 'https://www.wikimedia.org',
        logo_src    => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        logo_width  => '135',
        logo_height => '101',
        logo_alt    => 'Wikimedia',
        content     => template('varnish/errorpage.body.html.erb'),
        # An explanation for these (and more) fields is available here:
        # https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/formatting.en.html
        # Rendered example:
        # Request from 93.184.216.34 via cp1071.eqiad.wmnet, ATS/8.0.3
        # Error: 502, connect failed at 2019-04-04 12:22:08 GMT
        footer      => "<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p><p class='text-muted'><code>Request from %<{X-Client-IP}cqh> via ${::fqdn}, %<{Server}psh><br>Error: %<pssc>, %<prrp> at %<cqtd> %<cqtt> GMT</code></p>",
    }

    $instance_name = 'tls'
    $service_name = "trafficserver-${instance_name}"
    $do_ocsp = !empty($inbound_tls_settings['ocsp_stapling_path'])
    $paths = trafficserver::get_paths(false, $instance_name)

    profile::trafficserver::tls_material { 'unified':
        instance_name      => $instance_name,
        service_name       => $service_name,
        ssl_multicert_path => $paths['ssl_multicert'],
        certs              => ['globalsign-2018-ecdsa-unified', 'globalsign-2018-rsa-unified'],
        do_ocsp            => $do_ocsp,
        ocsp_proxy         => $ocsp_proxy,
    }

    trafficserver::instance { $instance_name:
        paths                => $paths,
        port                 => $port,
        inbound_tls_settings => $inbound_tls_settings,
        enable_xdebug        => $enable_xdebug,
        mapping_rules        => $mapping_rules,
        enable_caching       => false,
        log_formats          => $log_formats,
        log_filters          => $log_filters,
        logs                 => $logs,
        parent_rules         => $parent_rules,
        error_page           => template('mediawiki/errorpage.html.erb'),
    }

    # Monitoring
    profile::trafficserver::monitoring { "trafficserver_${instance_name}_monitoring":
        paths                    => $paths,
        port                     => $port,
        prometheus_exporter_port => $prometheus_exporter_port,
        inbound_tls              => true,
        do_ocsp                  => $do_ocsp,
        instance_name            => $instance_name,
        user                     => $user,
    }

    profile::trafficserver::logs { "trafficserver_${instance_name}_logs":
        instance_name   => $instance_name,
        user            => $user,
        service_name    => $service_name,
        logs            => $logs,
        paths           => $paths,
        atslog_filename => 'tls',
    }
}
