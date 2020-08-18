# @summary profile to configure librenms website
class profile::librenms::web {

    require profile::librenms

    $sitename       = $profile::librenms::sitename
    $install_dir    = $profile::librenms::install_dir
    $active_server  = $profile::librenms::active_server
    $auth_mechanism = $profile::librenms::auth_mechanism
    $ssl_settings   = ssl_ciphersuite('apache', 'strong', true)

    acme_chief::cert { 'librenms':
        puppet_svc => 'apache2',
    }

    if $auth_mechanism == 'sso' {
        include profile::idp::client::httpd_legacy
    } else {
        httpd::site { $sitename:
            content => template('profile/librenms/apache.conf.erb'),
        }
    }


    $monitoring_ensure = $active_server ? {
        $facts['fqdn'] => 'present',
        default        => 'absent',
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
