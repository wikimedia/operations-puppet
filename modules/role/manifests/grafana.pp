class role::grafana {
    include profile::base::production
    include profile::firewall

    class { '::httpd':
        modules => ['authnz_ldap', 'headers', 'proxy', 'proxy_http', 'rewrite']
    }

    include profile::grafana::production
    include profile::backup::host
    include profile::tlsproxy::envoy # TLS termination
}
