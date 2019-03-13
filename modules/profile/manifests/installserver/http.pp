# Installs a web server for the install server
class profile::installserver::http {

    include install_server::web_server
    class { '::sslcert::dhparam': }

    acme_chief::cert { 'apt':
        puppet_svc => 'nginx',
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
}

