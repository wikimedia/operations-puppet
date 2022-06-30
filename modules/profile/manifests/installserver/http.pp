# Installs a web server for the install server
class profile::installserver::http {

    include install_server::web_server # lint:ignore:wmf_styleguide

    class { '::sslcert::dhparam': }

    acme_chief::cert { 'apt':
        puppet_rsc =>  Exec['nginx-reload'],
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
