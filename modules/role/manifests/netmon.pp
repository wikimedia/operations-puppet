class role::netmon {
    system::role { 'netmon':
        description => 'Network monitoring and management'
    }
    # Basic boilerplate for network-related servers
    require ::role::network::monitor
    # needed by librenms and netbox web servers
    class { '::sslcert::dhparam': }
    include ::profile::backup::host
    include ::profile::librenms
    include ::profile::rancid
    include ::profile::smokeping
    include ::profile::netbox
    include ::profile::prometheus::postgres_exporter

    if os_version('debian >= stretch') {
        $php_module = 'php7.2'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'ssl',
                    'wsgi',
                    'fcgid',
                    $php_module,
                    ],
    }

    interface::add_ip6_mapped { 'main': }
}
