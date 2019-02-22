class librenms::web(
    Stdlib::Fqdn $sitename,
    Stdlib::Unixpath $install_dir,
    Stdlib::Fqdn $active_server,
) {

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    httpd::site { $sitename:
        content => template('librenms/apache.conf.erb'),
    }

    acme_chief::cert { 'librenms':
        puppet_svc => 'apache2',
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
