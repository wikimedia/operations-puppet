class librenms::web(
    $sitename,
    $install_dir,
) {
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::apache::mod::ssl

    if os_version('debian >= jessie || ubuntu >= trusty') {
        $ssl_settings = ssl_ciphersuite('apache-2.4', 'compat')
    } else {
        $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')
    }

    apache::site { $sitename:
        content => template('librenms/apache.conf.erb'),
    }

    sslcert::certificate { $sitename: }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!librenms.wikimedia.org',
    }

    monitoring::service { 'librenms':
        description   => 'LibreNMS HTTPS',
        check_command => "check_https_url!${sitename}!http://${sitename}",
    }
}
