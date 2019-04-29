class role::grafana {
    system::role { 'grafana':
        description => 'Grafana monitoring web server'
    }

    include ::profile::standard
    include ::profile::base::firewall

    class { '::httpd':
        modules => ['authnz_ldap', 'headers', 'proxy', 'proxy_http', 'rewrite']
    }

    include ::profile::grafana::production
}
