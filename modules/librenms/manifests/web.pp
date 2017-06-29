class librenms::web(
    $sitename,
    $install_dir,
) {
    include ::apache::mod::php7
    include ::apache::mod::rewrite

    include ::apache::mod::ssl

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    apache::site { $sitename:
        content => template('librenms/apache.conf.erb'),
    }

    letsencrypt::cert::integrated { 'librenms':
        subjects   => 'librenms.wikimedia.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
        require    => Class['apache::mod::ssl'],
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!librenms.wikimedia.org',
    }

    monitoring::service { 'librenms':
        description   => 'LibreNMS HTTPS',
        check_command => "check_https_url!${sitename}!http://${sitename}",
    }
}
