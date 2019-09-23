# Installs a web server for the install server
class profile::installserver::http {

    include install_server::web_server
    class { '::sslcert::dhparam': }

    acme_chief::cert { 'apt':
        puppet_rsc => Exec['nginx-reload'],
    }

    ferm::service { 'install_http':
        proto => 'tcp',
        port  => '(http https)'
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/APT_repository',
    }
    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt_ocsp!apt.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/APT_repository',
    }
}

