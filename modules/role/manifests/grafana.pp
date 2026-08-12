class role::grafana {
    include profile::base::production
    include profile::firewall

    class { '::httpd':
        modules   => ['authnz_ldap', 'headers', 'proxy', 'proxy_http',
                      'rewrite', 'ssl'],
        http_only => true,
    }

    include profile::grafana::production
    include profile::backup::host
    include profile::tlsproxy::envoy # TLS termination

    include profile::grafana::plugin::grafana_image_renderer
    include profile::grafana::plugin::dashboard_reporter
}
