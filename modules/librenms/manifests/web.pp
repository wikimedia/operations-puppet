class librenms::web(
    $sitename,
    $install_dir,
    $active_server,
) {

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    httpd::site { $sitename:
        content => template('librenms/apache.conf.erb'),
    }

    letsencrypt::cert::integrated { 'librenms':
        subjects   => 'librenms.wikimedia.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
        require    => Class['httpd'],
    }

    if $active_server == $::fqdn {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }

    monitoring::service { 'https':
        ensure        => $monitoring_ensure,
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!librenms.wikimedia.org',
    }

    monitoring::service { 'librenms':
        ensure        => $monitoring_ensure,
        description   => 'LibreNMS HTTPS',
        check_command => "check_https_url!${sitename}!http://${sitename}",
    }
}
