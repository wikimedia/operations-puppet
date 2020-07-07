# @summary profile to configure librenms website
class profile::librenms::web {

    require profile::librenms
    $sitename      = $profile::librenms::sitename
    $install_dir   = $profile::librenms::install_dir
    $active_server = $profile::librenms::active_server
    $ssl_settings  = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { $sitename:
        content => template('profile/librenms/apache.conf.erb'),
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
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LibreNMS',
    }

    monitoring::service { 'librenms':
        ensure        => $monitoring_ensure,
        description   => 'LibreNMS HTTPS',
        check_command => "check_https_url!${sitename}!http://${sitename}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LibreNMS',
    }
}
