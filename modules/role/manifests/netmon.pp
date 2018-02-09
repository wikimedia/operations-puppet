class role::netmon {
    system::role { 'netmon':
        description => 'Network monitoring and management'
    }
    # Basic boilerplate for network-related servers
    require ::role::network::monitor
    include ::profile::backup::host
    include ::profile::librenms
    include ::profile::rancid
    include ::profile::smokeping
    include ::profile::netbox
    include ::profile::prometheus::postgres_exporter

    if os_version('debian >= stretch') {
        $php_module = 'php7'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http', 'ssl', 'wsgi', $php_module, 'fcgid'],
    }

    interface::add_ip6_mapped { 'main': }
}
