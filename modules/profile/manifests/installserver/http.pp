# Installs a web server for the install server
class profile::installserver::http {

    # prevent a /srv root autoindex; empty for now.
    file { '/srv/index.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => '',
    }

    class { '::sslcert::dhparam': }

    acme_chief::cert { 'apt':
        puppet_svc => 'apache2',
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
