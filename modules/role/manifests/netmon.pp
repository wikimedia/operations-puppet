class role::netmon {
    system::role { 'netmon':
        description => 'Network monitoring and management'
    }
    # Basic boilerplate for network-related servers
    require ::role::network::monitor
    # needed by librenms and netbox web servers
    class { '::sslcert::dhparam': }
    include ::profile::atlasexporter
    include ::profile::backup::host
    include ::profile::librenms
    include ::profile::rancid
    include ::profile::smokeping

    if os_version('debian == stretch') {
        $php_module = 'php7.2'
    } else {
        $php_module = 'php7.3'
    }

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'ssl',
                    'fcgid',
                    $php_module,
                    ],
    }
}
