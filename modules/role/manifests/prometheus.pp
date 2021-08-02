class role::prometheus {
    system::role { 'prometheus':
        description => 'Prometheus server (main data centres)',
    }

    include ::profile::prometheus::k8s
    include ::profile::prometheus::analytics
    include ::profile::prometheus::services
    include ::profile::prometheus::global
    include ::profile::prometheus::ops
    include ::profile::prometheus::ops_mysql
    include ::profile::prometheus::ext

    include ::profile::prometheus::pushgateway

    include ::profile::alerts::deploy::prometheus

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::lvs::realserver

    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite'],
    }
}
